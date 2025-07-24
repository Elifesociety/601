import React, { useState, useEffect } from 'react';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { Settings, Save, RefreshCw } from "lucide-react";
import { typedSupabase, TABLES } from "@/lib/supabase-utils";
import { useToast } from "@/hooks/use-toast";

interface SystemSetting {
  id: string;
  setting_key: string;
  setting_value: any;
  description: string;
  updated_by: string;
  updated_at: string;
}

export const SystemSettings = () => {
  const [settings, setSettings] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      setLoading(true);
      const { data, error } = await typedSupabase
        .from(TABLES.SYSTEM_SETTINGS)
        .select('*');

      if (error) throw error;

      const settingsMap = (data || []).reduce((acc, setting) => {
        acc[setting.setting_key] = setting.setting_value;
        return acc;
      }, {} as Record<string, any>);

      setSettings(settingsMap);
    } catch (error) {
      console.error('Error fetching settings:', error);
      toast({
        title: "Error",
        description: "Failed to fetch system settings",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const updateSetting = async (key: string, value: any) => {
    try {
      const { error } = await typedSupabase
        .from(TABLES.SYSTEM_SETTINGS)
        .upsert({
          setting_key: key,
          setting_value: value,
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'setting_key'
        });

      if (error) throw error;

      setSettings(prev => ({ ...prev, [key]: value }));
    } catch (error) {
      console.error('Error updating setting:', error);
      throw error;
    }
  };

  const handleSaveAll = async () => {
    setSaving(true);
    try {
      const updates = Object.entries(settings).map(([key, value]) => ({
        setting_key: key,
        setting_value: value,
        updated_at: new Date().toISOString()
      }));

      const { error } = await typedSupabase
        .from(TABLES.SYSTEM_SETTINGS)
        .upsert(updates, { onConflict: 'setting_key' });

      if (error) throw error;

      toast({
        title: "Success",
        description: "System settings saved successfully"
      });
    } catch (error) {
      console.error('Error saving settings:', error);
      toast({
        title: "Error",
        description: "Failed to save system settings",
        variant: "destructive"
      });
    } finally {
      setSaving(false);
    }
  };

  const handleInputChange = (key: string, value: any) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center">
            <RefreshCw className="h-6 w-6 animate-spin mx-auto mb-2" />
            <p>Loading system settings...</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold flex items-center gap-2">
            <Settings className="h-6 w-6" />
            System Settings
          </h2>
          <p className="text-muted-foreground">Configure system-wide settings and preferences</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchSettings}>
            <RefreshCw className="mr-2 h-4 w-4" />
            Refresh
          </Button>
          <Button onClick={handleSaveAll} disabled={saving}>
            <Save className="mr-2 h-4 w-4" />
            {saving ? 'Saving...' : 'Save All'}
          </Button>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* General Settings */}
        <Card>
          <CardHeader>
            <CardTitle>General Settings</CardTitle>
            <CardDescription>Basic system configuration</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label htmlFor="system_name">System Name</Label>
              <Input
                id="system_name"
                value={settings.system_name || ''}
                onChange={(e) => handleInputChange('system_name', e.target.value)}
                placeholder="Enter system name"
              />
            </div>
            
            <div>
              <Label htmlFor="max_login_attempts">Max Login Attempts</Label>
              <Input
                id="max_login_attempts"
                type="number"
                value={settings.max_login_attempts || 5}
                onChange={(e) => handleInputChange('max_login_attempts', parseInt(e.target.value))}
                min="1"
                max="10"
              />
            </div>
            
            <div>
              <Label htmlFor="session_timeout">Session Timeout (seconds)</Label>
              <Input
                id="session_timeout"
                type="number"
                value={settings.session_timeout || 3600}
                onChange={(e) => handleInputChange('session_timeout', parseInt(e.target.value))}
                min="300"
                max="86400"
              />
            </div>
          </CardContent>
        </Card>

        {/* Security Settings */}
        <Card>
          <CardHeader>
            <CardTitle>Security Settings</CardTitle>
            <CardDescription>Security and access control settings</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="enable_guest_registration">Enable Guest Registration</Label>
                <p className="text-sm text-muted-foreground">Allow new users to register</p>
              </div>
              <Switch
                id="enable_guest_registration"
                checked={settings.enable_guest_registration || false}
                onCheckedChange={(checked) => handleInputChange('enable_guest_registration', checked)}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="require_email_verification">Require Email Verification</Label>
                <p className="text-sm text-muted-foreground">Verify email addresses for new users</p>
              </div>
              <Switch
                id="require_email_verification"
                checked={settings.require_email_verification || false}
                onCheckedChange={(checked) => handleInputChange('require_email_verification', checked)}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="maintenance_mode">Maintenance Mode</Label>
                <p className="text-sm text-muted-foreground">Enable system maintenance mode</p>
              </div>
              <Switch
                id="maintenance_mode"
                checked={settings.maintenance_mode || false}
                onCheckedChange={(checked) => handleInputChange('maintenance_mode', checked)}
              />
            </div>
            
            <div>
              <Label htmlFor="default_user_role">Default User Role</Label>
              <Input
                id="default_user_role"
                value={settings.default_user_role || 'user'}
                onChange={(e) => handleInputChange('default_user_role', e.target.value)}
                placeholder="Enter default role"
              />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Advanced Settings */}
      <Card>
        <CardHeader>
          <CardTitle>Advanced Settings</CardTitle>
          <CardDescription>Advanced system configuration options</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="custom_settings">Custom Settings (JSON)</Label>
            <Textarea
              id="custom_settings"
              value={JSON.stringify(settings.custom_settings || {}, null, 2)}
              onChange={(e) => {
                try {
                  const parsed = JSON.parse(e.target.value);
                  handleInputChange('custom_settings', parsed);
                } catch (error) {
                  // Invalid JSON, don't update
                }
              }}
              placeholder="Enter custom settings as JSON"
              rows={6}
              className="font-mono text-sm"
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );
};