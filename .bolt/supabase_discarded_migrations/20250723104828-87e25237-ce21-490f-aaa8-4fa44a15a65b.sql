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

-- Create panchayaths table
CREATE TABLE public.panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  district TEXT NOT NULL,
  state TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create agent role enum
CREATE TYPE public.agent_role AS ENUM ('coordinator', 'supervisor', 'group-leader', 'pro');

-- Create agents table
CREATE TABLE public.agents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  role public.agent_role NOT NULL,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id) ON DELETE CASCADE,
  superior_id UUID REFERENCES public.agents(id) ON DELETE SET NULL,
  email TEXT,
  phone TEXT,
  ward TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team_leaders table
CREATE TABLE public.team_leaders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team_leader_panchayaths junction table
CREATE TABLE public.team_leader_panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_leader_id UUID NOT NULL REFERENCES public.team_leaders(id) ON DELETE CASCADE,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(team_leader_id, panchayath_id)
);

-- Create management teams table
CREATE TABLE public.management_teams (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  team_password TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insert default management teams
INSERT INTO public.management_teams (name, description) VALUES 
('Administration', 'Administrative tasks and coordination'),
('HR', 'Human Resources management'),
('Accounts', 'Financial and accounting operations');

-- Create management_team_members junction table
CREATE TABLE public.management_team_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.management_teams(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(team_id, agent_id)
);

-- Create priority and status enums for tasks
CREATE TYPE public.task_priority AS ENUM ('high', 'medium', 'normal');
CREATE TYPE public.task_status AS ENUM ('pending', 'completed', 'cancelled');

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority public.task_priority NOT NULL DEFAULT 'normal',
  status public.task_status NOT NULL DEFAULT 'pending',
  allocated_to_team UUID REFERENCES public.management_teams(id) ON DELETE SET NULL,
  allocated_to_agent UUID REFERENCES public.agents(id) ON DELETE SET NULL,
  created_by TEXT,
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create task remarks table for tracking task updates
CREATE TABLE public.task_remarks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  remark TEXT NOT NULL,
  updated_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create agent_ratings table to store star ratings for agents
CREATE TABLE public.agent_ratings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  rated_by TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(agent_id, rated_by)
);

-- Create panchayath_notes table for storing notes and comments about panchayaths
CREATE TABLE public.panchayath_notes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user authentication and roles tables
CREATE TABLE public.user_profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'local_admin', 'user_admin')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insert the default admin users with bcrypt-style hashes
INSERT INTO public.user_profiles (username, password_hash, role) VALUES 
  ('evaadmin', '$2b$10$placeholder_hash_for_eva919123', 'super_admin'),
  ('admin1', '$2b$10$placeholder_hash_for_elife9094', 'local_admin'),
  ('admin2', '$2b$10$placeholder_hash_for_penny9094', 'user_admin');

-- Create daily_activities table for tracking agent activities
CREATE TABLE public.daily_activities (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  activity_description TEXT NOT NULL,
  activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

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

-- Enable Row Level Security
ALTER TABLE public.user_registration_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leader_panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.management_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.management_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_remarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.panchayath_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_notifications ENABLE ROW LEVEL SECURITY;

-- Create policies for all tables (allowing all operations for now since no auth is implemented)
CREATE POLICY "Enable all access for user_registration_requests" ON public.user_registration_requests FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for panchayaths" ON public.panchayaths FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for agents" ON public.agents FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for team_leaders" ON public.team_leaders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for team_leader_panchayaths" ON public.team_leader_panchayaths FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for management_teams" ON public.management_teams FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for management_team_members" ON public.management_team_members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for tasks" ON public.tasks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for task_remarks" ON public.task_remarks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for agent_ratings" ON public.agent_ratings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for panchayath_notes" ON public.panchayath_notes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for user_profiles" ON public.user_profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for daily_activities" ON public.daily_activities FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for team_notifications" ON public.team_notifications FOR ALL USING (true) WITH CHECK (true);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_user_registration_requests_updated_at
  BEFORE UPDATE ON public.user_registration_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_panchayaths_updated_at
  BEFORE UPDATE ON public.panchayaths
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agents_updated_at
  BEFORE UPDATE ON public.agents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_management_teams_updated_at
  BEFORE UPDATE ON public.management_teams
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agent_ratings_updated_at
  BEFORE UPDATE ON public.agent_ratings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_panchayath_notes_updated_at
  BEFORE UPDATE ON public.panchayath_notes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_team_leaders_updated_at
  BEFORE UPDATE ON public.team_leaders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_daily_activities_updated_at
  BEFORE UPDATE ON public.daily_activities
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_team_notifications_updated_at
  BEFORE UPDATE ON public.team_notifications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_agents_panchayath_id ON public.agents(panchayath_id);
CREATE INDEX idx_agents_superior_id ON public.agents(superior_id);
CREATE INDEX idx_agents_role ON public.agents(role);
CREATE INDEX idx_team_leader_panchayaths_team_leader_id ON public.team_leader_panchayaths(team_leader_id);
CREATE INDEX idx_team_leader_panchayaths_panchayath_id ON public.team_leader_panchayaths(panchayath_id);
CREATE INDEX idx_management_team_members_team_id ON public.management_team_members(team_id);
CREATE INDEX idx_management_team_members_agent_id ON public.management_team_members(agent_id);
CREATE INDEX idx_tasks_allocated_to_team ON public.tasks(allocated_to_team);
CREATE INDEX idx_tasks_allocated_to_agent ON public.tasks(allocated_to_agent);
CREATE INDEX idx_task_remarks_task_id ON public.task_remarks(task_id);
CREATE INDEX idx_agent_ratings_agent_id ON public.agent_ratings(agent_id);
CREATE INDEX idx_agent_ratings_rated_by ON public.agent_ratings(rated_by);
CREATE INDEX idx_panchayath_notes_panchayath_id ON public.panchayath_notes(panchayath_id);
CREATE INDEX idx_panchayath_notes_created_at ON public.panchayath_notes(created_at DESC);
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX idx_daily_activities_agent_id ON public.daily_activities(agent_id);
CREATE INDEX idx_daily_activities_date ON public.daily_activities(activity_date);
CREATE INDEX idx_team_notifications_team_id ON public.team_notifications(team_id);
CREATE INDEX idx_team_notifications_agent_mobile ON public.team_notifications(agent_mobile);
CREATE INDEX idx_team_notifications_task_id ON public.team_notifications(task_id);