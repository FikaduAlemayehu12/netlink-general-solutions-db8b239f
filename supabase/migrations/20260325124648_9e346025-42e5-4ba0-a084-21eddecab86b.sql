
-- update_updated_at_column function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Fix notifications insert policy
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "Authenticated can insert notifications" ON public.notifications FOR INSERT TO authenticated WITH CHECK (TRUE);

-- Add columns to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS department text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birthday date;

-- Support tickets
CREATE TABLE public.support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), ticket_number serial,
  title text NOT NULL, description text NOT NULL, category text NOT NULL DEFAULT 'general',
  priority text NOT NULL DEFAULT 'medium', status text NOT NULL DEFAULT 'open',
  created_by uuid NOT NULL, assigned_to uuid, resolved_at timestamptz, closed_at timestamptz,
  due_date date, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

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
CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON public.leave_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Announcements
CREATE TABLE public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), title text NOT NULL, content text NOT NULL,
  author_id uuid NOT NULL, priority text NOT NULL DEFAULT 'normal', pinned boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enhanced project management
ALTER TABLE public.project_groups ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';
ALTER TABLE public.project_groups ADD COLUMN IF NOT EXISTS start_date date;
ALTER TABLE public.project_groups ADD COLUMN IF NOT EXISTS end_date date;
ALTER TABLE public.project_groups ADD COLUMN IF NOT EXISTS budget numeric(12,2);
ALTER TABLE public.project_groups ADD COLUMN IF NOT EXISTS manager_id uuid;
ALTER TABLE public.project_tasks ADD COLUMN IF NOT EXISTS priority text DEFAULT 'medium';
ALTER TABLE public.project_tasks ADD COLUMN IF NOT EXISTS due_date date;
ALTER TABLE public.project_tasks ADD COLUMN IF NOT EXISTS attachments text[];
ALTER TABLE public.plans ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}';

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

-- Update is_executive
CREATE OR REPLACE FUNCTION public.is_executive(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('ceo', 'cto', 'coo', 'cio', 'hr', 'sysadmin', 'finance_manager', 'bd_head')) $$;

CREATE OR REPLACE FUNCTION public.is_ceo(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = 'ceo') $$;

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

-- RLS POLICIES for new tables
CREATE POLICY "Staff can create tickets" ON public.support_tickets FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "All staff read all tickets" ON public.support_tickets FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO creator or assigned update tickets" ON public.support_tickets FOR UPDATE TO authenticated USING (auth.uid() = assigned_to OR auth.uid() = created_by OR is_executive(auth.uid()));
CREATE POLICY "Read ticket comments" ON public.ticket_comments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_comments.ticket_id AND (t.created_by = auth.uid() OR t.assigned_to = auth.uid() OR is_executive(auth.uid()))));
CREATE POLICY "Create ticket comments" ON public.ticket_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Staff can clock in" ON public.attendance FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff read own or exec reads all att" ON public.attendance FOR SELECT TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));
CREATE POLICY "Staff update own attendance" ON public.attendance FOR UPDATE TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));
CREATE POLICY "Staff create own leave" ON public.leave_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff read own or exec reads all lv" ON public.leave_requests FOR SELECT TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));
CREATE POLICY "HR or Exec approve leave" ON public.leave_requests FOR UPDATE TO authenticated USING (auth.uid() = user_id OR is_executive(auth.uid()) OR has_role(auth.uid(), 'hr'));
CREATE POLICY "All staff read announcements" ON public.announcements FOR SELECT TO authenticated USING (true);
CREATE POLICY "Executives create announcements" ON public.announcements FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = author_id);
CREATE POLICY "Executives update announcements" ON public.announcements FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Executives delete announcements" ON public.announcements FOR DELETE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Team members read messages" ON public.team_messages FOR SELECT USING (EXISTS (SELECT 1 FROM project_groups pg WHERE pg.id = team_messages.group_id AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR is_executive(auth.uid()))));
CREATE POLICY "Team members send messages" ON public.team_messages FOR INSERT WITH CHECK (auth.uid() = sender_id AND EXISTS (SELECT 1 FROM project_groups pg WHERE pg.id = team_messages.group_id AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR is_executive(auth.uid()))));
CREATE POLICY "Delete own messages" ON public.team_messages FOR DELETE USING (auth.uid() = sender_id);
CREATE POLICY "Staff read msg reactions" ON public.message_reactions FOR SELECT USING (true);
CREATE POLICY "Staff add msg reactions" ON public.message_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff remove own msg reactions" ON public.message_reactions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users read own DMs" ON public.direct_messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users send DMs" ON public.direct_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update own DMs" ON public.direct_messages FOR UPDATE USING ((auth.uid() = sender_id) OR (auth.uid() = receiver_id));
CREATE POLICY "Users delete own sent DMs" ON public.direct_messages FOR DELETE USING (auth.uid() = sender_id);
CREATE POLICY "DM participants read reactions" ON public.dm_reactions FOR SELECT USING (EXISTS (SELECT 1 FROM direct_messages dm WHERE dm.id = dm_reactions.message_id AND (auth.uid() = dm.sender_id OR auth.uid() = dm.receiver_id)));
CREATE POLICY "Users add DM reactions" ON public.dm_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users remove own DM reactions" ON public.dm_reactions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "All staff read milestones" ON public.project_milestones FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO or exec manage milestones" ON public.project_milestones FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()));
CREATE POLICY "CEO or exec update milestones" ON public.project_milestones FOR UPDATE TO authenticated USING (is_executive(auth.uid()) OR auth.uid() = reviewer_id);
CREATE POLICY "CEO or exec delete milestones" ON public.project_milestones FOR DELETE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "All staff read project comments" ON public.project_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "All staff post project comments" ON public.project_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Own or exec delete project comments" ON public.project_comments FOR DELETE TO authenticated USING (auth.uid() = author_id OR is_executive(auth.uid()));
DROP POLICY IF EXISTS "Staff read groups they belong to" ON public.project_groups;
CREATE POLICY "All staff read all projects" ON public.project_groups FOR SELECT TO authenticated USING (true);
CREATE POLICY "All staff read performance records" ON public.plan_performance_records FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff create own records" ON public.plan_performance_records FOR INSERT TO authenticated WITH CHECK (auth.uid() = staff_id);
CREATE POLICY "Staff or exec update records" ON public.plan_performance_records FOR UPDATE TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "All staff read summaries" ON public.performance_summaries FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff or exec insert summaries" ON public.performance_summaries FOR INSERT TO authenticated WITH CHECK (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "Exec update summaries" ON public.performance_summaries FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Staff read own salary" ON public.salary_configs FOR SELECT TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "Executives insert salary" ON public.salary_configs FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = created_by);
CREATE POLICY "Executives update salary" ON public.salary_configs FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Executives delete salary" ON public.salary_configs FOR DELETE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Staff read own payments" ON public.salary_payments FOR SELECT TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));
CREATE POLICY "Executives insert payments" ON public.salary_payments FOR INSERT TO authenticated WITH CHECK (is_executive(auth.uid()) AND auth.uid() = created_by);
CREATE POLICY "Executives update payments" ON public.salary_payments FOR UPDATE TO authenticated USING (is_executive(auth.uid()));
CREATE POLICY "Executives delete payments" ON public.salary_payments FOR DELETE TO authenticated USING (is_executive(auth.uid()));

-- Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit) VALUES ('plan-attachments', 'plan-attachments', true, 104857600) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit) VALUES ('chat-attachments', 'chat-attachments', true, 104857600) ON CONFLICT DO NOTHING;

-- Storage policies (use IF NOT EXISTS pattern)
DO $$ BEGIN
  CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users upload own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users update own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users delete own avatar" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Staff view plan attachments" ON storage.objects FOR SELECT USING (bucket_id = 'plan-attachments');
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Staff upload plan attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'plan-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Staff delete own plan attachments" ON storage.objects FOR DELETE USING (bucket_id = 'plan-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Authenticated upload chat attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'chat-attachments' AND auth.role() = 'authenticated');
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Public read chat attachments" ON storage.objects FOR SELECT USING (bucket_id = 'chat-attachments');
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Own delete chat attachments" ON storage.objects FOR DELETE USING (bucket_id = 'chat-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- FK updates
ALTER TABLE public.plans DROP CONSTRAINT IF EXISTS plans_author_id_fkey;
ALTER TABLE public.announcements DROP CONSTRAINT IF EXISTS announcements_author_id_fkey;
ALTER TABLE public.quarter_winners DROP CONSTRAINT IF EXISTS quarter_winners_winner_id_fkey;
ALTER TABLE public.quarter_winners DROP CONSTRAINT IF EXISTS quarter_winners_posted_by_fkey;
ALTER TABLE public.performance_scores DROP CONSTRAINT IF EXISTS performance_scores_staff_id_fkey;
ALTER TABLE public.performance_scores DROP CONSTRAINT IF EXISTS performance_scores_assigned_by_fkey;
ALTER TABLE public.plan_comments DROP CONSTRAINT IF EXISTS plan_comments_author_id_fkey;

ALTER TABLE public.plans ADD CONSTRAINT plans_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.announcements ADD CONSTRAINT announcements_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.quarter_winners ADD CONSTRAINT quarter_winners_winner_id_fkey FOREIGN KEY (winner_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.quarter_winners ADD CONSTRAINT quarter_winners_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.performance_scores ADD CONSTRAINT performance_scores_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.performance_scores ADD CONSTRAINT performance_scores_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
ALTER TABLE public.plan_comments ADD CONSTRAINT plan_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

-- Enable realtime
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
