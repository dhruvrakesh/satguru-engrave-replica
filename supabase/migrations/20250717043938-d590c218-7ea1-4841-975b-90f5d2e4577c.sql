-- Add missing columns to stock table
ALTER TABLE public.stock 
ADD COLUMN IF NOT EXISTS opening_qty numeric DEFAULT 0;

-- Add missing columns to satguru_stock table  
ALTER TABLE public.satguru_stock 
ADD COLUMN IF NOT EXISTS opening_qty numeric DEFAULT 0;

-- Create missing function for Satguru item code generation
CREATE OR REPLACE FUNCTION public.satguru_generate_item_code(
  category_name text,
  qualifier text DEFAULT ''::text,
  size_mm text DEFAULT ''::text,
  gsm numeric DEFAULT NULL::numeric
)
RETURNS text
LANGUAGE plpgsql
AS $$
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
$$;