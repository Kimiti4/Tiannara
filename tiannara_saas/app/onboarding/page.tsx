'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { BarChart3, Zap, Brain, Activity, Shield, Settings } from 'lucide-react'

export default function OnboardingPage() {
  const router = useRouter()
  const [selectedUseCase, setSelectedUseCase] = useState<string[]>([])
  const [selectedTeamType, setSelectedTeamType] = useState('')
  const [step, setStep] = useState(1)

  const useCases = [
    { id: 'analytics', label: 'Analytics & Insights', icon: BarChart3, description: 'Generate insights from data and monitor business metrics' },
    { id: 'automation', label: 'Workflow Automation', icon: Zap, description: 'Automate repetitive tasks and intelligent processes' },
    { id: 'decision', label: 'AI Decision Support', icon: Brain, description: 'Augment human decisions with AI-powered insights' },
    { id: 'prediction', label: 'Prediction Systems', icon: Activity, description: 'Forecast trends and predict future outcomes' },
    { id: 'security', label: 'Fraud & Risk Detection', icon: Shield, description: 'Detect anomalies and prevent fraudulent activity' },
    { id: 'research', label: 'Research Automation', icon: Settings, description: 'Automate multi-step reasoning and analysis tasks' },
  ]

  const teamTypes = [
    { id: 'solo', label: 'Solo Project', description: 'Personal use or individual experimentation' },
    { id: 'startup', label: 'Startup Team', description: 'Small team building a product' },
    { id: 'business', label: 'Internal Business Tool', description: 'Enterprise internal automation' },
    { id: 'customer', label: 'Customer-Facing Product', description: 'AI features for your customers' },
    { id: 'research', label: 'Research/Academic', description: 'Academic or research institution' },
  ]

  const handleNext = () => {
    if (step === 1 && selectedUseCase.length > 0) {
      setStep(2)
    } else if (step === 2 && selectedTeamType) {
      // Save onboarding data and redirect to dashboard
      localStorage.setItem('tiannara_onboarding', JSON.stringify({
        useCases: selectedUseCase,
        teamType: selectedTeamType,
        completed: true
      }))
      router.push('/dashboard')
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center p-8">
      <div className="max-w-3xl w-full">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-white mb-4">Welcome to Tiannara</h1>
          <p className="text-xl text-slate-400">Build intelligent AI workflows without building AI infrastructure</p>
        </div>

        {/* Progress Steps */}
        <div className="flex items-center justify-center gap-4 mb-12">
          <div className={`flex items-center gap-2 px-4 py-2 rounded-lg ${step >= 1 ? 'bg-purple-600 text-white' : 'bg-slate-800 text-slate-400'}`}>
            <span className="font-semibold">1</span>
            <span>Use Case</span>
          </div>
          <div className={`w-12 h-0.5 ${step >= 2 ? 'bg-purple-600' : 'bg-slate-700'}`}></div>
          <div className={`flex items-center gap-2 px-4 py-2 rounded-lg ${step >= 2 ? 'bg-purple-600 text-white' : 'bg-slate-800 text-slate-400'}`}>
            <span className="font-semibold">2</span>
            <span>Setup</span>
          </div>
        </div>

        {/* Step 1: What would you like to build? */}
        {step === 1 && (
          <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 text-center">
              What would you like to build today?
            </h2>
            <p className="text-slate-400 text-center mb-8">
              Select one or more use cases that match your needs
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
              {useCases.map((useCase) => {
                const isSelected = selectedUseCase.includes(useCase.id)
                const Icon = useCase.icon
                return (
                  <button
                    key={useCase.id}
                    onClick={() => {
                      if (isSelected) {
                        setSelectedUseCase(selectedUseCase.filter(id => id !== useCase.id))
                      } else {
                        setSelectedUseCase([...selectedUseCase, useCase.id])
                      }
                    }}
                    className={`p-6 rounded-xl border-2 text-left transition-all ${
                      isSelected
                        ? 'border-purple-500 bg-purple-500/10'
                        : 'border-slate-800 bg-slate-900/30 hover:border-slate-700'
                    }`}
                  >
                    <div className="flex items-start gap-4">
                      <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                        isSelected ? 'bg-purple-500' : 'bg-slate-800'
                      }`}>
                        <Icon className={`w-6 h-6 ${isSelected ? 'text-white' : 'text-slate-400'}`} />
                      </div>
                      <div>
                        <h3 className="text-white font-semibold mb-1">{useCase.label}</h3>
                        <p className="text-sm text-slate-400">{useCase.description}</p>
                      </div>
                    </div>
                  </button>
                )
              })}
            </div>

            <button
              onClick={handleNext}
              disabled={selectedUseCase.length === 0}
              className="w-full py-4 bg-purple-600 hover:bg-purple-700 disabled:bg-slate-700 disabled:cursor-not-allowed text-white rounded-xl font-semibold text-lg transition-all flex items-center justify-center gap-2"
            >
              Continue
              <span className="text-purple-200">→</span>
            </button>
          </div>
        )}

        {/* Step 2: How will you use Tiannara? */}
        {step === 2 && (
          <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 text-center">
              How will you use Tiannara?
            </h2>
            <p className="text-slate-400 text-center mb-8">
              This helps us personalize your workspace and templates
            </p>

            <div className="space-y-3 mb-8">
              {teamTypes.map((type) => {
                const isSelected = selectedTeamType === type.id
                return (
                  <button
                    key={type.id}
                    onClick={() => setSelectedTeamType(type.id)}
                    className={`w-full p-4 rounded-xl border-2 text-left transition-all ${
                      isSelected
                        ? 'border-purple-500 bg-purple-500/10'
                        : 'border-slate-800 bg-slate-900/30 hover:border-slate-700'
                    }`}
                  >
                    <h3 className="text-white font-semibold mb-1">{type.label}</h3>
                    <p className="text-sm text-slate-400">{type.description}</p>
                  </button>
                )
              })}
            </div>

            <div className="flex gap-4">
              <button
                onClick={() => setStep(1)}
                className="flex-1 py-4 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold transition-all"
              >
                ← Back
              </button>
              <button
                onClick={handleNext}
                disabled={!selectedTeamType}
                className="flex-1 py-4 bg-purple-600 hover:bg-purple-700 disabled:bg-slate-700 disabled:cursor-not-allowed text-white rounded-xl font-semibold text-lg transition-all flex items-center justify-center gap-2"
              >
                Complete Setup
                <span className="text-purple-200">✓</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
