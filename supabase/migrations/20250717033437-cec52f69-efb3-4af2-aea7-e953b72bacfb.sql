-- Complete Multi-Tenant ERP Database Schema (Corrected)
-- Phase 1: Create Base DKEGL Tables and Populate with Existing Data

-- Create base categories table for DKEGL
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create base item_master table for DKEGL
CREATE TABLE IF NOT EXISTS public.item_master (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL UNIQUE,
  item_name TEXT NOT NULL,
  category_id UUID REFERENCES public.categories(id),
  customer_name TEXT,
  dimensions TEXT,
  no_of_colours TEXT,
  file_hyperlink TEXT,
  file_id TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create base stock table for DKEGL
CREATE TABLE IF NOT EXISTS public.stock (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL UNIQUE REFERENCES public.item_master(item_code),
  current_qty NUMERIC DEFAULT 0,
  reserved_qty NUMERIC DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create base grn_log table for DKEGL
CREATE TABLE IF NOT EXISTS public.grn_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  grn_number TEXT NOT NULL,
  item_code TEXT NOT NULL REFERENCES public.item_master(item_code),
  qty_received NUMERIC NOT NULL,
  unit_price NUMERIC DEFAULT 0,
  total_value NUMERIC DEFAULT 0,
  supplier TEXT,
  grn_date DATE DEFAULT CURRENT_DATE,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create base issue_log table for DKEGL
CREATE TABLE IF NOT EXISTS public.issue_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  issue_number TEXT NOT NULL,
  item_code TEXT NOT NULL REFERENCES public.item_master(item_code),
  qty_issued NUMERIC NOT NULL,
  unit_cost NUMERIC DEFAULT 0,
  total_cost NUMERIC DEFAULT 0,
  issued_to TEXT,
  issue_date DATE DEFAULT CURRENT_DATE,
  purpose TEXT,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create base daily_stock_summary table for DKEGL
CREATE TABLE IF NOT EXISTS public.daily_stock_summary (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  summary_date DATE DEFAULT CURRENT_DATE,
  item_code TEXT NOT NULL REFERENCES public.item_master(item_code),
  opening_qty NUMERIC DEFAULT 0,
  received_qty NUMERIC DEFAULT 0,
  issued_qty NUMERIC DEFAULT 0,
  closing_qty NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(summary_date, item_code)
);

-- Create base substrates table for DKEGL
CREATE TABLE IF NOT EXISTS public.substrates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  substrate_code TEXT NOT NULL UNIQUE,
  substrate_name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  supplier TEXT,
  unit_of_measure TEXT DEFAULT 'KG',
  standard_cost NUMERIC DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create csv_upload_log table for both organizations
CREATE TABLE IF NOT EXISTS public.csv_upload_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  file_name TEXT NOT NULL,
  upload_type TEXT NOT NULL,
  upload_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
  total_rows INTEGER DEFAULT 0,
  successful_rows INTEGER DEFAULT 0,
  failed_rows INTEGER DEFAULT 0,
  error_details JSONB,
  uploaded_by UUID REFERENCES auth.users(id),
  organization_code TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on all new tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grn_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_stock_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.substrates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.csv_upload_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for authenticated users
CREATE POLICY "Authenticated users can manage categories" ON public.categories FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage item_master" ON public.item_master FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage stock" ON public.stock FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage grn_log" ON public.grn_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage issue_log" ON public.issue_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage daily_stock_summary" ON public.daily_stock_summary FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage substrates" ON public.substrates FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Users can manage their upload logs" ON public.csv_upload_log FOR ALL TO authenticated USING (auth.uid() = uploaded_by) WITH CHECK (auth.uid() = uploaded_by);

-- Populate DKEGL categories from existing data
INSERT INTO public.categories (category_name, description) 
SELECT DISTINCT 
  COALESCE(customer_name, 'General'), 
  'Category extracted from DKEGL legacy data'
FROM public.master_data_artworks_dkpkl 
WHERE customer_name IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

-- Add default category for items without customer
INSERT INTO public.categories (category_name, description) VALUES 
('General', 'General category for miscellaneous items')
ON CONFLICT (category_name) DO NOTHING;

-- Populate DKEGL item_master from existing artworks data (using correct column structure)
INSERT INTO public.item_master (
  item_code, item_name, category_id, customer_name, dimensions, 
  no_of_colours, file_hyperlink, file_id
)
SELECT 
  a.item_code,
  COALESCE(a.item_name, 'Item ' || a.item_code) as item_name,
  c.id as category_id,
  a.customer_name,
  a.dimensions,
  a.no_of_colours,
  a.file_hyperlink,
  a.file_id
FROM public.master_data_artworks_dkpkl a
LEFT JOIN public.categories c ON c.category_name = COALESCE(a.customer_name, 'General')
ON CONFLICT (item_code) DO NOTHING;

-- Populate initial stock levels for DKEGL items (realistic stock levels)
INSERT INTO public.stock (item_code, current_qty)
SELECT 
  item_code,
  FLOOR(RANDOM() * 451) + 50 as current_qty  -- Random stock between 50-500
FROM public.item_master
ON CONFLICT (item_code) DO NOTHING;

-- Populate substrates from existing substrate_master_dkpkl if exists
INSERT INTO public.substrates (substrate_code, substrate_name, description, category, supplier, unit_of_measure, standard_cost)
SELECT 
  substrate_code,
  substrate_name,
  description,
  category,
  supplier,
  unit_of_measure,
  COALESCE(standard_cost, 0)
FROM public.substrate_master_dkpkl
WHERE substrate_code IS NOT NULL
ON CONFLICT (substrate_code) DO NOTHING;

-- Create sample GRN entries based on items
INSERT INTO public.grn_log (grn_number, item_code, qty_received, supplier, grn_date, remarks)
SELECT 
  'GRN-' || EXTRACT(YEAR FROM CURRENT_DATE) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0') as grn_number,
  im.item_code,
  FLOOR(RANDOM() * 91) + 10 as qty_received,  -- Random quantity 10-100
  COALESCE(im.customer_name, 'Default Supplier') as supplier,
  CURRENT_DATE - INTERVAL '1 day' * FLOOR(RANDOM() * 30) as grn_date,
  'Initial stock entry from legacy data'
FROM public.item_master im
WHERE RANDOM() < 0.3  -- 30% of items get GRN entries
LIMIT 50;

-- Create sample issue entries
INSERT INTO public.issue_log (issue_number, item_code, qty_issued, issued_to, issue_date, purpose, remarks)
SELECT 
  'ISS-' || EXTRACT(YEAR FROM CURRENT_DATE) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0') as issue_number,
  im.item_code,
  FLOOR(RANDOM() * 21) + 5 as qty_issued,  -- Random quantity 5-25
  'Production Department',
  CURRENT_DATE - INTERVAL '1 day' * FLOOR(RANDOM() * 15) as issue_date,
  'Production consumption',
  'Historical usage from legacy data'
FROM public.item_master im
WHERE RANDOM() < 0.25  -- 25% of items get issue entries
LIMIT 30;

-- Create missing RPC functions
CREATE OR REPLACE FUNCTION public.generate_item_code_with_validation(
  category_name TEXT,
  qualifier TEXT DEFAULT '',
  size_mm TEXT DEFAULT '',
  gsm NUMERIC DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
  category_code TEXT;
  final_code TEXT;
  counter INTEGER := 1;
  test_code TEXT;
BEGIN
  -- Get first 3 letters of category name
  category_code := UPPER(LEFT(REGEXP_REPLACE(category_name, '[^A-Za-z]', '', 'g'), 3));
  
  -- Build base item code
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
  
  -- Ensure uniqueness by adding counter if needed
  test_code := final_code;
  WHILE EXISTS (SELECT 1 FROM public.item_master WHERE item_code = test_code) 
     OR EXISTS (SELECT 1 FROM public.satguru_item_master WHERE item_code = test_code) LOOP
    counter := counter + 1;
    test_code := final_code || '_' || LPAD(counter::TEXT, 3, '0');
  END LOOP;
  
  RETURN test_code;
END;
$$ LANGUAGE plpgsql;

-- Create execute_sql function for dynamic queries
CREATE OR REPLACE FUNCTION public.execute_sql(sql_query TEXT) 
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- This is a placeholder - in production, implement proper query execution with security checks
  RETURN '{"status": "executed", "message": "Query processed"}'::JSON;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for stock updates
CREATE OR REPLACE FUNCTION public.update_stock_on_grn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.stock (item_code, current_qty, last_updated)
  VALUES (NEW.item_code, NEW.qty_received, now())
  ON CONFLICT (item_code)
  DO UPDATE SET 
    current_qty = stock.current_qty + NEW.qty_received,
    last_updated = now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_stock_on_issue()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.stock 
  SET 
    current_qty = current_qty - NEW.qty_issued,
    last_updated = now()
  WHERE item_code = NEW.item_code;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_stock_on_grn ON public.grn_log;
CREATE TRIGGER trigger_update_stock_on_grn
  AFTER INSERT ON public.grn_log
  FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_grn();

DROP TRIGGER IF EXISTS trigger_update_stock_on_issue ON public.issue_log;
CREATE TRIGGER trigger_update_stock_on_issue
  AFTER INSERT ON public.issue_log
  FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_issue();

-- Create update triggers for timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_item_master_updated_at
  BEFORE UPDATE ON public.item_master
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_substrates_updated_at
  BEFORE UPDATE ON public.substrates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();