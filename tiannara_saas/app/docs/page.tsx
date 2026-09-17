'use client'

import { useState } from 'react'
import { Book, Code, Play, Copy, Check, Terminal, Zap, Shield, Database } from 'lucide-react'

export default function APIDocsPage() {
  const [activeSection, setActiveSection] = useState('getting-started')
  const [copiedEndpoint, setCopiedEndpoint] = useState<string | null>(null)
  const [testEndpoint, setTestEndpoint] = useState('/api/v1/analytics/dashboard')
  const [testMethod, setTestMethod] = useState('GET')
  const [testResponse, setTestResponse] = useState<any>(null)
  const [isTesting, setIsTesting] = useState(false)

  const apiEndpoints = [
    {
      category: 'Analytics',
      endpoints: [
        { method: 'GET', path: '/api/v1/analytics/dashboard', description: 'Get dashboard metrics summary' },
        { method: 'GET', path: '/api/v1/analytics/center?time_range=7d', description: 'Get comprehensive analytics' },
        { method: 'GET', path: '/api/v1/analytics/predictions', description: 'Get AI predictions' },
        { method: 'GET', path: '/api/v1/analytics/insights', description: 'Get system insights' },
      ]
    },
    {
      category: 'Workflows',
      endpoints: [
        { method: 'GET', path: '/api/v1/workflows', description: 'List all workflows' },
        { method: 'POST', path: '/api/v1/workflows', description: 'Create new workflow' },
        { method: 'POST', path: '/api/v1/workflows/{id}/execute', description: 'Execute workflow' },
        { method: 'PUT', path: '/api/v1/workflows/{id}', description: 'Update workflow' },
      ]
    },
    {
      category: 'Automations',
      endpoints: [
        { method: 'GET', path: '/api/v1/automations', description: 'List automations' },
        { method: 'POST', path: '/api/v1/automations', description: 'Create automation' },
        { method: 'POST', path: '/api/v1/automations/{id}/toggle', description: 'Toggle automation' },
      ]
    },
    {
      category: 'Authentication',
      endpoints: [
        { method: 'POST', path: '/api/v1/auth/login', description: 'User login' },
        { method: 'POST', path: '/api/v1/auth/mfa/setup', description: 'Setup MFA' },
        { method: 'POST', path: '/api/v1/auth/mfa/enable', description: 'Enable MFA' },
        { method: 'GET', path: '/api/v1/auth/api-keys', description: 'List API keys' },
      ]
    }
  ]

  const copyToClipboard = (text: string, endpoint: string) => {
    navigator.clipboard.writeText(text)
    setCopiedEndpoint(endpoint)
    setTimeout(() => setCopiedEndpoint(null), 2000)
  }

  const runAPITest = async () => {
    setIsTesting(true)
    setTestResponse(null)

    try {
      const { authFetch, getApiBaseUrl } = await import('@/lib/fetch-auth')
      const response = await authFetch(
        testEndpoint.replace(/^\/api\/v1/, '') || testEndpoint,
        { method: testMethod }
      )

      const data = await response.json()
      setTestResponse({
        status: response.status,
        statusText: response.statusText,
        data: data
      })
    } catch (error: any) {
      setTestResponse({
        error: 'Request failed',
        message: error.message
      })
    } finally {
      setIsTesting(false)
    }
  }

  return (
    <div className="min-h-screen bg-slate-950">
      {/* Header */}
      <div className="border-b border-slate-800 bg-slate-900/50">
        <div className="max-w-7xl mx-auto px-6 py-8">
          <div className="flex items-center gap-3 mb-4">
            <Book className="w-8 h-8 text-purple-500" />
            <h1 className="text-3xl font-bold text-white">API Documentation</h1>
          </div>
          <p className="text-slate-400 text-lg">
            Complete reference for Tiannara's REST API. Build intelligent applications with our powerful endpoints.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Sidebar Navigation */}
          <div className="lg:col-span-1">
            <nav className="space-y-2 sticky top-8">
              <button
                onClick={() => setActiveSection('getting-started')}
                className={`w-full text-left px-4 py-3 rounded-lg transition-colors ${
                  activeSection === 'getting-started'
                    ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20'
                    : 'text-slate-400 hover:bg-slate-900 hover:text-white'
                }`}
              >
                Getting Started
              </button>
              <button
                onClick={() => setActiveSection('authentication')}
                className={`w-full text-left px-4 py-3 rounded-lg transition-colors ${
                  activeSection === 'authentication'
                    ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20'
                    : 'text-slate-400 hover:bg-slate-900 hover:text-white'
                }`}
              >
                Authentication
              </button>
              <button
                onClick={() => setActiveSection('endpoints')}
                className={`w-full text-left px-4 py-3 rounded-lg transition-colors ${
                  activeSection === 'endpoints'
                    ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20'
                    : 'text-slate-400 hover:bg-slate-900 hover:text-white'
                }`}
              >
                API Endpoints
              </button>
              <button
                onClick={() => setActiveSection('playground')}
                className={`w-full text-left px-4 py-3 rounded-lg transition-colors ${
                  activeSection === 'playground'
                    ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20'
                    : 'text-slate-400 hover:bg-slate-900 hover:text-white'
                }`}
              >
                API Playground
              </button>
              <button
                onClick={() => setActiveSection('sdks')}
                className={`w-full text-left px-4 py-3 rounded-lg transition-colors ${
                  activeSection === 'sdks'
                    ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20'
                    : 'text-slate-400 hover:bg-slate-900 hover:text-white'
                }`}
              >
                SDKs & Libraries
              </button>
            </nav>
          </div>

          {/* Main Content */}
          <div className="lg:col-span-3 space-y-8">
            {/* Getting Started */}
            {activeSection === 'getting-started' && (
              <div className="space-y-8">
                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Quick Start</h2>
                  <p className="text-slate-400 mb-6">
                    Get up and running with Tiannara API in minutes. Here's everything you need to know.
                  </p>

                  <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
                    <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                      <Terminal className="w-5 h-5 text-purple-400" />
                      Base URL
                    </h3>
                    <code className="block bg-slate-950 rounded-lg p-4 text-green-400 font-mono text-sm">
                      https://api.tiannara.ai/api/v1
                    </code>
                  </div>

                  <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
                    <h3 className="text-lg font-semibold text-white mb-4">Your First Request</h3>
                    <pre className="bg-slate-950 rounded-lg p-4 overflow-x-auto">
                      <code className="text-sm text-slate-300">
{`curl -X GET https://api.tiannara.ai/api/v1/analytics/dashboard \\
  -H "Authorization: Bearer YOUR_API_KEY" \\
  -H "Content-Type: application/json"`}
                      </code>
                    </pre>
                  </div>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Key Features</h2>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <FeatureCard
                      icon={Zap}
                      title="Real-Time Analytics"
                      description="Access live metrics, predictions, and insights from your AI workflows"
                    />
                    <FeatureCard
                      icon={Shield}
                      title="Secure Authentication"
                      description="JWT tokens and API keys with role-based access control"
                    />
                    <FeatureCard
                      icon={Database}
                      title="Workflow Management"
                      description="Create, execute, and monitor complex AI reasoning pipelines"
                    />
                    <FeatureCard
                      icon={Code}
                      title="SDK Support"
                      description="Official libraries for Python, JavaScript, and more"
                    />
                  </div>
                </section>
              </div>
            )}

            {/* Authentication */}
            {activeSection === 'authentication' && (
              <div className="space-y-8">
                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Authentication</h2>
                  <p className="text-slate-400 mb-6">
                    Tiannara API uses JWT tokens for authentication. Include your token in the Authorization header.
                  </p>

                  <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
                    <h3 className="text-lg font-semibold text-white mb-4">Header Format</h3>
                    <code className="block bg-slate-950 rounded-lg p-4 text-green-400 font-mono text-sm">
                      Authorization: Bearer YOUR_JWT_TOKEN
                    </code>
                  </div>

                  <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
                    <h3 className="text-lg font-semibold text-white mb-4">Getting Your API Key</h3>
                    <ol className="list-decimal list-inside space-y-3 text-slate-400">
                      <li>Navigate to Dashboard → API Keys</li>
                      <li>Click "Generate New Key"</li>
                      <li>Copy and securely store your key</li>
                      <li>Use the key in your API requests</li>
                    </ol>
                  </div>
                </section>
              </div>
            )}

            {/* API Endpoints */}
            {activeSection === 'endpoints' && (
              <div className="space-y-8">
                <section>
                  <h2 className="text-2xl font-bold text-white mb-6">API Endpoints</h2>
                  
                  {apiEndpoints.map((category) => (
                    <div key={category.category} className="mb-8">
                      <h3 className="text-xl font-semibold text-white mb-4">{category.category}</h3>
                      <div className="space-y-3">
                        {category.endpoints.map((endpoint) => (
                          <div
                            key={endpoint.path}
                            className="bg-slate-900/50 border border-slate-800 rounded-xl p-4 hover:border-purple-500/30 transition-colors"
                          >
                            <div className="flex items-start justify-between mb-2">
                              <div className="flex items-center gap-3 flex-1">
                                <span className={`px-2 py-1 rounded text-xs font-bold ${
                                  endpoint.method === 'GET' ? 'bg-blue-500/10 text-blue-400' :
                                  endpoint.method === 'POST' ? 'bg-green-500/10 text-green-400' :
                                  endpoint.method === 'PUT' ? 'bg-yellow-500/10 text-yellow-400' :
                                  'bg-red-500/10 text-red-400'
                                }`}>
                                  {endpoint.method}
                                </span>
                                <code className="text-sm text-slate-300 font-mono">{endpoint.path}</code>
                              </div>
                              <button
                                onClick={() => copyToClipboard(`${endpoint.method} ${endpoint.path}`, endpoint.path)}
                                className="p-2 hover:bg-slate-800 rounded-lg transition-colors"
                                title="Copy endpoint"
                              >
                                {copiedEndpoint === endpoint.path ? (
                                  <Check className="w-4 h-4 text-green-400" />
                                ) : (
                                  <Copy className="w-4 h-4 text-slate-400" />
                                )}
                              </button>
                            </div>
                            <p className="text-sm text-slate-400">{endpoint.description}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </section>
              </div>
            )}

            {/* API Playground */}
            {activeSection === 'playground' && (
              <div className="space-y-8">
                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">API Playground</h2>
                  <p className="text-slate-400 mb-6">
                    Test API endpoints directly from your browser. Requires authentication.
                  </p>

                  <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
                    <div className="flex gap-4 mb-4">
                      <select
                        value={testMethod}
                        onChange={(e) => setTestMethod(e.target.value)}
                        className="px-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                      >
                        <option value="GET">GET</option>
                        <option value="POST">POST</option>
                        <option value="PUT">PUT</option>
                        <option value="DELETE">DELETE</option>
                      </select>
                      <input
                        type="text"
                        value={testEndpoint}
                        onChange={(e) => setTestEndpoint(e.target.value)}
                        className="flex-1 px-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-white font-mono text-sm focus:border-purple-500 focus:outline-none"
                        placeholder="/api/v1/endpoint"
                      />
                      <button
                        onClick={runAPITest}
                        disabled={isTesting}
                        className="px-6 py-2 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 disabled:opacity-50 text-white rounded-lg transition-all font-semibold flex items-center gap-2"
                      >
                        {isTesting ? (
                          <>
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            Testing...
                          </>
                        ) : (
                          <>
                            <Play className="w-4 h-4" />
                            Run
                          </>
                        )}
                      </button>
                    </div>

                    {testResponse && (
                      <div className="mt-4">
                        <div className="flex items-center justify-between mb-2">
                          <h4 className="text-sm font-semibold text-slate-400">Response</h4>
                          <span className={`px-2 py-1 rounded text-xs font-bold ${
                            testResponse.status >= 200 && testResponse.status < 300
                              ? 'bg-green-500/10 text-green-400'
                              : 'bg-red-500/10 text-red-400'
                          }`}>
                            {testResponse.status || 'Error'}
                          </span>
                        </div>
                        <pre className="bg-slate-950 rounded-lg p-4 overflow-x-auto max-h-96 overflow-y-auto">
                          <code className="text-sm text-slate-300 font-mono">
                            {JSON.stringify(testResponse, null, 2)}
                          </code>
                        </pre>
                      </div>
                    )}
                  </div>
                </section>
              </div>
            )}

            {/* SDKs */}
            {activeSection === 'sdks' && (
              <div className="space-y-8">
                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">SDKs & Libraries</h2>
                  <p className="text-slate-400 mb-6">
                    Official client libraries for popular programming languages.
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <SDKCard
                      language="Python"
                      install="pip install tiannara-sdk"
                      example={`import tiannara

client = tiannara.Client(api_key="YOUR_KEY")

# Get dashboard metrics
metrics = client.analytics.dashboard()
print(metrics)`}
                    />
                    <SDKCard
                      language="JavaScript"
                      install="npm install @tiannara/sdk"
                      example={`import { TiannaraClient } from '@tiannara/sdk';

const client = new TiannaraClient({
  apiKey: 'YOUR_KEY'
});

// Get dashboard metrics
const metrics = await client.analytics.dashboard();
console.log(metrics);`}
                    />
                  </div>
                </section>
              </div>
            )}
          </div>
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
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/30 transition-colors">
      <div className="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center mb-4">
        <Icon className="w-5 h-5 text-purple-400" />
      </div>
      <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
      <p className="text-sm text-slate-400">{description}</p>
    </div>
  )
}

function SDKCard({ language, install, example }: {
  language: string
  install: string
  example: string
}) {
  const [copied, setCopied] = useState(false)

  const copyExample = () => {
    navigator.clipboard.writeText(example)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white">{language}</h3>
        <button
          onClick={copyExample}
          className="p-2 hover:bg-slate-800 rounded-lg transition-colors"
        >
          {copied ? (
            <Check className="w-4 h-4 text-green-400" />
          ) : (
            <Copy className="w-4 h-4 text-slate-400" />
          )}
        </button>
      </div>

      <div className="mb-4">
        <code className="block bg-slate-950 rounded-lg p-3 text-green-400 font-mono text-sm">
          {install}
        </code>
      </div>

      <pre className="bg-slate-950 rounded-lg p-4 overflow-x-auto">
        <code className="text-sm text-slate-300 font-mono">{example}</code>
      </pre>
    </div>
  )
}
