-- Phase 1: Critical Authentication & User Setup for Satguru Organization

-- Update the admin check function to handle both organizations
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
  SELECT COALESCE(
    (SELECT email FROM auth.users WHERE id = auth.uid()) IN ('info@dkenterprises.co.in', 'info@satguruengravures.com'),
    false
  );
$function$;

-- Create organization-aware admin check function
CREATE OR REPLACE FUNCTION public.is_organization_admin(org_code text)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
  SELECT CASE
    WHEN org_code = 'DKEGL' THEN 
      COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()) = 'info@dkenterprises.co.in', false)
    WHEN org_code = 'SATGURU' THEN 
      COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()) = 'info@satguruengravures.com', false)
    ELSE false
  END;
$function$;

-- Create profile for Satguru admin if not exists
INSERT INTO public.profiles (id, email, employee_id, is_approved, role, organization_id)
SELECT 
  '00000000-0000-0000-0000-000000000002'::uuid,
  'info@satguruengravures.com',
  'SATGURU_ADMIN',
  true,
  'admin',
  (SELECT id FROM organizations WHERE code = 'SATGURU' LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles WHERE email = 'info@satguruengravures.com'
);

-- Ensure DKEGL admin profile exists and is properly assigned
INSERT INTO public.profiles (id, email, employee_id, is_approved, role, organization_id)
SELECT 
  '00000000-0000-0000-0000-000000000001'::uuid,
  'info@dkenterprises.co.in',
  'DKEGL_ADMIN',
  true,
  'admin',
  (SELECT id FROM organizations WHERE code = 'DKEGL' LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles WHERE email = 'info@dkenterprises.co.in'
)
ON CONFLICT (id) DO UPDATE SET
  organization_id = (SELECT id FROM organizations WHERE code = 'DKEGL' LIMIT 1),
  role = 'admin',
  is_approved = true;

-- Update existing Satguru profile if it exists
UPDATE public.profiles 
SET 
  organization_id = (SELECT id FROM organizations WHERE code = 'SATGURU' LIMIT 1),
  role = 'admin',
  is_approved = true,
  employee_id = COALESCE(employee_id, 'SATGURU_ADMIN')
WHERE email = 'info@satguruengravures.com';

-- Populate Satguru with sample flexible packaging categories
INSERT INTO public.satguru_categories (name, description, is_active) VALUES
('Flexible Packaging Films', 'Various types of flexible packaging films and materials', true),
('Laminated Films', 'Multi-layer laminated films for food packaging', true),
('Barrier Films', 'High-barrier films for extended shelf life', true),
('Printed Films', 'Pre-printed flexible packaging films', true),
('Shrink Films', 'Heat shrinkable packaging films', true)
ON CONFLICT (name) DO NOTHING;

-- Add sample Satguru items using the item code generation function
DO $$
DECLARE
    cat_id uuid;
    film_cat_id uuid;
    lam_cat_id uuid;
    barrier_cat_id uuid;
BEGIN
    -- Get category IDs
    SELECT id INTO cat_id FROM public.satguru_categories WHERE name = 'Flexible Packaging Films' LIMIT 1;
    SELECT id INTO film_cat_id FROM public.satguru_categories WHERE name = 'Printed Films' LIMIT 1;
    SELECT id INTO lam_cat_id FROM public.satguru_categories WHERE name = 'Laminated Films' LIMIT 1;
    SELECT id INTO barrier_cat_id FROM public.satguru_categories WHERE name = 'Barrier Films' LIMIT 1;
    
    -- Insert sample items
    INSERT INTO public.satguru_item_master (item_code, item_name, category_id, description, unit, reorder_level, is_active) VALUES
    (public.satguru_generate_item_code('Flexible Packaging Films', 'PE', '100', 25), 'PE Film 100 microns 25 GSM', cat_id, 'Polyethylene flexible packaging film', 'KG', 500, true),
    (public.satguru_generate_item_code('Flexible Packaging Films', 'PP', '150', 30), 'PP Film 150 microns 30 GSM', cat_id, 'Polypropylene flexible packaging film', 'KG', 300, true),
    (public.satguru_generate_item_code('Laminated Films', 'PET_PE', '200', 40), 'PET/PE Laminated Film 200 microns', lam_cat_id, 'PET/PE laminated barrier film', 'KG', 200, true),
    (public.satguru_generate_item_code('Barrier Films', 'EVOH', '120', 35), 'EVOH Barrier Film 120 microns', barrier_cat_id, 'EVOH high barrier film for food packaging', 'KG', 150, true),
    (public.satguru_generate_item_code('Printed Films', 'BOPP', '180', 28), 'BOPP Printed Film 180 microns', film_cat_id, 'BOPP film with customer branding', 'KG', 400, true)
    ON CONFLICT (item_code) DO NOTHING;
END $$;

-- Add sample stock data for Satguru items
INSERT INTO public.satguru_stock (item_code, current_qty, minimum_qty, maximum_qty, unit_cost, last_updated)
SELECT 
    sm.item_code,
    CASE 
        WHEN sm.item_code LIKE '%PE%' THEN 1500
        WHEN sm.item_code LIKE '%PP%' THEN 1200
        WHEN sm.item_code LIKE '%PET%' THEN 800
        WHEN sm.item_code LIKE '%EVOH%' THEN 600
        WHEN sm.item_code LIKE '%BOPP%' THEN 1000
        ELSE 500
    END as current_qty,
    sm.reorder_level as minimum_qty,
    sm.reorder_level * 3 as maximum_qty,
    CASE 
        WHEN sm.item_code LIKE '%PE%' THEN 45.50
        WHEN sm.item_code LIKE '%PP%' THEN 52.75
        WHEN sm.item_code LIKE '%PET%' THEN 78.90
        WHEN sm.item_code LIKE '%EVOH%' THEN 125.60
        WHEN sm.item_code LIKE '%BOPP%' THEN 65.30
        ELSE 50.00
    END as unit_cost,
    now() as last_updated
FROM public.satguru_item_master sm
WHERE NOT EXISTS (
    SELECT 1 FROM public.satguru_stock ss WHERE ss.item_code = sm.item_code
);

-- Add sample GRN data for Satguru
INSERT INTO public.satguru_grn_log (item_code, qty_received, unit_rate, supplier_name, grn_date, remarks)
SELECT 
    item_code,
    500 as qty_received,
    CASE 
        WHEN item_code LIKE '%PE%' THEN 45.50
        WHEN item_code LIKE '%PP%' THEN 52.75
        WHEN item_code LIKE '%PET%' THEN 78.90
        WHEN item_code LIKE '%EVOH%' THEN 125.60
        WHEN item_code LIKE '%BOPP%' THEN 65.30
        ELSE 50.00
    END as unit_rate,
    'Flexible Films Supplier Pvt Ltd' as supplier_name,
    CURRENT_DATE - INTERVAL '7 days' as grn_date,
    'Initial stock receipt for flexible packaging materials' as remarks
FROM public.satguru_item_master
WHERE item_code IN (
    SELECT item_code FROM public.satguru_item_master LIMIT 3
);

-- Add sample issue data for Satguru
INSERT INTO public.satguru_issue_log (item_code, qty_issued, issued_to, issue_date, purpose, remarks)
SELECT 
    item_code,
    100 as qty_issued,
    'Production Department' as issued_to,
    CURRENT_DATE - INTERVAL '2 days' as issue_date,
    'Production' as purpose,
    'Material issued for flexible packaging production' as remarks
FROM public.satguru_item_master
WHERE item_code IN (
    SELECT item_code FROM public.satguru_item_master LIMIT 2
);

-- Create daily stock summary data for Satguru
INSERT INTO public.satguru_daily_stock_summary (summary_date, total_items, low_stock_items, total_value, average_turnover)
VALUES (
    CURRENT_DATE,
    (SELECT COUNT(*) FROM public.satguru_item_master WHERE is_active = true),
    (SELECT COUNT(*) FROM public.satguru_stock s JOIN public.satguru_item_master i ON s.item_code = i.item_code WHERE s.current_qty <= i.reorder_level),
    (SELECT COALESCE(SUM(s.current_qty * s.unit_cost), 0) FROM public.satguru_stock s),
    0.85
) ON CONFLICT (summary_date) DO UPDATE SET
    total_items = EXCLUDED.total_items,
    low_stock_items = EXCLUDED.low_stock_items,
    total_value = EXCLUDED.total_value,
    updated_at = now();