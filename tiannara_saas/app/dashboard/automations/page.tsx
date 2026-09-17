'use client'

import { useState, useEffect } from 'react'
import { Zap, Clock, Bell, Play, Pause, Loader2, Plus, X, Settings } from 'lucide-react'
import { apiClient } from '@/lib/api'

export default function AutomationsPage() {
  const [automations, setAutomations] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showCreateModal, setShowCreateModal] = useState(false)

  useEffect(() => {
    fetchAutomations()
  }, [])

  const fetchAutomations = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await apiClient.getAutomations()
      
      if (response.success && response.data) {
        setAutomations(response.data)
      }
    } catch (err) {
      console.error('Failed to fetch automations:', err)
      setError('Failed to load automations')
    } finally {
      setLoading(false)
    }
  }

  const toggleAutomation = async (id: string) => {
    try {
      const response = await apiClient.toggleAutomation(id)
      if (response.success && response.data) {
        // Update local state
        setAutomations(automations.map(a => 
          a.id === id ? { ...a, status: response.data.status } : a
        ))
      }
    } catch (err) {
      console.error('Failed to toggle automation:', err)
    }
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">Automations</h1>
          <p className="text-slate-400">Configure triggers, scheduled workflows, and alerts</p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="px-4 py-2 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-lg transition-all flex items-center gap-2 font-medium"
        >
          <Plus className="w-4 h-4" />
          Create Automation
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchAutomations}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : (
        <>
      {/* Active Automations */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {automations.length > 0 ? (
          automations.map((automation) => (
            <AutomationCard
              key={automation.id}
              name={automation.name}
              description={automation.description || `Trigger: ${automation.trigger_type}`}
              status={automation.status}
              trigger={automation.trigger_type.charAt(0).toUpperCase() + automation.trigger_type.slice(1)}
              lastTriggered={automation.last_triggered ? new Date(automation.last_triggered).toLocaleString() : 'Never'}
              icon={automation.trigger_type === 'scheduled' ? Clock : automation.trigger_type === 'event' ? Zap : Bell}
              onToggle={() => toggleAutomation(automation.id)}
            />
          ))
        ) : (
          <div className="col-span-2 text-center py-12">
            <p className="text-slate-400 mb-4">No automations configured yet.</p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-lg transition-all font-medium inline-flex items-center gap-2"
            >
              <Plus className="w-5 h-5" />
              Create Your First Automation
            </button>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Create New Automation</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <QuickAction
            title="Threshold Alert"
            description="Alert when metric exceeds threshold"
            icon={Bell}
            onClick={() => setShowCreateModal(true)}
          />
          <QuickAction
            title="Scheduled Task"
            description="Run workflow on schedule"
            icon={Clock}
            onClick={() => setShowCreateModal(true)}
          />
          <QuickAction
            title="Event Trigger"
            description="Respond to specific events"
            icon={Zap}
            onClick={() => setShowCreateModal(true)}
          />
        </div>
      </div>
        </>
      )}

      {/* Create Automation Modal */}
      {showCreateModal && (
        <CreateAutomationModal
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => {
            setShowCreateModal(false)
            fetchAutomations()
          }}
        />
      )}
    </div>
  )
}

function AutomationCard({ name, description, status, trigger, lastTriggered, icon: Icon, onToggle }: any) {
  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/40 transition-colors">
      <div className="flex items-start justify-between mb-4">
        <div className="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center">
          <Icon className="w-5 h-5 text-purple-400" />
        </div>
        <div className="flex items-center gap-2">
          <span className={`w-2 h-2 rounded-full ${status === 'active' ? 'bg-green-500' : 'bg-slate-500'}`}></span>
          <span className="text-sm text-slate-400">{status}</span>
        </div>
      </div>
      
      <div className="mb-4">
        <h3 className="text-base font-semibold text-white mb-1">{name}</h3>
        <p className="text-sm text-slate-400">{description}</p>
      </div>
      
      <div className="flex items-center justify-between pt-4 border-t border-slate-800">
        <div>
          <p className="text-xs text-slate-500 mb-1">Trigger: {trigger}</p>
          <p className="text-xs text-slate-500">Last triggered: {lastTriggered}</p>
        </div>
        <button
          onClick={onToggle}
          className={`px-3 py-1.5 rounded-lg text-sm transition-colors flex items-center gap-2 ${
            status === 'active'
              ? 'bg-slate-800 hover:bg-slate-700 text-slate-300'
              : 'bg-green-500/20 hover:bg-green-500/30 text-green-400'
          }`}
        >
          {status === 'active' ? (
            <>
              <Pause className="w-4 h-4" />
              Pause
            </>
          ) : (
            <>
              <Play className="w-4 h-4" />
              Activate
            </>
          )}
        </button>
      </div>
    </div>
  )
}

function QuickAction({ title, description, icon: Icon, onClick }: any) {
  return (
    <button 
      onClick={onClick}
      className="block p-4 bg-slate-800/50 hover:bg-slate-800 border border-slate-700 hover:border-purple-500/40 rounded-lg transition-all text-left group"
    >
      <div className="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center mb-3 group-hover:bg-purple-500/20 transition-colors">
        <Icon className="w-5 h-5 text-purple-400" />
      </div>
      <h3 className="text-sm font-semibold text-white mb-1">{title}</h3>
      <p className="text-xs text-slate-400">{description}</p>
    </button>
  )
}

function CreateAutomationModal({ onClose, onSuccess }: { onClose: () => void; onSuccess: () => void }) {
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [triggerType, setTriggerType] = useState<'scheduled' | 'event' | 'threshold'>('threshold')
  const [workflowId, setWorkflowId] = useState('')
  const [creating, setCreating] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!name || !workflowId) {
      setError('Name and workflow are required')
      return
    }

    try {
      setCreating(true)
      setError(null)
      
      // TODO: Implement create automation API call
      // For now, just close the modal
      setTimeout(() => {
        onSuccess()
      }, 500)
    } catch (err) {
      console.error('Failed to create automation:', err)
      setError('Failed to create automation')
    } finally {
      setCreating(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-slate-800">
          <h2 className="text-xl font-bold text-white">Create Automation</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-800 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-slate-400" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4 text-red-400 text-sm">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Automation Name *
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-white focus:border-purple-500 focus:outline-none"
              placeholder="e.g., Daily Report Generator"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Description
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-white focus:border-purple-500 focus:outline-none resize-none"
              rows={3}
              placeholder="Describe what this automation does..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Trigger Type *
            </label>
            <div className="grid grid-cols-3 gap-3">
              <button
                type="button"
                onClick={() => setTriggerType('threshold')}
                className={`p-4 border rounded-lg transition-all text-left ${
                  triggerType === 'threshold'
                    ? 'border-purple-500 bg-purple-500/10'
                    : 'border-slate-800 bg-slate-950 hover:border-slate-700'
                }`}
              >
                <Bell className="w-5 h-5 mb-2 text-purple-400" />
                <div className="text-sm font-medium text-white">Threshold</div>
                <div className="text-xs text-slate-400 mt-1">Alert on metric change</div>
              </button>
              <button
                type="button"
                onClick={() => setTriggerType('scheduled')}
                className={`p-4 border rounded-lg transition-all text-left ${
                  triggerType === 'scheduled'
                    ? 'border-purple-500 bg-purple-500/10'
                    : 'border-slate-800 bg-slate-950 hover:border-slate-700'
                }`}
              >
                <Clock className="w-5 h-5 mb-2 text-blue-400" />
                <div className="text-sm font-medium text-white">Scheduled</div>
                <div className="text-xs text-slate-400 mt-1">Run on schedule</div>
              </button>
              <button
                type="button"
                onClick={() => setTriggerType('event')}
                className={`p-4 border rounded-lg transition-all text-left ${
                  triggerType === 'event'
                    ? 'border-purple-500 bg-purple-500/10'
                    : 'border-slate-800 bg-slate-950 hover:border-slate-700'
                }`}
              >
                <Zap className="w-5 h-5 mb-2 text-green-400" />
                <div className="text-sm font-medium text-white">Event</div>
                <div className="text-xs text-slate-400 mt-1">Respond to events</div>
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Workflow *
            </label>
            <select
              value={workflowId}
              onChange={(e) => setWorkflowId(e.target.value)}
              className="w-full px-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-white focus:border-purple-500 focus:outline-none"
              required
            >
              <option value="">Select a workflow...</option>
              <option value="workflow_1">Customer Churn Analysis</option>
              <option value="workflow_2">Anomaly Detection</option>
              <option value="workflow_3">Daily Report Generation</option>
            </select>
          </div>

          <div className="flex gap-3 pt-4 border-t border-slate-800">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={creating}
              className="flex-1 px-4 py-2 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 disabled:opacity-50 text-white rounded-lg transition-all font-medium flex items-center justify-center gap-2"
            >
              {creating ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Creating...
                </>
              ) : (
                'Create Automation'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
