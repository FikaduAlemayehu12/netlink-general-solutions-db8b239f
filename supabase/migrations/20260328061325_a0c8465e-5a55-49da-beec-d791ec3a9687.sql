
-- Progress updates table for daily/weekly/monthly/quarterly submissions
CREATE TABLE public.project_updates (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  author_id UUID NOT NULL,
  update_type TEXT NOT NULL DEFAULT 'daily',
  content TEXT NOT NULL,
  attachment_urls TEXT[] DEFAULT '{}'::text[],
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.project_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All staff read project updates" ON public.project_updates
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Members post updates" ON public.project_updates
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Own or exec delete updates" ON public.project_updates
  FOR DELETE TO authenticated
  USING (auth.uid() = author_id OR is_executive(auth.uid()));

-- Add completed_at and final_attachment_urls to project_groups
ALTER TABLE public.project_groups
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS final_attachment_urls TEXT[] DEFAULT '{}'::text[];

-- Enable realtime for project_updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_updates;
