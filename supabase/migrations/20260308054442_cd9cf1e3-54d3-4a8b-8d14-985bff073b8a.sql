
-- Project milestones table for tracking 25/50/75/100% progress
CREATE TABLE public.project_milestones (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  target_percentage INTEGER NOT NULL,
  target_date DATE NOT NULL,
  actual_date DATE,
  status TEXT NOT NULL DEFAULT 'pending',
  reviewer_id UUID,
  reviewer_notes TEXT,
  action_items TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Project comments table for all-staff commenting
CREATE TABLE public.project_comments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  author_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.project_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_comments ENABLE ROW LEVEL SECURITY;

-- Milestone policies: all staff can read, CEO/exec can manage
CREATE POLICY "All staff read milestones" ON public.project_milestones FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO or exec manage milestones" ON public.project_milestones FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()));
CREATE POLICY "CEO or exec update milestones" ON public.project_milestones FOR UPDATE TO authenticated USING (is_executive(auth.uid()) OR auth.uid() = reviewer_id);
CREATE POLICY "CEO or exec delete milestones" ON public.project_milestones FOR DELETE TO authenticated USING (is_executive(auth.uid()));

-- Project comment policies: all staff can read and post
CREATE POLICY "All staff read project comments" ON public.project_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "All staff post project comments" ON public.project_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Own or exec delete project comments" ON public.project_comments FOR DELETE TO authenticated USING (auth.uid() = author_id OR is_executive(auth.uid()));

-- Update project_groups RLS: all staff can view all projects
DROP POLICY IF EXISTS "Staff read groups they belong to" ON public.project_groups;
CREATE POLICY "All staff read all projects" ON public.project_groups FOR SELECT TO authenticated USING (true);

-- Update support_tickets RLS: all staff can view all tickets
DROP POLICY IF EXISTS "Staff can read relevant tickets" ON public.support_tickets;
CREATE POLICY "All staff read all tickets" ON public.support_tickets FOR SELECT TO authenticated USING (true);

-- Update ticket assignment: CEO or creator can assign
DROP POLICY IF EXISTS "Assigned or exec can update tickets" ON public.support_tickets;
CREATE POLICY "CEO creator or assigned update tickets" ON public.support_tickets FOR UPDATE TO authenticated USING (
  auth.uid() = assigned_to OR auth.uid() = created_by OR is_executive(auth.uid())
);

-- Add due_date to support_tickets
ALTER TABLE public.support_tickets ADD COLUMN IF NOT EXISTS due_date DATE;

-- Enable realtime for new tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_milestones;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_comments;
