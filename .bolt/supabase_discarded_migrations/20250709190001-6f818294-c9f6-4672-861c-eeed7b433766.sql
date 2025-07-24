
-- Create enum for agent roles
CREATE TYPE public.agent_role AS ENUM ('coordinator', 'supervisor', 'group-leader', 'pro');

-- Create panchayaths table
CREATE TABLE public.panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  district TEXT NOT NULL,
  state TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create agents table
CREATE TABLE public.agents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  role agent_role NOT NULL,
  panchayath_id UUID REFERENCES public.panchayaths(id) ON DELETE CASCADE NOT NULL,
  superior_id UUID REFERENCES public.agents(id) ON DELETE SET NULL,
  email TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team leaders table
CREATE TABLE public.team_leaders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create junction table for team leader panchayath assignments
CREATE TABLE public.team_leader_panchayaths (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_leader_id UUID REFERENCES public.team_leaders(id) ON DELETE CASCADE NOT NULL,
  panchayath_id UUID REFERENCES public.panchayaths(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(team_leader_id, panchayath_id)
);

-- Enable Row Level Security
ALTER TABLE public.panchayaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leader_panchayaths ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for public access (since this is a public-facing management system)
CREATE POLICY "Enable read access for all users" ON public.panchayaths FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.panchayaths FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.panchayaths FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.panchayaths FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON public.agents FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.agents FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.agents FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.agents FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON public.team_leaders FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.team_leaders FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.team_leaders FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.team_leaders FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON public.team_leader_panchayaths FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.team_leader_panchayaths FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.team_leader_panchayaths FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.team_leader_panchayaths FOR DELETE USING (true);

-- Create indexes for better performance
CREATE INDEX idx_agents_panchayath_id ON public.agents(panchayath_id);
CREATE INDEX idx_agents_superior_id ON public.agents(superior_id);
CREATE INDEX idx_agents_role ON public.agents(role);
CREATE INDEX idx_team_leader_panchayaths_team_leader_id ON public.team_leader_panchayaths(team_leader_id);
CREATE INDEX idx_team_leader_panchayaths_panchayath_id ON public.team_leader_panchayaths(panchayath_id);

-- Insert sample data
INSERT INTO public.panchayaths (name, district, state) VALUES 
('Thiruvali Panchayath', 'Kollam', 'Kerala'),
('Sample Panchayath 2', 'Thiruvananthapuram', 'Kerala');

INSERT INTO public.team_leaders (name, email, phone) VALUES 
('Team Leader 1', 'teamlead1@example.com', '+91-9876543210');

-- Get the IDs for the sample data
DO $$
DECLARE
    thiruvali_id UUID;
    team_leader_id UUID;
    coordinator_id UUID;
    supervisor1_id UUID;
    supervisor2_id UUID;
BEGIN
    -- Get the Thiruvali panchayath ID
    SELECT id INTO thiruvali_id FROM public.panchayaths WHERE name = 'Thiruvali Panchayath';
    
    -- Get the team leader ID
    SELECT id INTO team_leader_id FROM public.team_leaders WHERE name = 'Team Leader 1';
    
    -- Assign team leader to panchayath
    INSERT INTO public.team_leader_panchayaths (team_leader_id, panchayath_id) 
    VALUES (team_leader_id, thiruvali_id);
    
    -- Insert coordinator
    INSERT INTO public.agents (name, role, panchayath_id, email, phone) 
    VALUES ('രാമകൃഷ്ണൻ സർ', 'coordinator', thiruvali_id, 'coordinator@example.com', '+91-9876543211')
    RETURNING id INTO coordinator_id;
    
    -- Insert supervisors
    INSERT INTO public.agents (name, role, panchayath_id, superior_id, email, phone) 
    VALUES ('ശ്യാമള', 'supervisor', thiruvali_id, coordinator_id, 'shyamala@example.com', '+91-9876543212')
    RETURNING id INTO supervisor1_id;
    
    INSERT INTO public.agents (name, role, panchayath_id, superior_id, email, phone) 
    VALUES ('രവി കൃഷ്ണൻ', 'supervisor', thiruvali_id, coordinator_id, 'ravi@example.com', '+91-9876543213')
    RETURNING id INTO supervisor2_id;
    
    -- Insert group leaders and PROs under first supervisor
    INSERT INTO public.agents (name, role, panchayath_id, superior_id, email, phone) 
    VALUES 
    ('Group Leader 1', 'group-leader', thiruvali_id, supervisor1_id, 'gl1@example.com', '+91-9876543214'),
    ('Group Leader 2', 'group-leader', thiruvali_id, supervisor1_id, 'gl2@example.com', '+91-9876543215');
    
    -- Insert group leaders under second supervisor  
    INSERT INTO public.agents (name, role, panchayath_id, superior_id, email, phone) 
    VALUES 
    ('Group Leader 3', 'group-leader', thiruvali_id, supervisor2_id, 'gl3@example.com', '+91-9876543216');
END $$;
