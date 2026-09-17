'use client'

import Link from 'next/link'
import { Brain, Zap, BarChart3, GitBranch, ArrowRight, CheckCircle, Code, Terminal } from 'lucide-react'

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950">
      {/* Navigation */}
      <nav className="border-b border-slate-800 bg-slate-950/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-xl flex items-center justify-center">
              <Brain className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold text-white">Tiannara</span>
          </Link>
          
          <div className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-slate-400 hover:text-white transition-colors">Features</a>
            <a href="#how-it-works" className="text-slate-400 hover:text-white transition-colors">How It Works</a>
            <a href="#use-cases" className="text-slate-400 hover:text-white transition-colors">Use Cases</a>
            <a href="#pricing" className="text-slate-400 hover:text-white transition-colors">Pricing</a>
            <a href="#api" className="text-slate-400 hover:text-white transition-colors">API</a>
          </div>

          <div className="flex items-center gap-4">
            <Link href="/login" className="text-slate-400 hover:text-white transition-colors">
              Sign In
            </Link>
            <Link
              href="/signup"
              className="bg-purple-600 hover:bg-purple-700 text-white px-5 py-2 rounded-lg font-medium transition-colors"
            >
              Start Free
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-20 pb-32">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <h1 className="text-5xl md:text-6xl font-bold text-white leading-tight mb-6">
                AI reasoning infrastructure for{' '}
                <span className="bg-gradient-to-r from-purple-400 to-cyan-400 bg-clip-text text-transparent">
                  intelligent workflows
                </span>
              </h1>
              
              <p className="text-xl text-slate-400 mb-8 leading-relaxed">
                Tiannara combines multiple reasoning systems to automate analysis, predictions, and intelligent decision workflows through one scalable platform.
              </p>

              <div className="flex flex-col sm:flex-row gap-4 mb-8">
                <Link
                  href="/signup"
                  className="bg-purple-600 hover:bg-purple-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all flex items-center justify-center gap-2 group"
                >
                  Start Free
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </Link>
                <Link
                  href="/demos"
                  className="bg-slate-800 hover:bg-slate-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all flex items-center justify-center gap-2"
                >
                  View Demo
                </Link>
              </div>

              <div className="flex items-center gap-6 text-sm text-slate-500">
                <div className="flex items-center gap-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>No credit card required</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>Free tier available</span>
                </div>
              </div>
            </div>

            {/* Hero Visual - Dashboard Preview */}
            <div className="relative">
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-2xl">
                <div className="flex items-center gap-2 mb-4">
                  <div className="w-3 h-3 rounded-full bg-red-500"></div>
                  <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                  <div className="w-3 h-3 rounded-full bg-green-500"></div>
                </div>
                <div className="space-y-4">
                  <div className="h-32 bg-gradient-to-br from-purple-500/20 to-cyan-500/20 rounded-lg flex items-center justify-center">
                    <BarChart3 className="w-16 h-16 text-purple-400" />
                  </div>
                  <div className="grid grid-cols-3 gap-3">
                    <div className="h-20 bg-slate-800 rounded-lg"></div>
                    <div className="h-20 bg-slate-800 rounded-lg"></div>
                    <div className="h-20 bg-slate-800 rounded-lg"></div>
                  </div>
                  <div className="h-24 bg-slate-800 rounded-lg"></div>
                </div>
              </div>
              
              {/* Floating elements */}
              <div className="absolute -top-4 -right-4 bg-purple-600 text-white px-4 py-2 rounded-lg text-sm font-medium shadow-lg">
                99.7% Success Rate
              </div>
              <div className="absolute -bottom-4 -left-4 bg-cyan-600 text-white px-4 py-2 rounded-lg text-sm font-medium shadow-lg">
                12K+ API Calls/Day
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Trust Bar */}
      <section className="border-y border-slate-800 bg-slate-900/50 py-8">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-wrap justify-center items-center gap-8 md:gap-16 text-slate-400">
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-purple-400" />
              <span className="font-medium">Built for intelligent automation</span>
            </div>
            <div className="flex items-center gap-2">
              <Code className="w-5 h-5 text-cyan-400" />
              <span className="font-medium">FastAPI + AI orchestration powered</span>
            </div>
            <div className="flex items-center gap-2">
              <GitBranch className="w-5 h-5 text-green-400" />
              <span className="font-medium">Designed for scalable workflows</span>
            </div>
          </div>
        </div>
      </section>

      {/* What Tiannara Does - Features */}
      <section id="features" className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">What Tiannara Does</h2>
            <p className="text-xl text-slate-400">Powerful AI reasoning capabilities in one platform</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            <FeatureCard
              icon={Brain}
              title="Intelligent Reasoning"
              description="Combine logic, prediction, analysis, and automation in one workflow engine."
              color="purple"
            />
            <FeatureCard
              icon={Zap}
              title="Workflow Automation"
              description="Create intelligent pipelines that adapt automatically to data and outcomes."
              color="cyan"
            />
            <FeatureCard
              icon={BarChart3}
              title="Predictive Insights"
              description="Generate explainable predictions, reports, and decision recommendations."
              color="green"
            />
            <FeatureCard
              icon={GitBranch}
              title="Cross-Domain Intelligence"
              description="Reasoning systems collaborate dynamically for more accurate outcomes."
              color="orange"
            />
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="py-20 bg-slate-900/30">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">How It Works</h2>
            <p className="text-xl text-slate-400">Simple four-step process</p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="space-y-8">
              <Step
                number="1"
                title="Connect data or inputs"
                description="Upload your data or connect to existing APIs and databases"
              />
              <div className="flex justify-center">
                <ArrowRight className="w-6 h-6 text-purple-400 rotate-90" />
              </div>
              <Step
                number="2"
                title="Tiannara orchestrates reasoning workflows"
                description="Our engine selects and combines the best reasoning approaches"
              />
              <div className="flex justify-center">
                <ArrowRight className="w-6 h-6 text-purple-400 rotate-90" />
              </div>
              <Step
                number="3"
                title="AI domains collaborate automatically"
                description="Multiple specialized engines work together on your task"
              />
              <div className="flex justify-center">
                <ArrowRight className="w-6 h-6 text-purple-400 rotate-90" />
              </div>
              <Step
                number="4"
                title="Receive predictions, insights, or actions"
                description="Get actionable results with full explainability and confidence scores"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases */}
      <section id="use-cases" className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">Use Cases</h2>
            <p className="text-xl text-slate-400">Real-world applications across industries</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <UseCaseCard
              title="Analytics"
              description="Generate insights from structured workflows"
              icon={BarChart3}
            />
            <UseCaseCard
              title="Risk Detection"
              description="Identify anomalies and fraud patterns"
              icon={Zap}
            />
            <UseCaseCard
              title="Prediction Systems"
              description="Run intelligent prediction pipelines"
              icon={Brain}
            />
            <UseCaseCard
              title="Research Automation"
              description="Automate multi-step reasoning tasks"
              icon={GitBranch}
            />
            <UseCaseCard
              title="Enterprise Workflows"
              description="Deploy scalable AI reasoning systems"
              icon={Code}
            />
            <UseCaseCard
              title="Decision Support"
              description="Augment human decisions with AI insights"
              icon={CheckCircle}
            />
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="py-20 bg-slate-900/30">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">Simple Pricing</h2>
            <p className="text-xl text-slate-400">Choose the plan that fits your needs</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            <PricingCard
              name="Starter"
              price="$49"
              period="/month"
              description="Build smarter workflows without building AI infrastructure from scratch"
              features={[
                '5,000 API requests/month',
                'Core reasoning & workflow engine',
                'AI-assisted analytics and insights',
                'Explainable outputs and reasoning traces',
                'Intelligent automation modules',
                'Basic dashboard analytics',
                'API access & documentation',
                'Community support',
                'Email support (48-hour response)'
              ]}
              targetAudience={[
                'Indie developers',
                'Small startups',
                'Researchers & students'
              ]}
              useCases={[
                'Customer segmentation',
                'Research automation',
                'Marketing analysis',
                'Sentiment analysis'
              ]}
            />
            <PricingCard
              name="Professional"
              price="$199"
              period="/month"
              description="Production-ready AI infrastructure for growing businesses"
              popular={true}
              features={[
                '50,000 API requests/month',
                'Priority processing & faster response times',
                'Advanced workflow orchestration',
                'Real-time analytics dashboard',
                'Team collaboration tools',
                'Webhooks & integrations',
                'Advanced monitoring & alerts',
                'SLA-backed uptime guarantee (99.5%)',
                'Priority email support (24-hour response)'
              ]}
              targetAudience={[
                'Growing startups',
                'SaaS companies',
                'Fintech products',
                'Analytics platforms'
              ]}
              useCases={[
                'Fraud detection workflows',
                'Predictive analytics systems',
                'AI-powered dashboards',
                'Customer intelligence platforms'
              ]}
            />
            <PricingCard
              name="Enterprise"
              price="Contact Sales"
              description="Enterprise AI infrastructure with compliance and dedicated support"
              features={[
                'Unlimited API access',
                'Dedicated infrastructure options',
                'Custom AI workflow deployment',
                'Explainability & audit reporting',
                'Compliance tooling & governance',
                'Dedicated account manager',
                '24/7 priority support',
                'Custom SLA agreements',
                'Private/on-premise deployment'
              ]}
              targetAudience={[
                'Large enterprises',
                'Financial services',
                'Healthcare organizations',
                'Compliance-heavy industries'
              ]}
              useCases={[
                'Claims processing systems',
                'Enterprise risk analysis',
                'Compliance automation',
                'Fraud prevention networks'
              ]}
            />
          </div>
        </div>
      </section>

      {/* API / Developer Section */}
      <section id="api" className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-4xl font-bold text-white mb-6">Developer-Friendly API</h2>
              <p className="text-xl text-slate-400 mb-8">
                Integrate Tiannara into your applications with just a few lines of code
              </p>

              <div className="space-y-4 mb-8">
                <div className="flex items-start gap-3">
                  <CheckCircle className="w-5 h-5 text-green-400 mt-1" />
                  <div>
                    <h4 className="text-white font-medium mb-1">RESTful API</h4>
                    <p className="text-slate-400 text-sm">Standard HTTP endpoints with JSON responses</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle className="w-5 h-5 text-green-400 mt-1" />
                  <div>
                    <h4 className="text-white font-medium mb-1">SDK Available</h4>
                    <p className="text-slate-400 text-sm">Python, JavaScript, and TypeScript libraries</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle className="w-5 h-5 text-green-400 mt-1" />
                  <div>
                    <h4 className="text-white font-medium mb-1">Comprehensive Docs</h4>
                    <p className="text-slate-400 text-sm">Detailed guides and API reference</p>
                  </div>
                </div>
              </div>

              <Link
                href="/docs"
                className="inline-flex items-center gap-2 text-purple-400 hover:text-purple-300 font-medium transition-colors"
              >
                View Documentation
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>

            {/* Code Example */}
            <div className="bg-slate-950 border border-slate-800 rounded-xl p-6">
              <div className="flex items-center gap-2 mb-4">
                <Terminal className="w-5 h-5 text-slate-400" />
                <span className="text-slate-400 text-sm">Python Example</span>
              </div>
              <pre className="text-sm text-slate-300 overflow-x-auto">
                <code>{`import tiannara

# Initialize client
client = tiannara.Client(api_key="your_key")

# Run prediction workflow
workflow = client.predict(
    data=input_data,
    domain="prediction"
)

# Get results
print(workflow.insights)
print(f"Confidence: {workflow.confidence}")`}</code>
              </pre>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20 bg-slate-900/30">
        <div className="max-w-4xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">Frequently Asked Questions</h2>
          </div>

          <div className="space-y-6">
            <FAQItem
              question="What makes Tiannara different?"
              answer="Tiannara combines multiple specialized AI reasoning engines that collaborate dynamically, providing more accurate and explainable results than single-model approaches."
            />
            <FAQItem
              question="Is it an API or dashboard?"
              answer="Both! Tiannara provides a RESTful API for developers and a web dashboard for visual workflow management and monitoring."
            />
            <FAQItem
              question="Can I integrate my own workflows?"
              answer="Yes! You can create custom workflows using our workflow builder or programmatically via the API."
            />
            <FAQItem
              question="Does it support teams?"
              answer="Absolutely. Professional and Enterprise plans include team collaboration features, shared workspaces, and role-based access control."
            />
            <FAQItem
              question="Is there a free trial?"
              answer="Yes! Our Starter plan includes a free tier with 1,000 API calls per month. No credit card required."
            />
            <FAQItem
              question="What industries work best?"
              answer="Tiannara works across many industries including finance (risk detection), healthcare (diagnosis support), research (data analysis), and enterprise (workflow automation)."
            />
          </div>
        </div>
      </section>

      {/* Why Choose Tiannara - Added Value Proposition */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">Why Teams Choose Tiannara</h2>
            <p className="text-xl text-slate-400">Build, scale, and automate with confidence</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/50 transition-colors">
              <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center mb-4">
                <Zap className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Launch Prototypes Faster</h3>
              <p className="text-slate-400 text-sm">Avoid building AI systems from scratch. Get intelligent workflows running in minutes, not months.</p>
            </div>
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-cyan-500/50 transition-colors">
              <div className="w-12 h-12 bg-gradient-to-br from-cyan-500 to-cyan-600 rounded-lg flex items-center justify-center mb-4">
                <BarChart3 className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Automate Repetitive Analysis</h3>
              <p className="text-slate-400 text-sm">Save hours of manual work with AI-powered reasoning, predictions, and data classification.</p>
            </div>
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-green-500/50 transition-colors">
              <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center mb-4">
                <Brain className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Scale to Production Reliably</h3>
              <p className="text-slate-400 text-sm">Start with 5K requests, scale to unlimited. Enterprise-grade infrastructure grows with you.</p>
            </div>
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-orange-500/50 transition-colors">
              <div className="w-12 h-12 bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg flex items-center justify-center mb-4">
                <Code className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Explainable AI Decisions</h3>
              <p className="text-slate-400 text-sm">Full reasoning traces and confidence scores. Understand exactly how decisions are made.</p>
            </div>
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-blue-500/50 transition-colors">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center mb-4">
                <GitBranch className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Cross-Domain Collaboration</h3>
              <p className="text-slate-400 text-sm">Multiple reasoning engines work together dynamically for more accurate outcomes.</p>
            </div>
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-pink-500/50 transition-colors">
              <div className="w-12 h-12 bg-gradient-to-br from-pink-500 to-pink-600 rounded-lg flex items-center justify-center mb-4">
                <CheckCircle className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Reduce Operational Overhead</h3>
              <p className="text-slate-400 text-sm">Built-in monitoring, alerts, and analytics. Focus on building, not maintaining infrastructure.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Start building intelligent AI workflows today
          </h2>
          <p className="text-xl text-slate-400 mb-8">
            Join thousands of developers and teams using Tiannara to automate complex reasoning tasks
          </p>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/signup"
              className="bg-purple-600 hover:bg-purple-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all flex items-center justify-center gap-2"
            >
              Start Free
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link
              href="/contact"
              className="bg-slate-800 hover:bg-slate-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all"
            >
              Book Demo
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-800 bg-slate-950 py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-lg flex items-center justify-center">
                  <Brain className="w-5 h-5 text-white" />
                </div>
                <span className="text-lg font-bold text-white">Tiannara</span>
              </div>
              <p className="text-slate-400 text-sm">
                AI reasoning infrastructure for intelligent workflows
              </p>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Product</h4>
              <ul className="space-y-2 text-sm text-slate-400">
                <li><a href="#features" className="hover:text-white transition-colors">Features</a></li>
                <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
                <li><a href="/docs" className="hover:text-white transition-colors">Documentation</a></li>
                <li><a href="/demos" className="hover:text-white transition-colors">Demos</a></li>
              </ul>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Company</h4>
              <ul className="space-y-2 text-sm text-slate-400">
                <li><a href="/about" className="hover:text-white transition-colors">About</a></li>
                <li><a href="/blog" className="hover:text-white transition-colors">Blog</a></li>
                <li><a href="/careers" className="hover:text-white transition-colors">Careers</a></li>
                <li><a href="/contact" className="hover:text-white transition-colors">Contact</a></li>
              </ul>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Legal</h4>
              <ul className="space-y-2 text-sm text-slate-400">
                <li><a href="/privacy" className="hover:text-white transition-colors">Privacy</a></li>
                <li><a href="/terms" className="hover:text-white transition-colors">Terms</a></li>
                <li><a href="/security" className="hover:text-white transition-colors">Security</a></li>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-slate-800 pt-8 text-center text-sm text-slate-500">
            © 2026 Tiannara. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  )
}

// Component helpers
function FeatureCard({ icon: Icon, title, description, color }: any) {
  const colors = {
    purple: 'from-purple-500 to-purple-600',
    cyan: 'from-cyan-500 to-cyan-600',
    green: 'from-green-500 to-green-600',
    orange: 'from-orange-500 to-orange-600',
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/50 transition-colors">
      <div className={`w-12 h-12 bg-gradient-to-br ${colors[color as keyof typeof colors]} rounded-lg flex items-center justify-center mb-4`}>
        <Icon className="w-6 h-6 text-white" />
      </div>
      <h3 className="text-xl font-semibold text-white mb-2">{title}</h3>
      <p className="text-slate-400">{description}</p>
    </div>
  )
}

function Step({ number, title, description }: any) {
  return (
    <div className="flex items-start gap-4">
      <div className="w-12 h-12 bg-purple-600 rounded-full flex items-center justify-center flex-shrink-0">
        <span className="text-white font-bold text-lg">{number}</span>
      </div>
      <div>
        <h3 className="text-xl font-semibold text-white mb-2">{title}</h3>
        <p className="text-slate-400">{description}</p>
      </div>
    </div>
  )
}

function UseCaseCard({ title, description, icon: Icon }: any) {
  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-cyan-500/50 transition-colors">
      <Icon className="w-10 h-10 text-cyan-400 mb-4" />
      <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
      <p className="text-slate-400">{description}</p>
    </div>
  )
}

function PricingCard({ name, price, period, description, features, popular, targetAudience, useCases }: any) {
  return (
    <div className={`bg-slate-900/50 border ${popular ? 'border-purple-500' : 'border-slate-800'} rounded-xl p-8 relative flex flex-col`}>
      {popular && (
        <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-purple-600 text-white px-4 py-1 rounded-full text-sm font-medium">
          Most Popular
        </div>
      )}
      <div className="mb-6">
        <h3 className="text-2xl font-bold text-white mb-2">{name}</h3>
        <p className="text-slate-400 text-sm">{description}</p>
      </div>
      <div className="mb-6">
        <span className="text-4xl font-bold text-white">{price}</span>
        {period && <span className="text-slate-400">{period}</span>}
      </div>
      
      {/* Features */}
      <ul className="space-y-3 mb-6 flex-grow">
        {features.map((feature: string, index: number) => (
          <li key={index} className="flex items-start gap-2 text-slate-300">
            <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
            <span className="text-sm">{feature}</span>
          </li>
        ))}
      </ul>

      {/* Target Audience */}
      {targetAudience && (
        <div className="mb-6">
          <p className="text-xs font-semibold text-purple-400 uppercase tracking-wide mb-2">Best For</p>
          <div className="flex flex-wrap gap-2">
            {targetAudience.map((audience: string, index: number) => (
              <span key={index} className="px-2 py-1 bg-purple-500/10 border border-purple-500/20 rounded text-xs text-purple-300">
                {audience}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Use Cases */}
      {useCases && (
        <div className="mb-6">
          <p className="text-xs font-semibold text-cyan-400 uppercase tracking-wide mb-2">Example Use Cases</p>
          <ul className="space-y-1">
            {useCases.map((useCase: string, index: number) => (
              <li key={index} className="text-xs text-slate-400 flex items-center gap-2">
                <span className="w-1 h-1 bg-cyan-400 rounded-full"></span>
                {useCase}
              </li>
            ))}
          </ul>
        </div>
      )}

      <Link
        href="/signup"
        className={`block w-full text-center py-3 rounded-lg font-semibold transition-colors ${
          popular
            ? 'bg-purple-600 hover:bg-purple-700 text-white'
            : 'bg-slate-800 hover:bg-slate-700 text-white'
        }`}
      >
        {price.includes('Contact') ? 'Contact Sales' : 'Get Started'}
      </Link>
    </div>
  )
}

function FAQItem({ question, answer }: any) {
  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-2">{question}</h3>
      <p className="text-slate-400">{answer}</p>
    </div>
  )
}
