
-- 1. Update the auto_flag_performance function to also compute achievement_pct
CREATE OR REPLACE FUNCTION public.auto_flag_performance()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.planned_value > 0 THEN
    NEW.achievement_pct := ROUND((NEW.actual_value::numeric / NEW.planned_value::numeric) * 100, 1);
  ELSE
    NEW.achievement_pct := 0;
  END IF;
  
  IF NEW.achievement_pct < 60 THEN
    NEW.flagged := true;
  ELSE
    NEW.flagged := false;
  END IF;
  
  NEW.grade := COALESCE(NEW.ceo_adjusted_grade, NEW.achievement_pct);
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$;

-- 2. Attach trigger to plan_performance_records table
DROP TRIGGER IF EXISTS trg_auto_flag_performance ON public.plan_performance_records;
CREATE TRIGGER trg_auto_flag_performance
  BEFORE INSERT OR UPDATE ON public.plan_performance_records
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_flag_performance();
