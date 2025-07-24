
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

-- Create management teams table
CREATE TABLE public.management_teams (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insert default management teams
INSERT INTO public.management_teams (name, description) VALUES 
('Administration', 'Administrative tasks and coordination'),
('HR', 'Human Resources management'),
('Accounts', 'Financial and accounting operations');

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

-- Enable Row Level Security
ALTER TABLE public.panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.management_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_remarks ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (since no auth is implemented)
CREATE POLICY "Enable all access for panchayaths" ON public.panchayaths FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for agents" ON public.agents FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for team_leaders" ON public.team_leaders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for management_teams" ON public.management_teams FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for tasks" ON public.tasks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for task_remarks" ON public.task_remarks FOR ALL USING (true) WITH CHECK (true);
