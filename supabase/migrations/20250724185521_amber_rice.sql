/*
  # Complete Admin System Setup

  1. New Tables
    - `admin_users` - Store admin user credentials and roles
    - `admin_permissions` - Define available permissions
    - `admin_user_permissions` - Link users to specific permissions
    - `system_settings` - Store system configuration
    - `audit_logs` - Track admin actions

  2. Security
    - Enable RLS on all new tables
    - Add policies for admin access control
    - Create secure password handling

  3. Data
    - Insert default admin users
    - Insert default permissions
    - Insert default system settings
*/

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text UNIQUE NOT NULL,
  email text UNIQUE,
  password_hash text NOT NULL,
  role text NOT NULL DEFAULT 'admin' CHECK (role IN ('super_admin', 'admin', 'local_admin')),
  is_active boolean DEFAULT true,
  last_login timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create admin_permissions table
CREATE TABLE IF NOT EXISTS admin_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module text NOT NULL,
  action text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(module, action)
);

-- Create admin_user_permissions table
CREATE TABLE IF NOT EXISTS admin_user_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES admin_permissions(id) ON DELETE CASCADE,
  granted_by uuid REFERENCES admin_users(id),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, permission_id)
);

-- Create system_settings table
CREATE TABLE IF NOT EXISTS system_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key text UNIQUE NOT NULL,
  setting_value jsonb,
  description text,
  updated_by uuid REFERENCES admin_users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES admin_users(id),
  action text NOT NULL,
  table_name text,
  record_id text,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admin_users
CREATE POLICY "Super admins can manage all users"
  ON admin_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au 
      WHERE au.id = auth.uid()::text::uuid 
      AND au.role = 'super_admin' 
      AND au.is_active = true
    )
  );

CREATE POLICY "Admins can view users"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au 
      WHERE au.id = auth.uid()::text::uuid 
      AND au.is_active = true
    )
  );

-- RLS Policies for admin_permissions
CREATE POLICY "Authenticated admins can view permissions"
  ON admin_permissions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au 
      WHERE au.id = auth.uid()::text::uuid 
      AND au.is_active = true
    )
  );

-- RLS Policies for admin_user_permissions
CREATE POLICY "Super admins can manage user permissions"
  ON admin_user_permissions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au 
      WHERE au.id = auth.uid()::text::uuid 
      AND au.role = 'super_admin' 
      AND au.is_active = true
    )
  );

-- RLS Policies for system_settings
CREATE POLICY "Admins can manage system settings"
  ON system_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au 
      WHERE au.id = auth.uid()::text::uuid 
      AND au.is_active = true
    )
  );

-- RLS Policies for audit_logs
CREATE POLICY "Admins can view audit logs"
  ON audit_logs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au 
      WHERE au.id = auth.uid()::text::uuid 
      AND au.is_active = true
    )
  );

-- Insert default admin users (passwords should be hashed in production)
INSERT INTO admin_users (username, email, password_hash, role) VALUES
  ('superadmin', 'super@admin.com', '$2b$10$example_hash_for_password123', 'super_admin'),
  ('admin1', 'admin1@system.com', '$2b$10$example_hash_for_admin123', 'admin'),
  ('localadmin', 'local@admin.com', '$2b$10$example_hash_for_local123', 'local_admin')
ON CONFLICT (username) DO NOTHING;

-- Insert default permissions
INSERT INTO admin_permissions (module, action, description) VALUES
  ('users', 'create', 'Create new users'),
  ('users', 'read', 'View user information'),
  ('users', 'update', 'Update user information'),
  ('users', 'delete', 'Delete users'),
  ('panchayaths', 'create', 'Create new panchayaths'),
  ('panchayaths', 'read', 'View panchayath information'),
  ('panchayaths', 'update', 'Update panchayath information'),
  ('panchayaths', 'delete', 'Delete panchayaths'),
  ('agents', 'create', 'Create new agents'),
  ('agents', 'read', 'View agent information'),
  ('agents', 'update', 'Update agent information'),
  ('agents', 'delete', 'Delete agents'),
  ('tasks', 'create', 'Create new tasks'),
  ('tasks', 'read', 'View task information'),
  ('tasks', 'update', 'Update task information'),
  ('tasks', 'delete', 'Delete tasks'),
  ('teams', 'create', 'Create management teams'),
  ('teams', 'read', 'View team information'),
  ('teams', 'update', 'Update team information'),
  ('teams', 'delete', 'Delete teams'),
  ('reports', 'read', 'View system reports'),
  ('settings', 'read', 'View system settings'),
  ('settings', 'update', 'Update system settings'),
  ('audit', 'read', 'View audit logs')
ON CONFLICT (module, action) DO NOTHING;

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
  ('system_name', '"Panchayath Management System"', 'Name of the system'),
  ('max_login_attempts', '5', 'Maximum login attempts before lockout'),
  ('session_timeout', '3600', 'Session timeout in seconds'),
  ('enable_guest_registration', 'true', 'Allow guest user registration'),
  ('require_email_verification', 'false', 'Require email verification for new users'),
  ('default_user_role', '"user"', 'Default role for new users'),
  ('maintenance_mode', 'false', 'Enable maintenance mode')
ON CONFLICT (setting_key) DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_admin_users_updated_at 
  BEFORE UPDATE ON admin_users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at 
  BEFORE UPDATE ON system_settings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to log admin actions
CREATE OR REPLACE FUNCTION log_admin_action()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values)
  VALUES (
    auth.uid()::text::uuid,
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id::text, OLD.id::text),
    CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN to_jsonb(NEW) ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Add audit triggers to important tables
CREATE TRIGGER audit_admin_users 
  AFTER INSERT OR UPDATE OR DELETE ON admin_users 
  FOR EACH ROW EXECUTE FUNCTION log_admin_action();

CREATE TRIGGER audit_panchayaths 
  AFTER INSERT OR UPDATE OR DELETE ON panchayaths 
  FOR EACH ROW EXECUTE FUNCTION log_admin_action();

CREATE TRIGGER audit_agents 
  AFTER INSERT OR UPDATE OR DELETE ON agents 
  FOR EACH ROW EXECUTE FUNCTION log_admin_action();

CREATE TRIGGER audit_management_teams 
  AFTER INSERT OR UPDATE OR DELETE ON management_teams 
  FOR EACH ROW EXECUTE FUNCTION log_admin_action();