
-- Recycle Bin table for soft-deleted records
CREATE TABLE public.deleted_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  original_table text NOT NULL,
  original_id uuid NOT NULL,
  deleted_by uuid NOT NULL,
  deleted_at timestamptz NOT NULL DEFAULT now(),
  record_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  reason text
);

ALTER TABLE public.deleted_records ENABLE ROW LEVEL SECURITY;

-- Only CEO can view deleted records
CREATE POLICY "CEO reads deleted records"
  ON public.deleted_records FOR SELECT TO authenticated
  USING (is_ceo(auth.uid()));

-- Authenticated users can insert (system logs deletions)
CREATE POLICY "Authenticated insert deleted records"
  ON public.deleted_records FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = deleted_by);

-- Only CEO can permanently delete from recycle bin
CREATE POLICY "CEO deletes from recycle bin"
  ON public.deleted_records FOR DELETE TO authenticated
  USING (is_ceo(auth.uid()));

-- Add leave attachment support
ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}'::text[];

-- Create leave-attachments storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('leave-attachments', 'leave-attachments', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Auth upload leave attachments"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'leave-attachments');

CREATE POLICY "Public read leave attachments"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'leave-attachments');
