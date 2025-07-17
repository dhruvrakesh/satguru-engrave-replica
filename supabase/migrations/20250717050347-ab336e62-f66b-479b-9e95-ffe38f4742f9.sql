-- Fix user profile assignment for Satguru admin
INSERT INTO public.profiles (id, email, employee_id, organization_id, role, is_approved, full_name)
SELECT 
  au.id,
  au.email,
  'SATGURU_ADMIN',
  org.id,
  'admin',
  true,
  'Satguru Admin'
FROM auth.users au
CROSS JOIN public.organizations org
WHERE au.email = 'info@satguruengravures.com' 
  AND org.code = 'SATGURU'
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = au.id)
ON CONFLICT (id) DO UPDATE SET
  organization_id = EXCLUDED.organization_id,
  role = EXCLUDED.role,
  is_approved = EXCLUDED.is_approved;

-- Enhance handle_new_user function to automatically assign organization based on email domain
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  emp_id TEXT;
  org_id UUID;
BEGIN
  -- Extract employee_id from user metadata
  emp_id := NEW.raw_user_meta_data->>'employee_id';
  
  -- If no employee_id in metadata, create a temporary one
  IF emp_id IS NULL OR emp_id = '' THEN
    emp_id := 'TEMP_' || substr(NEW.id::text, 1, 8);
  END IF;
  
  -- Determine organization based on email domain
  IF NEW.email LIKE '%@satguruengravures.com' THEN
    SELECT id INTO org_id FROM public.organizations WHERE code = 'SATGURU';
  ELSE
    SELECT id INTO org_id FROM public.organizations WHERE code = 'DKEGL';
  END IF;
  
  -- Insert into profiles table
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
    CASE 
      WHEN NEW.email IN ('info@dkenterprises.co.in', 'info@satguruengravures.com') THEN 'admin'
      ELSE 'employee'
    END,
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
    RETURN NEW;
END;
$$;

-- Populate Satguru test data
-- Create sample categories for Satguru
INSERT INTO public.satguru_categories (category_name, description) VALUES
('Raw Materials', 'Raw materials for production'),
('Finished Goods', 'Finished products ready for sale'),
('Packaging Materials', 'Materials used for packaging'),
('Chemicals', 'Chemical components and additives')
ON CONFLICT (category_name) DO NOTHING;

-- Create sample item master for Satguru (using correct schema)
INSERT INTO public.satguru_item_master (item_code, item_name, category_id, uom, qualifier, gsm, size_mm, status) 
SELECT 
  'SAT_' || substr(gen_random_uuid()::text, 1, 8),
  item_names.name,
  sc.id,
  'KG',
  'SAMPLE',
  80,
  '100x100',
  'active'
FROM (VALUES 
  ('Aluminum Foil Roll'),
  ('Plastic Film Sheet'),
  ('Paper Label Stock'),
  ('Adhesive Tape'),
  ('Corrugated Box'),
  ('Poly Bag'),
  ('Shrink Wrap'),
  ('Bubble Wrap')
) AS item_names(name)
CROSS JOIN public.satguru_categories sc
WHERE sc.category_name = 'Raw Materials'
LIMIT 8;

-- Create initial stock entries for Satguru items
INSERT INTO public.satguru_stock (item_code, current_qty, minimum_level, maximum_level, last_updated)
SELECT 
  sim.item_code,
  FLOOR(RANDOM() * 1000 + 100)::numeric,
  50,
  2000,
  now()
FROM public.satguru_item_master sim
WHERE NOT EXISTS (SELECT 1 FROM public.satguru_stock WHERE item_code = sim.item_code);

-- Create sample GRN entries for Satguru
INSERT INTO public.satguru_grn_log (grn_number, item_code, qty_received, unit_price, total_value, supplier, grn_date, remarks)
SELECT 
  'SGRN' || LPAD((ROW_NUMBER() OVER())::text, 6, '0'),
  sim.item_code,
  FLOOR(RANDOM() * 500 + 50)::numeric,
  ROUND((RANDOM() * 100 + 10)::numeric, 2),
  ROUND((FLOOR(RANDOM() * 500 + 50) * (RANDOM() * 100 + 10))::numeric, 2),
  'Sample Supplier ' || (ROW_NUMBER() OVER() % 3 + 1),
  CURRENT_DATE - INTERVAL '1 day' * (ROW_NUMBER() OVER() % 30),
  'Sample GRN for testing'
FROM public.satguru_item_master sim
LIMIT 10;

-- Create sample Issue entries for Satguru
INSERT INTO public.satguru_issue_log (issue_number, item_code, qty_issued, unit_cost, total_cost, issued_to, purpose, issue_date, remarks)
SELECT 
  'SISSUE' || LPAD((ROW_NUMBER() OVER())::text, 6, '0'),
  sim.item_code,
  FLOOR(RANDOM() * 200 + 10)::numeric,
  ROUND((RANDOM() * 100 + 10)::numeric, 2),
  ROUND((FLOOR(RANDOM() * 200 + 10) * (RANDOM() * 100 + 10))::numeric, 2),
  'Production Department',
  'Manufacturing Process',
  CURRENT_DATE - INTERVAL '1 day' * (ROW_NUMBER() OVER() % 20),
  'Sample issue for testing'
FROM public.satguru_item_master sim
LIMIT 8;

-- Create daily stock summary entries for Satguru
INSERT INTO public.satguru_daily_stock_summary (item_code, summary_date, opening_qty, received_qty, issued_qty, closing_qty)
SELECT 
  ss.item_code,
  CURRENT_DATE,
  ss.current_qty - COALESCE(recent_grn.total_received, 0) + COALESCE(recent_issue.total_issued, 0),
  COALESCE(recent_grn.total_received, 0),
  COALESCE(recent_issue.total_issued, 0),
  ss.current_qty
FROM public.satguru_stock ss
LEFT JOIN (
  SELECT item_code, SUM(qty_received) as total_received
  FROM public.satguru_grn_log 
  WHERE grn_date = CURRENT_DATE
  GROUP BY item_code
) recent_grn ON ss.item_code = recent_grn.item_code
LEFT JOIN (
  SELECT item_code, SUM(qty_issued) as total_issued
  FROM public.satguru_issue_log 
  WHERE issue_date = CURRENT_DATE
  GROUP BY item_code
) recent_issue ON ss.item_code = recent_issue.item_code
WHERE NOT EXISTS (
  SELECT 1 FROM public.satguru_daily_stock_summary 
  WHERE item_code = ss.item_code AND summary_date = CURRENT_DATE
);