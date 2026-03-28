
-- Plan performance records: tracks achievement % per plan
CREATE TABLE public.plan_performance_records (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL,
  plan_id UUID REFERENCES public.plans(id) ON DELETE SET NULL,
  plan_type TEXT NOT NULL DEFAULT 'daily',
  period_key TEXT NOT NULL,
  planned_value NUMERIC NOT NULL DEFAULT 100,
  actual_value NUMERIC NOT NULL DEFAULT 0,
  achievement_pct NUMERIC GENERATED ALWAYS AS (
    CASE WHEN planned_value > 0 THEN LEAST(ROUND((actual_value / planned_value) * 100, 1), 100) ELSE 0 END
  ) STORED,
  grade NUMERIC NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  approved_by UUID,
  approved_at TIMESTAMP WITH TIME ZONE,
  ceo_notes TEXT,
  ceo_adjusted_grade NUMERIC,
  flagged BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(staff_id, plan_id)
);

-- Weekly/monthly/quarterly aggregated performance
CREATE TABLE public.performance_summaries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL,
  period_type TEXT NOT NULL,
  period_key TEXT NOT NULL,
  average_grade NUMERIC NOT NULL DEFAULT 0,
  total_plans INTEGER NOT NULL DEFAULT 0,
  flagged_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'auto',
  ceo_adjusted_grade NUMERIC,
  ceo_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(staff_id, period_type, period_key)
);

-- Enable RLS
ALTER TABLE public.plan_performance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_summaries ENABLE ROW LEVEL SECURITY;

-- RLS: All staff can read all performance records (transparency)
CREATE POLICY "All staff read performance records" ON public.plan_performance_records FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff create own records" ON public.plan_performance_records FOR INSERT TO authenticated WITH CHECK (auth.uid() = staff_id);
CREATE POLICY "Staff or exec update records" ON public.plan_performance_records FOR UPDATE TO authenticated USING (auth.uid() = staff_id OR is_executive(auth.uid()));

CREATE POLICY "All staff read summaries" ON public.performance_summaries FOR SELECT TO authenticated USING (true);
CREATE POLICY "System insert summaries" ON public.performance_summaries FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Exec update summaries" ON public.performance_summaries FOR UPDATE TO authenticated USING (is_executive(auth.uid()));

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.plan_performance_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.performance_summaries;

-- Auto-flag records below 60%
CREATE OR REPLACE FUNCTION public.auto_flag_performance()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.achievement_pct < 60 THEN
    NEW.flagged := true;
  ELSE
    NEW.flagged := false;
  END IF;
  NEW.grade := COALESCE(NEW.ceo_adjusted_grade, NEW.achievement_pct);
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_flag_performance
BEFORE INSERT OR UPDATE ON public.plan_performance_records
FOR EACH ROW EXECUTE FUNCTION public.auto_flag_performance();
