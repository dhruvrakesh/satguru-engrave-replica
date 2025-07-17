-- Simplify handle_new_user function to reduce complexity and race conditions
-- This function runs when a new user signs up.
-- It assigns them to an organization based on their email domain
-- and creates a corresponding profile.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  org_id UUID;
  user_role TEXT;
BEGIN
  -- Determine organization based on email domain
  IF NEW.email LIKE '%@satguruengravures.com' THEN
    SELECT id INTO org_id FROM public.organizations WHERE code = 'SATGURU';
  ELSE
    -- Default to DKEGL for any other domain
    SELECT id INTO org_id FROM public.organizations WHERE code = 'DKEGL';
  END IF;

  -- Assign 'admin' role to the two specific admin emails, otherwise 'employee'
  IF NEW.email IN ('info@dkenterprises.co.in', 'info@satguruengravures.com') THEN
    user_role := 'admin';
  ELSE
    user_role := 'employee';
  END IF;

  -- Insert a new profile for the new user
  INSERT INTO public.profiles (id, email, full_name, organization_id, role, is_approved)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    org_id,
    user_role,
    -- auto-approve admin accounts
    (user_role = 'admin')
  );
  
  RETURN NEW;
END;
$$;

-- Ensure the trigger is attached to the auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();