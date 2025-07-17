-- Create Satguru Engravures Independent Database Schema
-- This creates a complete separate backend for Satguru with data isolation

-- Create Satguru categories table
CREATE TABLE public.satguru_categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category_name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create Satguru item master table
CREATE TABLE public.satguru_item_master (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL UNIQUE,
  item_name TEXT NOT NULL,
  category_id UUID REFERENCES public.satguru_categories(id),
  qualifier TEXT,
  gsm NUMERIC,
  size_mm TEXT,
  uom TEXT NOT NULL DEFAULT 'PCS',
  usage_type TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  auto_code TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create Satguru stock table
CREATE TABLE public.satguru_stock (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code) ON UPDATE CASCADE,
  opening_qty NUMERIC NOT NULL DEFAULT 0,
  current_qty NUMERIC NOT NULL DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(item_code)
);

-- Create Satguru GRN log table
CREATE TABLE public.satguru_grn_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  grn_number TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code) ON UPDATE CASCADE,
  uom TEXT NOT NULL,
  qty_received NUMERIC NOT NULL,
  invoice_number TEXT,
  amount_inr NUMERIC,
  vendor TEXT,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create Satguru issue log table
CREATE TABLE public.satguru_issue_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code) ON UPDATE CASCADE,
  qty_issued NUMERIC NOT NULL,
  purpose TEXT,
  total_issued_qty NUMERIC,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create Satguru daily stock summary table
CREATE TABLE public.satguru_daily_stock_summary (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL,
  item_name TEXT NOT NULL,
  category_name TEXT,
  summary_date DATE NOT NULL DEFAULT CURRENT_DATE,
  opening_qty NUMERIC NOT NULL DEFAULT 0,
  total_grn_qty NUMERIC NOT NULL DEFAULT 0,
  total_issued_qty NUMERIC NOT NULL DEFAULT 0,
  current_qty NUMERIC NOT NULL DEFAULT 0,
  days_of_cover NUMERIC,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(item_code, summary_date)
);

-- Enable RLS on all Satguru tables
ALTER TABLE public.satguru_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_item_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_grn_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_issue_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_daily_stock_summary ENABLE ROW LEVEL SECURITY;

-- Create organization table for multi-tenancy
CREATE TABLE public.organizations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insert default organizations
INSERT INTO public.organizations (name, code, description) VALUES
('DK Enterprises Group Limited (PKL)', 'DKEGL', 'Original DKEGL PKL operations'),
('Satguru Engravures', 'SATGURU', 'Satguru Engravures flexible packaging operations');

-- Add organization_id to profiles table
ALTER TABLE public.profiles ADD COLUMN organization_id UUID REFERENCES public.organizations(id);

-- Update existing profiles to DKEGL organization
UPDATE public.profiles SET organization_id = (SELECT id FROM public.organizations WHERE code = 'DKEGL');

-- Make organization_id required for new profiles
ALTER TABLE public.profiles ALTER COLUMN organization_id SET NOT NULL;

-- Create permissive policies for Satguru tables (authenticated users only)
CREATE POLICY "Allow authenticated users full access to Satguru categories" ON public.satguru_categories FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access to Satguru item master" ON public.satguru_item_master FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access to Satguru stock" ON public.satguru_stock FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access to Satguru GRN log" ON public.satguru_grn_log FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access to Satguru issue log" ON public.satguru_issue_log FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access to Satguru daily stock summary" ON public.satguru_daily_stock_summary FOR ALL USING (auth.role() = 'authenticated');

-- Create Satguru-specific functions
CREATE OR REPLACE FUNCTION public.satguru_generate_item_code(
  category_name TEXT,
  qualifier TEXT DEFAULT '',
  size_mm TEXT DEFAULT '',
  gsm NUMERIC DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
  category_code TEXT;
  final_code TEXT;
BEGIN
  -- Get first 3 letters of category name
  category_code := UPPER(LEFT(REGEXP_REPLACE(category_name, '[^A-Za-z]', '', 'g'), 3));
  
  -- Build item code
  final_code := category_code;
  
  IF qualifier IS NOT NULL AND qualifier != '' THEN
    final_code := final_code || '_' || UPPER(qualifier);
  END IF;
  
  IF size_mm IS NOT NULL AND size_mm != '' THEN
    final_code := final_code || '_' || size_mm;
  END IF;
  
  IF gsm IS NOT NULL THEN
    final_code := final_code || '_' || gsm::TEXT;
  END IF;
  
  RETURN final_code;
END;
$$ LANGUAGE plpgsql;

-- Create Satguru stock update functions
CREATE OR REPLACE FUNCTION public.satguru_update_stock_on_grn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.satguru_stock (item_code, current_qty, last_updated)
  VALUES (NEW.item_code, NEW.qty_received, now())
  ON CONFLICT (item_code)
  DO UPDATE SET 
    current_qty = satguru_stock.current_qty + NEW.qty_received,
    last_updated = now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.satguru_update_stock_on_issue()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.satguru_stock 
  SET 
    current_qty = current_qty - NEW.qty_issued,
    last_updated = now()
  WHERE item_code = NEW.item_code;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for Satguru stock updates
CREATE TRIGGER satguru_grn_stock_update
  AFTER INSERT ON public.satguru_grn_log
  FOR EACH ROW
  EXECUTE FUNCTION public.satguru_update_stock_on_grn();

CREATE TRIGGER satguru_issue_stock_update
  AFTER INSERT ON public.satguru_issue_log
  FOR EACH ROW
  EXECUTE FUNCTION public.satguru_update_stock_on_issue();

-- Create Satguru stock summary view
CREATE OR REPLACE VIEW public.satguru_stock_summary AS
SELECT 
  im.item_code,
  im.item_name,
  c.category_name,
  s.opening_qty,
  COALESCE(grn_totals.total_grn_qty, 0) as total_grn_qty,
  COALESCE(issue_totals.total_issued_qty, 0) as total_issued_qty,
  s.current_qty,
  CASE 
    WHEN COALESCE(issue_totals.avg_daily_consumption, 0) > 0 
    THEN s.current_qty / issue_totals.avg_daily_consumption
    ELSE NULL
  END as days_of_cover
FROM public.satguru_item_master im
LEFT JOIN public.satguru_categories c ON im.category_id = c.id
LEFT JOIN public.satguru_stock s ON im.item_code = s.item_code
LEFT JOIN (
  SELECT 
    item_code,
    SUM(qty_received) as total_grn_qty
  FROM public.satguru_grn_log
  GROUP BY item_code
) grn_totals ON im.item_code = grn_totals.item_code
LEFT JOIN (
  SELECT 
    item_code,
    SUM(qty_issued) as total_issued_qty,
    AVG(qty_issued) as avg_daily_consumption
  FROM public.satguru_issue_log
  WHERE date >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY item_code
) issue_totals ON im.item_code = issue_totals.item_code;

-- Create update timestamp triggers for Satguru tables
CREATE TRIGGER update_satguru_categories_updated_at
  BEFORE UPDATE ON public.satguru_categories
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_satguru_item_master_updated_at
  BEFORE UPDATE ON public.satguru_item_master
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default Satguru categories for flexible packaging
INSERT INTO public.satguru_categories (category_name, description) VALUES
('Flexible Films', 'Flexible packaging films and substrates'),
('Printing Inks', 'Inks and colorants for flexible packaging'),
('Adhesives', 'Laminating and bonding adhesives'),
('Substrates', 'Base materials for flexible packaging'),
('Chemicals', 'Processing chemicals and additives'),
('Tools & Equipment', 'Manufacturing tools and equipment parts'),
('Consumables', 'General consumable items');

-- Create RLS policies for organizations table
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view organizations" 
ON public.organizations 
FOR SELECT 
USING (auth.role() = 'authenticated');

-- Update profiles table RLS to include organization context
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

CREATE POLICY "Users can view profiles in their organization" 
ON public.profiles 
FOR SELECT 
USING (
  auth.role() = 'authenticated' AND (
    organization_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid()) OR
    is_admin()
  )
);

CREATE POLICY "Users can update their own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid() = id);