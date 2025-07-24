import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://gzbvyvzsuscexdhtioxe.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6YnZ5dnpzdXNjZXhkaHRpb3hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNjA5NDMsImV4cCI6MjA2ODgzNjk0M30.GSI4jvExn2nfzh1ZxoTYcGneunc3Ed-4gkvzXVq6W8Y";

// Create a typed supabase client to work around empty types file
export const typedSupabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});

// Common table names for type safety
export const TABLES = {
  AGENTS: 'agents',
  MANAGEMENT_TEAMS: 'management_teams',
  MANAGEMENT_TEAM_MEMBERS: 'management_team_members',
  PANCHAYATHS: 'panchayaths',
  TASKS: 'tasks',
  TASK_REMARKS: 'task_remarks',
  DAILY_ACTIVITIES: 'daily_activities',
  AGENT_RATINGS: 'agent_ratings',
  USER_PROFILES: 'user_profiles',
  USER_REGISTRATION_REQUESTS: 'user_registration_requests',
  PANCHAYATH_NOTES: 'panchayath_notes',
  TEAM_LEADERS: 'team_leaders',
  TEAM_LEADER_PANCHAYATHS: 'team_leader_panchayaths',
  ADMIN_USERS: 'admin_users',
  ADMIN_PERMISSIONS: 'admin_permissions',
  ADMIN_USER_PERMISSIONS: 'admin_user_permissions',
  SYSTEM_SETTINGS: 'system_settings',
  AUDIT_LOGS: 'audit_logs'
} as const;