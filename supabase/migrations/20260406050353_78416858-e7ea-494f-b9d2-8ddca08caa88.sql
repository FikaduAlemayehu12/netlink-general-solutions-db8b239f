
CREATE TABLE public.job_vacancies (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  department TEXT,
  description TEXT,
  responsibilities TEXT,
  qualifications TEXT,
  skills TEXT,
  experience TEXT,
  education TEXT,
  certifications TEXT,
  employment_type TEXT NOT NULL DEFAULT 'full-time',
  salary_range TEXT,
  benefits TEXT,
  location TEXT DEFAULT 'Addis Ababa',
  working_hours TEXT,
  deadline DATE,
  openings INTEGER NOT NULL DEFAULT 1,
  reporting_manager TEXT,
  vacancy_type TEXT NOT NULL DEFAULT 'external',
  status TEXT NOT NULL DEFAULT 'draft',
  author_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.job_vacancies ENABLE ROW LEVEL SECURITY;

-- Public can read published external vacancies (for careers page)
CREATE POLICY "Public read published external vacancies"
ON public.job_vacancies FOR SELECT TO anon
USING (status = 'published' AND vacancy_type = 'external');

-- Staff can read all vacancies
CREATE POLICY "Staff read all vacancies"
ON public.job_vacancies FOR SELECT TO authenticated
USING (true);

-- CEO creates vacancies
CREATE POLICY "CEO creates vacancies"
ON public.job_vacancies FOR INSERT TO authenticated
WITH CHECK (is_ceo(auth.uid()) AND auth.uid() = author_id);

-- CEO updates vacancies
CREATE POLICY "CEO updates vacancies"
ON public.job_vacancies FOR UPDATE TO authenticated
USING (is_ceo(auth.uid()));

-- CEO deletes vacancies
CREATE POLICY "CEO deletes vacancies"
ON public.job_vacancies FOR DELETE TO authenticated
USING (is_ceo(auth.uid()));

CREATE TRIGGER update_job_vacancies_updated_at
BEFORE UPDATE ON public.job_vacancies
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
