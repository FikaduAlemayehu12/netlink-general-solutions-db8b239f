
-- Create storage bucket for project attachments
INSERT INTO storage.buckets (id, name, public) VALUES ('project-attachments', 'project-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload project attachments
CREATE POLICY "Authenticated users can upload project attachments"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'project-attachments');

-- Allow authenticated users to read project attachments
CREATE POLICY "Authenticated users can read project attachments"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'project-attachments');

-- Allow users to delete their own project attachments
CREATE POLICY "Users can delete own project attachments"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'project-attachments');
