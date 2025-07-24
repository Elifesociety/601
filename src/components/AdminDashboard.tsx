import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { 
  Users, 
  Settings, 
  Shield, 
  Activity, 
  Database, 
  UserCheck,
  BarChart3,
  FileText,
  Clock,
  TrendingUp
} from "lucide-react";
import { typedSupabase, TABLES } from "@/lib/supabase-utils";
import { useToast } from "@/hooks/use-toast";

interface DashboardStats {
  totalUsers: number;
  totalPanchayaths: number;
  totalAgents: number;
  totalTasks: number;
  pendingRegistrations: number;
  activeTeams: number;
}

interface RecentActivity {
  id: string;
  action: string;
  table_name: string;
  created_at: string;
  user_id: string;
}

export const AdminDashboard = () => {
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    totalPanchayaths: 0,
    totalAgents: 0,
    totalTasks: 0,
    pendingRegistrations: 0,
    activeTeams: 0
  });
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);

      // Fetch all stats in parallel
      const [
        usersRes,
        panchayathsRes,
        agentsRes,
        tasksRes,
        registrationsRes,
        teamsRes,
        activityRes
      ] = await Promise.all([
        typedSupabase.from(TABLES.ADMIN_USERS).select('id', { count: 'exact' }),
        typedSupabase.from(TABLES.PANCHAYATHS).select('id', { count: 'exact' }),
        typedSupabase.from(TABLES.AGENTS).select('id', { count: 'exact' }),
        typedSupabase.from(TABLES.TASKS).select('id', { count: 'exact' }),
        typedSupabase.from(TABLES.USER_REGISTRATION_REQUESTS).select('id', { count: 'exact' }).eq('status', 'pending'),
        typedSupabase.from(TABLES.MANAGEMENT_TEAMS).select('id', { count: 'exact' }).eq('is_active', true),
        typedSupabase.from(TABLES.AUDIT_LOGS).select('*').order('created_at', { ascending: false }).limit(10)
      ]);

      setStats({
        totalUsers: usersRes.count || 0,
        totalPanchayaths: panchayathsRes.count || 0,
        totalAgents: agentsRes.count || 0,
        totalTasks: tasksRes.count || 0,
        pendingRegistrations: registrationsRes.count || 0,
        activeTeams: teamsRes.count || 0
      });

      setRecentActivity(activityRes.data || []);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      toast({
        title: "Error",
        description: "Failed to load dashboard data",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const StatCard = ({ title, value, icon: Icon, color, description }: {
    title: string;
    value: number;
    icon: React.ElementType;
    color: string;
    description: string;
  }) => (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className={`h-4 w-4 ${color}`} />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        <p className="text-xs text-muted-foreground">{description}</p>
      </CardContent>
    </Card>
  );

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[...Array(6)].map((_, i) => (
            <Card key={i}>
              <CardContent className="p-6">
                <div className="animate-pulse">
                  <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                  <div className="h-8 bg-gray-200 rounded w-1/2"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <StatCard
          title="Total Admin Users"
          value={stats.totalUsers}
          icon={Users}
          color="text-blue-600"
          description="Active admin accounts"
        />
        <StatCard
          title="Panchayaths"
          value={stats.totalPanchayaths}
          icon={Database}
          color="text-green-600"
          description="Registered panchayaths"
        />
        <StatCard
          title="Total Agents"
          value={stats.totalAgents}
          icon={UserCheck}
          color="text-purple-600"
          description="Active field agents"
        />
        <StatCard
          title="Total Tasks"
          value={stats.totalTasks}
          icon={FileText}
          color="text-orange-600"
          description="All tasks in system"
        />
        <StatCard
          title="Pending Registrations"
          value={stats.pendingRegistrations}
          icon={Clock}
          color="text-red-600"
          description="Awaiting approval"
        />
        <StatCard
          title="Active Teams"
          value={stats.activeTeams}
          icon={TrendingUp}
          color="text-teal-600"
          description="Management teams"
        />
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Recent System Activity
          </CardTitle>
          <CardDescription>
            Latest actions performed in the system
          </CardDescription>
        </CardHeader>
        <CardContent>
          {recentActivity.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              No recent activity found
            </div>
          ) : (
            <div className="space-y-3">
              {recentActivity.map((activity) => (
                <div key={activity.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    <div>
                      <p className="text-sm font-medium">
                        {activity.action} on {activity.table_name}
                      </p>
                      <p className="text-xs text-gray-500">
                        {new Date(activity.created_at).toLocaleString()}
                      </p>
                    </div>
                  </div>
                  <Badge variant="outline" className="text-xs">
                    {activity.action}
                  </Badge>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
          <CardDescription>
            Common administrative tasks
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Button variant="outline" className="h-20 flex flex-col gap-2">
              <Users className="h-6 w-6" />
              <span className="text-sm">Manage Users</span>
            </Button>
            <Button variant="outline" className="h-20 flex flex-col gap-2">
              <Shield className="h-6 w-6" />
              <span className="text-sm">Permissions</span>
            </Button>
            <Button variant="outline" className="h-20 flex flex-col gap-2">
              <Settings className="h-6 w-6" />
              <span className="text-sm">System Settings</span>
            </Button>
            <Button variant="outline" className="h-20 flex flex-col gap-2">
              <BarChart3 className="h-6 w-6" />
              <span className="text-sm">View Reports</span>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};