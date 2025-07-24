-- Create user registration requests table
CREATE TABLE public.user_registration_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT NOT NULL,
  mobile_number TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  approved_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create panchayaths table
CREATE TABLE public.panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  state TEXT NOT NULL,
  district TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create enum for agent roles
CREATE TYPE public.agent_role AS ENUM ('coordinator', 'supervisor', 'group-leader', 'pro');

-- Create agents table
CREATE TABLE public.agents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  role public.agent_role NOT NULL,
  ward TEXT,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id),
  superior_id UUID REFERENCES public.agents(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create management teams table
CREATE TABLE public.management_teams (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create management team members table
CREATE TABLE public.management_team_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.management_teams(id),
  agent_id UUID NOT NULL REFERENCES public.agents(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create enums for tasks
CREATE TYPE public.task_priority AS ENUM ('high', 'medium', 'normal');
CREATE TYPE public.task_status AS ENUM ('pending', 'completed', 'cancelled');

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority public.task_priority NOT NULL DEFAULT 'normal',
  status public.task_status NOT NULL DEFAULT 'pending',
  due_date DATE,
  allocated_to_agent UUID REFERENCES public.agents(id),
  allocated_to_team UUID REFERENCES public.management_teams(id),
  created_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create task remarks table
CREATE TABLE public.task_remarks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES public.tasks(id),
  remark TEXT NOT NULL,
  updated_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create agent ratings table
CREATE TABLE public.agent_ratings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  agent_id UUID NOT NULL REFERENCES public.agents(id),
  rating INTEGER NOT NULL,
  rated_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create panchayath notes table
CREATE TABLE public.panchayath_notes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id),
  note TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team leaders table
CREATE TABLE public.team_leaders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team leader panchayaths table
CREATE TABLE public.team_leader_panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_leader_id UUID NOT NULL REFERENCES public.team_leaders(id),
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user profiles table for authentication
CREATE TABLE public.user_profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.user_registration_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.management_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.management_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_remarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.panchayath_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leader_panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for all tables (allowing all operations for now)
CREATE POLICY "Enable all access for user_registration_requests" ON public.user_registration_requests FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for panchayaths" ON public.panchayaths FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for agents" ON public.agents FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for management_teams" ON public.management_teams FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for management_team_members" ON public.management_team_members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for tasks" ON public.tasks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for task_remarks" ON public.task_remarks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for agent_ratings" ON public.agent_ratings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for panchayath_notes" ON public.panchayath_notes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for team_leaders" ON public.team_leaders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for team_leader_panchayaths" ON public.team_leader_panchayaths FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for user_profiles" ON public.user_profiles FOR ALL USING (true) WITH CHECK (true);

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