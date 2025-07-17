-- Enable RLS on all Satguru tables
ALTER TABLE public.satguru_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_item_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_grn_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_issue_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_daily_stock_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_csv_upload_log ENABLE ROW LEVEL SECURITY;

-- Drop existing permissive policies on Satguru tables
DROP POLICY IF EXISTS "Authenticated users can manage satguru_categories" ON public.satguru_categories;
DROP POLICY IF EXISTS "Authenticated users can manage satguru_item_master" ON public.satguru_item_master;
DROP POLICY IF EXISTS "Authenticated users can manage satguru_stock" ON public.satguru_stock;
DROP POLICY IF EXISTS "Authenticated users can manage satguru_grn_log" ON public.satguru_grn_log;
DROP POLICY IF EXISTS "Authenticated users can manage satguru_issue_log" ON public.satguru_issue_log;
DROP POLICY IF EXISTS "Authenticated users can manage satguru_daily_stock_summary" ON public.satguru_daily_stock_summary;
DROP POLICY IF EXISTS "Users can manage their own upload logs" ON public.satguru_csv_upload_log;

-- Create organization-specific policies for Satguru tables
CREATE POLICY "Satguru users can manage categories" 
ON public.satguru_categories 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

CREATE POLICY "Satguru users can manage item master" 
ON public.satguru_item_master 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

CREATE POLICY "Satguru users can manage stock" 
ON public.satguru_stock 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

CREATE POLICY "Satguru users can manage grn log" 
ON public.satguru_grn_log 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

CREATE POLICY "Satguru users can manage issue log" 
ON public.satguru_issue_log 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

CREATE POLICY "Satguru users can manage daily stock summary" 
ON public.satguru_daily_stock_summary 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

CREATE POLICY "Satguru users can manage their upload logs" 
ON public.satguru_csv_upload_log 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'SATGURU'
  )
);

-- Update DKEGL table policies to be organization-specific
-- Drop existing overly permissive policies
DROP POLICY IF EXISTS "Authenticated users can manage categories" ON public.categories;
DROP POLICY IF EXISTS "Authenticated users can manage item_master" ON public.item_master;
DROP POLICY IF EXISTS "Authenticated users can manage stock" ON public.stock;
DROP POLICY IF EXISTS "Authenticated users can manage grn_log" ON public.grn_log;
DROP POLICY IF EXISTS "Authenticated users can manage issue_log" ON public.issue_log;
DROP POLICY IF EXISTS "Authenticated users can manage daily_stock_summary" ON public.daily_stock_summary;

-- Create organization-specific policies for DKEGL tables
CREATE POLICY "DKEGL users can manage categories" 
ON public.categories 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);

CREATE POLICY "DKEGL users can manage item master" 
ON public.item_master 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);

CREATE POLICY "DKEGL users can manage stock" 
ON public.stock 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);

CREATE POLICY "DKEGL users can manage grn log" 
ON public.grn_log 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);

CREATE POLICY "DKEGL users can manage issue log" 
ON public.issue_log 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);

CREATE POLICY "DKEGL users can manage daily stock summary" 
ON public.daily_stock_summary 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);

-- Update CSV upload log policy for DKEGL to be organization-specific
DROP POLICY IF EXISTS "Users can manage their own upload logs" ON public.csv_upload_log;
DROP POLICY IF EXISTS "Users can manage their upload logs" ON public.csv_upload_log;

CREATE POLICY "DKEGL users can manage their upload logs" 
ON public.csv_upload_log 
FOR ALL 
USING (
  auth.uid() = uploaded_by AND
  EXISTS (
    SELECT 1 FROM public.profiles p 
    JOIN public.organizations o ON p.organization_id = o.id 
    WHERE p.id = auth.uid() AND o.code = 'DKEGL'
  )
);