-- Check if the trigger exists and recreate it if necessary
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger to automatically create profiles for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verify that both admin accounts have proper profiles
-- If any are missing, create them
DO $$ 
BEGIN
  -- Create profile for DKEGL admin if missing
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'cfbc6c78-7d2c-4845-8a60-70ef2c525791') THEN
    INSERT INTO public.profiles (id, email, full_name, organization_id, role, is_approved)
    VALUES (
      'cfbc6c78-7d2c-4845-8a60-70ef2c525791',
      'info@dkenterprises.co.in',
      'DKEGL Admin',
      (SELECT id FROM public.organizations WHERE code = 'DKEGL'),
      'admin',
      true
    );
  END IF;

  -- Create profile for Satguru admin if missing
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = '013013f4-fac2-4316-b883-4a5970ae85d6') THEN
    INSERT INTO public.profiles (id, email, full_name, organization_id, role, is_approved)
    VALUES (
      '013013f4-fac2-4316-b883-4a5970ae85d6',
      'info@satguruengravures.com',
      'Satguru Admin',
      (SELECT id FROM public.organizations WHERE code = 'SATGURU'),
      'admin',
      true
    );
  END IF;
END $$;