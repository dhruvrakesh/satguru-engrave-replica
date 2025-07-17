-- Add organization_id column to profiles table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN organization_id UUID REFERENCES public.organizations(id);
  END IF;
END $$;

-- Update existing profiles to set organization_id based on email domain
UPDATE public.profiles 
SET organization_id = (
  SELECT id FROM public.organizations 
  WHERE code = CASE 
    WHEN profiles.email LIKE '%@satguruengravures.com' THEN 'SATGURU'
    WHEN profiles.email LIKE '%@dkenterprises.co.in' THEN 'DKEGL'
    ELSE 'DKEGL' -- Default to DKEGL
  END
)
WHERE organization_id IS NULL;