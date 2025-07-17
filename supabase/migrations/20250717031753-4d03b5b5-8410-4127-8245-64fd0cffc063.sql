-- Simple data population for Satguru with correct column structure

-- Add sample flexible packaging categories for Satguru (using correct column structure)
INSERT INTO public.satguru_categories (category_name, description) VALUES
('Flexible Packaging Films', 'Various types of flexible packaging films and materials'),
('Laminated Films', 'Multi-layer laminated films for food packaging'),
('Barrier Films', 'High-barrier films for extended shelf life'),
('Printed Films', 'Pre-printed flexible packaging films'),
('Shrink Films', 'Heat shrinkable packaging films')
ON CONFLICT (category_name) DO NOTHING;