'use client'

import { useState } from 'react'
import { Activity, TrendingUp, AlertTriangle, CheckCircle } from 'lucide-react'
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'

const usageData = [
  { date: 'Mon', requests: 1247, success: 1240, errors: 7 },
  { date: 'Tue', requests: 1532, success: 1525, errors: 7 },
  { date: 'Wed', requests: 1891, success: 1880, errors: 11 },
  { date: 'Thu', requests: 2103, success: 2095, errors: 8 },
  { date: 'Fri', requests: 1876, success: 1868, errors: 8 },
  { date: 'Sat', requests: 945, success: 942, errors: 3 },
  { date: 'Sun', requests: 823, success: 820, errors: 3 },
]

const domainUsage = [
  { name: 'Algorithm', value: 35, color: '#8b5cf6' },
  { name: 'Prediction', value: 28, color: '#06b6d4' },
  { name: 'NLP', value: 20, color: '#10b981' },
  { name: 'Causal', value: 12, color: '#f59e0b' },
  { name: 'Logic', value: 5, color: '#ef4444' },
]

export default function UsagePage() {
  const [timeRange, setTimeRange] = useState<'7d' | '30d' | '90d'>('7d')
  
  const currentPlan = {
    name: 'Starter',
    limit: 5000,
    used: 12847,
    resetDate: 'May 15, 2026'
  }

  const usagePercentage = Math.min((currentPlan.used / currentPlan.limit) * 100, 100)
  const isNearLimit = usagePercentage > 80

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">API Usage</h1>
          <p className="text-slate-400">Monitor your API consumption and performance metrics</p>
        </div>
        
        {/* Time Range Selector */}
        <div className="flex gap-2 bg-slate-900 border border-slate-800 rounded-xl p-1">
          {(['7d', '30d', '90d'] as const).map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                timeRange === range
                  ? 'bg-purple-600 text-white'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              {range === '7d' ? 'Last 7 days' : range === '30d' ? 'Last 30 days' : 'Last 90 days'}
            </button>
          ))}
        </div>
      </div>

      {/* Usage Quota Banner */}
      <div className={`rounded-xl p-6 mb-8 ${isNearLimit ? 'bg-orange-500/10 border border-orange-500/30' : 'bg-slate-900/50 border border-slate-800'}`}>
        <div className="flex items-start justify-between mb-4">
          <div>
            <h2 className="text-lg font-semibold text-white mb-1">{currentPlan.name} Plan</h2>
            <p className="text-slate-400 text-sm">
              {currentPlan.used.toLocaleString()} / {currentPlan.limit.toLocaleString()} requests this month
            </p>
          </div>
          {isNearLimit && (
            <div className="flex items-center gap-2 text-orange-400">
              <AlertTriangle className="w-5 h-5" />
              <span className="font-medium">Near limit</span>
            </div>
          )}
        </div>
        
        {/* Progress Bar */}
        <div className="w-full bg-slate-800 rounded-full h-3 mb-2">
          <div
            className={`h-3 rounded-full transition-all ${isNearLimit ? 'bg-orange-500' : 'bg-purple-600'}`}
            style={{ width: `${usagePercentage}%` }}
          />
        </div>
        
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-400">{usagePercentage.toFixed(1)}% used</span>
          <span className="text-slate-400">Resets {currentPlan.resetDate}</span>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Total Requests"
          value="12,847"
          change="+18.2%"
          trend="up"
          icon={Activity}
          color="purple"
        />
        <StatCard
          title="Success Rate"
          value="99.7%"
          change="+0.3%"
          trend="up"
          icon={CheckCircle}
          color="green"
        />
        <StatCard
          title="Avg Latency"
          value="124ms"
          change="-12ms"
          trend="down"
          icon={TrendingUp}
          color="cyan"
        />
        <StatCard
          title="Error Count"
          value="47"
          change="-23%"
          trend="down"
          icon={AlertTriangle}
          color="orange"
        />
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Request Volume Chart */}
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-6">Request Volume</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={usageData}>
              <defs>
                <linearGradient id="colorRequests" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="date" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#f1f5f9' }}
              />
              <Area type="monotone" dataKey="requests" stroke="#8b5cf6" fillOpacity={1} fill="url(#colorRequests)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Success vs Errors Chart */}
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-6">Success vs Errors</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={usageData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="date" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#f1f5f9' }}
              />
              <Bar dataKey="success" fill="#10b981" radius={[4, 4, 0, 0]} />
              <Bar dataKey="errors" fill="#ef4444" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Domain Usage Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-6">Domain Engine Usage</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={domainUsage}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                paddingAngle={5}
                dataKey="value"
              >
                {domainUsage.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#f1f5f9' }}
              />
            </PieChart>
          </ResponsiveContainer>
          
          {/* Legend */}
          <div className="grid grid-cols-2 gap-4 mt-4">
            {domainUsage.map((domain) => (
              <div key={domain.name} className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: domain.color }} />
                <span className="text-sm text-slate-400">{domain.name}</span>
                <span className="text-sm text-white font-medium ml-auto">{domain.value}%</span>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Activity Log */}
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-6">Recent Activity</h3>
          <div className="space-y-4">
            {[
              { endpoint: '/api/v1/predict', status: 200, latency: '124ms', time: '2 min ago' },
              { endpoint: '/api/v1/analyze', status: 200, latency: '89ms', time: '5 min ago' },
              { endpoint: '/api/v1/classify', status: 200, latency: '156ms', time: '12 min ago' },
              { endpoint: '/api/v1/reason', status: 500, latency: '2.3s', time: '18 min ago' },
              { endpoint: '/api/v1/predict', status: 200, latency: '98ms', time: '25 min ago' },
            ].map((request, idx) => (
              <div key={idx} className="flex items-center justify-between py-3 border-b border-slate-800 last:border-0">
                <div>
                  <code className="text-sm text-purple-400">{request.endpoint}</code>
                  <p className="text-xs text-slate-500 mt-1">{request.time}</p>
                </div>
                <div className="flex items-center gap-4">
                  <span className={`text-sm font-medium ${request.status === 200 ? 'text-green-400' : 'text-red-400'}`}>
                    {request.status}
                  </span>
                  <span className="text-sm text-slate-400">{request.latency}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function StatCard({ title, value, change, trend, icon: Icon, color }: any) {
  const colorClasses = {
    purple: 'from-purple-500 to-purple-600',
    green: 'from-green-500 to-green-600',
    cyan: 'from-cyan-500 to-cyan-600',
    orange: 'from-orange-500 to-orange-600',
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      <div className="flex items-start justify-between mb-4">
        <div className={`w-12 h-12 bg-gradient-to-br ${colorClasses[color as keyof typeof colorClasses]} rounded-xl flex items-center justify-center`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        <span className={`text-sm font-medium ${trend === 'up' ? 'text-green-400' : 'text-red-400'}`}>
          {change}
        </span>
      </div>
      <h3 className="text-2xl font-bold text-white mb-1">{value}</h3>
      <p className="text-sm text-slate-400">{title}</p>
    </div>
  )
}
