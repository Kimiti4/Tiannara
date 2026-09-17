'use client'

import { useState, useEffect } from 'react'
import { Users, GitBranch, Activity, Plus, Loader2 } from 'lucide-react'
import { apiClient } from '@/lib/api'

export default function TeamPage() {
  const [members, setMembers] = useState<any[]>([])
  const [activity, setActivity] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchTeamData()
  }, [])

  const fetchTeamData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const [membersRes, activityRes] = await Promise.all([
        apiClient.getTeamMembers(),
        apiClient.getActivityFeed()
      ])
      
      if (membersRes.success && membersRes.data) {
        setMembers(membersRes.data)
      }
      
      if (activityRes.success && activityRes.data) {
        setActivity(activityRes.data)
      }
    } catch (err) {
      console.error('Failed to fetch team data:', err)
      setError('Failed to load team data')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Organization Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white mb-2">Organization: Acme Financial Systems</h1>
        <p className="text-slate-400">Manage teams, shared workflows, and collaboration</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchTeamData}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : (
        <>
      {/* Teams Section - Simplified to show members */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Team Members ({members.length})</h2>
          <button className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg flex items-center gap-2 transition-colors text-sm">
            <Plus className="w-4 h-4" />
            Invite Member
          </button>
        </div>
        
        {members.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {members.map((member) => (
              <MemberCard
                key={member.id}
                email={member.email}
                role={member.role}
                status={member.status}
                lastActive={member.last_active ? new Date(member.last_active).toLocaleString() : 'Never'}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-12 bg-slate-900/50 border border-slate-800 rounded-xl">
            <Users className="w-12 h-12 text-slate-600 mx-auto mb-4" />
            <p className="text-slate-400 mb-2">No team members yet.</p>
            <p className="text-sm text-slate-500">Invite your first team member to get started!</p>
          </div>
        )}
      </div>

      {/* Activity Feed */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Recent Activity</h2>
        {activity.length > 0 ? (
          <div className="space-y-4">
            {activity.map((item) => (
              <ActivityItem
                key={item.id}
                user={item.user}
                action={item.action.replace(/_/g, ' ')}
                target={item.description}
                time={new Date(item.timestamp).toLocaleString()}
                icon={item.action.includes('workflow') ? GitBranch : item.action.includes('member') ? Users : Activity}
              />
            ))}
          </div>
        ) : (
          <p className="text-slate-400 text-center py-8">No recent activity.</p>
        )}
      </div>
        </>
      )}
    </div>
  )
}

function MemberCard({ email, role, status, lastActive }: any) {
  const roleColors = {
    admin: 'bg-purple-500/20 text-purple-400',
    member: 'bg-blue-500/20 text-blue-400',
    viewer: 'bg-slate-500/20 text-slate-400',
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/40 transition-colors">
      <div className="flex items-start justify-between mb-4">
        <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
          <span className="text-white font-bold text-lg">{email.charAt(0).toUpperCase()}</span>
        </div>
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${roleColors[role as keyof typeof roleColors]}`}>
          {role}
        </span>
      </div>
      
      <div className="mb-3">
        <h3 className="text-base font-semibold text-white mb-1">{email}</h3>
        <p className="text-sm text-slate-400">Status: {status}</p>
      </div>
      
      <div className="pt-3 border-t border-slate-800">
        <p className="text-xs text-slate-500">Last active: {lastActive}</p>
      </div>
    </div>
  )
}

function ActivityItem({ user, action, target, time, icon: Icon }: any) {
  return (
    <div className="flex items-start gap-3 p-3 hover:bg-slate-800/50 rounded-lg transition-colors">
      <div className="w-8 h-8 bg-purple-500/10 rounded-lg flex items-center justify-center flex-shrink-0">
        <Icon className="w-4 h-4 text-purple-400" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-slate-300">
          <span className="font-medium text-white">{user}</span> {action} {target}
        </p>
        <p className="text-xs text-slate-500 mt-1">{time}</p>
      </div>
    </div>
  )
}
