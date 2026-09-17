'use client'

import { useState, useEffect } from 'react'
import { 
  Eye, Globe, Search, FileText, Image as ImageIcon, 
  Activity, TrendingUp, Clock, AlertCircle, CheckCircle,
  RefreshCw, Download, Filter, Layers, Zap
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
  LineChart, Line, PieChart, Pie, Cell
} from 'recharts'

interface TaskMetrics {
  total_tasks: number
  successful: number
  failed: number
  pending: number
  avg_response_time_ms: number
}

interface VisionMetrics {
  images_processed: number
  ocr_extractions: number
  gpt4v_queries: number
  object_detections: number
  avg_confidence: number
}

interface WebMetrics {
  pages_fetched: number
  searches_performed: number
  rss_feeds_read: number
  apis_called: number
  js_pages_rendered: number
}

export default function VisionWebMonitoringPage() {
  const [activeTab, setActiveTab] = useState('overview')
  const [loading, setLoading] = useState(false)
  
  // Mock data - replace with real API calls
  const [taskMetrics, setTaskMetrics] = useState<TaskMetrics>({
    total_tasks: 1247,
    successful: 1089,
    failed: 42,
    pending: 116,
    avg_response_time_ms: 342
  })
  
  const [visionMetrics, setVisionMetrics] = useState<VisionMetrics>({
    images_processed: 523,
    ocr_extractions: 187,
    gpt4v_queries: 94,
    object_detections: 312,
    avg_confidence: 0.87
  })
  
  const [webMetrics, setWebMetrics] = useState<WebMetrics>({
    pages_fetched: 892,
    searches_performed: 156,
    rss_feeds_read: 67,
    apis_called: 234,
    js_pages_rendered: 89
  })

  // Chart data
  const taskTrendData = [
    { date: 'Mon', vision: 45, web: 67, total: 112 },
    { date: 'Tue', vision: 52, web: 73, total: 125 },
    { date: 'Wed', vision: 48, web: 81, total: 129 },
    { date: 'Thu', vision: 61, web: 69, total: 130 },
    { date: 'Fri', vision: 55, web: 78, total: 133 },
    { date: 'Sat', vision: 38, web: 45, total: 83 },
    { date: 'Sun', vision: 42, web: 52, total: 94 },
  ]

  const methodDistribution = [
    { name: 'OCR', value: 187, color: '#8884d8' },
    { name: 'GPT-4V', value: 94, color: '#82ca9d' },
    { name: 'Object Detection', value: 312, color: '#ffc658' },
    { name: 'Scene Analysis', value: 130, color: '#ff7c7c' },
  ]

  const webMethodDistribution = [
    { name: 'HTTP Fetch', value: 892, color: '#8884d8' },
    { name: 'Search', value: 156, color: '#82ca9d' },
    { name: 'RSS Feeds', value: 67, color: '#ffc658' },
    { name: 'API Calls', value: 234, color: '#ff7c7c' },
    { name: 'JS Rendering', value: 89, color: '#a4de6c' },
  ]

  const recentTasks = [
    {
      id: 1,
      type: 'vision',
      method: 'GPT-4V',
      description: 'Analyzed product photo for quality assessment',
      status: 'success',
      confidence: 0.92,
      time: '2 min ago',
      duration_ms: 1240
    },
    {
      id: 2,
      type: 'web',
      method: 'Playwright',
      description: 'Rendered React SPA and extracted dynamic content',
      status: 'success',
      confidence: 1.0,
      time: '5 min ago',
      duration_ms: 3420
    },
    {
      id: 3,
      type: 'vision',
      method: 'OCR',
      description: 'Extracted text from invoice document',
      status: 'success',
      confidence: 0.95,
      time: '8 min ago',
      duration_ms: 567
    },
    {
      id: 4,
      type: 'web',
      method: 'Search',
      description: 'Searched for "AI trends 2024"',
      status: 'failed',
      confidence: 0.0,
      time: '12 min ago',
      duration_ms: 8900,
      error: 'Rate limit exceeded'
    },
    {
      id: 5,
      type: 'multimodal',
      method: 'Vision+NLP',
      description: 'Visual QA: "What emotion is shown?"',
      status: 'success',
      confidence: 0.88,
      time: '15 min ago',
      duration_ms: 2100
    },
  ]

  const handleRefresh = () => {
    setLoading(true)
    setTimeout(() => setLoading(false), 1000)
  }

  const successRate = ((taskMetrics.successful / taskMetrics.total_tasks) * 100).toFixed(1)

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Vision & Web Intelligence</h1>
          <p className="text-slate-600 mt-1">Monitor image analysis, OCR, web scraping, and multimodal reasoning tasks</p>
        </div>
        <Button onClick={handleRefresh} disabled={loading} variant="outline">
          <RefreshCw className={`mr-2 h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      {/* Key Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-600 flex items-center">
              <Activity className="mr-2 h-4 w-4" />
              Total Tasks
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{taskMetrics.total_tasks.toLocaleString()}</div>
            <p className="text-xs text-slate-500 mt-1">Last 7 days</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-600 flex items-center">
              <CheckCircle className="mr-2 h-4 w-4 text-green-600" />
              Success Rate
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-green-600">{successRate}%</div>
            <p className="text-xs text-slate-500 mt-1">{taskMetrics.failed} failures</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-600 flex items-center">
              <Clock className="mr-2 h-4 w-4" />
              Avg Response Time
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{taskMetrics.avg_response_time_ms}ms</div>
            <p className="text-xs text-slate-500 mt-1">Per task</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-600 flex items-center">
              <Layers className="mr-2 h-4 w-4" />
              Active Methods
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">9</div>
            <p className="text-xs text-slate-500 mt-1">Vision + Web modules</p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="vision">Vision/OCR</TabsTrigger>
          <TabsTrigger value="web">Web Data</TabsTrigger>
          <TabsTrigger value="tasks">Recent Tasks</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Task Trends */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <TrendingUp className="mr-2 h-5 w-5" />
                  Task Volume Trends
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={taskTrendData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="vision" stroke="#8884d8" strokeWidth={2} />
                    <Line type="monotone" dataKey="web" stroke="#82ca9d" strokeWidth={2} />
                    <Line type="monotone" dataKey="total" stroke="#ff7c7c" strokeWidth={2} />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Method Distribution */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <PieChart className="mr-2 h-5 w-5" />
                  Vision Method Usage
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={methodDistribution}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      outerRadius={100}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {methodDistribution.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600">Vision Tasks</p>
                    <p className="text-2xl font-bold">{visionMetrics.images_processed}</p>
                  </div>
                  <Eye className="h-8 w-8 text-purple-600" />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600">Web Requests</p>
                    <p className="text-2xl font-bold">{webMetrics.pages_fetched}</p>
                  </div>
                  <Globe className="h-8 w-8 text-blue-600" />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600">Multimodal Queries</p>
                    <p className="text-2xl font-bold">{visionMetrics.gpt4v_queries}</p>
                  </div>
                  <Zap className="h-8 w-8 text-yellow-600" />
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Vision/OCR Tab */}
        <TabsContent value="vision" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Images Processed</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{visionMetrics.images_processed}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">OCR Extractions</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{visionMetrics.ocr_extractions}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">GPT-4V Queries</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{visionMetrics.gpt4v_queries}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Avg Confidence</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{(visionMetrics.avg_confidence * 100).toFixed(0)}%</div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Vision Module Performance</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={methodDistribution}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="value" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Web Data Tab */}
        <TabsContent value="web" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Pages Fetched</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{webMetrics.pages_fetched}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Searches</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{webMetrics.searches_performed}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">RSS Feeds</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{webMetrics.rss_feeds_read}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">API Calls</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{webMetrics.apis_called}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">JS Rendered</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{webMetrics.js_pages_rendered}</div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Web Method Distribution</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={webMethodDistribution}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="value" fill="#82ca9d" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Recent Tasks Tab */}
        <TabsContent value="tasks" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Recent Tasks</span>
                <Badge variant="outline">{recentTasks.length} tasks</Badge>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {recentTasks.map((task) => (
                  <div
                    key={task.id}
                    className="flex items-start justify-between p-4 border rounded-lg hover:bg-slate-50 transition-colors"
                  >
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        {task.type === 'vision' && <Eye className="h-4 w-4 text-purple-600" />}
                        {task.type === 'web' && <Globe className="h-4 w-4 text-blue-600" />}
                        {task.type === 'multimodal' && <Zap className="h-4 w-4 text-yellow-600" />}
                        <span className="font-medium text-sm">{task.method}</span>
                        <Badge 
                          variant={task.status === 'success' ? 'default' : 'destructive'}
                          className="text-xs"
                        >
                          {task.status}
                        </Badge>
                      </div>
                      <p className="text-sm text-slate-600">{task.description}</p>
                      {task.error && (
                        <p className="text-xs text-red-600 mt-1 flex items-center">
                          <AlertCircle className="h-3 w-3 mr-1" />
                          {task.error}
                        </p>
                      )}
                    </div>
                    <div className="text-right ml-4">
                      <p className="text-xs text-slate-500">{task.time}</p>
                      <p className="text-xs font-mono mt-1">{task.duration_ms}ms</p>
                      {task.confidence > 0 && (
                        <p className="text-xs text-slate-600 mt-1">
                          {(task.confidence * 100).toFixed(0)}% conf
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Export Actions */}
      <div className="flex justify-end gap-2">
        <Button variant="outline">
          <Download className="mr-2 h-4 w-4" />
          Export CSV
        </Button>
        <Button variant="outline">
          <FileText className="mr-2 h-4 w-4" />
          Generate Report
        </Button>
      </div>
    </div>
  )
}
