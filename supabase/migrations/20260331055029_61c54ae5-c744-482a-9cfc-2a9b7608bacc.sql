
-- 1. Add attachment_urls to support_tickets
ALTER TABLE public.support_tickets ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}'::text[];

-- 2. Add assigned_to_ids (multi-assign) to support_tickets
ALTER TABLE public.support_tickets ADD COLUMN IF NOT EXISTS assigned_to_ids uuid[] DEFAULT '{}'::uuid[];

-- 3. Create activity_logs table for audit monitoring
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  action text NOT NULL,
  module text NOT NULL,
  target_id uuid,
  target_type text,
  details jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- CEO and executives can read all logs
CREATE POLICY "CEO reads all activity logs" ON public.activity_logs
  FOR SELECT TO authenticated
  USING (is_ceo(auth.uid()) OR is_executive(auth.uid()));

-- Any authenticated user can insert logs (their own actions)
CREATE POLICY "Users insert own activity logs" ON public.activity_logs
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 4. Create storage bucket for ticket attachments
INSERT INTO storage.buckets (id, name, public) VALUES ('ticket-attachments', 'ticket-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- 5. Storage policies for ticket-attachments
CREATE POLICY "Authenticated users upload ticket files" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'ticket-attachments');

CREATE POLICY "Anyone can read ticket files" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'ticket-attachments');

CREATE POLICY "Owner or exec delete ticket files" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'ticket-attachments' AND (auth.uid()::text = (storage.foldername(name))[1] OR is_executive(auth.uid())));

-- 6. Allow CEO to delete tickets
CREATE POLICY "CEO deletes tickets" ON public.support_tickets
  FOR DELETE TO authenticated
  USING (is_ceo(auth.uid()) OR created_by = auth.uid());

-- 7. Allow delete on leave_requests for CEO
CREATE POLICY "CEO deletes leave requests" ON public.leave_requests
  FOR DELETE TO authenticated
  USING (is_ceo(auth.uid()) OR user_id = auth.uid());

-- 8. Allow update on ticket_comments
CREATE POLICY "Author updates ticket comments" ON public.ticket_comments
  FOR UPDATE TO authenticated
  USING (auth.uid() = author_id);

-- 9. Allow delete on ticket_comments
CREATE POLICY "Author or exec deletes ticket comments" ON public.ticket_comments
  FOR DELETE TO authenticated
  USING (auth.uid() = author_id OR is_executive(auth.uid()));

-- 10. Allow update on plan_comments
CREATE POLICY "Author updates plan comments" ON public.plan_comments
  FOR UPDATE TO authenticated
  USING (auth.uid() = author_id);

-- 11. Allow delete on attendance for CEO
CREATE POLICY "CEO deletes attendance" ON public.attendance
  FOR DELETE TO authenticated
  USING (is_ceo(auth.uid()));

-- 12. Allow delete on project_tasks for creator/exec
CREATE POLICY "Creator or exec deletes tasks" ON public.project_tasks
  FOR DELETE TO authenticated
  USING (auth.uid() = created_by OR is_executive(auth.uid()));

-- 13. Allow update on project_updates
CREATE POLICY "Author updates project updates" ON public.project_updates
  FOR UPDATE TO authenticated
  USING (auth.uid() = author_id OR is_executive(auth.uid()));
