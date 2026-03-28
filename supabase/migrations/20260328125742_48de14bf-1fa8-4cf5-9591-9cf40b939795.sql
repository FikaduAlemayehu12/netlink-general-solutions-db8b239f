
-- 1. Role enum
CREATE TYPE public.app_role AS ENUM ('ceo', 'cto', 'coo', 'hr', 'sysadmin', 'staff', 'cio', 'finance_manager', 'bd_head', 'network_engineer', 'support_tech');

-- 2. Profiles table
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  position TEXT,
  bio TEXT,
  avatar_url TEXT,
  email TEXT NOT NULL,
  must_change_password BOOLEAN NOT NULL DEFAULT TRUE,
  department text,
  phone text,
  birthday date,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. User roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  UNIQUE (user_id, role)
);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 4. Security definer functions
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role) $$;

CREATE OR REPLACE FUNCTION public.is_executive(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('ceo', 'cto', 'coo', 'cio', 'hr', 'sysadmin', 'finance_manager', 'bd_head')) $$;

CREATE OR REPLACE FUNCTION public.is_ceo(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = 'ceo') $$;

-- 5. Plans table
CREATE TABLE public.plans (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID NOT NULL,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('daily', 'weekly', 'quarterly')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  mentioned_user_ids UUID[] DEFAULT '{}',
  attachment_urls text[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

-- 6. Plan comments
CREATE TABLE public.plan_comments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  author_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.plan_comments ENABLE ROW LEVEL SECURITY;

-- 7. Plan reactions
CREATE TABLE public.plan_reactions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reaction TEXT NOT NULL CHECK (reaction IN ('like', 'dislike', 'approve')),
  UNIQUE (plan_id, user_id)
);
ALTER TABLE public.plan_reactions ENABLE ROW LEVEL SECURITY;

-- 8. Performance scores
CREATE TABLE public.performance_scores (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL,
  assigned_by UUID NOT NULL,
  plan_id UUID REFERENCES public.plans(id) ON DELETE SET NULL,
  points INTEGER NOT NULL DEFAULT 0,
  quarter TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.performance_scores ENABLE ROW LEVEL SECURITY;

-- 9. Quarter winners
CREATE TABLE public.quarter_winners (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  winner_id UUID NOT NULL,
  quarter TEXT NOT NULL UNIQUE,
  message TEXT,
  banner_url TEXT,
  posted_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.quarter_winners ENABLE ROW LEVEL SECURITY;

-- 10. Project groups
CREATE TABLE public.project_groups (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  member_ids UUID[] DEFAULT '{}',
  status text DEFAULT 'active',
  start_date date,
  end_date date,
  budget numeric(12,2),
  manager_id uuid,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  final_attachment_urls TEXT[] DEFAULT '{}'::text[],
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.project_groups ENABLE ROW LEVEL SECURITY;

-- 11. Project tasks
CREATE TABLE public.project_tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  priority text DEFAULT 'medium',
  due_date date,
  attachments text[],
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;

-- 12. Notifications
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  related_id UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Support tickets
CREATE TABLE public.support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), ticket_number serial,
  title text NOT NULL, description text NOT NULL, category text NOT NULL DEFAULT 'general',
  priority text NOT NULL DEFAULT 'medium', status text NOT NULL DEFAULT 'open',
  created_by uuid NOT NULL, assigned_to uuid, resolved_at timestamptz, closed_at timestamptz,
  due_date date, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.ticket_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  author_id uuid NOT NULL, content text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ticket_comments ENABLE ROW LEVEL SECURITY;

-- Attendance
CREATE TABLE public.attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL,
  clock_in timestamptz NOT NULL DEFAULT now(), clock_out timestamptz,
  work_hours numeric(5,2), overtime_hours numeric(5,2) DEFAULT 0, notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Leave requests
CREATE TABLE public.leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL,
  leave_type text NOT NULL DEFAULT 'annual', start_date date NOT NULL, end_date date NOT NULL,
  reason text, status text NOT NULL DEFAULT 'pending', approved_by uuid, approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

-- Announcements
CREATE TABLE public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), title text NOT NULL, content text NOT NULL,
  author_id uuid NOT NULL, priority text NOT NULL DEFAULT 'normal', pinned boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Team messages
CREATE TABLE public.team_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL, content text NOT NULL, attachment_urls text[] DEFAULT '{}'::text[],
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.team_messages ENABLE ROW LEVEL SECURITY;

-- Message reactions
CREATE TABLE public.message_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.team_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL, reaction text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, reaction)
);
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- Direct messages
CREATE TABLE public.direct_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), sender_id uuid NOT NULL, receiver_id uuid NOT NULL,
  content text NOT NULL DEFAULT '', attachment_urls text[] DEFAULT '{}'::text[],
  read boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.direct_messages REPLICA IDENTITY FULL;

-- DM reactions
CREATE TABLE public.dm_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.direct_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL, reaction text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, reaction)
);
ALTER TABLE public.dm_reactions ENABLE ROW LEVEL SECURITY;

-- Project milestones
CREATE TABLE public.project_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  target_percentage INTEGER NOT NULL, target_date DATE NOT NULL, actual_date DATE,
  status TEXT NOT NULL DEFAULT 'pending', reviewer_id UUID, reviewer_notes TEXT, action_items TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.project_milestones ENABLE ROW LEVEL SECURITY;

-- Project comments
CREATE TABLE public.project_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.project_groups(id) ON DELETE CASCADE,
  author_id UUID NOT NULL, content TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.project_comments ENABLE ROW LEVEL SECURITY;

-- Project updates
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

-- Plan performance records
CREATE TABLE public.plan_performance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), staff_id UUID NOT NULL,
  plan_id UUID REFERENCES public.plans(id) ON DELETE SET NULL, plan_type TEXT NOT NULL DEFAULT 'daily',
  period_key TEXT NOT NULL, planned_value NUMERIC NOT NULL DEFAULT 100, actual_value NUMERIC NOT NULL DEFAULT 0,
  achievement_pct NUMERIC DEFAULT 0, grade NUMERIC NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending',
  approved_by UUID, approved_at TIMESTAMPTZ, ceo_notes TEXT, ceo_adjusted_grade NUMERIC,
  flagged BOOLEAN NOT NULL DEFAULT false, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE(staff_id, plan_id)
);
ALTER TABLE public.plan_performance_records ENABLE ROW LEVEL SECURITY;

-- Performance summaries
CREATE TABLE public.performance_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), staff_id UUID NOT NULL,
  period_type TEXT NOT NULL, period_key TEXT NOT NULL, average_grade NUMERIC NOT NULL DEFAULT 0,
  total_plans INTEGER NOT NULL DEFAULT 0, flagged_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'auto', ceo_adjusted_grade NUMERIC, ceo_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(staff_id, period_type, period_key)
);
ALTER TABLE public.performance_summaries ENABLE ROW LEVEL SECURITY;

-- Salary configs
CREATE TABLE public.salary_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  payment_type text NOT NULL DEFAULT 'monthly', amount numeric NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'ETB', effective_from date NOT NULL, effective_to date,
  notes text, created_by uuid NOT NULL REFERENCES public.profiles(user_id),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_configs ENABLE ROW LEVEL SECURITY;

-- Salary payments
CREATE TABLE public.salary_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  period_start date NOT NULL, period_end date NOT NULL, payment_type text NOT NULL,
  base_amount numeric NOT NULL DEFAULT 0, units numeric NOT NULL DEFAULT 0,
  gross_salary numeric NOT NULL DEFAULT 0, deductions numeric NOT NULL DEFAULT 0,
  net_salary numeric NOT NULL DEFAULT 0, status text NOT NULL DEFAULT 'draft',
  approved_by uuid REFERENCES public.profiles(user_id), approved_at timestamptz, paid_at timestamptz,
  notes text, created_by uuid NOT NULL REFERENCES public.profiles(user_id),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_payments ENABLE ROW LEVEL SECURITY;

-- ==================== FUNCTIONS & TRIGGERS ====================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON public.plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_project_groups_updated_at BEFORE UPDATE ON public.project_groups FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_project_tasks_updated_at BEFORE UPDATE ON public.project_tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON public.leave_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, email, must_change_password)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), NEW.email, TRUE)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-flag performance trigger
CREATE OR REPLACE FUNCTION public.auto_flag_performance()
RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.planned_value > 0 THEN NEW.achievement_pct := ROUND((NEW.actual_value::numeric / NEW.planned_value::numeric) * 100, 1);
  ELSE NEW.achievement_pct := 0; END IF;
  IF NEW.achievement_pct < 60 THEN NEW.flagged := true; ELSE NEW.flagged := false; END IF;
  NEW.grade := COALESCE(NEW.ceo_adjusted_grade, NEW.achievement_pct);
  NEW.updated_at := now(); RETURN NEW;
END; $function$;

CREATE TRIGGER trg_auto_flag_performance BEFORE INSERT OR UPDATE ON public.plan_performance_records FOR EACH ROW EXECUTE FUNCTION public.auto_flag_performance();

-- ==================== RLS POLICIES ====================
-- Profiles
CREATE POLICY "Staff can read all profiles" ON public.profiles FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Executives can insert profiles" ON public.profiles FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()));
CREATE POLICY "Executives can delete profiles" ON public.profiles FOR DELETE TO authenticated USING (public.is_executive(auth.uid()));

-- User roles
CREATE POLICY "Authenticated can read own role" ON public.user_roles FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Executives can insert roles" ON public.user_roles FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()));
CREATE POLICY "Executives can delete roles" ON public.user_roles FOR DELETE TO authenticated USING (public.is_executive(auth.uid()));

-- Plans
CREATE POLICY "Staff can read all plans" ON public.plans FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Staff can create plans" ON public.plans FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Staff can update own plans" ON public.plans FOR UPDATE TO authenticated USING (auth.uid() = author_id);
CREATE POLICY "Executives can delete plans" ON public.plans FOR DELETE TO authenticated USING (public.is_executive(auth.uid()) OR auth.uid() = author_id);

-- Plan comments
CREATE POLICY "Staff can read comments" ON public.plan_comments FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Staff can create comments" ON public.plan_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Own user delete comments" ON public.plan_comments FOR DELETE TO authenticated USING (auth.uid() = author_id OR public.is_executive(auth.uid()));

-- Plan reactions
CREATE POLICY "Staff can read reactions" ON public.plan_reactions FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Staff can react" ON public.plan_reactions FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff can remove own reaction" ON public.plan_reactions FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Staff can update own reaction" ON public.plan_reactions FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Performance scores
CREATE POLICY "Staff can read scores" ON public.performance_scores FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Executives can assign scores" ON public.performance_scores FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()) AND auth.uid() = assigned_by);
CREATE POLICY "Executives can update scores" ON public.performance_scores FOR UPDATE TO authenticated USING (public.is_executive(auth.uid()));

-- Quarter winners
CREATE POLICY "All staff read winners" ON public.quarter_winners FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Executives post winners" ON public.quarter_winners FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()) AND auth.uid() = posted_by);
CREATE POLICY "Executives update winners" ON public.quarter_winners FOR UPDATE TO authenticated USING (public.is_executive(auth.uid()));

-- Project groups
CREATE POLICY "All staff read all projects" ON public.project_groups FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff create groups" ON public.project_groups FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Creator or exec update group" ON public.project_groups FOR UPDATE TO authenticated USING (auth.uid() = created_by OR public.is_executive(auth.uid()));

-- Project tasks
CREATE POLICY "Group members read tasks" ON public.project_tasks FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM public.project_groups pg WHERE pg.id = group_id AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR public.is_executive(auth.uid())))
);
CREATE POLICY "Group members create tasks" ON public.project_tasks FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Assigned or creator update task" ON public.project_tasks FOR UPDATE TO authenticated USING (auth.uid() = assigned_to OR auth.uid() = created_by OR public.is_executive(auth.uid()));

-- Notifications
CREATE POLICY "Own user notifications" ON public.notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Authenticated can insert notifications" ON public.notifications FOR INSERT TO authenticated WITH CHECK (TRUE);
CREATE POLICY "User mark own read" ON public.notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Support tickets
CREATE POLICY "Staff can create tickets" ON public.support_tickets FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "All staff read all tickets" ON public.support_tickets FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO creator or assigned update tickets" ON public.support_tickets FOR UPDATE TO authenticated USING (auth.uid() = assigned_to OR auth.uid() = created_by OR is_executive(auth.uid()));

-- Ticket comments
CREATE POLICY "Read ticket comments" ON public.ticket_comments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_comments.ticket_id AND (t.created_by = auth.uid() OR t.assigned_to = auth.uid() OR is_executive(auth.uid()))));
CREATE POLICY "Create ticket comments" ON public.ticket_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);

-- Attendance
CREATE POLICY "Staff can clock in" ON public.attendance FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff read own or exec reads all att" ON public.attendance FOR SELECT TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));
CREATE POLICY "Staff update own attendance" ON public.attendance FOR UPDATE TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));

-- Leave requests
CREATE POLICY "Staff create own leave" ON public.leave_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff read own or exec reads all lv" ON public.leave_requests FOR SELECT TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));
CREATE POLICY "HR or Exec approve leave" ON public.leave_requests FOR UPDATE TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));

-- Announcements
CREATE POLICY "All staff read announcements" ON public.announcements FOR SELECT TO authenticated USING (true);
CREATE POLICY "Executives create announcements" ON public.announcements FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = author_id);
CREATE POLICY "Executives update announcements" ON public.announcements FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Executives delete announcements" ON public.announcements FOR DELETE TO authenticated USING (is_executive(auth.uid()));

-- Team messages
CREATE POLICY "Team members read messages" ON public.team_messages FOR SELECT USING (EXISTS (SELECT 1 FROM project_groups pg WHERE pg.id = team_messages.group_id AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR is_executive(auth.uid()))));
CREATE POLICY "Team members send messages" ON public.team_messages FOR INSERT WITH CHECK (auth.uid() = sender_id AND EXISTS (SELECT 1 FROM project_groups pg WHERE pg.id = team_messages.group_id AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR is_executive(auth.uid()))));
CREATE POLICY "Delete own messages" ON public.team_messages FOR DELETE USING (auth.uid() = sender_id);

-- Message reactions
CREATE POLICY "Staff read msg reactions" ON public.message_reactions FOR SELECT USING (true);
CREATE POLICY "Staff add msg reactions" ON public.message_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff remove own msg reactions" ON public.message_reactions FOR DELETE USING (auth.uid() = user_id);

-- Direct messages
CREATE POLICY "Users read own DMs" ON public.direct_messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users send DMs" ON public.direct_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update own DMs" ON public.direct_messages FOR UPDATE USING ((auth.uid() = sender_id) OR (auth.uid() = receiver_id));
CREATE POLICY "Users delete own sent DMs" ON public.direct_messages FOR DELETE USING (auth.uid() = sender_id);

-- DM reactions
CREATE POLICY "DM participants read reactions" ON public.dm_reactions FOR SELECT USING (EXISTS (SELECT 1 FROM direct_messages dm WHERE dm.id = dm_reactions.message_id AND (auth.uid() = dm.sender_id OR auth.uid() = dm.receiver_id)));
CREATE POLICY "Users add DM reactions" ON public.dm_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users remove own DM reactions" ON public.dm_reactions FOR DELETE USING (auth.uid() = user_id);

-- Project milestones
CREATE POLICY "All staff read milestones" ON public.project_milestones FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO or exec manage milestones" ON public.project_milestones FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()));
CREATE POLICY "CEO or exec update milestones" ON public.project_milestones FOR UPDATE TO authenticated USING (is_executive(auth.uid()) OR auth.uid() = reviewer_id);
CREATE POLICY "CEO or exec delete milestones" ON public.project_milestones FOR DELETE TO authenticated USING (is_executive(auth.uid()));

-- Project comments
CREATE POLICY "All staff read project comments" ON public.project_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "All staff post project comments" ON public.project_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Own or exec delete project comments" ON public.project_comments FOR DELETE TO authenticated USING (auth.uid() = author_id OR is_executive(auth.uid()));

-- Project updates
CREATE POLICY "All staff read project updates" ON public.project_updates FOR SELECT TO authenticated USING (true);
CREATE POLICY "Members post updates" ON public.project_updates FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Own or exec delete updates" ON public.project_updates FOR DELETE TO authenticated USING (auth.uid() = author_id OR is_executive(auth.uid()));

-- Plan performance records
CREATE POLICY "All staff read performance records" ON public.plan_performance_records FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff create own records" ON public.plan_performance_records FOR INSERT TO authenticated WITH CHECK (auth.uid() = staff_id);
CREATE POLICY "Staff or exec update records" ON public.plan_performance_records FOR UPDATE TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));

-- Performance summaries
CREATE POLICY "All staff read summaries" ON public.performance_summaries FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff or exec insert summaries" ON public.performance_summaries FOR INSERT TO authenticated WITH CHECK (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "Exec update summaries" ON public.performance_summaries FOR UPDATE TO authenticated USING (is_executive(auth.uid()));

-- Salary configs
CREATE POLICY "Staff read own salary" ON public.salary_configs FOR SELECT TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "Executives insert salary" ON public.salary_configs FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = created_by);
CREATE POLICY "Executives update salary" ON public.salary_configs FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Executives delete salary" ON public.salary_configs FOR DELETE TO authenticated USING (is_executive(auth.uid()));

-- Salary payments
CREATE POLICY "Staff read own payments" ON public.salary_payments FOR SELECT TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "Executives insert payments" ON public.salary_payments FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = created_by);
CREATE POLICY "Executives update payments" ON public.salary_payments FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Executives delete payments" ON public.salary_payments FOR DELETE TO authenticated USING (is_executive(auth.uid()));

-- ==================== FOREIGN KEYS ====================
ALTER TABLE public.plans ADD CONSTRAINT plans_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.announcements ADD CONSTRAINT announcements_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.quarter_winners ADD CONSTRAINT quarter_winners_winner_id_fkey FOREIGN KEY (winner_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.quarter_winners ADD CONSTRAINT quarter_winners_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.performance_scores ADD CONSTRAINT performance_scores_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.performance_scores ADD CONSTRAINT performance_scores_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.plan_comments ADD CONSTRAINT plan_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

-- ==================== STORAGE BUCKETS ====================
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit) VALUES ('plan-attachments', 'plan-attachments', true, 104857600) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit) VALUES ('chat-attachments', 'chat-attachments', true, 104857600) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('project-attachments', 'project-attachments', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies
DO $$ BEGIN CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users upload own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users update own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users delete own avatar" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Staff view plan attachments" ON storage.objects FOR SELECT USING (bucket_id = 'plan-attachments'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Staff upload plan attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'plan-attachments' AND auth.uid()::text = (storage.foldername(name))[1]); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Staff delete own plan attachments" ON storage.objects FOR DELETE USING (bucket_id = 'plan-attachments' AND auth.uid()::text = (storage.foldername(name))[1]); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated upload chat attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'chat-attachments' AND auth.role() = 'authenticated'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Public read chat attachments" ON storage.objects FOR SELECT USING (bucket_id = 'chat-attachments'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Own delete chat attachments" ON storage.objects FOR DELETE USING (bucket_id = 'chat-attachments' AND auth.uid()::text = (storage.foldername(name))[1]); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated users can upload project attachments" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'project-attachments'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated users can read project attachments" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'project-attachments'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete own project attachments" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'project-attachments'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ==================== REALTIME ====================
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.plans;
ALTER PUBLICATION supabase_realtime ADD TABLE public.plan_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance;
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.dm_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_milestones;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.plan_performance_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.performance_summaries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.performance_scores;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quarter_winners;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_updates;
