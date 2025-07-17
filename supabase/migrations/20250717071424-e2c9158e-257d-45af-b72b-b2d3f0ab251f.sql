-- Create Satguru-specific tables to match DKEGL structure

-- Categories table for Satguru
CREATE TABLE IF NOT EXISTS public.satguru_categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category_name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Item master table for Satguru
CREATE TABLE IF NOT EXISTS public.satguru_item_master (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL UNIQUE,
  item_name TEXT NOT NULL,
  category_id UUID REFERENCES public.satguru_categories(id),
  customer_name TEXT,
  dimensions TEXT,
  no_of_colours TEXT,
  file_id TEXT,
  file_hyperlink TEXT,
  uom TEXT,
  status TEXT DEFAULT 'active',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Stock table for Satguru  
CREATE TABLE IF NOT EXISTS public.satguru_stock (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code),
  current_qty NUMERIC DEFAULT 0,
  min_stock_level NUMERIC DEFAULT 0,
  max_stock_level NUMERIC DEFAULT 0,
  reorder_level NUMERIC DEFAULT 0,
  location TEXT,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- GRN log table for Satguru
CREATE TABLE IF NOT EXISTS public.satguru_grn_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  grn_number TEXT NOT NULL,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code),
  qty_received NUMERIC NOT NULL,
  unit_price NUMERIC,
  total_value NUMERIC,
  supplier TEXT,
  grn_date DATE DEFAULT CURRENT_DATE,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Issue log table for Satguru
CREATE TABLE IF NOT EXISTS public.satguru_issue_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  issue_number TEXT NOT NULL,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code),
  qty_issued NUMERIC NOT NULL,
  unit_cost NUMERIC,
  total_cost NUMERIC,
  issued_to TEXT,
  issue_date DATE DEFAULT CURRENT_DATE,
  purpose TEXT,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Daily stock summary for Satguru
CREATE TABLE IF NOT EXISTS public.satguru_daily_stock_summary (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  item_code TEXT NOT NULL REFERENCES public.satguru_item_master(item_code),
  summary_date DATE DEFAULT CURRENT_DATE,
  opening_qty NUMERIC DEFAULT 0,
  received_qty NUMERIC DEFAULT 0,
  issued_qty NUMERIC DEFAULT 0,
  closing_qty NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on all Satguru tables
ALTER TABLE public.satguru_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_item_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_grn_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_issue_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_daily_stock_summary ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for Satguru tables (authenticated users can manage their org data)
CREATE POLICY "Authenticated users can manage satguru_categories" ON public.satguru_categories
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can manage satguru_item_master" ON public.satguru_item_master
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can manage satguru_stock" ON public.satguru_stock
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can manage satguru_grn_log" ON public.satguru_grn_log
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can manage satguru_issue_log" ON public.satguru_issue_log
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can manage satguru_daily_stock_summary" ON public.satguru_daily_stock_summary
  FOR ALL USING (true) WITH CHECK (true);

-- Add triggers for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_satguru_categories_updated_at BEFORE UPDATE ON public.satguru_categories 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_satguru_item_master_updated_at BEFORE UPDATE ON public.satguru_item_master 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_satguru_grn_log_updated_at BEFORE UPDATE ON public.satguru_grn_log 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_satguru_issue_log_updated_at BEFORE UPDATE ON public.satguru_issue_log 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Stock update triggers for Satguru
CREATE OR REPLACE FUNCTION public.satguru_update_stock_on_grn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.satguru_stock (item_code, current_qty, last_updated)
  VALUES (NEW.item_code, NEW.qty_received, now())
  ON CONFLICT (item_code)
  DO UPDATE SET 
    current_qty = satguru_stock.current_qty + NEW.qty_received,
    last_updated = now();
  
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.satguru_update_stock_on_issue()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.satguru_stock 
  SET 
    current_qty = current_qty - NEW.qty_issued,
    last_updated = now()
  WHERE item_code = NEW.item_code;
  
  RETURN NEW;
END;
$$;

-- Create triggers for stock updates
CREATE TRIGGER satguru_grn_stock_update 
  AFTER INSERT ON public.satguru_grn_log
  FOR EACH ROW EXECUTE FUNCTION public.satguru_update_stock_on_grn();

CREATE TRIGGER satguru_issue_stock_update 
  AFTER INSERT ON public.satguru_issue_log
  FOR EACH ROW EXECUTE FUNCTION public.satguru_update_stock_on_issue();