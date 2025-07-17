-- Fix infinite recursion in profiles RLS policies and enhance backend trigger

-- First, drop the problematic RLS policies that cause infinite recursion
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;

-- Create simple, non-recursive RLS policies for profiles
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id);

CREATE POLICY "Admin can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (has_role('admin'));

CREATE POLICY "Admin can update all profiles" 
ON public.profiles 
FOR UPDATE 
USING (has_role('admin'));

-- Ensure the handle_new_user trigger is robust and handles organization assignment correctly
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  emp_id TEXT;
  org_id UUID;
  user_role TEXT := 'employee';
BEGIN
  -- Extract employee_id from user metadata
  emp_id := NEW.raw_user_meta_data->>'employee_id';
  
  -- If no employee_id in metadata, create a temporary one
  IF emp_id IS NULL OR emp_id = '' THEN
    emp_id := 'TEMP_' || substr(NEW.id::text, 1, 8);
  END IF;
  
  -- Determine organization and role based on email domain
  IF NEW.email LIKE '%@satguruengravures.com' THEN
    SELECT id INTO org_id FROM public.organizations WHERE code = 'SATGURU';
    -- Make Satguru admin users automatically admin
    IF NEW.email = 'info@satguruengravures.com' THEN
      user_role := 'admin';
    END IF;
  ELSIF NEW.email LIKE '%@dkenterprises.co.in' THEN
    SELECT id INTO org_id FROM public.organizations WHERE code = 'DKEGL';
    -- Make DKEGL admin users automatically admin
    IF NEW.email = 'info@dkenterprises.co.in' THEN
      user_role := 'admin';
    END IF;
  ELSE
    -- Default to DKEGL for unknown domains
    SELECT id INTO org_id FROM public.organizations WHERE code = 'DKEGL';
  END IF;
  
  -- Insert into profiles table (handle conflicts gracefully)
  INSERT INTO public.profiles (id, email, employee_id, organization_id, is_approved, role, full_name)
  VALUES (
    NEW.id, 
    NEW.email, 
    emp_id,
    org_id,
    CASE 
      WHEN NEW.email IN ('info@dkenterprises.co.in', 'info@satguruengravures.com') THEN true
      ELSE false
    END,
    user_role,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    employee_id = EXCLUDED.employee_id,
    organization_id = EXCLUDED.organization_id,
    updated_at = timezone('utc'::text, now());
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log any errors but don't block user creation
    RAISE LOG 'Error in handle_new_user trigger: %', SQLERRM;
    RETURN NEW;
END;
$$;