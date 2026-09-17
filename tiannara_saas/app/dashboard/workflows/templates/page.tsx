'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { 
  Search, Filter, Zap, BarChart3, Shield, Activity, Cpu, Search as SearchIcon,
  ArrowRight, CheckCircle, Star, Loader2, AlertCircle, X, Settings
} from 'lucide-react'
import { WORKFLOW_TEMPLATES, WorkflowTemplate, getTemplatesByCategory, searchTemplates } from '@/lib/workflow-templates'
import { translateTechnicalName } from '@/lib/translation-layer'
import { apiClient } from '@/lib/api'

export default function WorkflowTemplatesPage() {
  const router = useRouter()
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)
  const [selectedDifficulty, setSelectedDifficulty] = useState<string | null>(null)
  const [deployingTemplate, setDeployingTemplate] = useState<string | null>(null)
  const [deployError, setDeployError] = useState<string | null>(null)
  
  // Input configuration modal state
  const [showInputModal, setShowInputModal] = useState(false)
  const [selectedTemplateForInput, setSelectedTemplateForInput] = useState<WorkflowTemplate | null>(null)
  const [inputData, setInputData] = useState<Record<string, any>>({})
  
  // Template description expansion state
  const [expandedDescriptions, setExpandedDescriptions] = useState<Set<string>>(new Set())

  // Filter templates
  let filteredTemplates = WORKFLOW_TEMPLATES
  
  if (searchQuery) {
    filteredTemplates = searchTemplates(searchQuery)
  }
  
  if (selectedCategory) {
    filteredTemplates = filteredTemplates.filter(t => t.category === selectedCategory)
  }
  
  if (selectedDifficulty) {
    filteredTemplates = filteredTemplates.filter(t => t.difficulty === selectedDifficulty)
  }

  const categories = Array.from(new Set(WORKFLOW_TEMPLATES.map(t => t.category)))
  const difficulties = ['beginner', 'intermediate', 'advanced']

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'fraud': return Shield
      case 'analytics': return BarChart3
      case 'marketing': return Star
      case 'monitoring': return Activity
      case 'prediction': return Cpu
      case 'research': return SearchIcon
      default: return Zap
    }
  }

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'beginner': return 'green'
      case 'intermediate': return 'yellow'
      case 'advanced': return 'red'
      default: return 'gray'
    }
  }

  const handleDeployTemplate = async (template: WorkflowTemplate, executeImmediately: boolean = false, customInputData?: Record<string, any>) => {
    try {
      setDeployingTemplate(template.id)
      setDeployError(null)
      
      // Step 1: Create workflow from template
      const response = await apiClient.createWorkflowFromTemplate(template.id)
      
      if (!response.success || !response.data) {
        setDeployError(response.message || 'Failed to deploy template')
        return
      }
      
      const workflowId = response.data.workflow_id
      
      if (executeImmediately) {
        // Step 2: Execute the workflow immediately through Tiannara Core
        const executionResponse = await apiClient.executeWorkflow(
          workflowId,
          customInputData || inputData || {}, // Use custom input if provided
          'sequential'
        )
        
        if (executionResponse.success && executionResponse.data) {
          // Redirect to execution results page
          router.push(`/dashboard/workflows/executor?execution_id=${executionResponse.data.execution_id}`)
        } else {
          setDeployError(executionResponse.message || 'Failed to execute workflow')
        }
      } else {
        // Just redirect to workflow builder for customization
        router.push(`/dashboard/workflows/builder?workflow_id=${workflowId}`)
      }
    } catch (err: any) {
      console.error('Failed to deploy template:', err)
      setDeployError(err.message || 'Failed to deploy template')
    } finally {
      setDeployingTemplate(null)
    }
  }

  const handleOpenInputModal = (template: WorkflowTemplate) => {
    setSelectedTemplateForInput(template)
    setInputData({})
    setShowInputModal(true)
  }

  const handleCloseInputModal = () => {
    setShowInputModal(false)
    setSelectedTemplateForInput(null)
    setInputData({})
  }

  const handleExecuteWithInput = () => {
    if (selectedTemplateForInput) {
      handleDeployTemplate(selectedTemplateForInput, true, inputData)
      handleCloseInputModal()
    }
  }

  const toggleDescription = (templateId: string) => {
    setExpandedDescriptions(prev => {
      const newSet = new Set(prev)
      if (newSet.has(templateId)) {
        newSet.delete(templateId)
      } else {
        newSet.add(templateId)
      }
      return newSet
    })
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Workflow Templates</h1>
        <p className="text-slate-400">
          Pre-built workflows for common use cases. Deploy with one click and customize to your needs.
        </p>
      </div>

      {/* Deploy Error Alert */}
      {deployError && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 mb-6 flex items-center gap-3">
          <AlertCircle className="w-5 h-5 text-red-400" />
          <p className="text-red-400 text-sm">{deployError}</p>
          <button onClick={() => setDeployError(null)} className="ml-auto text-red-400 hover:text-red-300">✕</button>
        </div>
      )}

      {/* Filters */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          {/* Search */}
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                placeholder="Search templates..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:border-purple-500"
              />
            </div>
          </div>

          {/* Category Filter */}
          <div className="flex items-center gap-2">
            <Filter className="w-5 h-5 text-slate-400" />
            <select
              value={selectedCategory || ''}
              onChange={(e) => setSelectedCategory(e.target.value || null)}
              className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
            >
              <option value="">All Categories</option>
              {categories.map(cat => (
                <option key={cat} value={cat}>
                  {cat.charAt(0).toUpperCase() + cat.slice(1)}
                </option>
              ))}
            </select>
          </div>

          {/* Difficulty Filter */}
          <div className="flex items-center gap-2">
            <Star className="w-5 h-5 text-slate-400" />
            <select
              value={selectedDifficulty || ''}
              onChange={(e) => setSelectedDifficulty(e.target.value || null)}
              className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
            >
              <option value="">All Levels</option>
              {difficulties.map(diff => (
                <option key={diff} value={diff}>
                  {diff.charAt(0).toUpperCase() + diff.slice(1)}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Templates Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredTemplates.map((template) => {
          const CategoryIcon = getCategoryIcon(template.category)
          const difficultyColor = getDifficultyColor(template.difficulty)
          
          return (
            <div
              key={template.id}
              className="bg-slate-900/50 border border-slate-800 rounded-xl overflow-hidden hover:border-purple-500/50 transition-all group"
            >
              {/* Template Header */}
              <div className={`p-6 bg-gradient-to-br from-${template.color}-500/10 to-transparent border-b border-slate-800`}>
                <div className="flex items-start justify-between mb-4">
                  <div className={`w-12 h-12 rounded-lg bg-${template.color}-500/20 flex items-center justify-center`}>
                    <CategoryIcon className={`w-6 h-6 text-${template.color}-400`} />
                  </div>
                  <span className={`px-3 py-1 bg-${difficultyColor}-500/20 text-${difficultyColor}-400 text-xs rounded-full capitalize`}>
                    {template.difficulty}
                  </span>
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">
                  {template.name}
                </h3>
                <div>
                  <p className={`text-sm text-slate-400 ${
                    expandedDescriptions.has(template.id) ? '' : 'line-clamp-2'
                  }`}>
                    {template.description}
                  </p>
                  {template.description.length > 150 && (
                    <button
                      onClick={() => toggleDescription(template.id)}
                      className="text-xs text-purple-400 hover:text-purple-300 mt-1 transition-colors"
                    >
                      {expandedDescriptions.has(template.id) ? 'Show Less' : 'Read More'}
                    </button>
                  )}
                </div>
              </div>

              {/* Template Details */}
              <div className="p-6">
                {/* Tier Badge */}
                {template.tierRequired && (
                  <div className="mb-3">
                    <span className={`px-2 py-1 text-xs rounded-md font-medium ${
                      template.tierRequired === 'starter' ? 'bg-green-500/20 text-green-400' :
                      template.tierRequired === 'professional' ? 'bg-blue-500/20 text-blue-400' :
                      'bg-purple-500/20 text-purple-400'
                    }`}>
                      {template.tierRequired.charAt(0).toUpperCase() + template.tierRequired.slice(1)} Plan
                    </span>
                  </div>
                )}

                {/* Tags */}
                <div className="flex flex-wrap gap-2 mb-4">
                  {template.tags.slice(0, 3).map((tag, idx) => (
                    <span
                      key={idx}
                      className="px-2 py-1 bg-slate-800 text-slate-300 text-xs rounded-md"
                    >
                      {tag}
                    </span>
                  ))}
                </div>

                {/* Domains Used (if advanced template) */}
                {template.domainsUsed && template.domainsUsed.length > 0 && (
                  <div className="mb-4 p-3 bg-slate-800/50 rounded-lg">
                    <p className="text-xs text-slate-400 mb-2">Core Domains:</p>
                    <div className="flex flex-wrap gap-1">
                      {template.domainsUsed.slice(0, 4).map((domain, idx) => (
                        <span key={idx} className="text-xs text-cyan-400">
                          {domain.replace(/_/g, ' ')}
                          {idx < Math.min(template.domainsUsed.length, 4) - 1 && ', '}
                        </span>
                      ))}
                      {template.domainsUsed.length > 4 && (
                        <span className="text-xs text-slate-500">+{template.domainsUsed.length - 4} more</span>
                      )}
                    </div>
                  </div>
                )}

                {/* Info */}
                <div className="space-y-2 mb-6 text-sm">
                  <div className="flex items-center justify-between text-slate-400">
                    <span>Setup Time:</span>
                    <span className="text-white">{template.estimatedTime}</span>
                  </div>
                  <div className="flex items-center justify-between text-slate-400">
                    <span>Nodes:</span>
                    <span className="text-white">{template.nodes.length}</span>
                  </div>
                  <div className="flex items-center justify-between text-slate-400">
                    <span>Recommended for:</span>
                    <span className="text-white capitalize">{template.recommendedFor}</span>
                  </div>
                  {template.outputs && template.outputs.length > 0 && (
                    <div className="pt-2 border-t border-slate-800">
                      <p className="text-xs text-slate-400 mb-1">Outputs:</p>
                      <div className="flex flex-wrap gap-1">
                        {template.outputs.slice(0, 2).map((output, idx) => (
                          <span key={idx} className="text-xs text-green-400">• {output}</span>
                        ))}
                        {template.outputs.length > 2 && (
                          <span className="text-xs text-slate-500">+{template.outputs.length - 2}</span>
                        )}
                      </div>
                    </div>
                  )}
                </div>

                {/* Deploy Buttons */}
                <div className="space-y-2">
                  {/* Execute Now Button - Primary Action */}
                  <button
                    onClick={() => handleDeployTemplate(template, true)}
                    disabled={deployingTemplate === template.id}
                    className="w-full px-4 py-3 bg-gradient-to-r from-purple-600 to-cyan-600 hover:from-purple-700 hover:to-cyan-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-all flex items-center justify-center gap-2 shadow-lg shadow-purple-500/25"
                  >
                    {deployingTemplate === template.id ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Executing...
                      </>
                    ) : (
                      <>
                        <Zap className="w-4 h-4" />
                        Execute Now
                        <ArrowRight className="w-4 h-4" />
                      </>
                    )}
                  </button>
                  
                  {/* Configure & Execute Button - Secondary Action */}
                  <button
                    onClick={() => handleOpenInputModal(template)}
                    disabled={deployingTemplate === template.id}
                    className="w-full px-4 py-2 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed text-slate-300 font-medium rounded-lg transition-colors flex items-center justify-center gap-2 border border-slate-700"
                  >
                    <Settings className="w-4 h-4" />
                    Configure & Execute
                  </button>
                  
                  {/* Deploy & Customize Button - Tertiary Action */}
                  <button
                    onClick={() => handleDeployTemplate(template, false)}
                    disabled={deployingTemplate === template.id}
                    className="w-full px-4 py-2 bg-transparent hover:bg-slate-800/50 disabled:opacity-50 disabled:cursor-not-allowed text-slate-400 text-sm font-medium rounded-lg transition-colors flex items-center justify-center gap-2"
                  >
                    <Cpu className="w-4 h-4" />
                    Deploy & Customize in Builder
                  </button>
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Empty State */}
      {filteredTemplates.length === 0 && (
        <div className="text-center py-16">
          <div className="w-20 h-20 bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-4">
            <Search className="w-10 h-10 text-slate-600" />
          </div>
          <h3 className="text-xl font-semibold text-white mb-2">No templates found</h3>
          <p className="text-slate-400">
            Try adjusting your search or filters
          </p>
        </div>
      )}

      {/* Quick Start Guide */}
      <div className="mt-12 bg-gradient-to-r from-purple-600/10 to-cyan-600/10 border border-purple-500/30 rounded-xl p-8">
        <h2 className="text-2xl font-bold text-white mb-4">How Templates Work</h2>
        <p className="text-slate-400 mb-6">
          Templates are pre-built AI workflow blueprints that connect Tiannara Core's intelligence domains 
          to solve specific business problems. Deploy with one click and customize to your needs.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-purple-400 font-bold">1</span>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-1">Choose a Template</h3>
              <p className="text-sm text-slate-400">Browse templates by category or search for your specific use case</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-purple-400 font-bold">2</span>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-1">Deploy & Customize</h3>
              <p className="text-sm text-slate-400">Click deploy to create the workflow, then customize nodes and settings</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-purple-400 font-bold">3</span>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-1">Run & Monitor</h3>
              <p className="text-sm text-slate-400">Execute your workflow and monitor results in real-time</p>
            </div>
          </div>
        </div>

        {/* Template Categories Info */}
        <div className="border-t border-purple-500/30 pt-6">
          <h3 className="text-lg font-semibold text-white mb-4">Template Categories</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div className="bg-slate-900/50 rounded-lg p-4">
              <h4 className="text-blue-400 font-medium mb-2">📊 Analytics</h4>
              <p className="text-xs text-slate-400">Customer segmentation, sales forecasting, churn prediction, marketing analysis</p>
            </div>
            <div className="bg-slate-900/50 rounded-lg p-4">
              <h4 className="text-red-400 font-medium mb-2">🛡️ Security & Fraud</h4>
              <p className="text-xs text-slate-400">Fraud detection, anomaly detection, threat intelligence, risk scoring</p>
            </div>
            <div className="bg-slate-900/50 rounded-lg p-4">
              <h4 className="text-emerald-400 font-medium mb-2">🔮 Prediction</h4>
              <p className="text-xs text-slate-400">Sports prediction, demand forecasting, risk assessment, trend analysis</p>
            </div>
            <div className="bg-slate-900/50 rounded-lg p-4">
              <h4 className="text-indigo-400 font-medium mb-2">🔬 Research & Discovery</h4>
              <p className="text-xs text-slate-400">Root cause analysis, hypothesis generation, causal inference</p>
            </div>
            <div className="bg-slate-900/50 rounded-lg p-4">
              <h4 className="text-orange-400 font-medium mb-2">⚙️ Automation</h4>
              <p className="text-xs text-slate-400">Business monitoring, workflow orchestration, report generation</p>
            </div>
            <div className="bg-slate-900/50 rounded-lg p-4">
              <h4 className="text-violet-400 font-medium mb-2">🏢 Organization</h4>
              <p className="text-xs text-slate-400">Executive dashboards, compliance monitoring, team analytics</p>
            </div>
          </div>
        </div>
      </div>

      {/* Input Configuration Modal */}
      {showInputModal && selectedTemplateForInput && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full max-h-[80vh] overflow-y-auto shadow-2xl">
            {/* Modal Header */}
            <div className="sticky top-0 bg-slate-900 border-b border-slate-800 p-6 flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <Settings className="w-5 h-5 text-purple-400" />
                  Configure Workflow Input
                </h2>
                <p className="text-sm text-slate-400 mt-1">{selectedTemplateForInput.name}</p>
              </div>
              <button
                onClick={handleCloseInputModal}
                className="p-2 hover:bg-slate-800 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-slate-400" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 space-y-6">
              {/* Template Description */}
              <div className="bg-slate-800/50 rounded-lg p-4">
                <p className="text-sm text-slate-300">{selectedTemplateForInput.description}</p>
              </div>

              {/* Dynamic Input Fields Based on Template Category */}
              <div className="space-y-4">
                <h3 className="text-sm font-semibold text-white">Input Parameters</h3>
                
                {/* Common Fields for All Templates */}
                <div>
                  <label className="block text-sm text-slate-400 mb-2">Workflow Name (Optional)</label>
                  <input
                    type="text"
                    placeholder="Custom workflow name"
                    value={inputData.workflow_name || ''}
                    onChange={(e) => setInputData({ ...inputData, workflow_name: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                  />
                </div>

                {/* Category-Specific Fields */}
                {selectedTemplateForInput.category === 'prediction' && (
                  <>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Dataset Source</label>
                      <select
                        value={inputData.dataset_source || ''}
                        onChange={(e) => setInputData({ ...inputData, dataset_source: e.target.value })}
                        className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
                      >
                        <option value="">Select data source...</option>
                        <option value="csv">CSV File Upload</option>
                        <option value="api">API Endpoint</option>
                        <option value="database">Database Connection</option>
                        <option value="manual">Manual Entry</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Prediction Horizon</label>
                      <input
                        type="text"
                        placeholder="e.g., 7 days, 30 days"
                        value={inputData.prediction_horizon || ''}
                        onChange={(e) => setInputData({ ...inputData, prediction_horizon: e.target.value })}
                        className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                      />
                    </div>
                  </>
                )}

                {selectedTemplateForInput.category === 'analytics' && (
                  <>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Analysis Type</label>
                      <select
                        value={inputData.analysis_type || ''}
                        onChange={(e) => setInputData({ ...inputData, analysis_type: e.target.value })}
                        className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
                      >
                        <option value="">Select analysis type...</option>
                        <option value="segmentation">Customer Segmentation</option>
                        <option value="forecasting">Sales Forecasting</option>
                        <option value="churn">Churn Prediction</option>
                        <option value="sentiment">Sentiment Analysis</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Time Period</label>
                      <input
                        type="text"
                        placeholder="e.g., Last 6 months"
                        value={inputData.time_period || ''}
                        onChange={(e) => setInputData({ ...inputData, time_period: e.target.value })}
                        className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                      />
                    </div>
                  </>
                )}

                {selectedTemplateForInput.category === 'fraud' && (
                  <>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Transaction Data Source</label>
                      <input
                        type="text"
                        placeholder="API endpoint or file path"
                        value={inputData.transaction_source || ''}
                        onChange={(e) => setInputData({ ...inputData, transaction_source: e.target.value })}
                        className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Risk Threshold</label>
                      <input
                        type="number"
                        placeholder="0.0 - 1.0"
                        min="0"
                        max="1"
                        step="0.1"
                        value={inputData.risk_threshold || ''}
                        onChange={(e) => setInputData({ ...inputData, risk_threshold: parseFloat(e.target.value) })}
                        className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                      />
                    </div>
                  </>
                )}

                {/* Note about advanced configuration */}
                <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4">
                  <p className="text-xs text-blue-300">
                    💡 <strong>Tip:</strong> For advanced configuration, deploy to the workflow builder first where you can customize nodes, parameters, and execution settings in detail.
                  </p>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="sticky bottom-0 bg-slate-900 border-t border-slate-800 p-6 flex gap-3">
              <button
                onClick={handleCloseInputModal}
                className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 text-white font-medium rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleExecuteWithInput}
                disabled={deployingTemplate === selectedTemplateForInput.id}
                className="flex-1 px-4 py-3 bg-gradient-to-r from-purple-600 to-cyan-600 hover:from-purple-700 hover:to-cyan-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-all flex items-center justify-center gap-2 shadow-lg shadow-purple-500/25"
              >
                {deployingTemplate === selectedTemplateForInput.id ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Executing...
                  </>
                ) : (
                  <>
                    <Zap className="w-4 h-4" />
                    Execute with Config
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
