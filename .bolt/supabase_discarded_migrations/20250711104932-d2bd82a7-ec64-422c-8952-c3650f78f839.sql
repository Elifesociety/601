
-- Create user authentication and roles tables
CREATE TABLE public.user_profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'local_admin', 'user_admin')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for user_profiles (allow all for now since we're handling auth manually)
CREATE POLICY "Enable all access for user_profiles" 
  ON public.user_profiles 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Insert the default admin users with bcrypt-style hashes (these are placeholder hashes - you'd need proper bcrypt in production)
INSERT INTO public.user_profiles (username, password_hash, role) VALUES 
  ('evaadmin', '$2b$10$placeholder_hash_for_eva919123', 'super_admin'),
  ('admin1', '$2b$10$placeholder_hash_for_elife9094', 'local_admin'),
  ('admin2', '$2b$10$placeholder_hash_for_penny9094', 'user_admin');

-- Fix the management_teams table structure
-- Clear any existing malformed data
DELETE FROM public.management_teams WHERE name IN ('Administration', 'HR', 'Accounts');

-- Reset the management_teams table to have proper structure
ALTER TABLE public.management_teams 
ALTER COLUMN description TYPE TEXT,
ALTER COLUMN description SET DEFAULT NULL;

-- Insert clean default management teams
INSERT INTO public.management_teams (name, description) VALUES 
  ('Administration', 'Administrative tasks and coordination'),
  ('HR', 'Human Resources management'),
  ('Accounts', 'Financial and accounting operations');

-- Create the junction table for team members if it doesn't exist
CREATE TABLE IF NOT EXISTS public.management_team_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.management_teams(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(team_id, agent_id)
);

-- Enable RLS on management_team_members if not already enabled
ALTER TABLE public.management_team_members ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for management_team_members
CREATE POLICY "Enable all access for management_team_members" 
  ON public.management_team_members 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_management_team_members_team_id ON public.management_team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_management_team_members_agent_id ON public.management_team_members(agent_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);
