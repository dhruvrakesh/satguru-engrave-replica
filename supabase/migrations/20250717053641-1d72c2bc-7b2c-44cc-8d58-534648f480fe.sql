-- Ensure admin users have proper authentication setup
-- This will help reset their authentication if needed

-- First, let's make sure we have a function to check if users exist
CREATE OR REPLACE FUNCTION public.ensure_admin_users_setup()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  dkegl_user_id uuid;
  satguru_user_id uuid;
BEGIN
  -- Get user IDs from auth.users
  SELECT id INTO dkegl_user_id FROM auth.users WHERE email = 'info@dkenterprises.co.in';
  SELECT id INTO satguru_user_id FROM auth.users WHERE email = 'info@satguruengravures.com';
  
  -- Update profiles to ensure they have the correct user_id mapping
  IF dkegl_user_id IS NOT NULL THEN
    UPDATE public.profiles 
    SET id = dkegl_user_id 
    WHERE email = 'info@dkenterprises.co.in' AND id != dkegl_user_id;
    
    -- Log the action
    RAISE NOTICE 'DKEGL admin user ID: %', dkegl_user_id;
  END IF;
  
  IF satguru_user_id IS NOT NULL THEN
    UPDATE public.profiles 
    SET id = satguru_user_id 
    WHERE email = 'info@satguruengravures.com' AND id != satguru_user_id;
    
    -- Log the action
    RAISE NOTICE 'Satguru admin user ID: %', satguru_user_id;
  END IF;
  
  -- Ensure both profiles are approved and have admin role
  UPDATE public.profiles 
  SET 
    is_approved = true,
    role = 'admin',
    updated_at = now()
  WHERE email IN ('info@dkenterprises.co.in', 'info@satguruengravures.com');
  
  RAISE NOTICE 'Admin users setup completed';
END;
$$;

-- Run the function
SELECT public.ensure_admin_users_setup();