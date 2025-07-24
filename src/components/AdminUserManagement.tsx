import React, { useState, useEffect } from 'react';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { UserPlus, Edit, Trash2, Shield, Eye, EyeOff } from "lucide-react";
import { typedSupabase, TABLES } from "@/lib/supabase-utils";
import { useToast } from "@/hooks/use-toast";

interface AdminUser {
  id: string;
  username: string;
  email: string;
  role: 'super_admin' | 'admin' | 'local_admin';
  is_active: boolean;
  last_login: string;
  created_at: string;
}

interface Permission {
  id: string;
  module: string;
  action: string;
  description: string;
}

interface UserPermission {
  id: string;
  user_id: string;
  permission_id: string;
  admin_permissions: Permission;
}

export const AdminUserManagement = () => {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [userPermissions, setUserPermissions] = useState<UserPermission[]>([]);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isPermissionDialogOpen, setIsPermissionDialogOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<AdminUser | null>(null);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    role: 'admin' as 'super_admin' | 'admin' | 'local_admin'
  });
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([]);
  const { toast } = useToast();

  useEffect(() => {
    fetchUsers();
    fetchPermissions();
    fetchUserPermissions();
  }, []);

  const fetchUsers = async () => {
    try {
      const { data, error } = await typedSupabase
        .from(TABLES.ADMIN_USERS)
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setUsers(data || []);
    } catch (error) {
      console.error('Error fetching users:', error);
      toast({
        title: "Error",
        description: "Failed to fetch admin users",
        variant: "destructive"
      });
    }
  };

  const fetchPermissions = async () => {
    try {
      const { data, error } = await typedSupabase
        .from(TABLES.ADMIN_PERMISSIONS)
        .select('*')
        .order('module', { ascending: true });

      if (error) throw error;
      setPermissions(data || []);
    } catch (error) {
      console.error('Error fetching permissions:', error);
    }
  };

  const fetchUserPermissions = async () => {
    try {
      const { data, error } = await typedSupabase
        .from(TABLES.ADMIN_USER_PERMISSIONS)
        .select(`
          *,
          admin_permissions (*)
        `);

      if (error) throw error;
      setUserPermissions(data || []);
    } catch (error) {
      console.error('Error fetching user permissions:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.username || !formData.email || (!editingUser && !formData.password)) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive"
      });
      return;
    }

    try {
      if (editingUser) {
        const updateData: any = {
          username: formData.username,
          email: formData.email,
          role: formData.role
        };

        if (formData.password) {
          // In production, hash the password properly
          updateData.password_hash = `$2b$10$${formData.password}`;
        }

        const { error } = await typedSupabase
          .from(TABLES.ADMIN_USERS)
          .update(updateData)
          .eq('id', editingUser.id);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "User updated successfully"
        });
      } else {
        const { error } = await typedSupabase
          .from(TABLES.ADMIN_USERS)
          .insert([{
            username: formData.username,
            email: formData.email,
            password_hash: `$2b$10$${formData.password}`, // Hash properly in production
            role: formData.role
          }]);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "User created successfully"
        });
      }

      resetForm();
      fetchUsers();
    } catch (error) {
      console.error('Error saving user:', error);
      toast({
        title: "Error",
        description: "Failed to save user",
        variant: "destructive"
      });
    }
  };

  const handleToggleStatus = async (userId: string, currentStatus: boolean) => {
    try {
      const { error } = await typedSupabase
        .from(TABLES.ADMIN_USERS)
        .update({ is_active: !currentStatus })
        .eq('id', userId);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: `User ${!currentStatus ? 'activated' : 'deactivated'} successfully`
      });
      
      fetchUsers();
    } catch (error) {
      console.error('Error updating user status:', error);
      toast({
        title: "Error",
        description: "Failed to update user status",
        variant: "destructive"
      });
    }
  };

  const handleDeleteUser = async (userId: string) => {
    if (!confirm('Are you sure you want to delete this user?')) return;

    try {
      const { error } = await typedSupabase
        .from(TABLES.ADMIN_USERS)
        .delete()
        .eq('id', userId);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: "User deleted successfully"
      });
      
      fetchUsers();
    } catch (error) {
      console.error('Error deleting user:', error);
      toast({
        title: "Error",
        description: "Failed to delete user",
        variant: "destructive"
      });
    }
  };

  const openPermissionDialog = async (user: AdminUser) => {
    setSelectedUser(user);
    
    // Fetch current user permissions
    const userPerms = userPermissions
      .filter(up => up.user_id === user.id)
      .map(up => up.permission_id);
    
    setSelectedPermissions(userPerms);
    setIsPermissionDialogOpen(true);
  };

  const saveUserPermissions = async () => {
    if (!selectedUser) return;

    try {
      // Delete existing permissions
      await typedSupabase
        .from(TABLES.ADMIN_USER_PERMISSIONS)
        .delete()
        .eq('user_id', selectedUser.id);

      // Insert new permissions
      if (selectedPermissions.length > 0) {
        const permissionInserts = selectedPermissions.map(permId => ({
          user_id: selectedUser.id,
          permission_id: permId
        }));

        const { error } = await typedSupabase
          .from(TABLES.ADMIN_USER_PERMISSIONS)
          .insert(permissionInserts);

        if (error) throw error;
      }

      toast({
        title: "Success",
        description: "Permissions updated successfully"
      });

      setIsPermissionDialogOpen(false);
      fetchUserPermissions();
    } catch (error) {
      console.error('Error saving permissions:', error);
      toast({
        title: "Error",
        description: "Failed to save permissions",
        variant: "destructive"
      });
    }
  };

  const resetForm = () => {
    setFormData({ username: '', email: '', password: '', role: 'admin' });
    setEditingUser(null);
    setIsDialogOpen(false);
  };

  const handleEdit = (user: AdminUser) => {
    setEditingUser(user);
    setFormData({
      username: user.username,
      email: user.email || '',
      password: '',
      role: user.role
    });
    setIsDialogOpen(true);
  };

  const getRoleBadge = (role: string) => {
    switch (role) {
      case 'super_admin':
        return <Badge variant="destructive">SUPER ADMIN</Badge>;
      case 'admin':
        return <Badge variant="default">ADMIN</Badge>;
      case 'local_admin':
        return <Badge variant="secondary">LOCAL ADMIN</Badge>;
      default:
        return <Badge variant="outline">{role}</Badge>;
    }
  };

  const groupedPermissions = permissions.reduce((acc, perm) => {
    if (!acc[perm.module]) {
      acc[perm.module] = [];
    }
    acc[perm.module].push(perm);
    return acc;
  }, {} as Record<string, Permission[]>);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">Admin User Management</h2>
          <p className="text-muted-foreground">Manage admin users and their permissions</p>
        </div>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => setEditingUser(null)}>
              <UserPlus className="mr-2 h-4 w-4" />
              Add Admin User
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {editingUser ? 'Edit Admin User' : 'Create Admin User'}
              </DialogTitle>
              <DialogDescription>
                {editingUser ? 'Update admin user details' : 'Add a new admin user to the system'}
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Label htmlFor="username">Username *</Label>
                <Input
                  id="username"
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  placeholder="Enter username"
                  required
                />
              </div>
              
              <div>
                <Label htmlFor="email">Email *</Label>
                <Input
                  id="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  placeholder="Enter email address"
                  required
                />
              </div>
              
              <div>
                <Label htmlFor="password">
                  {editingUser ? 'New Password (leave empty to keep current)' : 'Password *'}
                </Label>
                <Input
                  id="password"
                  type="password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  placeholder="Enter password"
                  required={!editingUser}
                />
              </div>

              <div>
                <Label htmlFor="role">Role *</Label>
                <Select value={formData.role} onValueChange={(value) => setFormData({ ...formData, role: value as any })}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select role" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">Admin</SelectItem>
                    <SelectItem value="local_admin">Local Admin</SelectItem>
                    <SelectItem value="super_admin">Super Admin</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <DialogFooter>
                <Button type="button" variant="outline" onClick={resetForm}>
                  Cancel
                </Button>
                <Button type="submit">
                  {editingUser ? 'Update User' : 'Create User'}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Admin Users</CardTitle>
          <CardDescription>
            Manage system administrators and their access levels
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Username</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Last Login</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">{user.username}</TableCell>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>{getRoleBadge(user.role)}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={user.is_active}
                        onCheckedChange={() => handleToggleStatus(user.id, user.is_active)}
                      />
                      <span className="text-sm">
                        {user.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    {user.last_login 
                      ? new Date(user.last_login).toLocaleDateString()
                      : 'Never'
                    }
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEdit(user)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => openPermissionDialog(user)}
                      >
                        <Shield className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-red-600 hover:text-red-700"
                        onClick={() => handleDeleteUser(user.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Permissions Dialog */}
      <Dialog open={isPermissionDialogOpen} onOpenChange={setIsPermissionDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Manage Permissions - {selectedUser?.username}</DialogTitle>
            <DialogDescription>
              Select permissions for this admin user
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            {Object.entries(groupedPermissions).map(([module, modulePermissions]) => (
              <Card key={module}>
                <CardHeader className="pb-3">
                  <CardTitle className="text-lg capitalize">{module}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 gap-3">
                    {modulePermissions.map((permission) => (
                      <div key={permission.id} className="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          id={permission.id}
                          checked={selectedPermissions.includes(permission.id)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setSelectedPermissions([...selectedPermissions, permission.id]);
                            } else {
                              setSelectedPermissions(selectedPermissions.filter(id => id !== permission.id));
                            }
                          }}
                          className="rounded border-gray-300"
                        />
                        <Label htmlFor={permission.id} className="text-sm">
                          {permission.action}
                        </Label>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsPermissionDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={saveUserPermissions}>
              Save Permissions
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};