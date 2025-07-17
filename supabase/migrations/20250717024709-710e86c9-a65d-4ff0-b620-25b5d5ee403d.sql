-- Create csv_upload_log table for both organizations
CREATE TABLE public.csv_upload_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  file_name TEXT NOT NULL,
  upload_type TEXT NOT NULL,
  total_rows INTEGER NOT NULL DEFAULT 0,
  successful_rows INTEGER NOT NULL DEFAULT 0,
  failed_rows INTEGER NOT NULL DEFAULT 0,
  error_details JSONB,
  uploaded_by UUID REFERENCES auth.users(id),
  upload_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create Satguru version
CREATE TABLE public.satguru_csv_upload_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  file_name TEXT NOT NULL,
  upload_type TEXT NOT NULL,
  total_rows INTEGER NOT NULL DEFAULT 0,
  successful_rows INTEGER NOT NULL DEFAULT 0,
  failed_rows INTEGER NOT NULL DEFAULT 0,
  error_details JSONB,
  uploaded_by UUID REFERENCES auth.users(id),
  upload_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.csv_upload_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satguru_csv_upload_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own upload logs" ON public.csv_upload_log
  FOR ALL USING (auth.uid() = uploaded_by);

CREATE POLICY "Users can manage their own upload logs" ON public.satguru_csv_upload_log
  FOR ALL USING (auth.uid() = uploaded_by);

-- Add updated_at trigger
CREATE TRIGGER update_csv_upload_log_updated_at
  BEFORE UPDATE ON public.csv_upload_log
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_satguru_csv_upload_log_updated_at
  BEFORE UPDATE ON public.satguru_csv_upload_log
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();