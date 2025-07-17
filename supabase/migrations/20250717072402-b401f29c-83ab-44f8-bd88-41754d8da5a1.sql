-- Insert some test data into Satguru tables for testing

-- Add a few test categories
INSERT INTO public.satguru_categories (category_name, description) VALUES 
('Test Category 1', 'Test category for Satguru organization'),
('Test Category 2', 'Another test category for Satguru'),
('Raw Materials', 'Raw materials for production')
ON CONFLICT DO NOTHING;

-- Add a few test items
INSERT INTO public.satguru_item_master (item_code, item_name, category_id) 
SELECT 'SAT001', 'Test Item 1', id FROM public.satguru_categories WHERE category_name = 'Test Category 1' LIMIT 1
ON CONFLICT (item_code) DO NOTHING;

INSERT INTO public.satguru_item_master (item_code, item_name, category_id) 
SELECT 'SAT002', 'Test Item 2', id FROM public.satguru_categories WHERE category_name = 'Test Category 2' LIMIT 1
ON CONFLICT (item_code) DO NOTHING;

-- Add stock data for the test items
INSERT INTO public.satguru_stock (item_code, current_qty, min_stock_level, max_stock_level)
VALUES 
('SAT001', 100, 10, 500),
('SAT002', 50, 5, 200)
ON CONFLICT (item_code) DO UPDATE SET
  current_qty = EXCLUDED.current_qty,
  min_stock_level = EXCLUDED.min_stock_level,
  max_stock_level = EXCLUDED.max_stock_level;