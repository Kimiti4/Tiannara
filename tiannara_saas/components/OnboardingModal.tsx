'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { 
  BarChart3, Workflow, Brain, Zap, Search, Bell,
  CheckCircle, ArrowRight, Sparkles
} from 'lucide-react'
import { apiClient } from '@/lib/api'

interface OnboardingData {
  useCase: string | null
  userType: string | null
  completed: boolean
  completedAt?: string
}

const USE_CASES = [
  {
    id: 'analytics',
    title: 'Analytics & Insights',
    description: 'Analyze data, discover patterns, and generate actionable insights',
    icon: BarChart3,
    color: 'blue',
    recommendedTemplates: ['customer_segmentation', 'business_monitoring']
  },
  {
    id: 'automation',
    title: 'Workflow Automation',
    description: 'Automate repetitive tasks and build intelligent pipelines',
    icon: Workflow,
    color: 'purple',
    recommendedTemplates: ['fraud_detection', 'prediction_pipeline']
  },
  {
    id: 'decision_support',
    title: 'AI Decision Support',
    description: 'Get AI-powered recommendations for critical decisions',
    icon: Brain,
    color: 'green',
    recommendedTemplates: ['root_cause_analysis', 'marketing_analysis']
  },
  {
    id: 'prediction',
    title: 'Prediction Systems',
    description: 'Forecast trends and predict future outcomes',
    icon: Zap,
    color: 'orange',
    recommendedTemplates: ['prediction_pipeline', 'business_monitoring']
  },
  {
    id: 'research',
    title: 'Research & Analysis',
    description: 'Conduct deep research and comprehensive analysis',
    icon: Search,
    color: 'indigo',
    recommendedTemplates: ['root_cause_analysis', 'customer_segmentation']
  },
  {
    id: 'monitoring',
    title: 'Monitoring & Alerts',
    description: 'Monitor systems and get alerts for important events',
    icon: Bell,
    color: 'red',
    recommendedTemplates: ['business_monitoring', 'fraud_detection']
  }
]

const USER_TYPES = [
  {
    id: 'solo',
    title: 'Solo Project',
    description: 'Working on personal projects or experiments',
    features: ['Basic workflows', 'Personal dashboard', '5K API requests/month']
  },
  {
    id: 'startup',
    title: 'Startup Team',
    description: 'Small team building a product or service',
    features: ['Team collaboration', 'Shared workflows', '50K API requests/month']
  },
  {
    id: 'internal',
    title: 'Internal Business Tool',
    description: 'Building tools for internal business operations',
    features: ['Advanced automation', 'Custom integrations', 'Priority support']
  },
  {
    id: 'customer_facing',
    title: 'Customer-Facing Product',
    description: 'Building products that customers will use directly',
    features: ['White-label options', 'SLA guarantees', 'Enterprise features']
  },
  {
    id: 'research',
    title: 'Research/Academic',
    description: 'Academic research or experimental projects',
    features: ['Research templates', 'Data export', 'Collaboration tools']
  }
]

export default function OnboardingModal({ onClose }: { onClose?: () => void }) {
  const router = useRouter()
  const [step, setStep] = useState<1 | 2 | 3>(1)
  const [selectedUseCase, setSelectedUseCase] = useState<string | null>(null)
  const [selectedUserType, setSelectedUserType] = useState<string | null>(null)
  const [isCompleting, setIsCompleting] = useState(false)

  // Check if onboarding was already completed
  useEffect(() => {
    const onboarding = localStorage.getItem('tiannara_onboarding')
    if (onboarding) {
      const data: OnboardingData = JSON.parse(onboarding)
      if (data.completed) {
        // Already completed, close modal
        if (onClose) onClose()
      }
    }
  }, [onClose])

  const handleUseCaseSelect = (useCaseId: string) => {
    setSelectedUseCase(useCaseId)
  }

  const handleUserTypeSelect = (userTypeId: string) => {
    setSelectedUserType(userTypeId)
  }

  const handleComplete = async () => {
    if (!selectedUseCase || !selectedUserType) return

    setIsCompleting(true)

    try {
      // Save onboarding data
      const onboardingData: OnboardingData = {
        useCase: selectedUseCase,
        userType: selectedUserType,
        completed: true,
        completedAt: new Date().toISOString()
      }

      localStorage.setItem('tiannara_onboarding', JSON.stringify(onboardingData))

      // Get recommended templates based on selections
      const useCase = USE_CASES.find(uc => uc.id === selectedUseCase)
      
      // Show completion message briefly
      await new Promise(resolve => setTimeout(resolve, 1000))

      // Redirect to dashboard with template suggestions
      if (onClose) {
        onClose()
      } else {
        router.push('/dashboard')
      }
    } catch (error) {
      console.error('Failed to complete onboarding:', error)
    } finally {
      setIsCompleting(false)
    }
  }

  const handleSkip = () => {
    // Mark as completed even if skipped
    const onboardingData: OnboardingData = {
      useCase: null,
      userType: null,
      completed: true,
      completedAt: new Date().toISOString()
    }
    localStorage.setItem('tiannara_onboarding', JSON.stringify(onboardingData))
    
    if (onClose) {
      onClose()
    } else {
      router.push('/dashboard')
    }
  }

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="p-8 border-b border-slate-800">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-xl flex items-center justify-center">
              <Sparkles className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-white">Welcome to Tiannara</h1>
              <p className="text-slate-400">Let's personalize your experience</p>
            </div>
          </div>

          {/* Progress Steps */}
          <div className="flex items-center gap-2 mt-6">
            <div className={`flex items-center gap-2 ${step >= 1 ? 'text-purple-400' : 'text-slate-600'}`}>
              <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                step >= 1 ? 'border-purple-500 bg-purple-500/20' : 'border-slate-700'
              }`}>
                <span className="text-sm font-semibold">1</span>
              </div>
              <span className="text-sm font-medium">What to build</span>
            </div>
            <div className={`flex-1 h-0.5 ${step >= 2 ? 'bg-purple-500' : 'bg-slate-700'}`} />
            <div className={`flex items-center gap-2 ${step >= 2 ? 'text-purple-400' : 'text-slate-600'}`}>
              <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                step >= 2 ? 'border-purple-500 bg-purple-500/20' : 'border-slate-700'
              }`}>
                <span className="text-sm font-semibold">2</span>
              </div>
              <span className="text-sm font-medium">How you'll use it</span>
            </div>
            <div className={`flex-1 h-0.5 ${step >= 3 ? 'bg-purple-500' : 'bg-slate-700'}`} />
            <div className={`flex items-center gap-2 ${step >= 3 ? 'text-purple-400' : 'text-slate-600'}`}>
              <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                step >= 3 ? 'border-purple-500 bg-purple-500/20' : 'border-slate-700'
              }`}>
                <CheckCircle className="w-4 h-4" />
              </div>
              <span className="text-sm font-medium">Ready</span>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-8">
          {step === 1 && (
            <div>
              <h2 className="text-xl font-semibold text-white mb-2">
                What would you like to build today?
              </h2>
              <p className="text-slate-400 mb-6">
                Select the primary use case that best matches your goals
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {USE_CASES.map((useCase) => {
                  const Icon = useCase.icon
                  const isSelected = selectedUseCase === useCase.id
                  
                  return (
                    <button
                      key={useCase.id}
                      onClick={() => handleUseCaseSelect(useCase.id)}
                      className={`p-6 rounded-xl border-2 text-left transition-all ${
                        isSelected
                          ? `border-${useCase.color}-500 bg-${useCase.color}-500/10`
                          : 'border-slate-700 bg-slate-800/50 hover:border-slate-600'
                      }`}
                    >
                      <div className="flex items-start gap-4">
                        <div className={`w-12 h-12 rounded-lg bg-${useCase.color}-500/20 flex items-center justify-center flex-shrink-0`}>
                          <Icon className={`w-6 h-6 text-${useCase.color}-400`} />
                        </div>
                        <div className="flex-1">
                          <h3 className="text-lg font-semibold text-white mb-1">
                            {useCase.title}
                          </h3>
                          <p className="text-sm text-slate-400">
                            {useCase.description}
                          </p>
                        </div>
                        {isSelected && (
                          <CheckCircle className="w-6 h-6 text-purple-400 flex-shrink-0" />
                        )}
                      </div>
                    </button>
                  )
                })}
              </div>
            </div>
          )}

          {step === 2 && (
            <div>
              <h2 className="text-xl font-semibold text-white mb-2">
                How will you use Tiannara?
              </h2>
              <p className="text-slate-400 mb-6">
                This helps us configure the right features and templates for you
              </p>

              <div className="space-y-4">
                {USER_TYPES.map((userType) => {
                  const isSelected = selectedUserType === userType.id
                  
                  return (
                    <button
                      key={userType.id}
                      onClick={() => handleUserTypeSelect(userType.id)}
                      className={`w-full p-6 rounded-xl border-2 text-left transition-all ${
                        isSelected
                          ? 'border-purple-500 bg-purple-500/10'
                          : 'border-slate-700 bg-slate-800/50 hover:border-slate-600'
                      }`}
                    >
                      <div className="flex items-start gap-4">
                        <div className="flex-1">
                          <h3 className="text-lg font-semibold text-white mb-2">
                            {userType.title}
                          </h3>
                          <p className="text-sm text-slate-400 mb-3">
                            {userType.description}
                          </p>
                          <div className="flex flex-wrap gap-2">
                            {userType.features.map((feature, idx) => (
                              <span
                                key={idx}
                                className="px-3 py-1 bg-slate-800 text-slate-300 text-xs rounded-full"
                              >
                                {feature}
                              </span>
                            ))}
                          </div>
                        </div>
                        {isSelected && (
                          <CheckCircle className="w-6 h-6 text-purple-400 flex-shrink-0" />
                        )}
                      </div>
                    </button>
                  )
                })}
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="text-center py-8">
              <div className="w-20 h-20 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-full flex items-center justify-center mx-auto mb-6">
                <CheckCircle className="w-10 h-10 text-white" />
              </div>
              <h2 className="text-2xl font-bold text-white mb-4">
                You're all set!
              </h2>
              <p className="text-slate-400 mb-8 max-w-md mx-auto">
                We've personalized your workspace based on your selections. 
                Let's get started with some recommended templates.
              </p>

              {selectedUseCase && (
                <div className="bg-slate-800/50 rounded-xl p-6 mb-6 max-w-md mx-auto">
                  <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3">
                    Recommended Templates
                  </h3>
                  <div className="space-y-2">
                    {USE_CASES.find(uc => uc.id === selectedUseCase)?.recommendedTemplates.map((templateId, idx) => (
                      <div key={idx} className="flex items-center gap-2 text-white">
                        <ArrowRight className="w-4 h-4 text-purple-400" />
                        <span>{templateId.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-8 border-t border-slate-800 flex items-center justify-between">
          <button
            onClick={handleSkip}
            className="px-6 py-2 text-slate-400 hover:text-white transition-colors"
          >
            Skip for now
          </button>

          <div className="flex items-center gap-3">
            {step > 1 && (
              <button
                onClick={() => setStep(prev => (prev - 1) as 1 | 2 | 3)}
                className="px-6 py-2 border border-slate-700 text-slate-300 rounded-lg hover:bg-slate-800 transition-colors"
              >
                Back
              </button>
            )}

            {step < 3 ? (
              <button
                onClick={() => setStep(prev => (prev + 1) as 1 | 2 | 3)}
                disabled={(step === 1 && !selectedUseCase) || (step === 2 && !selectedUserType)}
                className="px-6 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-slate-700 disabled:cursor-not-allowed text-white rounded-lg transition-colors flex items-center gap-2"
              >
                Continue
                <ArrowRight className="w-4 h-4" />
              </button>
            ) : (
              <button
                onClick={handleComplete}
                disabled={isCompleting}
                className="px-8 py-2 bg-gradient-to-r from-purple-600 to-cyan-600 hover:from-purple-700 hover:to-cyan-700 disabled:opacity-50 text-white rounded-lg transition-all flex items-center gap-2"
              >
                {isCompleting ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    Setting up...
                  </>
                ) : (
                  <>
                    Get Started
                    <Sparkles className="w-4 h-4" />
                  </>
                )}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
