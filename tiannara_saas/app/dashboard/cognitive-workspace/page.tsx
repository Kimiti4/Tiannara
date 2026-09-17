'use client'

import { useState, useRef } from 'react'
import { Upload, Image as ImageIcon, Globe, Brain, Zap, Loader2, CheckCircle, AlertCircle } from 'lucide-react'
import { apiClient } from '@/lib/api'

interface AnalysisResult {
  vision?: {
    objects: string[]
    description: string
    confidence: number
  }
  web?: {
    related_info: string[]
    sources: string[]
  }
  nlp?: {
    summary: string
    entities: string[]
    sentiment: string
  }
  prediction?: {
    insights: string[]
    recommendations: string[]
  }
}

export default function CognitiveWorkspacePage() {
  const [activeTab, setActiveTab] = useState<'upload' | 'text'>('upload')
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [textInput, setTextInput] = useState('')
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [selectedDomains, setSelectedDomains] = useState({
    vision: true,
    web: true,
    nlp: true,
    prediction: false,
  })
  const [result, setResult] = useState<AnalysisResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setImageFile(file)
      const reader = new FileReader()
      reader.onloadend = () => {
        setImagePreview(reader.result as string)
      }
      reader.readAsDataURL(file)
      setResult(null)
      setError(null)
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    const file = e.dataTransfer.files?.[0]
    if (file && file.type.startsWith('image/')) {
      setImageFile(file)
      const reader = new FileReader()
      reader.onloadend = () => {
        setImagePreview(reader.result as string)
      }
      reader.readAsDataURL(file)
      setResult(null)
      setError(null)
    }
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
  }

  const toggleDomain = (domain: keyof typeof selectedDomains) => {
    setSelectedDomains(prev => ({
      ...prev,
      [domain]: !prev[domain],
    }))
  }

  const analyzeContent = async () => {
    if (!imageFile && !textInput.trim()) {
      setError('Please upload an image or enter text to analyze')
      return
    }

    try {
      setIsAnalyzing(true)
      setError(null)
      setResult(null)

      // Build active domains list
      const activeDomains = Object.entries(selectedDomains)
        .filter(([_, enabled]) => enabled)
        .map(([domain]) => domain)

      if (activeDomains.length === 0) {
        setError('Please select at least one cognitive domain')
        setIsAnalyzing(false)
        return
      }

      let response

      // Call appropriate API based on input type
      if (imageFile) {
        // Image analysis
        response = await apiClient.analyzeImage(imageFile, activeDomains)
      } else {
        // Text analysis - convert to base64
        const base64Text = btoa(unescape(encodeURIComponent(textInput)))
        response = await apiClient.runCognitiveAnalysis(
          'text',
          base64Text,
          activeDomains
        )
      }

      if (response.success && response.data) {
        // Transform API response to match our interface
        const apiResults = response.data.results || {}
        
        const transformedResult: AnalysisResult = {}
        
        if (apiResults.vision) {
          transformedResult.vision = {
            objects: apiResults.vision.objects || [],
            description: apiResults.vision.description || '',
            confidence: apiResults.vision.confidence || 0,
          }
        }
        
        if (apiResults.web) {
          transformedResult.web = {
            related_info: apiResults.web.related_info || [],
            sources: apiResults.web.sources || [],
          }
        }
        
        if (apiResults.nlp) {
          transformedResult.nlp = {
            summary: apiResults.nlp.summary || '',
            entities: apiResults.nlp.entities || [],
            sentiment: apiResults.nlp.sentiment || 'neutral',
          }
        }
        
        if (apiResults.prediction) {
          transformedResult.prediction = {
            insights: apiResults.prediction.insights || [],
            recommendations: apiResults.prediction.recommendations || [],
          }
        }
        
        setResult(transformedResult)
      } else {
        setError(response.error || 'Analysis failed. Please try again.')
      }
    } catch (err) {
      setError('Analysis failed. Please try again.')
      console.error('Analysis error:', err)
    } finally {
      setIsAnalyzing(false)
    }
  }

  const resetAnalysis = () => {
    setImageFile(null)
    setImagePreview(null)
    setTextInput('')
    setResult(null)
    setError(null)
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Cognitive Workspace</h1>
        <p className="text-slate-400">
          Upload images or text for multi-domain AI analysis. Vision, Web, NLP, and Prediction engines collaborate to provide comprehensive insights.
        </p>
      </div>

      {/* Domain Selection */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Brain className="w-5 h-5 text-purple-400" />
          Active Cognitive Domains
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <button
            onClick={() => toggleDomain('vision')}
            className={`p-4 rounded-xl border-2 transition-all ${
              selectedDomains.vision
                ? 'border-purple-500 bg-purple-500/10'
                : 'border-slate-700 bg-slate-800/50 opacity-50'
            }`}
          >
            <ImageIcon className="w-6 h-6 mb-2 mx-auto text-purple-400" />
            <p className="text-sm font-medium text-white">Vision</p>
            <p className="text-xs text-slate-400 mt-1">Image understanding</p>
          </button>

          <button
            onClick={() => toggleDomain('web')}
            className={`p-4 rounded-xl border-2 transition-all ${
              selectedDomains.web
                ? 'border-blue-500 bg-blue-500/10'
                : 'border-slate-700 bg-slate-800/50 opacity-50'
            }`}
          >
            <Globe className="w-6 h-6 mb-2 mx-auto text-blue-400" />
            <p className="text-sm font-medium text-white">Web Intelligence</p>
            <p className="text-xs text-slate-400 mt-1">Context & research</p>
          </button>

          <button
            onClick={() => toggleDomain('nlp')}
            className={`p-4 rounded-xl border-2 transition-all ${
              selectedDomains.nlp
                ? 'border-green-500 bg-green-500/10'
                : 'border-slate-700 bg-slate-800/50 opacity-50'
            }`}
          >
            <Brain className="w-6 h-6 mb-2 mx-auto text-green-400" />
            <p className="text-sm font-medium text-white">NLP</p>
            <p className="text-xs text-slate-400 mt-1">Text analysis</p>
          </button>

          <button
            onClick={() => toggleDomain('prediction')}
            className={`p-4 rounded-xl border-2 transition-all ${
              selectedDomains.prediction
                ? 'border-orange-500 bg-orange-500/10'
                : 'border-slate-700 bg-slate-800/50 opacity-50'
            }`}
          >
            <Zap className="w-6 h-6 mb-2 mx-auto text-orange-400" />
            <p className="text-sm font-medium text-white">Prediction</p>
            <p className="text-xs text-slate-400 mt-1">Insights & forecasts</p>
          </button>
        </div>
      </div>

      {/* Input Section */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-6">
        {/* Tab Switcher */}
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setActiveTab('upload')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              activeTab === 'upload'
                ? 'bg-purple-600 text-white'
                : 'bg-slate-800 text-slate-400 hover:text-white'
            }`}
          >
            Image Upload
          </button>
          <button
            onClick={() => setActiveTab('text')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              activeTab === 'text'
                ? 'bg-purple-600 text-white'
                : 'bg-slate-800 text-slate-400 hover:text-white'
            }`}
          >
            Text Input
          </button>
        </div>

        {/* Image Upload Area */}
        {activeTab === 'upload' && (
          <div
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            className="border-2 border-dashed border-slate-700 rounded-xl p-8 text-center hover:border-purple-500 transition-colors cursor-pointer"
            onClick={() => fileInputRef.current?.click()}
          >
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleImageUpload}
              className="hidden"
            />

            {imagePreview ? (
              <div className="relative">
                <img
                  src={imagePreview}
                  alt="Preview"
                  className="max-h-64 mx-auto rounded-lg"
                />
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    resetAnalysis()
                  }}
                  className="absolute top-2 right-2 bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded-lg text-sm"
                >
                  Remove
                </button>
              </div>
            ) : (
              <>
                <Upload className="w-12 h-12 mx-auto text-slate-500 mb-4" />
                <p className="text-white font-medium mb-2">
                  Drop your image here, or click to browse
                </p>
                <p className="text-sm text-slate-400">
                  Supports JPG, PNG, GIF up to 10MB
                </p>
              </>
            )}
          </div>
        )}

        {/* Text Input Area */}
        {activeTab === 'text' && (
          <textarea
            value={textInput}
            onChange={(e) => setTextInput(e.target.value)}
            placeholder="Enter text to analyze... The cognitive domains will collaborate to provide comprehensive insights."
            className="w-full h-48 bg-slate-950 border border-slate-800 rounded-xl p-4 text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 transition-colors resize-none"
          />
        )}

        {/* Error Message */}
        {error && (
          <div className="mt-4 bg-red-500/10 border border-red-500/50 rounded-lg p-3 flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-red-400" />
            <p className="text-sm text-red-400">{error}</p>
          </div>
        )}

        {/* Analyze Button */}
        <div className="mt-6 flex gap-3">
          <button
            onClick={analyzeContent}
            disabled={isAnalyzing || (!imageFile && !textInput.trim())}
            className="flex-1 px-6 py-3 bg-purple-600 hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium rounded-xl transition-colors flex items-center justify-center gap-2"
          >
            {isAnalyzing ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Analyzing with {Object.values(selectedDomains).filter(Boolean).length} domains...
              </>
            ) : (
              <>
                <Brain className="w-4 h-4" />
                Run Cognitive Analysis
              </>
            )}
          </button>

          {(imageFile || textInput) && (
            <button
              onClick={resetAnalysis}
              className="px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white font-medium rounded-xl transition-colors"
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Results Section */}
      {result && (
        <div className="space-y-6">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <CheckCircle className="w-5 h-5 text-green-400" />
            Analysis Results
          </h2>

          {/* Vision Results */}
          {result.vision && (
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-purple-400 mb-4 flex items-center gap-2">
                <ImageIcon className="w-5 h-5" />
                Vision Analysis
              </h3>
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-slate-400 mb-1">Description</p>
                  <p className="text-white">{result.vision.description}</p>
                </div>
                <div>
                  <p className="text-sm text-slate-400 mb-2">Detected Objects</p>
                  <div className="flex flex-wrap gap-2">
                    {result.vision.objects.map((obj, idx) => (
                      <span
                        key={idx}
                        className="px-3 py-1 bg-purple-500/20 text-purple-300 rounded-full text-sm"
                      >
                        {obj}
                      </span>
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-sm text-slate-400">Confidence</p>
                  <div className="flex items-center gap-2">
                    <div className="flex-1 bg-slate-800 rounded-full h-2">
                      <div
                        className="bg-purple-500 h-2 rounded-full transition-all"
                        style={{ width: `${result.vision.confidence * 100}%` }}
                      />
                    </div>
                    <span className="text-white font-medium">
                      {(result.vision.confidence * 100).toFixed(1)}%
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Web Intelligence Results */}
          {result.web && (
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-blue-400 mb-4 flex items-center gap-2">
                <Globe className="w-5 h-5" />
                Web Intelligence
              </h3>
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-slate-400 mb-2">Related Information</p>
                  <ul className="space-y-2">
                    {result.web.related_info.map((info, idx) => (
                      <li key={idx} className="text-white text-sm flex items-start gap-2">
                        <span className="text-blue-400 mt-1">•</span>
                        {info}
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <p className="text-sm text-slate-400 mb-2">Sources</p>
                  <div className="flex flex-wrap gap-2">
                    {result.web.sources.map((source, idx) => (
                      <span
                        key={idx}
                        className="px-3 py-1 bg-blue-500/20 text-blue-300 rounded-full text-sm"
                      >
                        {source}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* NLP Results */}
          {result.nlp && (
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-green-400 mb-4 flex items-center gap-2">
                <Brain className="w-5 h-5" />
                NLP Analysis
              </h3>
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-slate-400 mb-1">Summary</p>
                  <p className="text-white">{result.nlp.summary}</p>
                </div>
                <div>
                  <p className="text-sm text-slate-400 mb-2">Key Entities</p>
                  <div className="flex flex-wrap gap-2">
                    {result.nlp.entities.map((entity, idx) => (
                      <span
                        key={idx}
                        className="px-3 py-1 bg-green-500/20 text-green-300 rounded-full text-sm"
                      >
                        {entity}
                      </span>
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-sm text-slate-400">Sentiment</p>
                  <span
                    className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                      result.nlp.sentiment === 'Positive'
                        ? 'bg-green-500/20 text-green-300'
                        : result.nlp.sentiment === 'Negative'
                        ? 'bg-red-500/20 text-red-300'
                        : 'bg-yellow-500/20 text-yellow-300'
                    }`}
                  >
                    {result.nlp.sentiment}
                  </span>
                </div>
              </div>
            </div>
          )}

          {/* Prediction Results */}
          {result.prediction && (
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-orange-400 mb-4 flex items-center gap-2">
                <Zap className="w-5 h-5" />
                Predictive Insights
              </h3>
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-slate-400 mb-2">Key Insights</p>
                  <ul className="space-y-2">
                    {result.prediction.insights.map((insight, idx) => (
                      <li key={idx} className="text-white text-sm flex items-start gap-2">
                        <span className="text-orange-400 mt-1">▸</span>
                        {insight}
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <p className="text-sm text-slate-400 mb-2">Recommendations</p>
                  <ul className="space-y-2">
                    {result.prediction.recommendations.map((rec, idx) => (
                      <li key={idx} className="text-white text-sm flex items-start gap-2">
                        <span className="text-orange-400 mt-1">✓</span>
                        {rec}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
