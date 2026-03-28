
-- Drop existing FKs that point to auth.users (PostgREST can't resolve joins through auth schema)
ALTER TABLE public.plans DROP CONSTRAINT plans_author_id_fkey;
ALTER TABLE public.announcements DROP CONSTRAINT IF EXISTS announcements_author_id_fkey;
ALTER TABLE public.quarter_winners DROP CONSTRAINT quarter_winners_winner_id_fkey;
ALTER TABLE public.quarter_winners DROP CONSTRAINT quarter_winners_posted_by_fkey;
ALTER TABLE public.performance_scores DROP CONSTRAINT performance_scores_staff_id_fkey;
ALTER TABLE public.performance_scores DROP CONSTRAINT performance_scores_assigned_by_fkey;
ALTER TABLE public.plan_comments DROP CONSTRAINT plan_comments_author_id_fkey;

-- Recreate FKs pointing to profiles.user_id
ALTER TABLE public.plans
  ADD CONSTRAINT plans_author_id_fkey
  FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

ALTER TABLE public.announcements
  ADD CONSTRAINT announcements_author_id_fkey
  FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

ALTER TABLE public.quarter_winners
  ADD CONSTRAINT quarter_winners_winner_id_fkey
  FOREIGN KEY (winner_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

ALTER TABLE public.quarter_winners
  ADD CONSTRAINT quarter_winners_posted_by_fkey
  FOREIGN KEY (posted_by) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

ALTER TABLE public.performance_scores
  ADD CONSTRAINT performance_scores_staff_id_fkey
  FOREIGN KEY (staff_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

ALTER TABLE public.performance_scores
  ADD CONSTRAINT performance_scores_assigned_by_fkey
  FOREIGN KEY (assigned_by) REFERENCES public.profiles(user_id) ON DELETE CASCADE;

ALTER TABLE public.plan_comments
  ADD CONSTRAINT plan_comments_author_id_fkey
  FOREIGN KEY (author_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;
