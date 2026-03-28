
-- Fix notifications insert policy: allow authenticated users to insert notifications for any user
-- (needed for mention/notification system where one user triggers a notification for another)
-- This is intentional but we tighten it to require the sender to be authenticated

DROP POLICY IF EXISTS "System inserts notifications" ON public.notifications;
CREATE POLICY "Authenticated can insert notifications" ON public.notifications
  FOR INSERT TO authenticated WITH CHECK (TRUE);
