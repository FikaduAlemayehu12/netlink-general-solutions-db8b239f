
-- =============================================
-- STEP 2: RLS POLICIES + UPDATED FUNCTIONS
-- =============================================

-- Update is_executive to include new executive roles
CREATE OR REPLACE FUNCTION public.is_executive(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id
      AND role IN ('ceo', 'cto', 'coo', 'cio', 'hr', 'sysadmin', 'finance_manager', 'bd_head')
  )
$$;

-- SUPPORT TICKETS RLS
CREATE POLICY "Staff can create tickets" ON public.support_tickets
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Staff can read relevant tickets" ON public.support_tickets
  FOR SELECT TO authenticated
  USING (auth.uid() = created_by OR auth.uid() = assigned_to OR is_executive(auth.uid()));

CREATE POLICY "Assigned or exec can update tickets" ON public.support_tickets
  FOR UPDATE TO authenticated
  USING (auth.uid() = assigned_to OR auth.uid() = created_by OR is_executive(auth.uid()));

-- TICKET COMMENTS RLS
CREATE POLICY "Read ticket comments" ON public.ticket_comments
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets t
      WHERE t.id = ticket_comments.ticket_id
        AND (t.created_by = auth.uid() OR t.assigned_to = auth.uid() OR is_executive(auth.uid()))
    )
  );

CREATE POLICY "Create ticket comments" ON public.ticket_comments
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);

-- ATTENDANCE RLS
CREATE POLICY "Staff can clock in" ON public.attendance
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff read own or exec reads all" ON public.attendance
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));

CREATE POLICY "Staff update own attendance" ON public.attendance
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));

-- LEAVE REQUESTS RLS
CREATE POLICY "Staff create own leave" ON public.leave_requests
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff read own or exec reads all" ON public.leave_requests
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));

CREATE POLICY "HR or Exec approve leave" ON public.leave_requests
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));

-- ANNOUNCEMENTS RLS
CREATE POLICY "All staff read announcements" ON public.announcements
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Executives create announcements" ON public.announcements
  FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = author_id);

CREATE POLICY "Executives update announcements" ON public.announcements
  FOR UPDATE TO authenticated USING (is_executive(auth.uid()));

CREATE POLICY "Executives delete announcements" ON public.announcements
  FOR DELETE TO authenticated USING (is_executive(auth.uid()));
