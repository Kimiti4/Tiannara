'use client'

import { useState, useEffect } from 'react'
import { Plus, Search, Filter, Play, Pause, MoreVertical, Zap, Shield, BarChart3, Users, Activity, Loader2 } from 'lucide-react'
import { apiClient } from '@/lib/api'

export default function WorkflowsListPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [workflows, setWorkflows] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchWorkflows()
  }, [])

  const fetchWorkflows = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await apiClient.getWorkflows()
      
      if (response.success && response.data) {
        setWorkflows(response.data)
      }
    } catch (err) {
      console.error('Failed to fetch workflows:', err)
      setError('Failed to load workflows')
    } finally {
      setLoading(false)
    }
  }

  const filteredWorkflows = workflows.filter(w =>
    w.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    w.description.toLowerCase().includes(searchQuery.toLowerCase())
  )

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">Workflows</h1>
          <p className="text-slate-400">Manage and monitor your AI workflows</p>
        </div>
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg flex items-center gap-2 transition-colors">
            <Filter className="w-4 h-4" />
            Filter
          </button>
          <button className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg flex items-center gap-2 transition-colors">
            <Plus className="w-4 h-4" />
            New Workflow
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
          <input
            type="text"
            placeholder="Search workflows..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-slate-900/50 border border-slate-800 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 transition-colors"
          />
        </div>
      </div>

      {/* Workflows List */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchWorkflows}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredWorkflows.map(workflow => (
            <WorkflowCard key={workflow.id} workflow={workflow} />
          ))}
        </div>
      )}

      {/* Empty State */}
      {filteredWorkflows.length === 0 && (
        <div className="text-center py-12">
          <p className="text-slate-500">No workflows found</p>
        </div>
      )}

      {/* Quick Actions */}
      <div className="mt-8 bg-gradient-to-br from-purple-500/10 to-blue-500/10 border border-purple-500/20 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-2">Start with a Template</h2>
        <p className="text-sm text-slate-400 mb-4">Choose from pre-built workflows to get started quickly</p>
        <a
          href="/dashboard/workflows/templates"
          className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors font-medium"
        >
          Browse Templates
        </a>
      </div>
    </div>
  )
}

function WorkflowCard({ workflow }: { workflow: any }) {
  const statusColors = {
    Running: 'bg-green-500',
    Monitoring: 'bg-blue-500',
    Scheduled: 'bg-yellow-500',
    Paused: 'bg-slate-500',
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/40 transition-colors group">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 bg-purple-500/10 rounded-xl flex items-center justify-center">
            <Activity className="w-6 h-6 text-purple-400" />
          </div>
          <div>
            <h3 className="text-base font-semibold text-white mb-1">{workflow.name}</h3>
            <p className="text-sm text-slate-400">{workflow.description || `${workflow.nodes?.length || 0} nodes configured`}</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className={`w-2 h-2 rounded-full ${statusColors[workflow.status as keyof typeof statusColors]}`}></span>
          <span className="text-sm text-slate-400">{workflow.status}</span>
          <button className="p-2 hover:bg-slate-800 rounded-lg transition-colors opacity-0 group-hover:opacity-100">
            <MoreVertical className="w-4 h-4 text-slate-400" />
          </button>
        </div>
      </div>
      
      <div className="flex items-center justify-between pt-4 border-t border-slate-800">
        <div className="flex items-center gap-6 text-sm">
          <div>
            <span className="text-slate-500">Last run:</span>
            <span className="ml-2 text-slate-300">{workflow.last_run ? new Date(workflow.last_run).toLocaleString() : 'Never'}</span>
          </div>
          <div>
            <span className="text-slate-500">Runs:</span>
            <span className="ml-2 text-green-400 font-medium">{workflow.run_count || 0}</span>
          </div>
          <div>
            <span className="px-2 py-1 bg-slate-800 text-slate-400 rounded-full text-xs">{workflow.category || 'Workflow'}</span>
          </div>
        </div>
        
        <div className="flex gap-2">
          {workflow.status === 'Paused' ? (
            <button className="px-3 py-1.5 bg-green-500/20 hover:bg-green-500/30 text-green-400 rounded-lg text-sm transition-colors flex items-center gap-2">
              <Play className="w-4 h-4" />
              Resume
            </button>
          ) : (
            <button className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-sm transition-colors flex items-center gap-2">
              <Pause className="w-4 h-4" />
              Pause
            </button>
          )}
          <button className="px-3 py-1.5 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm transition-colors">
            View Details
          </button>
        </div>
      </div>
    </div>
  )
}
