
-- Job applications table
CREATE TABLE public.job_applications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  applicant_name TEXT NOT NULL,
  applicant_email TEXT NOT NULL,
  position TEXT,
  cover_message TEXT,
  cv_url TEXT,
  vacancy_id UUID REFERENCES public.job_vacancies(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'new',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- Anyone can submit an application
CREATE POLICY "Anyone can submit applications"
ON public.job_applications FOR INSERT TO anon, authenticated
WITH CHECK (true);

-- Executives can read applications
CREATE POLICY "Executives read applications"
ON public.job_applications FOR SELECT TO authenticated
USING (is_executive(auth.uid()));

-- Executives can update applications
CREATE POLICY "Executives update applications"
ON public.job_applications FOR UPDATE TO authenticated
USING (is_executive(auth.uid()));

-- CEO can delete applications
CREATE POLICY "CEO deletes applications"
ON public.job_applications FOR DELETE TO authenticated
USING (is_ceo(auth.uid()));

CREATE TRIGGER update_job_applications_updated_at
BEFORE UPDATE ON public.job_applications
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Storage bucket for CVs
INSERT INTO storage.buckets (id, name, public) VALUES ('job-applications', 'job-applications', true);

-- Anyone can upload CVs
CREATE POLICY "Anyone can upload CVs"
ON storage.objects FOR INSERT TO anon, authenticated
WITH CHECK (bucket_id = 'job-applications');

-- Anyone can read uploaded CVs (for download links)
CREATE POLICY "Anyone can read job application files"
ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id = 'job-applications');

-- CEO can delete CV files
CREATE POLICY "CEO deletes job application files"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'job-applications' AND is_ceo(auth.uid()));
