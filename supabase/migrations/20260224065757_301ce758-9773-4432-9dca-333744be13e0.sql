
-- 1. Add birthday column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birthday date;

-- 2. Add attachment_urls to plans for file attachments
ALTER TABLE public.plans ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}';

-- 3. Create team_messages table for real-time chat
CREATE TABLE public.team_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL,
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.team_messages ENABLE ROW LEVEL SECURITY;

-- Team members can read messages in their groups
CREATE POLICY "Team members read messages" ON public.team_messages
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_groups pg
    WHERE pg.id = team_messages.group_id
    AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR is_executive(auth.uid()))
  )
);

-- Team members can send messages in their groups
CREATE POLICY "Team members send messages" ON public.team_messages
FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM project_groups pg
    WHERE pg.id = team_messages.group_id
    AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR is_executive(auth.uid()))
  )
);

-- Team members can delete own messages
CREATE POLICY "Delete own messages" ON public.team_messages
FOR DELETE USING (auth.uid() = sender_id);

-- Enable realtime for team_messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_messages;

-- 4. Storage bucket for avatars
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- Avatar storage policies
CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users upload own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users update own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own avatar" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 5. Storage bucket for plan attachments (100MB per file)
INSERT INTO storage.buckets (id, name, public, file_size_limit) VALUES ('plan-attachments', 'plan-attachments', true, 104857600);

-- Plan attachment storage policies
CREATE POLICY "Staff view plan attachments" ON storage.objects FOR SELECT USING (bucket_id = 'plan-attachments');
CREATE POLICY "Staff upload plan attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'plan-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Staff delete own plan attachments" ON storage.objects FOR DELETE USING (bucket_id = 'plan-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 6. Create a function to check if user is CEO
CREATE OR REPLACE FUNCTION public.is_ceo(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = 'ceo'
  )
$$;
