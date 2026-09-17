'use client'

import { useState, useEffect } from 'react'
import { 
  Home, Workflow, Zap, BarChart3, Activity, Users, Key, CreditCard, Settings,
  Search, Bell, Plus, ArrowRight, CheckCircle, TrendingUp, Brain, Shield, Archive,
  Eye, Globe, Sparkles, LogOut, User, ChevronDown
} from 'lucide-react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import OnboardingModal from '@/components/OnboardingModal'
import { apiClient } from '@/lib/api'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [onboardingCompleted, setOnboardingCompleted] = useState(false)
  const [showOnboarding, setShowOnboarding] = useState(false)
  const [expandedSections, setExpandedSections] = useState<string[]>(['workflows'])
  const [profileMenuOpen, setProfileMenuOpen] = useState(false)
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [userProfile, setUserProfile] = useState<any>(null)
  const [notifications, setNotifications] = useState<any[]>([])
  const router = useRouter()

  useEffect(() => {
    const onboarding = localStorage.getItem('tiannara_onboarding')
    if (onboarding) {
      const data = JSON.parse(onboarding)
      setOnboardingCompleted(data.completed)
    } else {
      // First time user - show onboarding
      setShowOnboarding(true)
    }
    
    // Fetch user profile
    fetchUserProfile()
    
    // Fetch notifications
    fetchNotifications()
    
    // Close dropdowns when clicking outside
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement
      if (!target.closest('.profile-menu-container') && !target.closest('.notifications-container')) {
        setProfileMenuOpen(false)
        setNotificationsOpen(false)
      }
    }
    
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const toggleSection = (section: string) => {
    setExpandedSections(prev => 
      prev.includes(section) 
        ? prev.filter(s => s !== section)
        : [...prev, section]
    )
  }

  const fetchUserProfile = async () => {
    try {
      const response = await apiClient.getProfile()
      if (response.success && response.data) {
        setUserProfile(response.data)
      }
    } catch (err) {
      console.error('Failed to fetch user profile:', err)
    }
  }

  const fetchNotifications = async () => {
    try {
      const response = await apiClient.getActivityFeed(10)
      if (response.success && response.data) {
        setNotifications(response.data.slice(0, 5))
      }
    } catch (err) {
      console.error('Failed to fetch notifications:', err)
    }
  }

  const handleLogout = () => {
    apiClient.clearToken()
    router.push('/login')
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      // TODO: Implement search functionality
      console.log('Searching for:', searchQuery)
      alert(`Search functionality coming soon! Query: ${searchQuery}`)
    }
  }

  const sidebarItems = [
    { icon: Sparkles, label: 'Cognitive Workspace', href: '/dashboard/cognitive-workspace', section: 'main', highlight: true },
    { icon: Home, label: 'Dashboard', href: '/dashboard', section: 'main' },
    { icon: Workflow, label: 'Workflows', href: '/dashboard/workflows', section: 'main' },
    { icon: Zap, label: 'Automations', href: '/dashboard/automations', section: 'main' },
    { icon: BarChart3, label: 'Analytics', href: '/dashboard/analytics', section: 'main' },
    { icon: Activity, label: 'Forecasting', href: '/dashboard/forecasting', section: 'main' },
    { icon: Brain, label: 'Cognitive Domains', href: '/dashboard/cognitive-domains', section: 'cognitive' },
    { icon: Activity, label: 'Monitoring', href: '/dashboard/monitoring', section: 'cognitive' },
    { icon: Archive, label: 'Failure Museum', href: '/dashboard/failure-museum', section: 'cognitive' },
    { icon: Eye, label: 'Vision & Web', href: '/dashboard/vision-web-monitoring', section: 'intelligence' },
    { icon: Users, label: 'Team', href: '/dashboard/team', section: 'workspace' },
    { icon: Key, label: 'API Access', href: '/dashboard/keys', section: 'workspace' },
    { icon: CreditCard, label: 'Billing', href: '/dashboard/billing', section: 'workspace' },
    { icon: Settings, label: 'Settings', href: '/dashboard/settings', section: 'workspace' },
  ]

  const workflowSubItems = [
    { label: 'All Workflows', href: '/dashboard/workflows' },
    { label: 'Templates', href: '/dashboard/workflows/templates' },
  ]

  return (
    <div className="min-h-screen bg-slate-950 flex">
      {/* Sidebar */}
      <aside className={`${sidebarOpen ? 'w-64' : 'w-20'} bg-slate-900 border-r border-slate-800 transition-all duration-300 flex flex-col`}>
        {/* Logo */}
        <div className="p-6 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-xl flex items-center justify-center flex-shrink-0">
              <Workflow className="w-5 h-5 text-white" />
            </div>
            {sidebarOpen && <span className="text-xl font-bold text-white">Tiannara</span>}
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-6 overflow-y-auto">
          {/* Main Section */}
          {sidebarOpen && (
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 px-3">
                Main
              </p>
              <div className="space-y-1">
                {sidebarItems.filter(item => item.section === 'main').map((item) => {
                  const Icon = item.icon
                  const hasSubItems = item.label === 'Workflows'
                  const isExpanded = expandedSections.includes('workflows')
                  const isHighlight = (item as any).highlight
                  
                  return (
                    <div key={item.href}>
                      <Link
                        href={item.href}
                        className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all ${
                          isHighlight
                            ? 'bg-gradient-to-r from-purple-600/20 to-cyan-600/20 border border-purple-500/50 text-white hover:from-purple-600/30 hover:to-cyan-600/30'
                            : 'text-slate-400 hover:text-white hover:bg-slate-800'
                        }`}
                      >
                        <Icon className={`w-5 h-5 flex-shrink-0 ${isHighlight ? 'text-purple-400' : ''}`} />
                        <span className="text-sm flex-1 text-left font-medium">{item.label}</span>
                        {isHighlight && (
                          <span className="text-xs bg-purple-500 text-white px-2 py-0.5 rounded-full">NEW</span>
                        )}
                      </Link>
                      {hasSubItems && isExpanded && (
                        <div className="ml-8 mt-1 space-y-1">
                          {workflowSubItems.map((subItem) => (
                            <Link
                              key={subItem.href}
                              href={subItem.href}
                              className="block px-3 py-1.5 rounded-lg text-sm text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                            >
                              {subItem.label}
                            </Link>
                          ))}
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* Cognitive Infrastructure Section */}
          {sidebarOpen && (
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 px-3">
                Cognitive Infrastructure
              </p>
              <div className="space-y-1">
                {sidebarItems.filter(item => item.section === 'cognitive').map((item) => {
                  const Icon = item.icon
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                      <Icon className="w-5 h-5 flex-shrink-0" />
                      {sidebarOpen && <span className="text-sm">{item.label}</span>}
                    </Link>
                  )
                })}
              </div>
            </div>
          )}

          {/* Intelligence Modules Section */}
          {sidebarOpen && (
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 px-3">
                Intelligence Modules
              </p>
              <div className="space-y-1">
                {sidebarItems.filter(item => item.section === 'intelligence').map((item) => {
                  const Icon = item.icon
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                      <Icon className="w-5 h-5 flex-shrink-0" />
                      {sidebarOpen && <span className="text-sm">{item.label}</span>}
                    </Link>
                  )
                })}
              </div>
            </div>
          )}

          {/* Workspace Section */}
          {sidebarOpen && (
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 px-3">
                Workspace
              </p>
              <div className="space-y-1">
                {sidebarItems.filter(item => item.section === 'workspace').map((item) => {
                  const Icon = item.icon
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                      <Icon className="w-5 h-5 flex-shrink-0" />
                      {sidebarOpen && <span className="text-sm">{item.label}</span>}
                    </Link>
                  )
                })}
              </div>
            </div>
          )}
        </nav>

        {/* Toggle Button */}
        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="p-4 border-t border-slate-800 text-slate-400 hover:text-white transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
              </svg>
            </div>
            {sidebarOpen && <span className="text-sm">Collapse</span>}
          </div>
        </button>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        {/* Topbar */}
        <header className="h-16 bg-slate-900/50 border-b border-slate-800 flex items-center justify-between px-6">
          <div className="flex items-center gap-4 flex-1">
            <form onSubmit={handleSearch} className="flex items-center gap-2 px-3 py-2 bg-slate-800 rounded-lg max-w-md w-full">
              <Search className="w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search workflows, projects..."
                className="bg-transparent text-sm text-white placeholder-slate-400 outline-none flex-1"
              />
            </form>
          </div>
          
          <div className="flex items-center gap-4">
            {/* Notifications */}
            <div className="relative notifications-container">
              <button 
                onClick={() => {
                  setNotificationsOpen(!notificationsOpen)
                  setProfileMenuOpen(false)
                }}
                className="relative p-2 text-slate-400 hover:text-white transition-colors"
              >
                <Bell className="w-5 h-5" />
                {notifications.length > 0 && (
                  <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
                )}
              </button>
              
              {/* Notifications Dropdown */}
              {notificationsOpen && (
                <div className="absolute right-0 mt-2 w-80 bg-slate-900 border border-slate-800 rounded-xl shadow-2xl z-50">
                  <div className="p-4 border-b border-slate-800">
                    <h3 className="text-white font-semibold">Notifications</h3>
                  </div>
                  <div className="max-h-96 overflow-y-auto">
                    {notifications.length === 0 ? (
                      <div className="p-8 text-center">
                        <Bell className="w-12 h-12 text-slate-700 mx-auto mb-3" />
                        <p className="text-slate-400 text-sm">No new notifications</p>
                      </div>
                    ) : (
                      notifications.map((notification, idx) => (
                        <div key={idx} className="p-4 border-b border-slate-800 hover:bg-slate-800/50 transition-colors">
                          <p className="text-sm text-white">{notification.description || notification.action}</p>
                          <p className="text-xs text-slate-400 mt-1">
                            {notification.timestamp ? new Date(notification.timestamp).toLocaleString() : 'Recent'}
                          </p>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>
            
            {/* Profile Menu */}
            <div className="relative profile-menu-container">
              <button
                onClick={() => {
                  setProfileMenuOpen(!profileMenuOpen)
                  setNotificationsOpen(false)
                }}
                className="flex items-center gap-3 pl-4 border-l border-slate-800 hover:bg-slate-800/50 rounded-lg px-3 py-2 transition-colors"
              >
                <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-medium">
                    {userProfile?.name?.charAt(0) || userProfile?.email?.charAt(0) || 'U'}
                  </span>
                </div>
                <div className="hidden md:block text-left">
                  <p className="text-sm text-white font-medium">
                    {userProfile?.name || userProfile?.email || 'User'}
                  </p>
                  <p className="text-xs text-slate-400 capitalize">
                    {userProfile?.tier || 'Starter'} Plan
                  </p>
                </div>
                <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform ${profileMenuOpen ? 'rotate-180' : ''}`} />
              </button>
              
              {/* Profile Dropdown */}
              {profileMenuOpen && (
                <div className="absolute right-0 mt-2 w-64 bg-slate-900 border border-slate-800 rounded-xl shadow-2xl z-50">
                  <div className="p-4 border-b border-slate-800">
                    <p className="text-white font-semibold">{userProfile?.name || 'User'}</p>
                    <p className="text-sm text-slate-400">{userProfile?.email}</p>
                    <p className="text-xs text-purple-400 mt-1 capitalize">{userProfile?.tier || 'starter'} Plan</p>
                  </div>
                  <div className="p-2">
                    <Link
                      href="/dashboard/settings"
                      onClick={() => setProfileMenuOpen(false)}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                      <User className="w-4 h-4" />
                      <span className="text-sm">Profile Settings</span>
                    </Link>
                    <Link
                      href="/dashboard/billing"
                      onClick={() => setProfileMenuOpen(false)}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                      <CreditCard className="w-4 h-4" />
                      <span className="text-sm">Billing & Subscription</span>
                    </Link>
                    <Link
                      href="/dashboard/team"
                      onClick={() => setProfileMenuOpen(false)}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                      <Users className="w-4 h-4" />
                      <span className="text-sm">Team Management</span>
                    </Link>
                  </div>
                  <div className="p-2 border-t border-slate-800">
                    <button
                      onClick={handleLogout}
                      className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-red-400 hover:text-red-300 hover:bg-red-500/10 transition-colors"
                    >
                      <LogOut className="w-4 h-4" />
                      <span className="text-sm">Sign Out</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-8">
          {children}
        </main>
      </div>

      {/* Onboarding Modal */}
      {showOnboarding && (
        <OnboardingModal onClose={() => setShowOnboarding(false)} />
      )}
    </div>
  )
}
