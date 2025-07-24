
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

-- Enable Row Level Security
ALTER TABLE public.agent_ratings ENABLE ROW LEVEL SECURITY;

-- Create policies for agent_ratings
CREATE POLICY "Enable all access for agent_ratings" 
  ON public.agent_ratings 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Create index for better performance
CREATE INDEX idx_agent_ratings_agent_id ON public.agent_ratings(agent_id);
CREATE INDEX idx_agent_ratings_rated_by ON public.agent_ratings(rated_by);
