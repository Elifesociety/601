-- Create daily activity log table
CREATE TABLE public.daily_activities (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  agent_id UUID NOT NULL,
  mobile_number TEXT NOT NULL,
  activity_date DATE NOT NULL,
  activity_description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(agent_id, activity_date)
);

-- Enable Row Level Security
ALTER TABLE public.daily_activities ENABLE ROW LEVEL SECURITY;

-- Create policies for daily_activities
CREATE POLICY "Enable all access for daily_activities" 
ON public.daily_activities 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_daily_activities_updated_at
BEFORE UPDATE ON public.daily_activities
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();