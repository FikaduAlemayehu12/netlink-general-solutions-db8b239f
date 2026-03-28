
-- 1. Role enum
CREATE TYPE public.app_role AS ENUM ('ceo', 'cto', 'coo', 'hr', 'sysadmin', 'staff');

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
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. User roles table (separate, never on profiles)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 4. Security definer function to check roles (avoids RLS recursion)
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Helper: check if user is an executive (ceo/cto/coo/hr/sysadmin)
CREATE OR REPLACE FUNCTION public.is_executive(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id
      AND role IN ('ceo', 'cto', 'coo', 'hr', 'sysadmin')
  )
$$;

-- 5. Plans table
CREATE TABLE public.plans (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('daily', 'weekly', 'quarterly')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  mentioned_user_ids UUID[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

-- 6. Plan comments
CREATE TABLE public.plan_comments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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
  staff_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES public.plans(id) ON DELETE SET NULL,
  points INTEGER NOT NULL DEFAULT 0,
  quarter TEXT NOT NULL, -- e.g. "2025-Q1"
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.performance_scores ENABLE ROW LEVEL SECURITY;

-- 9. Quarter winners
CREATE TABLE public.quarter_winners (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  winner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quarter TEXT NOT NULL UNIQUE,
  message TEXT,
  banner_url TEXT,
  posted_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- ==================== RLS POLICIES ====================

-- Profiles: all staff can read, own user writes their own
CREATE POLICY "Staff can read all profiles" ON public.profiles FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Executives can insert profiles" ON public.profiles FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()));
CREATE POLICY "Executives can delete profiles" ON public.profiles FOR DELETE TO authenticated USING (public.is_executive(auth.uid()));

-- User roles: only executives can manage
CREATE POLICY "Authenticated can read own role" ON public.user_roles FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Executives can insert roles" ON public.user_roles FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()));
CREATE POLICY "Executives can delete roles" ON public.user_roles FOR DELETE TO authenticated USING (public.is_executive(auth.uid()));

-- Plans
CREATE POLICY "Staff can read all plans" ON public.plans FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Staff can create plans" ON public.plans FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Staff can update own plans" ON public.plans FOR UPDATE TO authenticated USING (auth.uid() = author_id);
CREATE POLICY "Executives can delete plans" ON public.plans FOR DELETE TO authenticated USING (public.is_executive(auth.uid()) OR auth.uid() = author_id);

-- Comments
CREATE POLICY "Staff can read comments" ON public.plan_comments FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Staff can create comments" ON public.plan_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Own user delete comments" ON public.plan_comments FOR DELETE TO authenticated USING (auth.uid() = author_id OR public.is_executive(auth.uid()));

-- Reactions
CREATE POLICY "Staff can read reactions" ON public.plan_reactions FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Staff can react" ON public.plan_reactions FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff can remove own reaction" ON public.plan_reactions FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Staff can update own reaction" ON public.plan_reactions FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Performance scores: executives assign, all read
CREATE POLICY "Staff can read scores" ON public.performance_scores FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Executives can assign scores" ON public.performance_scores FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()) AND auth.uid() = assigned_by);
CREATE POLICY "Executives can update scores" ON public.performance_scores FOR UPDATE TO authenticated USING (public.is_executive(auth.uid()));

-- Quarter winners
CREATE POLICY "All staff read winners" ON public.quarter_winners FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Executives post winners" ON public.quarter_winners FOR INSERT TO authenticated WITH CHECK (public.is_executive(auth.uid()) AND auth.uid() = posted_by);
CREATE POLICY "Executives update winners" ON public.quarter_winners FOR UPDATE TO authenticated USING (public.is_executive(auth.uid()));

-- Project groups: members can see their group
CREATE POLICY "Staff read groups they belong to" ON public.project_groups FOR SELECT TO authenticated USING (auth.uid() = ANY(member_ids) OR auth.uid() = created_by OR public.is_executive(auth.uid()));
CREATE POLICY "Staff create groups" ON public.project_groups FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Creator or exec update group" ON public.project_groups FOR UPDATE TO authenticated USING (auth.uid() = created_by OR public.is_executive(auth.uid()));

-- Project tasks
CREATE POLICY "Group members read tasks" ON public.project_tasks FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM public.project_groups pg WHERE pg.id = group_id AND (auth.uid() = ANY(pg.member_ids) OR auth.uid() = pg.created_by OR public.is_executive(auth.uid())))
);
CREATE POLICY "Group members create tasks" ON public.project_tasks FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Assigned or creator update task" ON public.project_tasks FOR UPDATE TO authenticated USING (auth.uid() = assigned_to OR auth.uid() = created_by OR public.is_executive(auth.uid()));

-- Notifications: own only
CREATE POLICY "Read own notifications" ON public.notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "System inserts notifications" ON public.notifications FOR INSERT TO authenticated WITH CHECK (TRUE);
CREATE POLICY "Mark own read" ON public.notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- ==================== TRIGGERS ====================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON public.plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_project_groups_updated_at BEFORE UPDATE ON public.project_groups FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_project_tasks_updated_at BEFORE UPDATE ON public.project_tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

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

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.plans;
ALTER PUBLICATION supabase_realtime ADD TABLE public.plan_comments;
