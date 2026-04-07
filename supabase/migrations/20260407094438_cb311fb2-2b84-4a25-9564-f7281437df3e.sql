
-- Announcement reactions
CREATE TABLE public.announcement_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  reaction text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(announcement_id, user_id, reaction)
);
ALTER TABLE public.announcement_reactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff read announcement reactions" ON public.announcement_reactions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff add announcement reactions" ON public.announcement_reactions FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff remove own announcement reactions" ON public.announcement_reactions FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Announcement comments
CREATE TABLE public.announcement_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  author_id uuid NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.announcement_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff read announcement comments" ON public.announcement_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff add announcement comments" ON public.announcement_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Author or exec delete announcement comments" ON public.announcement_comments FOR DELETE TO authenticated USING (auth.uid() = author_id OR is_executive(auth.uid()));
CREATE POLICY "Author update announcement comments" ON public.announcement_comments FOR UPDATE TO authenticated USING (auth.uid() = author_id);

-- Site content (news, testimonials, gallery)
CREATE TABLE public.site_content (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_type text NOT NULL DEFAULT 'news',
  title text NOT NULL,
  content text,
  attachment_urls text[] DEFAULT '{}',
  audience text NOT NULL DEFAULT 'both',
  status text NOT NULL DEFAULT 'draft',
  author_id uuid NOT NULL,
  client_name text,
  client_company text,
  rating integer,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.site_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read published client content" ON public.site_content FOR SELECT TO anon USING (status = 'published' AND audience IN ('client', 'both'));
CREATE POLICY "Staff read all content" ON public.site_content FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO creates content" ON public.site_content FOR INSERT TO authenticated WITH CHECK (is_ceo(auth.uid()) AND auth.uid() = author_id);
CREATE POLICY "CEO updates content" ON public.site_content FOR UPDATE TO authenticated USING (is_ceo(auth.uid()));
CREATE POLICY "CEO deletes content" ON public.site_content FOR DELETE TO authenticated USING (is_ceo(auth.uid()));

-- Trigger for updated_at
CREATE TRIGGER update_site_content_updated_at BEFORE UPDATE ON public.site_content FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Site content storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('site-content', 'site-content', true);
CREATE POLICY "Anyone can read site content files" ON storage.objects FOR SELECT USING (bucket_id = 'site-content');
CREATE POLICY "Authenticated upload site content" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'site-content');
CREATE POLICY "CEO delete site content files" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'site-content' AND is_ceo(auth.uid()));

-- Visitor log for live counter
CREATE TABLE public.visitor_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_hash text NOT NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.visitor_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can insert visitor" ON public.visitor_log FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Anyone can read visitors" ON public.visitor_log FOR SELECT TO anon, authenticated USING (true);

-- Function to get and increment visitor count
CREATE OR REPLACE FUNCTION public.track_visitor(p_hash text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count bigint;
BEGIN
  INSERT INTO visitor_log (visitor_hash) VALUES (p_hash) ON CONFLICT DO NOTHING;
  SELECT count(*) INTO v_count FROM visitor_log;
  RETURN v_count;
END;
$$;

-- Add unique constraint on visitor_hash
ALTER TABLE public.visitor_log ADD CONSTRAINT visitor_log_hash_unique UNIQUE (visitor_hash);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcement_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcement_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.visitor_log;
