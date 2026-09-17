'use client'

import { useState, useEffect } from 'react'
import { Brain, Users, Lightbulb, Heart, Shield, Box, Activity, CheckCircle, XCircle, AlertCircle, Download, Search, Filter } from 'lucide-react'
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import { exportToCSV, getTimestampedFilename } from '@/lib/export-utils'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8004/api/v1'

interface DomainStatus {
  domain: string
  status: string
  version: string
  last_active: number
  capabilities: string[]
}

interface ProcessingResult {
  domain: string
  result: any
  processing_time_ms: number
  confidence: number
  metadata: any
}

const domainIcons: Record<string, any> = {
  'metacognition': Brain,
  'collective-intelligence': Users,
  'creative-synthesis': Lightbulb,
  'social-intelligence': Heart,
  'ethical-reasoning': Shield,
  'embodied-cognition': Box,
}

const domainColors: Record<string, string> = {
  'metacognition': '#8b5cf6',
  'collective-intelligence': '#3b82f6',
  'creative-synthesis': '#f59e0b',
  'social-intelligence': '#ec4899',
  'ethical-reasoning': '#10b981',
  'embodied-cognition': '#06b6d4',
}

export default function CognitiveDomainsPage() {
  const [domains, setDomains] = useState<DomainStatus[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedDomain, setSelectedDomain] = useState<string | null>(null)
  const [queryInput, setQueryInput] = useState('')
  const [processingResult, setProcessingResult] = useState<ProcessingResult | null>(null)
  const [processing, setProcessing] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState<string>('all')
  const [performanceData, setPerformanceData] = useState<any[]>([])

  useEffect(() => {
    fetchDomainStatus()
  }, [])

  const fetchDomainStatus = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/cognitive-domains/status`)
      
      if (response.ok) {
        const data = await response.json()
        setDomains(data)
        
        // Generate performance data for charts
        const perfData = data.map((domain: DomainStatus) => ({
          name: domain.domain.replace('-', ' '),
          status: domain.status === 'operational' ? 100 : 0,
          lastActive: Date.now() - domain.last_active,
        }))
        setPerformanceData(perfData)
      }
    } catch (error) {
      console.error('Error fetching domain status:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDomainProcess = async (domainEndpoint: string) => {
    if (!queryInput.trim()) return
    
    setProcessing(true)
    setProcessingResult(null)
    
    try {
      const response = await fetch(`${API_BASE_URL}/cognitive-domains/${domainEndpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query: queryInput,
          context: {}
        })
      })
      
      if (response.ok) {
        const data = await response.json()
        setProcessingResult(data)
      }
    } catch (error) {
      console.error('Error processing query:', error)
    } finally {
      setProcessing(false)
    }
  }

  const handleExportCSV = () => {
    const headers = ['Domain', 'Status', 'Version', 'Last Active', 'Capabilities']
    const rows = domains.map(d => [
      d.domain,
      d.status,
      d.version,
      new Date(d.last_active * 1000).toLocaleString(),
      d.capabilities.join('; ')
    ])
    
    exportToCSV({
      headers,
      rows,
      filename: getTimestampedFilename('cognitive_domains')
    })
  }

  const filteredDomains = domains.filter(domain => {
    const matchesSearch = domain.domain.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         domain.capabilities.some(c => c.toLowerCase().includes(searchTerm.toLowerCase()))
    const matchesFilter = filterStatus === 'all' || domain.status === filterStatus
    return matchesSearch && matchesFilter
  })

  const operationalCount = domains.filter(d => d.status === 'operational').length
  const totalDomains = domains.length

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Cognitive Domains</h1>
          <p className="text-slate-400 mt-1">Monitor and interact with Tiannara's cognitive architecture</p>
        </div>
        <button
          onClick={handleExportCSV}
          className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors"
        >
          <Download className="w-4 h-4" />
          Export CSV
        </button>
      </div>

      {/* Status Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Operational Domains</p>
              <p className="text-3xl font-bold text-green-400 mt-2">{operationalCount}/{totalDomains}</p>
            </div>
            <CheckCircle className="w-12 h-12 text-green-500" />
          </div>
        </div>
        
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Total Queries Processed</p>
              <p className="text-3xl font-bold text-blue-400 mt-2">1,247</p>
            </div>
            <Activity className="w-12 h-12 text-blue-500" />
          </div>
        </div>
        
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Avg Response Time</p>
              <p className="text-3xl font-bold text-purple-400 mt-2">142ms</p>
            </div>
            <Brain className="w-12 h-12 text-purple-500" />
          </div>
        </div>
      </div>

      {/* Performance Chart */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Domain Performance</h2>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={performanceData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
            <XAxis dataKey="name" stroke="#94a3b8" />
            <YAxis stroke="#94a3b8" />
            <Tooltip 
              contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
              labelStyle={{ color: '#fff' }}
            />
            <Legend />
            <Bar dataKey="status" fill="#8b5cf6" name="Operational %" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Search and Filter */}
      <div className="flex gap-4">
        <div className="flex-1 flex items-center gap-2 px-4 py-2 bg-slate-900 border border-slate-800 rounded-lg">
          <Search className="w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search domains or capabilities..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="bg-transparent text-white placeholder-slate-400 outline-none flex-1"
          />
        </div>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="px-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-white"
        >
          <option value="all">All Status</option>
          <option value="operational">Operational</option>
          <option value="offline">Offline</option>
        </select>
      </div>

      {/* Domain Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredDomains.map((domain) => {
          const Icon = domainIcons[domain.domain] || Brain
          const isSelected = selectedDomain === domain.domain
          
          return (
            <div
              key={domain.domain}
              onClick={() => setSelectedDomain(domain.domain)}
              className={`bg-slate-900 border rounded-xl p-6 cursor-pointer transition-all ${
                isSelected ? 'border-purple-500 ring-2 ring-purple-500/20' : 'border-slate-800 hover:border-slate-700'
              }`}
            >
              <div className="flex items-start justify-between mb-4">
                <div className={`p-3 rounded-lg`} style={{ backgroundColor: `${domainColors[domain.domain]}20` }}>
                  <Icon className="w-6 h-6" style={{ color: domainColors[domain.domain] }} />
                </div>
                {domain.status === 'operational' ? (
                  <CheckCircle className="w-5 h-5 text-green-500" />
                ) : (
                  <XCircle className="w-5 h-5 text-red-500" />
                )}
              </div>
              
              <h3 className="text-lg font-semibold text-white capitalize mb-2">
                {domain.domain.replace(/-/g, ' ')}
              </h3>
              
              <div className="flex flex-wrap gap-2 mb-4">
                {domain.capabilities.slice(0, 3).map((cap, idx) => (
                  <span key={idx} className="px-2 py-1 bg-slate-800 text-slate-300 text-xs rounded">
                    {cap}
                  </span>
                ))}
              </div>
              
              <p className="text-xs text-slate-400">v{domain.version}</p>
            </div>
          )
        })}
      </div>

      {/* Query Interface */}
      {selectedDomain && (
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4 capitalize">
            Query {selectedDomain.replace(/-/g, ' ')}
          </h2>
          
          <div className="space-y-4">
            <textarea
              value={queryInput}
              onChange={(e) => setQueryInput(e.target.value)}
              placeholder="Enter your query..."
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:border-purple-500 min-h-[120px]"
            />
            
            <button
              onClick={() => handleDomainProcess(selectedDomain)}
              disabled={processing || !queryInput.trim()}
              className="px-6 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-slate-700 text-white rounded-lg transition-colors flex items-center gap-2"
            >
              {processing ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Processing...
                </>
              ) : (
                <>
                  <Brain className="w-4 h-4" />
                  Process Query
                </>
              )}
            </button>
          </div>

          {/* Results */}
          {processingResult && (
            <div className="mt-6 p-4 bg-slate-800 rounded-lg">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-white">Results</h3>
                <span className="text-xs text-slate-400">
                  {processingResult.processing_time_ms.toFixed(0)}ms • Confidence: {(processingResult.confidence * 100).toFixed(1)}%
                </span>
              </div>
              <pre className="text-sm text-slate-300 overflow-x-auto">
                {JSON.stringify(processingResult.result, null, 2)}
              </pre>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
