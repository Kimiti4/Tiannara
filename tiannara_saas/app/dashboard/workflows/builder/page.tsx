'use client'

import { useState, useEffect } from 'react'
import { 
  Play, Pause, Save, Trash2, Plus, ArrowRight, 
  Search, Zap, BarChart3, Activity, Bell,
  CheckCircle, X, Settings, Eye
} from 'lucide-react'
import { apiClient } from '@/lib/api'
import { WORKFLOW_TEMPLATES } from '@/lib/workflow-templates'
import { translateTechnicalName } from '@/lib/translation-layer'

interface Node {
  id: string
  type: string
  position: { x: number; y: number }
  data: {
    label: string
    description?: string
    config?: Record<string, any>
  }
}

interface Edge {
  id: string
  source: string
  target: string
}

export default function WorkflowBuilder() {
  const [nodes, setNodes] = useState<Node[]>([])
  const [edges, setEdges] = useState<Edge[]>([])
  const [selectedNode, setSelectedNode] = useState<string | null>(null)
  const [workflowName, setWorkflowName] = useState('')
  const [workflowDescription, setWorkflowDescription] = useState('')
  const [isRunning, setIsRunning] = useState(false)
  const [output, setOutput] = useState<any>(null)
  const [showTemplates, setShowTemplates] = useState(false)
  const [loading, setLoading] = useState(false)

  // Component categories for sidebar
  const componentCategories = [
    {
      name: 'Inputs',
      icon: Plus,
      items: [
        { type: 'text_input', label: 'Text Input', icon: '📝' },
        { type: 'file_upload', label: 'File Upload', icon: '📁' },
        { type: 'api_endpoint', label: 'API Endpoint', icon: '🔌' },
      ]
    },
    {
      name: 'AI Analysis',
      icon: Brain,
      items: [
        { type: 'nlp_analysis', label: 'NLP Analysis', icon: '🧠' },
        { type: 'pattern_intelligence', label: 'Pattern Intelligence', icon: '🔍' },
        { type: 'root_cause_analysis', label: 'Root Cause Analysis', icon: '🎯' },
      ]
    },
    {
      name: 'Forecasting',
      icon: BarChart3,
      items: [
        { type: 'prediction_engine', label: 'Prediction Engine', icon: '🔮' },
        { type: 'trend_analysis', label: 'Trend Analysis', icon: '📈' },
        { type: 'risk_scoring', label: 'Risk Scoring', icon: '⚠️' },
      ]
    },
    {
      name: 'Monitoring',
      icon: Activity,
      items: [
        { type: 'anomaly_detection', label: 'Anomaly Detection', icon: '🚨' },
        { type: 'threshold_monitor', label: 'Threshold Monitor', icon: '📊' },
      ]
    },
    {
      name: 'Notifications',
      icon: Bell,
      items: [
        { type: 'email_alert', label: 'Email Alert', icon: '📧' },
        { type: 'webhook', label: 'Webhook', icon: '🔔' },
        { type: 'dashboard_update', label: 'Dashboard Update', icon: '📱' },
      ]
    }
  ]

  const addNode = (type: string, label: string) => {
    const newNode: Node = {
      id: `node_${Date.now()}`,
      type,
      position: { x: 100 + nodes.length * 50, y: 100 + nodes.length * 50 },
      data: {
        label,
        description: `Configure ${label.toLowerCase()}`,
        config: {}
      }
    }
    setNodes([...nodes, newNode])
  }

  const removeNode = (nodeId: string) => {
    setNodes(nodes.filter(n => n.id !== nodeId))
    setEdges(edges.filter(e => e.source !== nodeId && e.target !== nodeId))
    if (selectedNode === nodeId) {
      setSelectedNode(null)
    }
  }

  const connectNodes = (sourceId: string, targetId: string) => {
    const newEdge: Edge = {
      id: `edge_${Date.now()}`,
      source: sourceId,
      target: targetId
    }
    setEdges([...edges, newEdge])
  }

  const loadTemplate = (templateId: string) => {
    const template = WORKFLOW_TEMPLATES.find(t => t.id === templateId)
    if (template) {
      setNodes(template.nodes)
      setEdges(template.edges)
      setWorkflowName(template.name)
      setWorkflowDescription(template.description)
      setShowTemplates(false)
    }
  }

  const saveWorkflow = async () => {
    if (!workflowName.trim()) {
      alert('Please enter a workflow name')
      return
    }

    try {
      setLoading(true)
      const response = await apiClient.createWorkflow({
        name: workflowName,
        description: workflowDescription,
        nodes,
        edges,
        status: 'draft'
      })

      if (response.success) {
        alert('Workflow saved successfully!')
      } else {
        alert('Failed to save workflow: ' + response.error)
      }
    } catch (error) {
      console.error('Save error:', error)
      alert('Failed to save workflow')
    } finally {
      setLoading(false)
    }
  }

  const runWorkflow = async () => {
    if (nodes.length === 0) {
      alert('Please add at least one node to the workflow')
      return
    }

    try {
      setIsRunning(true)
      setOutput(null)

      // Execute workflow through API Gateway
      const response = await apiClient.executeWorkflow({
        nodes,
        edges,
        input_data: {}
      })

      if (response.success) {
        setOutput(response.data)
      } else {
        alert('Workflow execution failed: ' + response.error)
      }
    } catch (error) {
      console.error('Execution error:', error)
      alert('Failed to execute workflow')
    } finally {
      setIsRunning(false)
    }
  }

  return (
    <div className="h-screen flex flex-col bg-slate-950">
      {/* Header */}
      <div className="border-b border-slate-800 bg-slate-900/50 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <h1 className="text-xl font-bold text-white">Workflow Builder</h1>
            <input
              type="text"
              placeholder="Workflow name..."
              value={workflowName}
              onChange={(e) => setWorkflowName(e.target.value)}
              className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
            />
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowTemplates(!showTemplates)}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors flex items-center gap-2"
            >
              <Search className="w-4 h-4" />
              Templates
            </button>
            <button
              onClick={saveWorkflow}
              disabled={loading}
              className="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {loading ? 'Saving...' : 'Save'}
            </button>
            <button
              onClick={runWorkflow}
              disabled={isRunning || nodes.length === 0}
              className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50"
            >
              {isRunning ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
              {isRunning ? 'Running...' : 'Run'}
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 flex overflow-hidden">
        {/* Components Sidebar */}
        <div className="w-64 border-r border-slate-800 bg-slate-900/30 overflow-y-auto">
          <div className="p-4">
            <h2 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">Components</h2>
            
            {componentCategories.map((category) => (
              <div key={category.name} className="mb-6">
                <div className="flex items-center gap-2 mb-3">
                  <category.icon className="w-4 h-4 text-purple-400" />
                  <h3 className="text-xs font-medium text-slate-300">{category.name}</h3>
                </div>
                
                <div className="space-y-2">
                  {category.items.map((item) => (
                    <button
                      key={item.type}
                      onClick={() => addNode(item.type, item.label)}
                      className="w-full flex items-center gap-3 px-3 py-2 bg-slate-800/50 hover:bg-slate-800 border border-slate-700 hover:border-purple-500/40 rounded-lg transition-all group"
                    >
                      <span className="text-lg">{item.icon}</span>
                      <span className="text-sm text-slate-300 group-hover:text-white">{item.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Canvas */}
        <div className="flex-1 relative bg-slate-950">
          {/* Grid Background */}
          <div 
            className="absolute inset-0 opacity-10"
            style={{
              backgroundImage: 'radial-gradient(circle, #9333ea 1px, transparent 1px)',
              backgroundSize: '20px 20px'
            }}
          />

          {/* Nodes */}
          <div className="relative z-10 p-8">
            {nodes.length === 0 ? (
              <div className="flex items-center justify-center h-full">
                <div className="text-center">
                  <p className="text-slate-500 mb-4">Start building your workflow</p>
                  <button
                    onClick={() => setShowTemplates(true)}
                    className="px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
                  >
                    Browse Templates
                  </button>
                </div>
              </div>
            ) : (
              <div className="grid grid-cols-1 gap-4 max-w-4xl mx-auto">
                {nodes.map((node, index) => (
                  <div key={node.id} className="relative">
                    {/* Connection Line */}
                    {index > 0 && (
                      <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                        <ArrowRight className="w-5 h-5 text-purple-500 rotate-90" />
                      </div>
                    )}
                    
                    {/* Node Card */}
                    <div
                      className={`bg-slate-900 border-2 rounded-xl p-4 cursor-pointer transition-all ${
                        selectedNode === node.id
                          ? 'border-purple-500 shadow-lg shadow-purple-500/20'
                          : 'border-slate-700 hover:border-slate-600'
                      }`}
                      onClick={() => setSelectedNode(node.id)}
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex items-center gap-3">
                          <span className="text-2xl">
                            {componentCategories
                              .flatMap(c => c.items)
                              .find(i => i.type === node.type)?.icon || '📦'}
                          </span>
                          <div>
                            <h3 className="text-sm font-semibold text-white">{node.data.label}</h3>
                            <p className="text-xs text-slate-400">{node.data.description}</p>
                          </div>
                        </div>
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            removeNode(node.id)
                          }}
                          className="p-1 hover:bg-red-500/20 rounded transition-colors"
                        >
                          <Trash2 className="w-4 h-4 text-slate-500 hover:text-red-400" />
                        </button>
                      </div>
                      
                      {/* Node Status */}
                      <div className="flex items-center gap-2 mt-3 pt-3 border-t border-slate-800">
                        <div className="w-2 h-2 rounded-full bg-green-500"></div>
                        <span className="text-xs text-slate-400">Ready</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Templates Modal */}
          {showTemplates && (
            <div className="absolute inset-0 bg-black/50 backdrop-blur-sm z-20 flex items-center justify-center p-8">
              <div className="bg-slate-900 border border-slate-700 rounded-xl max-w-4xl w-full max-h-[80vh] overflow-y-auto">
                <div className="p-6 border-b border-slate-800 flex items-center justify-between">
                  <h2 className="text-lg font-bold text-white">Workflow Templates</h2>
                  <button
                    onClick={() => setShowTemplates(false)}
                    className="p-2 hover:bg-slate-800 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
                
                <div className="p-6 grid grid-cols-2 gap-4">
                  {WORKFLOW_TEMPLATES.map((template) => (
                    <button
                      key={template.id}
                      onClick={() => loadTemplate(template.id)}
                      className="bg-slate-800/50 hover:bg-slate-800 border border-slate-700 hover:border-purple-500/40 rounded-xl p-4 text-left transition-all"
                    >
                      <div className="flex items-center gap-3 mb-3">
                        <span className="text-2xl">{template.icon}</span>
                        <div>
                          <h3 className="text-sm font-semibold text-white">{template.name}</h3>
                          <p className="text-xs text-slate-400 capitalize">{template.difficulty} • {template.estimatedTime}</p>
                        </div>
                      </div>
                      <p className="text-xs text-slate-400 mb-3 line-clamp-2">{template.description}</p>
                      <div className="flex items-center gap-2">
                        {template.tags.slice(0, 3).map(tag => (
                          <span key={tag} className="text-xs px-2 py-1 bg-purple-500/10 text-purple-400 rounded">
                            {tag}
                          </span>
                        ))}
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Properties Panel */}
        {selectedNode && (
          <div className="w-80 border-l border-slate-800 bg-slate-900/30 overflow-y-auto">
            <div className="p-4">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Properties</h2>
                <button
                  onClick={() => setSelectedNode(null)}
                  className="p-1 hover:bg-slate-800 rounded transition-colors"
                >
                  <X className="w-4 h-4 text-slate-400" />
                </button>
              </div>
              
              {(() => {
                const node = nodes.find(n => n.id === selectedNode)
                if (!node) return null
                
                return (
                  <div className="space-y-4">
                    <div>
                      <label className="block text-xs text-slate-400 mb-1">Label</label>
                      <input
                        type="text"
                        value={node.data.label}
                        onChange={(e) => {
                          const updated = nodes.map(n =>
                            n.id === selectedNode ? { ...n, data: { ...n.data, label: e.target.value } } : n
                          )
                          setNodes(updated)
                        }}
                        className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-xs text-slate-400 mb-1">Description</label>
                      <textarea
                        value={node.data.description || ''}
                        onChange={(e) => {
                          const updated = nodes.map(n =>
                            n.id === selectedNode ? { ...n, data: { ...n.data, description: e.target.value } } : n
                          )
                          setNodes(updated)
                        }}
                        rows={3}
                        className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500 resize-none"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-xs text-slate-400 mb-2">Configuration</label>
                      <div className="bg-slate-800/50 rounded-lg p-3 border border-slate-700">
                        <p className="text-xs text-slate-500">Configure node-specific settings here</p>
                      </div>
                    </div>
                  </div>
                )
              })()}
            </div>
          </div>
        )}
      </div>

      {/* Output Panel */}
      {output && (
        <div className="border-t border-slate-800 bg-slate-900/50 max-h-64 overflow-y-auto">
          <div className="p-4">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-white flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-green-400" />
                Workflow Output
              </h3>
              <button
                onClick={() => setOutput(null)}
                className="text-xs text-slate-400 hover:text-white"
              >
                Clear
              </button>
            </div>
            <pre className="text-xs text-slate-300 bg-slate-950 rounded-lg p-3 overflow-x-auto">
              {JSON.stringify(output, null, 2)}
            </pre>
          </div>
        </div>
      )}
    </div>
  )
}

function Brain(props: any) {
  return (
    <svg {...props} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z" />
      <path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z" />
    </svg>
  )
}
