import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { CalendarIcon, BarChart3, Download, RefreshCw, TrendingUp, Users, MapPin } from "lucide-react";
import { format, subDays, startOfMonth, endOfMonth } from "date-fns";
import { typedSupabase, TABLES } from "@/lib/supabase-utils";
import { useToast } from "@/hooks/use-toast";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

interface ReportData {
  agentsByRole: Array<{ role: string; count: number }>;
  tasksByStatus: Array<{ status: string; count: number }>;
  panchayathsByState: Array<{ state: string; count: number }>;
  dailyActivity: Array<{ date: string; count: number }>;
  topPerformers: Array<{ name: string; rating: number; tasks: number }>;
}

export const SystemReports = () => {
  const [reportData, setReportData] = useState<ReportData>({
    agentsByRole: [],
    tasksByStatus: [],
    panchayathsByState: [],
    dailyActivity: [],
    topPerformers: []
  });
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({
    from: startOfMonth(new Date()),
    to: endOfMonth(new Date())
  });
  const { toast } = useToast();

  useEffect(() => {
    fetchReportData();
  }, [dateRange]);

  const fetchReportData = async () => {
    try {
      setLoading(true);

      // Fetch agents by role
      const { data: agentsData } = await typedSupabase
        .from(TABLES.AGENTS)
        .select('role');

      const agentsByRole = agentsData?.reduce((acc, agent) => {
        acc[agent.role] = (acc[agent.role] || 0) + 1;
        return acc;
      }, {} as Record<string, number>) || {};

      // Fetch tasks by status
      const { data: tasksData } = await typedSupabase
        .from(TABLES.TASKS)
        .select('status');

      const tasksByStatus = tasksData?.reduce((acc, task) => {
        acc[task.status] = (acc[task.status] || 0) + 1;
        return acc;
      }, {} as Record<string, number>) || {};

      // Fetch panchayaths by state
      const { data: panchayathsData } = await typedSupabase
        .from(TABLES.PANCHAYATHS)
        .select('state');

      const panchayathsByState = panchayathsData?.reduce((acc, panchayath) => {
        acc[panchayath.state] = (acc[panchayath.state] || 0) + 1;
        return acc;
      }, {} as Record<string, number>) || {};

      // Fetch daily activity (simplified - using task creation as activity)
      const { data: dailyData } = await typedSupabase
        .from(TABLES.TASKS)
        .select('created_at')
        .gte('created_at', dateRange.from.toISOString())
        .lte('created_at', dateRange.to.toISOString());

      const dailyActivity = dailyData?.reduce((acc, task) => {
        const date = format(new Date(task.created_at), 'yyyy-MM-dd');
        acc[date] = (acc[date] || 0) + 1;
        return acc;
      }, {} as Record<string, number>) || {};

      // Fetch top performers (agents with highest ratings)
      const { data: ratingsData } = await typedSupabase
        .from(TABLES.AGENT_RATINGS)
        .select(`
          agent_id,
          rating,
          agents (name)
        `);

      const topPerformers = ratingsData?.reduce((acc, rating) => {
        const agentName = rating.agents?.name || 'Unknown';
        if (!acc[rating.agent_id]) {
          acc[rating.agent_id] = {
            name: agentName,
            totalRating: 0,
            ratingCount: 0,
            tasks: 0
          };
        }
        acc[rating.agent_id].totalRating += rating.rating;
        acc[rating.agent_id].ratingCount += 1;
        return acc;
      }, {} as Record<string, any>) || {};

      setReportData({
        agentsByRole: Object.entries(agentsByRole).map(([role, count]) => ({ role, count })),
        tasksByStatus: Object.entries(tasksByStatus).map(([status, count]) => ({ status, count })),
        panchayathsByState: Object.entries(panchayathsByState).map(([state, count]) => ({ state, count })),
        dailyActivity: Object.entries(dailyActivity).map(([date, count]) => ({ date, count })),
        topPerformers: Object.values(topPerformers)
          .map((performer: any) => ({
            name: performer.name,
            rating: performer.totalRating / performer.ratingCount,
            tasks: performer.tasks
          }))
          .sort((a, b) => b.rating - a.rating)
          .slice(0, 10)
      });
    } catch (error) {
      console.error('Error fetching report data:', error);
      toast({
        title: "Error",
        description: "Failed to fetch report data",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold flex items-center gap-2">
            <BarChart3 className="h-6 w-6" />
            System Reports
          </h2>
          <p className="text-muted-foreground">Analytics and insights about system usage</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchReportData}>
            <RefreshCw className="mr-2 h-4 w-4" />
            Refresh
          </Button>
          <Button variant="outline" onClick={() => {}}>
            <Download className="mr-2 h-4 w-4" />
            Export Report
          </Button>
        </div>
      </div>

      {/* Date Range Selector */}
      <Card>
        <CardHeader>
          <CardTitle>Report Period</CardTitle>
          <CardDescription>Select date range for reports</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex gap-4 items-center">
            <div>
              <Label>From Date</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-full justify-start text-left font-normal">
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {format(dateRange.from, "PPP")}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar
                    mode="single"
                    selected={dateRange.from}
                    onSelect={(date) => date && setDateRange({ ...dateRange, from: date })}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
            
            <div>
              <Label>To Date</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-full justify-start text-left font-normal">
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {format(dateRange.to, "PPP")}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar
                    mode="single"
                    selected={dateRange.to}
                    onSelect={(date) => date && setDateRange({ ...dateRange, to: date })}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>

            <div className="flex gap-2">
              <Button 
                variant="outline" 
                onClick={() => setDateRange({ from: subDays(new Date(), 7), to: new Date() })}
              >
                Last 7 Days
              </Button>
              <Button 
                variant="outline" 
                onClick={() => setDateRange({ from: subDays(new Date(), 30), to: new Date() })}
              >
                Last 30 Days
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {loading ? (
        <div className="text-center py-8">
          <RefreshCw className="h-6 w-6 animate-spin mx-auto mb-2" />
          <p>Loading report data...</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2">
          {/* Agents by Role */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5" />
                Agents by Role
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={reportData.agentsByRole}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="role" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Tasks by Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5" />
                Tasks by Status
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={reportData.tasksByStatus}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="count"
                  >
                    {reportData.tasksByStatus.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Panchayaths by State */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5" />
                Panchayaths by State
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={reportData.panchayathsByState}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="state" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="#82ca9d" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Daily Activity */}
          <Card>
            <CardHeader>
              <CardTitle>Daily Activity</CardTitle>
              <CardDescription>Task creation activity over time</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={reportData.dailyActivity}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="#ffc658" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
};