-- Create Satguru tables to mirror the main tables for organization-specific data

-- Create Satguru categories table
CREATE TABLE public.satguru_categories (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category_name text NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create Satguru item master table
CREATE TABLE public.satguru_item_master (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code text NOT NULL UNIQUE,
  item_name text NOT NULL,
  category_id uuid REFERENCES public.satguru_categories(id),
  customer_name text,
  dimensions text,
  file_hyperlink text,
  file_id text,
  no_of_colours text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create Satguru stock table
CREATE TABLE public.satguru_stock (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code text NOT NULL UNIQUE REFERENCES public.satguru_item_master(item_code),
  current_qty numeric DEFAULT 0,
  opening_qty numeric DEFAULT 0,
  reserved_qty numeric DEFAULT 0,
  last_updated timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now()
);

-- Create Satguru GRN log table
CREATE TABLE public.satguru_grn_log (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  grn_number text NOT NULL,
  item_code text NOT NULL REFERENCES public.satguru_item_master(item_code),
  qty_received numeric NOT NULL,
  unit_price numeric,
  total_value numeric,
  supplier text,
  grn_date date,
  remarks text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create Satguru issue log table
CREATE TABLE public.satguru_issue_log (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  issue_number text NOT NULL,
  item_code text NOT NULL REFERENCES public.satguru_item_master(item_code),
  qty_issued numeric NOT NULL,
  unit_cost numeric,
  total_cost numeric,
  issued_to text,
  purpose text,
  issue_date date,
  remarks text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create Satguru daily stock summary table
CREATE TABLE public.satguru_daily_stock_summary (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code text NOT NULL REFERENCES public.satguru_item_master(item_code),
  summary_date date DEFAULT CURRENT_DATE,
  opening_qty numeric DEFAULT 0,
  received_qty numeric DEFAULT 0,
  issued_qty numeric DEFAULT 0,
  closing_qty numeric DEFAULT 0,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS on all Satguru tables
ALTER TABLE public.satguru_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_item_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_grn_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_issue_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_daily_stock_summary ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for authenticated users
CREATE POLICY "Authenticated users can manage satguru_categories" ON public.satguru_categories FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage satguru_item_master" ON public.satguru_item_master FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage satguru_stock" ON public.satguru_stock FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage satguru_grn_log" ON public.satguru_grn_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage satguru_issue_log" ON public.satguru_issue_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage satguru_daily_stock_summary" ON public.satguru_daily_stock_summary FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Create triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_satguru_categories_updated_at BEFORE UPDATE ON public.satguru_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_satguru_item_master_updated_at BEFORE UPDATE ON public.satguru_item_master FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_satguru_grn_log_updated_at BEFORE UPDATE ON public.satguru_grn_log FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_satguru_issue_log_updated_at BEFORE UPDATE ON public.satguru_issue_log FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create a stock summary view for Satguru (similar to the existing one)
CREATE OR REPLACE VIEW public.satguru_stock_summary AS
SELECT 
  im.item_code,
  im.item_name,
  c.category_name,
  c.id as category_id,
  COALESCE(s.current_qty, 0) as current_qty,
  COALESCE(s.opening_qty, 0) as opening_qty,
  COALESCE(s.reserved_qty, 0) as reserved_qty,
  s.last_updated
FROM public.satguru_item_master im
LEFT JOIN public.satguru_categories c ON im.category_id = c.id
LEFT JOIN public.satguru_stock s ON im.item_code = s.item_code
WHERE im.is_active = true;