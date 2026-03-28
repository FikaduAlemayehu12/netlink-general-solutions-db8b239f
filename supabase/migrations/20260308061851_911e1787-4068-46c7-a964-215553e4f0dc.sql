
-- Fix overly permissive INSERT policy on performance_summaries
DROP POLICY "System insert summaries" ON public.performance_summaries;
CREATE POLICY "Staff or exec insert summaries" ON public.performance_summaries FOR INSERT TO authenticated WITH CHECK (auth.uid() = staff_id OR is_executive(auth.uid()));

-- The "Staff create own records" policy is already scoped to auth.uid() = staff_id, which is fine.
-- The "Staff or exec update records" is also properly scoped.
