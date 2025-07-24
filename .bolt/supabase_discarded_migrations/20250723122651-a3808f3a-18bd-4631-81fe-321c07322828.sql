-- Add missing panchayath_id column to user_registration_requests table
ALTER TABLE public.user_registration_requests 
ADD COLUMN panchayath_id uuid REFERENCES public.panchayaths(id);

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_user_registration_requests_panchayath_id 
ON public.user_registration_requests(panchayath_id);

-- Ensure management_teams table has is_active column for team management
ALTER TABLE public.management_teams 
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;