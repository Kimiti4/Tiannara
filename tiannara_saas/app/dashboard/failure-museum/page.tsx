'use client'

import { useState, useEffect } from 'react'
import { Archive, BookOpen, AlertTriangle, Search, Filter, RefreshCw, Clock, Tag, BarChart3, PlayCircle, Download } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import { exportToCSV, getTimestampedFilename } from '@/lib/export-utils'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8004/api/v1'

interface FailureStatistics {
  total_failures: number
  total_replays: number
  by_type: Record<string, number>
}

interface TourFailure {
  id: string
  type: string
  description: string
  timestamp: number
  context?: any
  lessons_learned?: string[]
  replay_count: number
}

const COLORS = ['#8b5cf6', '#3b82f6', '#f59e0b', '#ec4899', '#10b981', '#06b6d4']

export default function FailureMuseumPage() {
  const [statistics, setStatistics] = useState<FailureStatistics | null>(null)
  const [tourResults, setTourResults] = useState<TourFailure[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedFilter, setSelectedFilter] = useState<string>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [conductingTour, setConductingTour] = useState(false)

  useEffect(() => {
    fetchStatistics()
    conductTour()
  }, [])

  const fetchStatistics = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/monitoring/failure-museum/statistics`)
      
      if (response.ok) {
        const data = await response.json()
        setStatistics(data)
      }
    } catch (error) {
      console.error('Error fetching statistics:', error)
    } finally {
      setLoading(false)
    }
  }

  const conductTour = async (type: string = 'all', limit: number = 10) => {
    setConductingTour(true)
    try {
      const response = await fetch(
        `${API_BASE_URL}/monitoring/failure-museum/tour?limit=${limit}&type=${type}`
      )
      
      if (response.ok) {
        const data = await response.json()
        setTourResults(data.failures || [])
      }
    } catch (error) {
      console.error('Error conducting tour:', error)
    } finally {
      setConductingTour(false)
    }
  }

  const handleExportCSV = () => {
    if (!tourResults.length) return
    
    const headers = ['ID', 'Type', 'Description', 'Timestamp', 'Replay Count', 'Lessons Learned']
    const rows = tourResults.map(f => [
      f.id,
      f.type,
      f.description,
      new Date(f.timestamp * 1000).toLocaleString(),
      f.replay_count,
      (f.lessons_learned || []).join('; ')
    ])
    
    exportToCSV({
      headers,
      rows,
      filename: getTimestampedFilename('failure_museum')
    })
  }

  const filteredFailures = tourResults.filter(failure => {
    const matchesSearch = !searchQuery || 
      failure.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      failure.type.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesFilter = selectedFilter === 'all' || failure.type === selectedFilter
    return matchesSearch && matchesFilter
  })

  // Prepare chart data
  const failureTypeData = statistics?.by_type
    ? Object.entries(statistics.by_type).map(([name, value]) => ({ name, value }))
    : []

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
          <h1 className="text-3xl font-bold text-white">Failure Museum</h1>
          <p className="text-slate-400 mt-1">Learn from past failures to improve future performance</p>
        </div>
        <button
          onClick={handleExportCSV}
          disabled={!tourResults.length}
          className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 disabled:bg-slate-900 disabled:text-slate-600 text-white rounded-lg transition-colors"
        >
          <Download className="w-4 h-4" />
          Export CSV
        </button>
      </div>

      {/* Statistics Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Total Failures</p>
              <p className="text-3xl font-bold text-orange-400 mt-2">{statistics?.total_failures || 0}</p>
            </div>
            <Archive className="w-12 h-12 text-orange-500" />
          </div>
        </div>
        
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Total Replays</p>
              <p className="text-3xl font-bold text-blue-400 mt-2">{statistics?.total_replays || 0}</p>
            </div>
            <RefreshCw className="w-12 h-12 text-blue-500" />
          </div>
        </div>
        
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Failure Types</p>
              <p className="text-3xl font-bold text-purple-400 mt-2">
                {Object.keys(statistics?.by_type || {}).length}
              </p>
            </div>
            <Tag className="w-12 h-12 text-purple-500" />
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Failure Types Distribution */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <BarChart3 className="w-5 h-5" />
            Failure Types Distribution
          </h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={failureTypeData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="name" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#fff' }}
              />
              <Legend />
              <Bar dataKey="value" fill="#f59e0b" name="Count" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Pie Chart */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <PieChart className="w-5 h-5" />
            Failure Type Breakdown
          </h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={failureTypeData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {failureTypeData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#fff' }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Search and Filter Controls */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1 flex items-center gap-2 px-4 py-2 bg-slate-800 rounded-lg">
            <Search className="w-4 h-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search failures by description or type..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-transparent text-white placeholder-slate-400 outline-none flex-1"
            />
          </div>
          
          <select
            value={selectedFilter}
            onChange={(e) => setSelectedFilter(e.target.value)}
            className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
          >
            <option value="all">All Types</option>
            {Object.keys(statistics?.by_type || {}).map(type => (
              <option key={type} value={type}>{type}</option>
            ))}
          </select>
          
          <button
            onClick={() => conductTour(selectedFilter)}
            disabled={conductingTour}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-slate-700 text-white rounded-lg transition-colors flex items-center gap-2"
          >
            <PlayCircle className="w-4 h-4" />
            {conductingTour ? 'Loading...' : 'Conduct Tour'}
          </button>
        </div>
      </div>

      {/* Failure Cards */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold text-white">
          Recent Failures ({filteredFailures.length})
        </h2>
        
        {filteredFailures.length === 0 ? (
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-12 text-center">
            <BookOpen className="w-16 h-16 text-slate-600 mx-auto mb-4" />
            <p className="text-slate-400">No failures found matching your criteria</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredFailures.map((failure) => (
              <div key={failure.id} className="bg-slate-900 border border-slate-800 rounded-xl p-6 hover:border-slate-700 transition-colors">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <AlertTriangle className="w-5 h-5 text-orange-500" />
                      <span className="px-2 py-1 bg-orange-500/20 text-orange-400 text-xs rounded">
                        {failure.type}
                      </span>
                      <span className="text-xs text-slate-500 flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {new Date(failure.timestamp * 1000).toLocaleString()}
                      </span>
                    </div>
                    <p className="text-white font-medium">{failure.description}</p>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <span className="text-xs text-slate-400">
                      Replayed: {failure.replay_count} times
                    </span>
                  </div>
                </div>
                
                {failure.lessons_learned && failure.lessons_learned.length > 0 && (
                  <div className="mt-4 pt-4 border-t border-slate-800">
                    <p className="text-sm text-slate-400 mb-2 font-medium">Lessons Learned:</p>
                    <ul className="space-y-1">
                      {failure.lessons_learned.map((lesson, idx) => (
                        <li key={idx} className="text-sm text-slate-300 flex items-start gap-2">
                          <span className="text-green-500 mt-1">•</span>
                          <span>{lesson}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
