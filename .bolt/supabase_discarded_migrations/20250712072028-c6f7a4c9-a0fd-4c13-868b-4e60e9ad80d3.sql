
-- Create panchayath_notes table for storing notes and comments about panchayaths
CREATE TABLE public.panchayath_notes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on panchayath_notes
ALTER TABLE public.panchayath_notes ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for panchayath_notes (allow all users to read and write)
CREATE POLICY "Enable all access for panchayath_notes" 
  ON public.panchayath_notes 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_panchayath_notes_panchayath_id ON public.panchayath_notes(panchayath_id);
CREATE INDEX IF NOT EXISTS idx_panchayath_notes_created_at ON public.panchayath_notes(created_at DESC);
