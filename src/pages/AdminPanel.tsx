import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ArrowLeft, Settings, Users, LogOut, MapPin, UserCheck, Shield, Activity, BarChart3, Database } from "lucide-react";
import { Link } from "react-router-dom";
import { TeamManagementNew } from "@/components/TeamManagementNew";
import { AddPanchayathForm } from "@/components/AddPanchayathForm";
import { useAuth } from "@/components/AuthProvider";
import LoginForm from "@/components/LoginForm";
import { AdminApprovalPanel } from "@/components/AdminApprovalPanel";
import { TeamPasswordManager } from "@/components/TeamPasswordManager";
import { AdminDashboard } from "@/components/AdminDashboard";
import { AdminUserManagement } from "@/components/AdminUserManagement";
import { SystemSettings } from "@/components/SystemSettings";
import { AuditLogs } from "@/components/AuditLogs";
import { SystemReports } from "@/components/SystemReports";

const AdminPanelContent = () => {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');

  if (!user) {
    return <LoginForm />;
  }

  const isSuperAdmin = 'role' in user && user.role === 'super_admin';
  const isAdmin = 'role' in user && ['admin', 'super_admin'].includes(user.role);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <div className="flex justify-between items-start mb-4">
            <Link to="/">
              <Button variant="ghost">
                <ArrowLeft className="mr-2 h-4 w-4" />
                Back to Home
              </Button>
            </Link>
            <div className="flex items-center gap-4">
              <div className="text-right">
                <p className="text-sm text-gray-600">Welcome back,</p>
                <p className="font-medium">
                  {'username' in user ? `${user.username} (${user.role.replace('_', ' ')})` : `${user.teamName} Team`}
                </p>
              </div>
              <Button variant="outline" onClick={logout}>
                <LogOut className="mr-2 h-4 w-4" />
                Logout
              </Button>
            </div>
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-2 flex items-center gap-3">
            <Settings className="h-8 w-8 text-blue-600" />
            Admin Panel
          </h1>
          <p className="text-gray-600">Comprehensive system administration and management</p>
        </div>

        <Card>
          <CardContent className="p-6">
            <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
              <TabsList className="grid w-full grid-cols-8">
                <TabsTrigger value="dashboard" className="flex items-center gap-2">
                  <Database className="h-4 w-4" />
                  Dashboard
                </TabsTrigger>
                <TabsTrigger value="users" className="flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  Admin Users
                </TabsTrigger>
                <TabsTrigger value="teams" className="flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  Teams
                </TabsTrigger>
                <TabsTrigger value="panchayaths" className="flex items-center gap-2">
                  <MapPin className="h-4 w-4" />
                  Panchayaths
                </TabsTrigger>
                <TabsTrigger value="approvals" className="flex items-center gap-2">
                  <UserCheck className="h-4 w-4" />
                  Approvals
                </TabsTrigger>
                <TabsTrigger value="settings" className="flex items-center gap-2">
                  <Settings className="h-4 w-4" />
                  Settings
                </TabsTrigger>
                <TabsTrigger value="audit" className="flex items-center gap-2">
                  <Activity className="h-4 w-4" />
                  Audit Logs
                </TabsTrigger>
                <TabsTrigger value="reports" className="flex items-center gap-2">
                  <BarChart3 className="h-4 w-4" />
                  Reports
                </TabsTrigger>
              </TabsList>
              
              <TabsContent value="dashboard" className="mt-6">
                <AdminDashboard />
              </TabsContent>
              
              {isSuperAdmin && (
                <TabsContent value="users" className="mt-6">
                  <AdminUserManagement />
                </TabsContent>
              )}
              
              <TabsContent value="teams" className="mt-6">
                <div className="space-y-6">
                  <TeamManagementNew />
                  <TeamPasswordManager />
                </div>
              </TabsContent>
              
              <TabsContent value="panchayaths" className="mt-6">
                <Card>
                  <CardContent className="p-6">
                    <AddPanchayathForm />
                  </CardContent>
                </Card>
              </TabsContent>
              
              <TabsContent value="approvals" className="mt-6">
                <AdminApprovalPanel />
              </TabsContent>
              
              <TabsContent value="settings" className="mt-6">
                <SystemSettings />
              </TabsContent>
              
              {isAdmin && (
                <TabsContent value="audit" className="mt-6">
                  <AuditLogs />
                </TabsContent>
              )}
              
              <TabsContent value="reports" className="mt-6">
                <SystemReports />
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

const AdminPanel = () => {
  return <AdminPanelContent />;
};

export default AdminPanel;