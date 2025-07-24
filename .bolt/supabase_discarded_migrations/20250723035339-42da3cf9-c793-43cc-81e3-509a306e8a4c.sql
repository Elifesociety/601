-- Add password field to management_teams table for team login
ALTER TABLE public.management_teams 
ADD COLUMN team_password TEXT;

-- Create team_notifications table for team vs individual task notifications
CREATE TABLE public.team_notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID REFERENCES public.management_teams(id) ON DELETE CASCADE,
  agent_mobile TEXT NOT NULL,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('team_task', 'individual_task')),
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on team_notifications
ALTER TABLE public.team_notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for team_notifications
CREATE POLICY "Enable all access for team_notifications" 
  ON public.team_notifications 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX idx_team_notifications_team_id ON public.team_notifications(team_id);
CREATE INDEX idx_team_notifications_agent_mobile ON public.team_notifications(agent_mobile);
CREATE INDEX idx_team_notifications_task_id ON public.team_notifications(task_id);

-- Add trigger for automatic timestamp updates on team_notifications
CREATE TRIGGER update_team_notifications_updated_at
  BEFORE UPDATE ON public.team_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();