
-- Salary rate configurations: supports hourly/daily/weekly/monthly with time-bound rates
CREATE TABLE public.salary_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  payment_type text NOT NULL DEFAULT 'monthly', -- hourly, daily, weekly, monthly
  amount numeric NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'ETB',
  effective_from date NOT NULL,
  effective_to date, -- null means current/ongoing
  notes text,
  created_by uuid NOT NULL REFERENCES public.profiles(user_id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.salary_configs ENABLE ROW LEVEL SECURITY;

-- All staff can read their own salary; executives can read all
CREATE POLICY "Staff read own salary" ON public.salary_configs
  FOR SELECT TO authenticated
  USING (auth.uid() = staff_id OR is_executive(auth.uid()));

-- Only CEO/executives can insert salary configs
CREATE POLICY "Executives insert salary" ON public.salary_configs
  FOR INSERT TO authenticated
  WITH CHECK (is_executive(auth.uid()) AND auth.uid() = created_by);

-- Only CEO/executives can update salary configs
CREATE POLICY "Executives update salary" ON public.salary_configs
  FOR UPDATE TO authenticated
  USING (is_executive(auth.uid()));

-- Only CEO/executives can delete salary configs
CREATE POLICY "Executives delete salary" ON public.salary_configs
  FOR DELETE TO authenticated
  USING (is_executive(auth.uid()));

-- Salary payments/calculations log
CREATE TABLE public.salary_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  period_start date NOT NULL,
  period_end date NOT NULL,
  payment_type text NOT NULL,
  base_amount numeric NOT NULL DEFAULT 0,
  units numeric NOT NULL DEFAULT 0, -- hours/days/weeks/months worked
  gross_salary numeric NOT NULL DEFAULT 0,
  deductions numeric NOT NULL DEFAULT 0,
  net_salary numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'draft', -- draft, approved, paid
  approved_by uuid REFERENCES public.profiles(user_id),
  approved_at timestamptz,
  paid_at timestamptz,
  notes text,
  created_by uuid NOT NULL REFERENCES public.profiles(user_id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.salary_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff read own payments" ON public.salary_payments
  FOR SELECT TO authenticated
  USING (auth.uid() = staff_id OR is_executive(auth.uid()));

CREATE POLICY "Executives insert payments" ON public.salary_payments
  FOR INSERT TO authenticated
  WITH CHECK (is_executive(auth.uid()) AND auth.uid() = created_by);

CREATE POLICY "Executives update payments" ON public.salary_payments
  FOR UPDATE TO authenticated
  USING (is_executive(auth.uid()));

CREATE POLICY "Executives delete payments" ON public.salary_payments
  FOR DELETE TO authenticated
  USING (is_executive(auth.uid()));
