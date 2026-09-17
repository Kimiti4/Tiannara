'use client'

import { LineChart, Line, AreaChart, Area, PieChart, Pie, Cell, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts'

const TOOLTIP_STYLE = {
  background: 'rgba(10, 14, 26, 0.95)',
  border: '1px solid rgba(0, 217, 255, 0.3)',
  borderRadius: '6px',
  color: '#e2e8f0',
  fontSize: '11px',
}

export function UptimeSparkline({ data }: { data: { day: string; value: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={80}>
      <AreaChart data={data}>
        <defs>
          <linearGradient id="uptimeGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#00d9ff" stopOpacity={0.3} />
            <stop offset="100%" stopColor="#00d9ff" stopOpacity={0} />
          </linearGradient>
        </defs>
        <Area type="monotone" dataKey="value" stroke="#00d9ff" strokeWidth={1.5} fill="url(#uptimeGrad)" />
        <Tooltip contentStyle={TOOLTIP_STYLE} />
      </AreaChart>
    </ResponsiveContainer>
  )
}

export function DiscoveryChart({ data }: {
  data: { label: string; discoveries: number; validations: number; principles: number }[]
}) {
  return (
    <ResponsiveContainer width="100%" height={120}>
      <LineChart data={data}>
        <CartesianGrid stroke="rgba(0,217,255,0.05)" />
        <XAxis dataKey="label" tick={{ fontSize: 9, fill: '#64748b' }} axisLine={false} tickLine={false} />
        <YAxis tick={{ fontSize: 9, fill: '#64748b' }} axisLine={false} tickLine={false} />
        <Tooltip contentStyle={TOOLTIP_STYLE} />
        <Line type="monotone" dataKey="discoveries" stroke="#00ff9f" strokeWidth={1.5} dot={false} />
        <Line type="monotone" dataKey="validations" stroke="#00d9ff" strokeWidth={1.5} dot={false} />
        <Line type="monotone" dataKey="principles" stroke="#bd00ff" strokeWidth={1.5} dot={false} />
      </LineChart>
    </ResponsiveContainer>
  )
}

export function PipelineDoughnut({ data }: {
  data: { label: string; value: number; color: string }[]
}) {
  return (
    <ResponsiveContainer width="100%" height={120}>
      <PieChart>
        <Pie data={data} cx="50%" cy="50%" innerRadius={30} outerRadius={50} paddingAngle={2} dataKey="value">
          {data.map((e) => <Cell key={e.label} fill={e.color} />)}
        </Pie>
        <Tooltip contentStyle={TOOLTIP_STYLE} />
      </PieChart>
    </ResponsiveContainer>
  )
}

export function ProgressTimeline({ data }: {
  data: { label: string; value: number }[]
}) {
  return (
    <ResponsiveContainer width="100%" height={100}>
      <AreaChart data={data}>
        <defs>
          <linearGradient id="progressGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#00d9ff" stopOpacity={0.3} />
            <stop offset="100%" stopColor="#00d9ff" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid stroke="rgba(0,217,255,0.05)" />
        <XAxis dataKey="label" tick={{ fontSize: 9, fill: '#64748b' }} axisLine={false} tickLine={false} />
        <YAxis domain={[0, 100]} tick={{ fontSize: 9, fill: '#64748b' }} axisLine={false} tickLine={false} />
        <Tooltip contentStyle={TOOLTIP_STYLE} />
        <Area type="monotone" dataKey="value" stroke="#00d9ff" strokeWidth={2} fill="url(#progressGrad)" />
      </AreaChart>
    </ResponsiveContainer>
  )
}

export function ChallengeDoughnut({ data }: {
  data: { label: string; value: number; color: string }[]
}) {
  return (
    <ResponsiveContainer width="100%" height={120}>
      <PieChart>
        <Pie data={data} cx="50%" cy="50%" innerRadius={28} outerRadius={48} paddingAngle={2} dataKey="value">
          {data.map((e) => <Cell key={e.label} fill={e.color} />)}
        </Pie>
        <Tooltip contentStyle={TOOLTIP_STYLE} />
      </PieChart>
    </ResponsiveContainer>
  )
}
