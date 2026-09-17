import Link from 'next/link'
import { Check, Brain } from 'lucide-react'

export default function Pricing() {
  const plans = [
    {
      name: 'Starter',
      price: '$0',
      period: '/month',
      description: 'Perfect for experimentation and small projects',
      features: [
        '5,000 API requests/month',
        'All 5 domain engines',
        'Basic analytics',
        'Community support',
        '1 API key',
        'Standard rate limits',
      ],
      cta: 'Get Started Free',
      popular: false,
    },
    {
      name: 'Pro',
      price: '$99',
      period: '/month',
      description: 'For growing applications and production workloads',
      features: [
        '50,000 API requests/month',
        'All 5 domain engines',
        'Advanced analytics & insights',
        'Priority email support',
        '5 API keys',
        'Higher rate limits',
        'Custom workflows',
        'Webhook notifications',
      ],
      cta: 'Start Pro Trial',
      popular: true,
    },
    {
      name: 'Enterprise',
      price: 'Custom',
      period: '',
      description: 'For large-scale deployments with custom requirements',
      features: [
        'Unlimited API requests',
        'All 5 domain engines',
        'Real-time analytics dashboard',
        '24/7 dedicated support',
        'Unlimited API keys',
        'No rate limits',
        'Custom engine tuning',
        'SLA guarantees',
        'On-premise deployment',
        'Custom integrations',
      ],
      cta: 'Contact Sales',
      popular: false,
    },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950">
      {/* Navigation */}
      <nav className="border-b border-slate-800 bg-slate-950/50 backdrop-blur-lg sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-cyan-500 rounded-xl flex items-center justify-center">
              <Brain className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold text-white">Tiannara</span>
          </Link>
          <div className="flex items-center gap-6">
            <Link href="/login" className="text-slate-400 hover:text-white transition-colors">Login</Link>
            <Link href="/signup" className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium transition-colors">
              Get Started
            </Link>
          </div>
        </div>
      </nav>

      {/* Header */}
      <section className="pt-20 pb-16">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h1 className="text-5xl font-bold text-white mb-6">Simple, Transparent Pricing</h1>
          <p className="text-xl text-slate-400">
            Choose the plan that fits your needs. Upgrade or downgrade at any time.
          </p>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="pb-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`relative bg-slate-900/50 border rounded-2xl p-8 ${
                  plan.popular ? 'border-purple-500 ring-2 ring-purple-500/20' : 'border-slate-800'
                }`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 bg-purple-600 text-white text-sm font-medium rounded-full">
                    Most Popular
                  </div>
                )}
                
                <div className="mb-6">
                  <h3 className="text-2xl font-bold text-white mb-2">{plan.name}</h3>
                  <p className="text-slate-400 text-sm">{plan.description}</p>
                </div>

                <div className="mb-8">
                  <span className="text-5xl font-bold text-white">{plan.price}</span>
                  <span className="text-slate-400">{plan.period}</span>
                </div>

                <ul className="space-y-4 mb-8">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                      <span className="text-slate-300 text-sm">{feature}</span>
                    </li>
                  ))}
                </ul>

                <Link
                  href="/signup"
                  className={`block w-full py-3 rounded-xl font-semibold text-center transition-colors ${
                    plan.popular
                      ? 'bg-purple-600 hover:bg-purple-700 text-white'
                      : 'bg-slate-800 hover:bg-slate-700 text-white'
                  }`}
                >
                  {plan.cta}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section className="py-20 bg-slate-900/50 border-t border-slate-800">
        <div className="max-w-4xl mx-auto px-6">
          <h2 className="text-3xl font-bold text-white text-center mb-12">Frequently Asked Questions</h2>
          <div className="space-y-6">
            <FAQItem
              question="What happens if I exceed my API request limit?"
              answer="You'll receive a warning at 80% usage. If you exceed your limit, API calls will be throttled until your billing cycle resets. You can upgrade your plan at any time for immediate additional capacity."
            />
            <FAQItem
              question="Can I switch between plans?"
              answer="Yes! You can upgrade or downgrade your plan at any time. Changes take effect immediately, and we'll prorate any differences in your next billing cycle."
            />
            <FAQItem
              question="Do you offer a free trial for Pro plans?"
              answer="Yes, we offer a 14-day free trial for Pro plans. No credit card required to start. You'll have full access to all Pro features during the trial period."
            />
            <FAQItem
              question="What's included in Enterprise support?"
              answer="Enterprise customers get 24/7 dedicated support with guaranteed response times, a dedicated account manager, custom SLA agreements, and priority feature requests."
            />
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h2 className="text-3xl font-bold text-white mb-6">Ready to Get Started?</h2>
          <p className="text-lg text-slate-400 mb-8">
            Join thousands of developers building intelligent applications with Tiannara
          </p>
          <Link href="/signup" className="inline-block px-8 py-4 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-semibold text-lg transition-colors">
            Start Building Free
          </Link>
        </div>
      </section>
    </div>
  )
}

function FAQItem({ question, answer }: { question: string; answer: string }) {
  return (
    <div className="bg-slate-950/50 border border-slate-800 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-3">{question}</h3>
      <p className="text-slate-400">{answer}</p>
    </div>
  )
}
