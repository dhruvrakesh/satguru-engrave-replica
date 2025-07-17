-- Add missing columns to item_master table
ALTER TABLE public.item_master 
ADD COLUMN IF NOT EXISTS uom text,
ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';

-- Create daily_stock_snapshots table for legacy data functionality
CREATE TABLE IF NOT EXISTS public.daily_stock_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_date date NOT NULL DEFAULT CURRENT_DATE,
  snapshot_data jsonb NOT NULL,
  record_count integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  metadata jsonb
);

-- Enable RLS on daily_stock_snapshots
ALTER TABLE public.daily_stock_snapshots ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for daily_stock_snapshots
CREATE POLICY "Authenticated users can manage stock snapshots" ON public.daily_stock_snapshots
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Add similar columns to satguru_item_master for consistency
ALTER TABLE public.satguru_item_master 
ADD COLUMN IF NOT EXISTS uom text,
ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';

-- Create index on snapshot_date for better performance
CREATE INDEX IF NOT EXISTS idx_daily_stock_snapshots_date ON public.daily_stock_snapshots(snapshot_date);

-- Update existing item_master records to have a default status if null
UPDATE public.item_master SET status = 'active' WHERE status IS NULL;
UPDATE public.satguru_item_master SET status = 'active' WHERE status IS NULL;