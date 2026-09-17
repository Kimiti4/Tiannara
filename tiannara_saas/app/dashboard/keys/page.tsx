'use client'

import { useState, useEffect } from 'react'
import { Key, Copy, Trash2, Plus, Eye, EyeOff, CheckCircle, Loader2, AlertCircle } from 'lucide-react'
import { apiClient } from '@/lib/api'

interface ApiKey {
  id: string
  name: string
  key?: string  // Only present when newly created
  key_masked?: string  // Masked version for display
  workspace_id: string
  created_by: string
  createdAt: string
  lastUsed: string | null
  requests: number
  status: 'active' | 'revoked'
}

export default function ApiKeysPage() {
  const [keys, setKeys] = useState<ApiKey[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showNewKeyModal, setShowNewKeyModal] = useState(false)
  const [newKeyName, setNewKeyName] = useState('')
  const [visibleKeys, setVisibleKeys] = useState<Set<string>>(new Set())
  const [copiedId, setCopiedId] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)
  const [newlyCreatedKey, setNewlyCreatedKey] = useState<string | null>(null)

  // Get workspace ID from context or default
  const workspaceId = 'ws_default' // TODO: Get from workspace context

  useEffect(() => {
    fetchKeys()
  }, [])

  const fetchKeys = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await apiClient.listApiKeys(workspaceId)
      
      if (response.success && response.data) {
        setKeys(response.data.map((key: any) => ({
          id: key.id,
          name: key.name,
          key_masked: key.key_masked,
          workspace_id: key.workspace_id,
          created_by: key.created_by,
          createdAt: new Date(key.created_at).toLocaleDateString(),
          lastUsed: key.last_used ? new Date(key.last_used).toLocaleDateString() : 'Never',
          requests: key.request_count,
          status: key.status
        })))
      }
    } catch (err) {
      console.error('Failed to fetch API keys:', err)
      setError('Failed to load API keys')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateKey = async () => {
    if (!newKeyName.trim()) return
    
    try {
      setCreating(true)
      setError(null)
      
      const response = await apiClient.createApiKey(newKeyName, workspaceId)
      
      if (response.success && response.data) {
        // Store the newly created key for one-time display
        setNewlyCreatedKey(response.data.key)
        
        // Refresh the key list
        await fetchKeys()
        
        setNewKeyName('')
        setShowNewKeyModal(false)
      } else {
        setError(response.message || 'Failed to create API key')
      }
    } catch (err: any) {
      console.error('Failed to create API key:', err)
      setError(err.message || 'Failed to create API key')
    } finally {
      setCreating(false)
    }
  }

  const handleRevokeKey = async (id: string) => {
    if (!confirm('Are you sure you want to revoke this API key? This action cannot be undone.')) {
      return
    }
    
    try {
      setError(null)
      
      const response = await apiClient.revokeApiKey(id, workspaceId)
      
      if (response.success) {
        // Update local state
        setKeys(keys.map(key => 
          key.id === id ? { ...key, status: 'revoked' as const } : key
        ))
      } else {
        setError(response.message || 'Failed to revoke API key')
      }
    } catch (err: any) {
      console.error('Failed to revoke API key:', err)
      setError(err.message || 'Failed to revoke API key')
    }
  }

  const toggleKeyVisibility = (id: string) => {
    const newVisible = new Set(visibleKeys)
    if (newVisible.has(id)) {
      newVisible.delete(id)
    } else {
      newVisible.add(id)
    }
    setVisibleKeys(newVisible)
  }

  const copyToClipboard = (key: string, id: string) => {
    navigator.clipboard.writeText(key)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 2000)
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">API Keys</h1>
          <p className="text-slate-400">Manage workspace API keys and access credentials</p>
        </div>
        <button
          onClick={() => setShowNewKeyModal(true)}
          className="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-xl font-semibold transition-colors flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Create New Key
        </button>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 mb-6 flex items-center gap-3">
          <AlertCircle className="w-5 h-5 text-red-400" />
          <p className="text-red-400 text-sm">{error}</p>
          <button onClick={() => setError(null)} className="ml-auto text-red-400 hover:text-red-300">✕</button>
        </div>
      )}

      {/* Info Banner */}
      <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-4 mb-6">
        <div className="flex items-start gap-3">
          <Key className="w-5 h-5 text-blue-400 mt-0.5" />
          <div>
            <h3 className="text-blue-400 font-semibold mb-1">Workspace API Keys</h3>
            <p className="text-sm text-slate-400">
              API keys are scoped to your workspace. Only workspace OWNERS and ADMINS can create or revoke keys.
              Keys are returned only once at creation - store them securely.
            </p>
          </div>
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
          <span className="ml-3 text-slate-400">Loading API keys...</span>
        </div>
      )}

      {/* API Keys List */}
      {!loading && (
        <div className="space-y-4">
          {keys.map((apiKey) => (
            <div
              key={apiKey.id}
              className={`bg-slate-900/50 border ${apiKey.status === 'revoked' ? 'border-red-500/30' : 'border-slate-800'} rounded-xl p-6`}
            >
              <div className="flex items-start justify-between mb-4">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="text-lg font-semibold text-white">{apiKey.name}</h3>
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      apiKey.status === 'active' 
                        ? 'bg-green-500/20 text-green-400' 
                        : 'bg-red-500/20 text-red-400'
                    }`}>
                      {apiKey.status === 'active' ? 'Active' : 'Revoked'}
                    </span>
                  </div>
                  <div className="flex items-center gap-6 text-sm text-slate-400">
                    <span>Created {apiKey.createdAt}</span>
                    <span>Last used {apiKey.lastUsed}</span>
                    <span>{apiKey.requests.toLocaleString()} requests</span>
                  </div>
                </div>
                
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => toggleKeyVisibility(apiKey.id)}
                    className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
                    title={visibleKeys.has(apiKey.id) ? 'Hide key' : 'Show key'}
                  >
                    {visibleKeys.has(apiKey.id) ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                  <button
                    onClick={() => copyToClipboard(apiKey.key_masked || '', apiKey.id)}
                    className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
                    title="Copy key"
                  >
                    {copiedId === apiKey.id ? <CheckCircle className="w-5 h-5 text-green-400" /> : <Copy className="w-5 h-5" />}
                  </button>
                  {apiKey.status === 'active' && (
                    <button
                      onClick={() => handleRevokeKey(apiKey.id)}
                      className="p-2 text-slate-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                      title="Revoke key"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  )}
                </div>
              </div>

              {/* Key Display */}
              <div className="bg-slate-950 border border-slate-800 rounded-lg p-4 font-mono text-sm">
                <code className={visibleKeys.has(apiKey.id) ? 'text-green-400' : 'text-slate-500'}>
                  {visibleKeys.has(apiKey.id) ? (apiKey.key || apiKey.key_masked) : apiKey.key_masked}
                </code>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Empty State */}
      {!loading && keys.length === 0 && (
        <div className="text-center py-12">
          <Key className="w-16 h-16 text-slate-700 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-white mb-2">No API keys yet</h3>
          <p className="text-slate-400 mb-6">Create your first API key to start using Tiannara Core</p>
          <button
            onClick={() => setShowNewKeyModal(true)}
            className="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-xl font-semibold transition-colors inline-flex items-center gap-2"
          >
            <Plus className="w-5 h-5" />
            Create Your First Key
          </button>
        </div>
      )}

      {/* Create Key Modal */}
      {showNewKeyModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-8 max-w-md w-full mx-4">
            <h2 className="text-2xl font-bold text-white mb-4">Create New API Key</h2>
            <p className="text-slate-400 mb-6">Give your API key a descriptive name. The key will be shown only once.</p>
            
            <div className="mb-6">
              <label className="block text-sm font-medium text-slate-300 mb-2">
                Key Name
              </label>
              <input
                type="text"
                value={newKeyName}
                onChange={(e) => setNewKeyName(e.target.value)}
                placeholder="e.g., Production App, Mobile App, Testing"
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 transition-colors"
                autoFocus
                disabled={creating}
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setShowNewKeyModal(false)}
                className="flex-1 bg-slate-800 hover:bg-slate-700 text-white px-4 py-3 rounded-xl font-semibold transition-colors"
                disabled={creating}
              >
                Cancel
              </button>
              <button
                onClick={handleCreateKey}
                disabled={!newKeyName.trim() || creating}
                className="flex-1 bg-purple-600 hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-3 rounded-xl font-semibold transition-colors flex items-center justify-center gap-2"
              >
                {creating ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Creating...
                  </>
                ) : (
                  'Create Key'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
