-- Fix RLS policies for user_registration_requests table
-- Allow anyone to insert registration requests (for guest registration)
-- Allow admin users to view and update requests

-- Drop existing policies if any
DROP POLICY IF EXISTS "Enable all access for user_registration_requests" ON public.user_registration_requests;

-- Enable RLS
ALTER TABLE public.user_registration_requests ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert new registration requests (for guest registration)
CREATE POLICY "Anyone can submit registration requests" 
ON public.user_registration_requests 
FOR INSERT 
WITH CHECK (true);

-- Allow everyone to read their own requests or all requests (for admin panel)
CREATE POLICY "Enable read access for user_registration_requests" 
ON public.user_registration_requests 
FOR SELECT 
USING (true);

-- Allow everyone to update registration requests (for admin approval)
CREATE POLICY "Enable update access for user_registration_requests" 
ON public.user_registration_requests 
FOR UPDATE 
USING (true);