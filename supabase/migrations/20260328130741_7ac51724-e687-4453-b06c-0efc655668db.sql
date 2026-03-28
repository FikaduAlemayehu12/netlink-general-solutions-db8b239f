
-- Add UPDATE policy for executives on profiles
CREATE POLICY "Executives can update any profile"
ON public.profiles FOR UPDATE TO authenticated
USING (is_executive(auth.uid()) OR auth.uid() = user_id);

-- Drop the old restrictive update policy
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- Ensure user_roles has an UPDATE policy for executives
CREATE POLICY "Executives can update roles"
ON public.user_roles FOR UPDATE TO authenticated
USING (is_executive(auth.uid()));
