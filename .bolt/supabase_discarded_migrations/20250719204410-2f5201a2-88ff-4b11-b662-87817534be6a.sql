-- Add panchayath_id column to user_registration_requests table
ALTER TABLE public.user_registration_requests 
ADD COLUMN panchayath_id uuid REFERENCES public.panchayaths(id);