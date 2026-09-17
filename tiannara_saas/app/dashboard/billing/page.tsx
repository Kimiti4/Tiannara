'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import {
  CreditCard,
  Download,
  ArrowUpRight,
  CheckCircle2,
  AlertCircle,
  Clock,
  TrendingUp,
  Zap,
  Shield,
  Crown
} from 'lucide-react'
import { apiClient } from '@/lib/api'

interface Subscription {
  id: string
  plan: 'free' | 'starter' | 'professional' | 'enterprise'
  status: 'active' | 'cancelled' | 'past_due' | 'trialing'
  current_period_start: string
  current_period_end: string
  amount: number
  currency: string
  usage: {
    api_calls: {
      current: number
      limit: number
      percentage: number
    }
    workflows: {
      current: number
      limit: number
      percentage: number
    }
    storage: {
      current: number
      limit: number
      percentage: number
    }
  }
}

interface PaymentHistory {
  id: string
  amount: number
  currency: string
  status: 'paid' | 'pending' | 'failed'
  invoice_number: string
  created_at: string
  description: string
  download_url?: string
}

interface PlanUpgrade {
  name: string
  price: number
  features: string[]
  popular?: boolean
}

export default function BillingPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(true)
  const [subscription, setSubscription] = useState<Subscription | null>(null)
  const [paymentHistory, setPaymentHistory] = useState<PaymentHistory[]>([])
  const [showUpgradeModal, setShowUpgradeModal] = useState(false)

  useEffect(() => {
    fetchBillingData()
  }, [])

  const fetchBillingData = async () => {
    try {
      setLoading(true)
      
      // Fetch subscription info
      const subResponse = await apiClient.getSubscription()
      if (subResponse.success && subResponse.data) {
        setSubscription(subResponse.data)
      }
      
      // Fetch payment history
      const paymentResponse = await apiClient.getPaymentHistory()
      if (paymentResponse.success && paymentResponse.data) {
        setPaymentHistory(paymentResponse.data)
      }
    } catch (error) {
      console.error('Failed to fetch billing data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleUpgrade = async (plan: string) => {
    try {
      const response = await apiClient.createCheckoutSession(
        plan,
        `${window.location.origin}/dashboard/billing/success`,
        `${window.location.origin}/dashboard/billing`
      )
      
      if (response.success && response.data?.checkout_url) {
        window.location.href = response.data.checkout_url
      }
    } catch (error) {
      console.error('Failed to create checkout session:', error)
      alert('Failed to initiate upgrade. Please try again.')
    }
  }

  const handleDownloadInvoice = async (paymentId: string) => {
    try {
      // TODO: Implement invoice download endpoint
      alert('Invoice download will be available soon.')
    } catch (error) {
      console.error('Failed to download invoice:', error)
      alert('Failed to download invoice. Please try again.')
    }
  }

  const planUpgradeOptions: PlanUpgrade[] = [
    {
      name: 'Starter',
      price: 49,
      features: [
        '5,000 API calls/month',
        '10 workflows',
        '5 GB storage',
        'Email support',
        'Basic analytics'
      ]
    },
    {
      name: 'Professional',
      price: 199,
      features: [
        '50,000 API calls/month',
        '50 workflows',
        '50 GB storage',
        'Priority support',
        'Advanced analytics',
        'Custom alert rules',
        'Team collaboration (5 members)'
      ],
      popular: true
    },
    {
      name: 'Enterprise',
      price: 999,
      features: [
        'Unlimited API calls',
        'Unlimited workflows',
        '500 GB storage',
        '24/7 dedicated support',
        'Custom integrations',
        'SSO/SAML',
        'White-label branding',
        'Team collaboration (unlimited)'
      ]
    }
  ]

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-500/10 text-green-400 border-green-500/20',
      cancelled: 'bg-red-500/10 text-red-400 border-red-500/20',
      past_due: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
      trialing: 'bg-blue-500/10 text-blue-400 border-blue-500/20'
    }
    
    const icons = {
      active: CheckCircle2,
      cancelled: AlertCircle,
      past_due: Clock,
      trialing: Zap
    }
    
    const Icon = icons[status as keyof typeof icons] || AlertCircle
    
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles]}`}>
        <Icon className="w-3.5 h-3.5" />
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  const getPlanIcon = (plan: string) => {
    const icons = {
      free: Shield,
      starter: Zap,
      professional: TrendingUp,
      enterprise: Crown
    }
    const Icon = icons[plan as keyof typeof icons] || Shield
    return <Icon className="w-5 h-5" />
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  const formatCurrency = (amount: number, currency: string = 'USD') => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency
    }).format(amount / 100)
  }

  const getUsageColor = (percentage: number) => {
    if (percentage >= 90) return 'text-red-400'
    if (percentage >= 70) return 'text-yellow-400'
    return 'text-green-400'
  }

  const getUsageBarColor = (percentage: number) => {
    if (percentage >= 90) return 'bg-red-500'
    if (percentage >= 70) return 'bg-yellow-500'
    return 'bg-green-500'
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-2 border-purple-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-slate-400">Loading billing information...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-950 p-6">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Billing & Subscription</h1>
          <p className="text-slate-400">Manage your subscription, view usage, and download invoices</p>
        </div>

        {/* Current Subscription */}
        {subscription && (
          <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
            <div className="flex items-start justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-purple-500/10 rounded-lg">
                  {getPlanIcon(subscription.plan)}
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-white capitalize">{subscription.plan} Plan</h2>
                  <p className="text-sm text-slate-400">
                    {formatCurrency(subscription.amount)}/{subscription.amount > 0 ? 'month' : 'forever'}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                {getStatusBadge(subscription.status)}
                {subscription.plan !== 'enterprise' && (
                  <button
                    onClick={() => setShowUpgradeModal(true)}
                    className="flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm font-medium transition-colors"
                  >
                    <ArrowUpRight className="w-4 h-4" />
                    Upgrade
                  </button>
                )}
              </div>
            </div>

            {/* Billing Period */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="bg-slate-800/50 rounded-lg p-4">
                <p className="text-xs text-slate-400 mb-1">Current Period Start</p>
                <p className="text-white font-medium">{formatDate(subscription.current_period_start)}</p>
              </div>
              <div className="bg-slate-800/50 rounded-lg p-4">
                <p className="text-xs text-slate-400 mb-1">Next Billing Date</p>
                <p className="text-white font-medium">{formatDate(subscription.current_period_end)}</p>
              </div>
            </div>

            {/* Usage Limits */}
            <div className="space-y-4">
              <h3 className="text-sm font-semibold text-slate-300">Usage This Month</h3>
              
              {/* API Calls */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-slate-400">API Calls</span>
                  <span className={`text-sm font-medium ${getUsageColor(subscription.usage.api_calls.percentage)}`}>
                    {subscription.usage.api_calls.current.toLocaleString()} / {subscription.usage.api_calls.limit.toLocaleString()}
                  </span>
                </div>
                <div className="w-full bg-slate-800 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${getUsageBarColor(subscription.usage.api_calls.percentage)}`}
                    style={{ width: `${subscription.usage.api_calls.percentage}%` }}
                  ></div>
                </div>
              </div>

              {/* Workflows */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-slate-400">Active Workflows</span>
                  <span className={`text-sm font-medium ${getUsageColor(subscription.usage.workflows.percentage)}`}>
                    {subscription.usage.workflows.current} / {subscription.usage.workflows.limit}
                  </span>
                </div>
                <div className="w-full bg-slate-800 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${getUsageBarColor(subscription.usage.workflows.percentage)}`}
                    style={{ width: `${subscription.usage.workflows.percentage}%` }}
                  ></div>
                </div>
              </div>

              {/* Storage */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-slate-400">Storage</span>
                  <span className={`text-sm font-medium ${getUsageColor(subscription.usage.storage.percentage)}`}>
                    {subscription.usage.storage.current} GB / {subscription.usage.storage.limit} GB
                  </span>
                </div>
                <div className="w-full bg-slate-800 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${getUsageBarColor(subscription.usage.storage.percentage)}`}
                    style={{ width: `${subscription.usage.storage.percentage}%` }}
                  ></div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Payment History */}
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-6">Payment History</h2>
          
          {paymentHistory.length === 0 ? (
            <div className="text-center py-12">
              <CreditCard className="w-12 h-12 text-slate-600 mx-auto mb-4" />
              <p className="text-slate-400">No payment history yet</p>
            </div>
          ) : (
            <div className="space-y-3">
              {paymentHistory.map((payment) => (
                <div
                  key={payment.id}
                  className="flex items-center justify-between p-4 bg-slate-800/50 rounded-lg hover:bg-slate-800 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <div className={`p-2 rounded-lg ${
                      payment.status === 'paid' ? 'bg-green-500/10' :
                      payment.status === 'pending' ? 'bg-yellow-500/10' :
                      'bg-red-500/10'
                    }`}>
                      <CreditCard className={`w-5 h-5 ${
                        payment.status === 'paid' ? 'text-green-400' :
                        payment.status === 'pending' ? 'text-yellow-400' :
                        'text-red-400'
                      }`} />
                    </div>
                    <div>
                      <p className="text-white font-medium">{payment.description}</p>
                      <p className="text-sm text-slate-400">
                        {payment.invoice_number} • {formatDate(payment.created_at)}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className={`text-sm font-medium ${
                      payment.status === 'paid' ? 'text-green-400' :
                      payment.status === 'pending' ? 'text-yellow-400' :
                      'text-red-400'
                    }`}>
                      {formatCurrency(payment.amount, payment.currency)}
                    </span>
                    {payment.status === 'paid' && (
                      <button
                        onClick={() => handleDownloadInvoice(payment.id)}
                        className="p-2 text-slate-400 hover:text-white hover:bg-slate-700 rounded-lg transition-colors"
                        title="Download Invoice"
                      >
                        <Download className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Upgrade Modal */}
        {showUpgradeModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold text-white">Upgrade Your Plan</h2>
                <button
                  onClick={() => setShowUpgradeModal(false)}
                  className="text-slate-400 hover:text-white transition-colors"
                >
                  ✕
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {planUpgradeOptions.map((plan) => (
                  <div
                    key={plan.name}
                    className={`relative p-6 rounded-xl border ${
                      plan.popular
                        ? 'bg-purple-500/10 border-purple-500/50'
                        : 'bg-slate-800/50 border-slate-700'
                    }`}
                  >
                    {plan.popular && (
                      <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 bg-purple-600 text-white text-xs font-medium rounded-full">
                        Most Popular
                      </div>
                    )}
                    
                    <h3 className="text-xl font-bold text-white mb-2">{plan.name}</h3>
                    <p className="text-3xl font-bold text-white mb-4">
                      ${plan.price}<span className="text-sm text-slate-400 font-normal">/month</span>
                    </p>
                    
                    <ul className="space-y-2 mb-6">
                      {plan.features.map((feature, idx) => (
                        <li key={idx} className="flex items-start gap-2 text-sm text-slate-300">
                          <CheckCircle2 className="w-4 h-4 text-green-400 flex-shrink-0 mt-0.5" />
                          {feature}
                        </li>
                      ))}
                    </ul>
                    
                    <button
                      onClick={() => handleUpgrade(plan.name.toLowerCase())}
                      className={`w-full py-3 rounded-lg font-medium transition-colors ${
                        plan.popular
                          ? 'bg-purple-600 hover:bg-purple-700 text-white'
                          : 'bg-slate-700 hover:bg-slate-600 text-white'
                      }`}
                    >
                      Upgrade to {plan.name}
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
