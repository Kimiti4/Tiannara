'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { 
  Users, Plus, Search, Filter, MoreVertical, Shield, UserCheck, 
  UserX, Mail, Calendar, Edit2, Trash2, Eye, Lock, Unlock
} from 'lucide-react'

interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'member' | 'viewer'
  status: 'active' | 'inactive' | 'pending'
  lastActive: string
  joinedAt: string
  workflows: number
}

const mockUsers: User[] = [
  {
    id: '1',
    name: 'Amos Muiruri',
    email: 'amos@acmefinancial.com',
    role: 'admin',
    status: 'active',
    lastActive: '2 mins ago',
    joinedAt: 'Jan 15, 2026',
    workflows: 14,
  },
  {
    id: '2',
    name: 'Sarah Chen',
    email: 'sarah@acmefinancial.com',
    role: 'member',
    status: 'active',
    lastActive: '1 hour ago',
    joinedAt: 'Feb 3, 2026',
    workflows: 8,
  },
  {
    id: '3',
    name: 'James Wilson',
    email: 'james@acmefinancial.com',
    role: 'member',
    status: 'active',
    lastActive: '4 hours ago',
    joinedAt: 'Feb 10, 2026',
    workflows: 5,
  },
  {
    id: '4',
    name: 'Emily Rodriguez',
    email: 'emily@acmefinancial.com',
    role: 'viewer',
    status: 'active',
    lastActive: '1 day ago',
    joinedAt: 'Mar 1, 2026',
    workflows: 2,
  },
  {
    id: '5',
    name: 'Mike Thompson',
    email: 'mike@acmefinancial.com',
    role: 'member',
    status: 'inactive',
    lastActive: '2 weeks ago',
    joinedAt: 'Jan 20, 2026',
    workflows: 0,
  },
]

export default function UserManagement() {
  const router = useRouter()
  const [users, setUsers] = useState<User[]>(mockUsers)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedRole, setSelectedRole] = useState<string>('All')
  const [showInviteModal, setShowInviteModal] = useState(false)

  // Check authentication
  useEffect(() => {
    import('@/lib/fetch-auth').then(({ checkSession }) => {
      checkSession().then((ok) => {
        if (!ok) router.push('/login')
      })
    })
  }, [router])

  const filteredUsers = users.filter(user => {
    const matchesSearch = 
      user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.email.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesRole = selectedRole === 'All' || user.role === selectedRole
    return matchesSearch && matchesRole
  })

  const handleDeleteUser = (userId: string) => {
    if (confirm('Are you sure you want to remove this user?')) {
      setUsers(users.filter(u => u.id !== userId))
    }
  }

  const handleToggleStatus = (userId: string) => {
    setUsers(users.map(user => 
      user.id === userId 
        ? { ...user, status: user.status === 'active' ? 'inactive' : 'active' }
        : user
    ))
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 p-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <button
                onClick={() => router.push('/admin')}
                className="text-slate-400 hover:text-white transition-colors"
              >
                ← Back to Admin
              </button>
            </div>
            <h1 className="text-3xl font-bold text-white mb-2">User Management</h1>
            <p className="text-slate-400">Manage organization members and roles</p>
          </div>
          <button
            onClick={() => setShowInviteModal(true)}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg flex items-center gap-2 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Invite User
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <StatCard label="Total Users" value={users.length.toString()} icon={Users} />
          <StatCard label="Active" value={users.filter(u => u.status === 'active').length.toString()} icon={UserCheck} color="green" />
          <StatCard label="Admins" value={users.filter(u => u.role === 'admin').length.toString()} icon={Shield} color="purple" />
          <StatCard label="Pending" value={users.filter(u => u.status === 'pending').length.toString()} icon={Mail} color="yellow" />
        </div>

        {/* Filters */}
        <div className="flex gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
            <input
              type="text"
              placeholder="Search users..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-slate-900/50 border border-slate-800 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
            />
          </div>
          <select
            value={selectedRole}
            onChange={(e) => setSelectedRole(e.target.value)}
            className="px-4 py-2 bg-slate-900/50 border border-slate-800 rounded-lg text-white focus:outline-none focus:border-purple-500"
          >
            <option value="All">All Roles</option>
            <option value="admin">Admin</option>
            <option value="member">Member</option>
            <option value="viewer">Viewer</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full">
          <thead className="bg-slate-800/50 border-b border-slate-700">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-semibold text-slate-400">User</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-slate-400">Role</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-slate-400">Status</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-slate-400">Workflows</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-slate-400">Last Active</th>
              <th className="px-6 py-4 text-right text-sm font-semibold text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {filteredUsers.map(user => (
              <tr key={user.id} className="hover:bg-slate-800/30 transition-colors">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-full flex items-center justify-center text-white font-medium">
                      {user.name.split(' ').map(n => n[0]).join('')}
                    </div>
                    <div>
                      <p className="text-white font-medium">{user.name}</p>
                      <p className="text-sm text-slate-400">{user.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <RoleBadge role={user.role} />
                </td>
                <td className="px-6 py-4">
                  <StatusBadge status={user.status} />
                </td>
                <td className="px-6 py-4">
                  <span className="text-white">{user.workflows}</span>
                </td>
                <td className="px-6 py-4">
                  <span className="text-slate-400 text-sm">{user.lastActive}</span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center justify-end gap-2">
                    <button className="p-2 hover:bg-slate-700 rounded-lg transition-colors" title="View Details">
                      <Eye className="w-4 h-4 text-slate-400" />
                    </button>
                    <button className="p-2 hover:bg-slate-700 rounded-lg transition-colors" title="Edit User">
                      <Edit2 className="w-4 h-4 text-slate-400" />
                    </button>
                    <button 
                      onClick={() => handleToggleStatus(user.id)}
                      className="p-2 hover:bg-slate-700 rounded-lg transition-colors" 
                      title={user.status === 'active' ? 'Deactivate' : 'Activate'}
                    >
                      {user.status === 'active' ? (
                        <Lock className="w-4 h-4 text-slate-400" />
                      ) : (
                        <Unlock className="w-4 h-4 text-green-400" />
                      )}
                    </button>
                    <button 
                      onClick={() => handleDeleteUser(user.id)}
                      className="p-2 hover:bg-red-500/20 rounded-lg transition-colors" 
                      title="Remove User"
                    >
                      <Trash2 className="w-4 h-4 text-red-400" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredUsers.length === 0 && (
          <div className="text-center py-12">
            <Users className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <p className="text-slate-500">No users found</p>
          </div>
        )}
      </div>

      {/* Role Permissions Info */}
      <div className="mt-8 bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold text-white mb-4">Role Permissions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <RoleInfo
            role="Admin"
            permissions={[
              'Full access to all features',
              'Manage users and roles',
              'View system logs and metrics',
              'Configure organization settings',
              'Manage billing and subscriptions',
            ]}
            icon={Shield}
            color="purple"
          />
          <RoleInfo
            role="Member"
            permissions={[
              'Create and manage workflows',
              'View analytics and insights',
              'Run automations',
              'Access API keys',
              'Collaborate with team',
            ]}
            icon={UserCheck}
            color="cyan"
          />
          <RoleInfo
            role="Viewer"
            permissions={[
              'View dashboards and reports',
              'Read-only access to workflows',
              'View analytics',
              'Cannot modify settings',
              'Cannot create resources',
            ]}
            icon={Eye}
            color="green"
          />
        </div>
      </div>
    </div>
  )
}

function StatCard({ label, value, icon: Icon, color = 'purple' }: any) {
  const colors = {
    purple: 'from-purple-500/10 to-purple-600/10 border-purple-500/20',
    green: 'from-green-500/10 to-green-600/10 border-green-500/20',
    yellow: 'from-yellow-500/10 to-yellow-600/10 border-yellow-500/20',
  }

  return (
    <div className={`bg-gradient-to-br ${colors[color as keyof typeof colors]} border rounded-xl p-4`}>
      <div className="flex items-center justify-between mb-2">
        <Icon className="w-5 h-5 text-white opacity-80" />
      </div>
      <p className="text-2xl font-bold text-white">{value}</p>
      <p className="text-sm text-slate-400">{label}</p>
    </div>
  )
}

function RoleBadge({ role }: { role: string }) {
  const styles = {
    admin: 'bg-purple-500/20 text-purple-400 border-purple-500/30',
    member: 'bg-cyan-500/20 text-cyan-400 border-cyan-500/30',
    viewer: 'bg-green-500/20 text-green-400 border-green-500/30',
  }

  return (
    <span className={`px-3 py-1 rounded-full text-xs font-medium border ${styles[role as keyof typeof styles]}`}>
      {role.charAt(0).toUpperCase() + role.slice(1)}
    </span>
  )
}

function StatusBadge({ status }: { status: string }) {
  const styles = {
    active: 'bg-green-500/20 text-green-400',
    inactive: 'bg-slate-700 text-slate-400',
    pending: 'bg-yellow-500/20 text-yellow-400',
  }

  return (
    <span className={`px-3 py-1 rounded-full text-xs font-medium ${styles[status as keyof typeof styles]}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  )
}

function RoleInfo({ role, permissions, icon: Icon, color }: any) {
  const colors = {
    purple: 'from-purple-500 to-purple-600',
    cyan: 'from-cyan-500 to-cyan-600',
    green: 'from-green-500 to-green-600',
  }

  return (
    <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-5">
      <div className="flex items-center gap-3 mb-4">
        <div className={`w-10 h-10 bg-gradient-to-br ${colors[color as keyof typeof colors]} rounded-lg flex items-center justify-center`}>
          <Icon className="w-5 h-5 text-white" />
        </div>
        <h4 className="text-base font-semibold text-white">{role}</h4>
      </div>
      <ul className="space-y-2">
        {permissions.map((perm: string, idx: number) => (
          <li key={idx} className="flex items-start gap-2 text-sm text-slate-400">
            <span className="w-1.5 h-1.5 bg-slate-500 rounded-full mt-1.5 flex-shrink-0"></span>
            {perm}
          </li>
        ))}
      </ul>
    </div>
  )
}
