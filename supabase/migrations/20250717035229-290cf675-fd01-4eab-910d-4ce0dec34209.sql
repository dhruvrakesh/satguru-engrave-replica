-- Create organizations table
CREATE TABLE public.organizations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insert DKEGL and SATGURU organizations
INSERT INTO public.organizations (name, code, description) VALUES
('DK Enterprises Gujarat Limited', 'DKEGL', 'Main organization for DKEGL operations'),
('Satguru', 'SATGURU', 'Satguru organization operations');

-- Add organization_id to profiles table if it doesn't exist
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id);

-- Update existing profiles to reference DKEGL as default organization
UPDATE public.profiles 
SET organization_id = (SELECT id FROM public.organizations WHERE code = 'DKEGL')
WHERE organization_id IS NULL;

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Create policies for organizations
CREATE POLICY "Users can view their organization" 
ON public.organizations 
FOR SELECT 
USING (id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Authenticated users can view organizations" 
ON public.organizations 
FOR SELECT 
USING (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.organizations TO authenticated;
GRANT USAGE ON SEQUENCE organizations_id_seq TO authenticated;