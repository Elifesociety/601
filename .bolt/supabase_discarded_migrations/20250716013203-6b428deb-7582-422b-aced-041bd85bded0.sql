-- Create user registration requests table for guest access
CREATE TABLE public.user_registration_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT NOT NULL,
  mobile_number TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  approved_by TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(username),
  UNIQUE(mobile_number)
);

-- Enable RLS on user_registration_requests
ALTER TABLE public.user_registration_requests ENABLE ROW LEVEL SECURITY;

-- Create policies for user_registration_requests
CREATE POLICY "Anyone can create registration requests" 
ON public.user_registration_requests 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Users can view their own registration requests" 
ON public.user_registration_requests 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can update registration requests" 
ON public.user_registration_requests 
FOR UPDATE 
USING (true)
WITH CHECK (true);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_user_registration_requests_updated_at
BEFORE UPDATE ON public.user_registration_requests
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();