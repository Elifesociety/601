-- Create enum for agent roles
CREATE TYPE public.agent_role AS ENUM ('coordinator', 'supervisor', 'group-leader', 'pro');

-- Create enum for task priority
CREATE TYPE public.task_priority AS ENUM ('high', 'medium', 'normal');

-- Create enum for task status
CREATE TYPE public.task_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');

-- Create enum for registration status
CREATE TYPE public.registration_status AS ENUM ('pending', 'approved', 'rejected');

-- Create panchayaths table
CREATE TABLE public.panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  district TEXT NOT NULL,
  state TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team_leaders table
CREATE TABLE public.team_leaders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create agents table
CREATE TABLE public.agents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  role agent_role NOT NULL,
  panchayath_id UUID NOT NULL REFERENCES public.panchayaths(id) ON DELETE CASCADE,
  superior_id UUID REFERENCES public.agents(id),
  phone TEXT,
  ward TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority task_priority NOT NULL DEFAULT 'normal',
  due_date DATE,
  allocated_to_agent UUID REFERENCES public.agents(id),
  allocated_to_team UUID REFERENCES public.team_leaders(id),
  status task_status NOT NULL DEFAULT 'pending',
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user_registration_requests table
CREATE TABLE public.user_registration_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  mobile_number TEXT NOT NULL UNIQUE,
  status registration_status NOT NULL DEFAULT 'pending',
  approved_by UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security on all tables
ALTER TABLE public.panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_registration_requests ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (adjust as needed for your security requirements)
CREATE POLICY "Enable read access for all users" ON public.panchayaths FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.panchayaths FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.panchayaths FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON public.team_leaders FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.team_leaders FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.team_leaders FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON public.agents FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.agents FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.agents FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON public.tasks FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.tasks FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON public.user_registration_requests FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.user_registration_requests FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.user_registration_requests FOR UPDATE USING (true);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_panchayaths_updated_at
  BEFORE UPDATE ON public.panchayaths
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_team_leaders_updated_at
  BEFORE UPDATE ON public.team_leaders
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agents_updated_at
  BEFORE UPDATE ON public.agents
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_registration_requests_updated_at
  BEFORE UPDATE ON public.user_registration_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();