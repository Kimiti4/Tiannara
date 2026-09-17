'use client'

import { useState } from 'react'
import { Play, Brain, Zap, BarChart3, CheckCircle, Loader2, ArrowRight, Sparkles } from 'lucide-react'

export default function DemosPage() {
  const [activeDemo, setActiveDemo] = useState<string | null>(null)
  const [isRunning, setIsRunning] = useState(false)
  const [demoResult, setDemoResult] = useState<any>(null)

  const demos = [
    {
      id: 'prediction',
      title: 'Run a Prediction',
      description: 'See how Tiannara analyzes data and generates intelligent predictions',
      icon: BarChart3,
      color: 'purple',
      sampleInput: {
        metric: 'customer_churn',
        data_points: 150,
        time_range: 'last_30_days'
      },
      expectedOutput: {
        prediction: 'High churn risk detected in segment A',
        confidence: 0.87,
        key_factors: [
          'Decreased engagement over past 2 weeks',
          'Support ticket volume increased by 45%',
          'Payment delays observed in 23% of accounts'
        ],
        recommendation: 'Implement proactive outreach campaign for at-risk customers'
      }
    },
    {
      id: 'workflow',
      title: 'Try a Workflow',
      description: 'Experience automated multi-step reasoning pipelines',
      icon: Zap,
      color: 'blue',
      sampleInput: {
        workflow_type: 'anomaly_detection',
        dataset: 'transaction_logs',
        threshold: 0.95
      },
      expectedOutput: {
        status: 'completed',
        anomalies_detected: 3,
        processing_time_ms: 2340,
        steps_completed: [
          'Data ingestion and validation',
          'Pattern analysis across 10K records',
          'Anomaly scoring with ML model',
          'Root cause identification',
          'Alert generation'
        ]
      }
    },
    {
      id: 'analysis',
      title: 'Analyze Sample Data',
      description: 'Watch Tiannara discover insights from structured data',
      icon: Brain,
      color: 'green',
      sampleInput: {
        analysis_type: 'root_cause',
        question: 'What drives customer satisfaction?',
        data_source: 'survey_responses'
      },
      expectedOutput: {
        insights: [
          {
            type: 'root_cause',
            finding: 'Response time is the #1 driver of satisfaction (correlation: 0.82)',
            confidence: 0.91,
            evidence: 'Customers with <2hr response time rate 4.8/5 vs 3.2/5 for >24hr'
          },
          {
            type: 'recommendation',
            finding: 'Implementing auto-acknowledgment could improve scores by 23%',
            confidence: 0.78,
            impact: 'high'
          }
        ]
      }
    }
  ]

  const runDemo = async (demoId: string) => {
    setActiveDemo(demoId)
    setIsRunning(true)
    setDemoResult(null)

    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 2500))

    const demo = demos.find(d => d.id === demoId)
    if (demo) {
      setDemoResult(demo.expectedOutput)
    }

    setIsRunning(false)
  }

  const getColorClasses = (color: string) => {
    switch (color) {
      case 'purple':
        return {
          bg: 'bg-purple-500/10',
          border: 'border-purple-500/20',
          text: 'text-purple-400',
          hover: 'hover:border-purple-500/40',
          button: 'from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700'
        }
      case 'blue':
        return {
          bg: 'bg-blue-500/10',
          border: 'border-blue-500/20',
          text: 'text-blue-400',
          hover: 'hover:border-blue-500/40',
          button: 'from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700'
        }
      case 'green':
        return {
          bg: 'bg-green-500/10',
          border: 'border-green-500/20',
          text: 'text-green-400',
          hover: 'hover:border-green-500/40',
          button: 'from-green-500 to-green-600 hover:from-green-600 hover:to-green-700'
        }
      default:
        return {
          bg: 'bg-slate-500/10',
          border: 'border-slate-500/20',
          text: 'text-slate-400',
          hover: 'hover:border-slate-500/40',
          button: 'from-slate-500 to-slate-600 hover:from-slate-600 hover:to-slate-700'
        }
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950">
      {/* Header */}
      <div className="max-w-7xl mx-auto px-6 py-16">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-purple-500/10 border border-purple-500/20 rounded-full text-purple-400 text-sm font-medium mb-6">
            <Sparkles className="w-4 h-4" />
            Interactive Demos
          </div>
          <h1 className="text-5xl font-bold text-white mb-6">
            See Tiannara in Action
          </h1>
          <p className="text-xl text-slate-400 max-w-3xl mx-auto">
            Try live demonstrations of Tiannara's AI capabilities. No signup required.
          </p>
        </div>

        {/* Demo Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-16">
          {demos.map((demo) => {
            const colors = getColorClasses(demo.color)
            const Icon = demo.icon
            const isActive = activeDemo === demo.id

            return (
              <div
                key={demo.id}
                className={`relative bg-slate-900/50 border ${colors.border} rounded-2xl p-8 transition-all ${colors.hover} ${
                  isActive ? 'ring-2 ring-purple-500/50' : ''
                }`}
              >
                <div className={`w-14 h-14 ${colors.bg} rounded-xl flex items-center justify-center mb-6`}>
                  <Icon className={`w-7 h-7 ${colors.text}`} />
                </div>

                <h3 className="text-2xl font-bold text-white mb-3">{demo.title}</h3>
                <p className="text-slate-400 mb-8 leading-relaxed">{demo.description}</p>

                <button
                  onClick={() => runDemo(demo.id)}
                  disabled={isRunning && !isActive}
                  className={`w-full px-6 py-4 bg-gradient-to-r ${colors.button} text-white rounded-xl transition-all font-semibold flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed`}
                >
                  {isRunning && isActive ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Running Demo...
                    </>
                  ) : (
                    <>
                      <Play className="w-5 h-5" />
                      Run Demo
                    </>
                  )}
                </button>
              </div>
            )
          })}
        </div>

        {/* Demo Result Panel */}
        {activeDemo && demoResult && (
          <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex items-center gap-3 mb-6">
              <CheckCircle className="w-6 h-6 text-green-400" />
              <h2 className="text-2xl font-bold text-white">Demo Results</h2>
            </div>

            <div className="space-y-6">
              {/* Display results based on demo type */}
              {activeDemo === 'prediction' && demoResult.prediction && (
                <>
                  <div className="bg-slate-800/50 rounded-xl p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div>
                        <h3 className="text-lg font-semibold text-white mb-2">Prediction</h3>
                        <p className="text-slate-300">{demoResult.prediction}</p>
                      </div>
                      <div className="text-right">
                        <div className="text-3xl font-bold text-green-400">
                          {(demoResult.confidence * 100).toFixed(0)}%
                        </div>
                        <div className="text-sm text-slate-400">Confidence</div>
                      </div>
                    </div>

                    <div className="space-y-3 mt-6">
                      <h4 className="text-sm font-semibold text-slate-400 uppercase tracking-wide">Key Factors</h4>
                      {demoResult.key_factors.map((factor: string, idx: number) => (
                        <div key={idx} className="flex items-start gap-3 text-slate-300">
                          <div className="w-1.5 h-1.5 rounded-full bg-purple-500 mt-2 flex-shrink-0" />
                          {factor}
                        </div>
                      ))}
                    </div>

                    <div className="mt-6 pt-6 border-t border-slate-700">
                      <h4 className="text-sm font-semibold text-slate-400 uppercase tracking-wide mb-2">Recommendation</h4>
                      <p className="text-slate-300">{demoResult.recommendation}</p>
                    </div>
                  </div>
                </>
              )}

              {activeDemo === 'workflow' && demoResult.status && (
                <>
                  <div className="bg-slate-800/50 rounded-xl p-6">
                    <div className="flex items-center justify-between mb-6">
                      <div>
                        <h3 className="text-lg font-semibold text-white mb-1">Workflow Execution</h3>
                        <p className="text-slate-400 text-sm">Completed in {demoResult.processing_time_ms}ms</p>
                      </div>
                      <div className="px-4 py-2 bg-green-500/10 border border-green-500/20 rounded-lg text-green-400 font-semibold">
                        {demoResult.anomalies_detected} Anomalies Detected
                      </div>
                    </div>

                    <div className="space-y-3">
                      <h4 className="text-sm font-semibold text-slate-400 uppercase tracking-wide">Steps Completed</h4>
                      {demoResult.steps_completed.map((step: string, idx: number) => (
                        <div key={idx} className="flex items-center gap-3 text-slate-300">
                          <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                          {step}
                        </div>
                      ))}
                    </div>
                  </div>
                </>
              )}

              {activeDemo === 'analysis' && demoResult.insights && (
                <>
                  <div className="space-y-4">
                    {demoResult.insights.map((insight: any, idx: number) => (
                      <div key={idx} className="bg-slate-800/50 rounded-xl p-6">
                        <div className="flex items-start justify-between mb-3">
                          <div className="px-3 py-1 bg-purple-500/10 border border-purple-500/20 rounded-full text-purple-400 text-sm font-medium">
                            {insight.type.replace('_', ' ').toUpperCase()}
                          </div>
                          <div className="text-right">
                            <div className="text-lg font-bold text-green-400">
                              {(insight.confidence * 100).toFixed(0)}%
                            </div>
                            <div className="text-xs text-slate-400">Confidence</div>
                          </div>
                        </div>

                        <h3 className="text-lg font-semibold text-white mb-2">{insight.finding}</h3>
                        
                        {insight.evidence && (
                          <div className="mt-4 pt-4 border-t border-slate-700">
                            <h4 className="text-sm font-semibold text-slate-400 uppercase tracking-wide mb-2">Evidence</h4>
                            <p className="text-slate-300">{insight.evidence}</p>
                          </div>
                        )}

                        {insight.impact && (
                          <div className="mt-4 flex items-center gap-2">
                            <span className="text-sm text-slate-400">Impact:</span>
                            <span className={`px-2 py-1 rounded text-sm font-medium ${
                              insight.impact === 'high' ? 'bg-red-500/10 text-red-400' :
                              insight.impact === 'medium' ? 'bg-yellow-500/10 text-yellow-400' :
                              'bg-blue-500/10 text-blue-400'
                            }`}>
                              {insight.impact.toUpperCase()}
                            </span>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>

            <div className="mt-8 pt-8 border-t border-slate-800 flex items-center justify-between">
              <p className="text-slate-400">
                Want to see more? Start your free trial to unlock full capabilities.
              </p>
              <button className="px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-xl transition-all font-semibold flex items-center gap-2">
                Get Started Free
                <ArrowRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}

        {/* Features Grid */}
        <div className="mt-24 grid grid-cols-1 md:grid-cols-3 gap-8">
          <FeatureCard
            icon={Brain}
            title="Multi-Domain Reasoning"
            description="Tiannara orchestrates multiple AI domains to collaborate on complex problems"
          />
          <FeatureCard
            icon={Zap}
            title="Automated Workflows"
            description="Build and deploy intelligent workflows that execute automatically"
          />
          <FeatureCard
            icon={BarChart3}
            title="Real-Time Analytics"
            description="Monitor performance, track metrics, and get actionable insights"
          />
        </div>
      </div>
    </div>
  )
}

function FeatureCard({ icon: Icon, title, description }: {
  icon: any
  title: string
  description: string
}) {
  return (
    <div className="bg-slate-900/30 border border-slate-800 rounded-xl p-6 hover:border-purple-500/30 transition-colors">
      <div className="w-12 h-12 bg-purple-500/10 rounded-lg flex items-center justify-center mb-4">
        <Icon className="w-6 h-6 text-purple-400" />
      </div>
      <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
      <p className="text-slate-400 text-sm leading-relaxed">{description}</p>
    </div>
  )
}
