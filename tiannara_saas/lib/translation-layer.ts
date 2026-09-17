/**
 * Translation Layer - Technical to User-Friendly Naming
 * 
 * Maps internal system terminology to user-friendly SaaS naming.
 * This makes onboarding easier and reduces cognitive load for users.
 * 
 * Based on architecture.md lines 638-649
 */

export interface TranslationMap {
  [technicalName: string]: {
    friendly: string
    description: string
    icon?: string
    category: 'analysis' | 'automation' | 'intelligence' | 'infrastructure'
  }
}

/**
 * Core translation mapping from technical domain names to user-friendly terms
 */
export const DOMAIN_TRANSLATIONS: TranslationMap = {
  // Cognitive Domains
  'causal_engine': {
    friendly: 'Root Cause Analysis',
    description: 'Identify underlying causes and dependencies in your data',
    icon: 'search',
    category: 'analysis'
  },
  'prediction_domain': {
    friendly: 'Forecasting',
    description: 'Predict future trends and outcomes with confidence scores',
    icon: 'trending-up',
    category: 'analysis'
  },
  'reverse_engineering': {
    friendly: 'Pattern Intelligence',
    description: 'Discover hidden patterns and reverse-engineer complex systems',
    icon: 'puzzle',
    category: 'intelligence'
  },
  'workflow_orchestrator': {
    friendly: 'Automation Engine',
    description: 'Automate multi-step workflows and decision pipelines',
    icon: 'zap',
    category: 'automation'
  },
  'memory_system': {
    friendly: 'Knowledge Workspace',
    description: 'Store, retrieve, and build upon organizational knowledge',
    icon: 'database',
    category: 'infrastructure'
  },
  'evolution_engine': {
    friendly: 'Adaptive Optimization',
    description: 'Continuously improve workflows based on performance data',
    icon: 'refresh-cw',
    category: 'automation'
  },
  
  // Vision & Web Domains
  'vision_engine': {
    friendly: 'Visual Intelligence',
    description: 'Analyze images, detect objects, and understand visual content',
    icon: 'eye',
    category: 'intelligence'
  },
  'web_intelligence': {
    friendly: 'Web Research',
    description: 'Gather context, verify facts, and analyze trends from the web',
    icon: 'globe',
    category: 'intelligence'
  },
  'nlp_engine': {
    friendly: 'Text Analytics',
    description: 'Extract insights, sentiment, and entities from text',
    icon: 'file-text',
    category: 'analysis'
  },
  
  // Workflow Components
  'input_node': {
    friendly: 'Data Input',
    description: 'Connect your data sources and inputs',
    icon: 'download',
    category: 'infrastructure'
  },
  'transform_node': {
    friendly: 'Data Transform',
    description: 'Clean, filter, and transform your data',
    icon: 'shuffle',
    category: 'automation'
  },
  'alert_node': {
    friendly: 'Alert System',
    description: 'Set up notifications and alerts for key events',
    icon: 'bell',
    category: 'automation'
  },
  'report_node': {
    friendly: 'Report Generator',
    description: 'Generate comprehensive reports and summaries',
    icon: 'file-bar-chart',
    category: 'analysis'
  }
}

/**
 * Translate a technical name to user-friendly display name
 */
export function translateTechnicalName(technicalName: string): string {
  const translation = DOMAIN_TRANSLATIONS[technicalName]
  return translation ? translation.friendly : technicalName
}

/**
 * Get full translation details for a technical name
 */
export function getTranslationDetails(technicalName: string) {
  return DOMAIN_TRANSLATIONS[technicalName] || {
    friendly: technicalName,
    description: 'System component',
    category: 'infrastructure'
  }
}

/**
 * Get all translations by category
 */
export function getTranslationsByCategory(category: TranslationMap[string]['category']) {
  return Object.entries(DOMAIN_TRANSLATIONS)
    .filter(([_, value]) => value.category === category)
    .map(([key, value]) => ({
      technicalName: key,
      ...value
    }))
}

/**
 * Get all available categories
 */
export function getAvailableCategories() {
  const categories = new Set<string>()
  Object.values(DOMAIN_TRANSLATIONS).forEach(item => {
    categories.add(item.category)
  })
  return Array.from(categories)
}

/**
 * Search translations by keyword
 */
export function searchTranslations(query: string) {
  const lowercaseQuery = query.toLowerCase()
  return Object.entries(DOMAIN_TRANSLATIONS)
    .filter(([key, value]) => 
      key.toLowerCase().includes(lowercaseQuery) ||
      value.friendly.toLowerCase().includes(lowercaseQuery) ||
      value.description.toLowerCase().includes(lowercaseQuery)
    )
    .map(([key, value]) => ({
      technicalName: key,
      ...value
    }))
}

/**
 * Convert array of technical names to friendly names
 */
export function translateMultipleNames(technicalNames: string[]): string[] {
  return technicalNames.map(name => translateTechnicalName(name))
}

/**
 * Get suggested friendly name for workflow templates
 */
export function getTemplateFriendlyName(templateId: string): string {
  const templateNames: Record<string, string> = {
    'fraud_detection': 'Fraud Detection Pipeline',
    'customer_segmentation': 'Customer Segmentation Analysis',
    'marketing_analysis': 'Marketing Campaign Insights',
    'business_monitoring': 'Business Health Monitor',
    'prediction_pipeline': 'Predictive Analytics Workflow',
    'root_cause_analysis': 'Root Cause Investigation',
    'content_moderation': 'Content Moderation System',
    'risk_assessment': 'Risk Assessment Framework',
    'anomaly_detection': 'Anomaly Detection System',
    'sentiment_tracking': 'Sentiment Tracking Dashboard'
  }
  
  return templateNames[templateId] || templateId
}
