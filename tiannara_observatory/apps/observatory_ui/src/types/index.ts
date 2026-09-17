export interface MissionEvent {
  id: string
  domain: string
  type: string
  payload: Record<string, unknown>
  timestamp: string
  priority?: 'constitutional' | 'scientific' | 'alert' | 'metric' | 'normal' | 'background'
}

export interface StreamBatch {
  topic: string
  events: MissionEvent[]
  count: number
  timestamp: string
  aggregated: boolean
}

export interface WidgetConfig {
  id: string
  type: string
  title: string
  room: string
  x: number
  y: number
  w: number
  h: number
  dataSource?: string
  refreshInterval?: number
}

export interface MissionLayout {
  id: string
  name: string
  mode: MissionMode
  widgets: WidgetConfig[]
  createdAt: string
  updatedAt: string
}

export type MissionMode = 'laboratory' | 'discovery' | 'certification' | 'planetary' | 'civilization' | 'emergency'

export interface RoomConfig {
  slug: string
  name: string
  icon: string
  description: string
}

export interface CommandAction {
  id: string
  label: string
  shortcut?: string
  action: () => void
  category: string
}

export interface Alert {
  id: string
  category: string
  severity: 'info' | 'notice' | 'warning' | 'critical' | 'constitutional' | 'scientific' | 'civilizational'
  message: string
  status: 'active' | 'acknowledged' | 'resolved'
  raisedAt: string
}

export interface HealthStatus {
  status: string
  uptime: number
  constitutionVersion: string
  apiVersion: string
}
