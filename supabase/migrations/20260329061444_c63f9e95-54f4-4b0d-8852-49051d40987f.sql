
-- Departments table
CREATE TABLE public.departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL
);
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All staff read departments" ON public.departments FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO manages departments" ON public.departments FOR INSERT TO authenticated WITH CHECK (is_ceo(auth.uid()));
CREATE POLICY "CEO updates departments" ON public.departments FOR UPDATE TO authenticated USING (is_ceo(auth.uid()));
CREATE POLICY "CEO deletes departments" ON public.departments FOR DELETE TO authenticated USING (is_ceo(auth.uid()));

-- Sub-departments table
CREATE TABLE public.sub_departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_id uuid NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  UNIQUE(department_id, name)
);
ALTER TABLE public.sub_departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All staff read sub_departments" ON public.sub_departments FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO manages sub_departments" ON public.sub_departments FOR INSERT TO authenticated WITH CHECK (is_ceo(auth.uid()));
CREATE POLICY "CEO updates sub_departments" ON public.sub_departments FOR UPDATE TO authenticated USING (is_ceo(auth.uid()));
CREATE POLICY "CEO deletes sub_departments" ON public.sub_departments FOR DELETE TO authenticated USING (is_ceo(auth.uid()));

-- Staff-to-sub-department assignments (many-to-many)
CREATE TABLE public.staff_sub_departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  sub_department_id uuid NOT NULL REFERENCES public.sub_departments(id) ON DELETE CASCADE,
  assigned_by uuid NOT NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, sub_department_id)
);
ALTER TABLE public.staff_sub_departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All staff read assignments" ON public.staff_sub_departments FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO manages assignments" ON public.staff_sub_departments FOR INSERT TO authenticated WITH CHECK (is_ceo(auth.uid()));
CREATE POLICY "CEO deletes assignments" ON public.staff_sub_departments FOR DELETE TO authenticated USING (is_ceo(auth.uid()));

-- Custom permissions table (CEO-delegated granular permissions)
CREATE TABLE public.staff_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  can_reset_passwords boolean NOT NULL DEFAULT false,
  can_create_staff boolean NOT NULL DEFAULT false,
  can_edit_profiles boolean NOT NULL DEFAULT false,
  can_manage_projects boolean NOT NULL DEFAULT false,
  can_manage_attendance boolean NOT NULL DEFAULT false,
  can_manage_salary boolean NOT NULL DEFAULT false,
  can_post_announcements boolean NOT NULL DEFAULT false,
  can_pause_users boolean NOT NULL DEFAULT false,
  granted_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.staff_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All staff read permissions" ON public.staff_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "CEO manages permissions" ON public.staff_permissions FOR INSERT TO authenticated WITH CHECK (is_ceo(auth.uid()));
CREATE POLICY "CEO updates permissions" ON public.staff_permissions FOR UPDATE TO authenticated USING (is_ceo(auth.uid()));
CREATE POLICY "CEO deletes permissions" ON public.staff_permissions FOR DELETE TO authenticated USING (is_ceo(auth.uid()));

-- Seed initial departments
INSERT INTO public.departments (name, description, created_by) VALUES
  ('IT Department', 'Information Technology and Software', '00000000-0000-0000-0000-000000000000'),
  ('Civil & Construction Engineering', 'Civil engineering and construction projects', '00000000-0000-0000-0000-000000000000'),
  ('HR Department', 'Human Resources management', '00000000-0000-0000-0000-000000000000'),
  ('Finance Department', 'Financial management and accounting', '00000000-0000-0000-0000-000000000000'),
  ('Business Development', 'Business growth and client relations', '00000000-0000-0000-0000-000000000000');

-- Seed sub-departments
INSERT INTO public.sub_departments (department_id, name, created_by)
SELECT d.id, s.name, '00000000-0000-0000-0000-000000000000'
FROM public.departments d
CROSS JOIN LATERAL (VALUES
  ('IT Department', 'Software Development'),
  ('IT Department', 'DevOps & Cloud Infrastructure'),
  ('IT Department', 'Cybersecurity'),
  ('IT Department', 'IT Support & Systems Admin'),
  ('IT Department', 'UI/UX & Product Design'),
  ('Civil & Construction Engineering', 'Structural Engineering'),
  ('Civil & Construction Engineering', 'Site Management'),
  ('Civil & Construction Engineering', 'Construction Planning'),
  ('Civil & Construction Engineering', 'Quality Control'),
  ('HR Department', 'Recruitment & Talent Acquisition'),
  ('HR Department', 'Employee Relations'),
  ('HR Department', 'Training & Development'),
  ('HR Department', 'Performance Management'),
  ('Finance Department', 'Accounting'),
  ('Finance Department', 'Payroll'),
  ('Finance Department', 'Budgeting & Forecasting'),
  ('Business Development', 'Sales & Marketing'),
  ('Business Development', 'Client Relations'),
  ('Business Development', 'Partnerships')
) AS s(dept_name, name)
WHERE d.name = s.dept_name;
