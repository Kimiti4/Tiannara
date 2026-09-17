/**
 * Workflow Templates System - Tiannara SaaS Launch Catalog
 * 
 * Based on templates.md (lines 1505-1907)
 * UX Principle: Hide complexity, expose intelligence
 * Users see business value, not technical domains
 */

export interface WorkflowNode {
  id: string
  type: string
  position: { x: number; y: number }
  data: {
    label: string
    description?: string
    config?: Record<string, any>
  }
}

export interface WorkflowEdge {
  id: string
  source: string
  target: string
  type?: string
  data?: Record<string, any>
}

export interface WorkflowTemplate {
  id: string
  name: string
  description: string
  category: 'analytics' | 'fraud' | 'research' | 'automation' | 'prediction' | 'organization'
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  estimatedTime: string
  nodes: WorkflowNode[]
  edges: WorkflowEdge[]
  tags: string[]
  recommendedFor: 'starter' | 'professional' | 'enterprise'
  icon: string
  color: string
  
  // Template metadata (from templates.md)
  tierRequired?: 'starter' | 'professional' | 'enterprise'
  domainsUsed?: string[]  // Required Tiannara Core domains
  outputs?: string[]  // Expected outputs
  dashboardWidgets?: string[]  // Auto-generated dashboard components
  automationRules?: string[]  // Built-in automation triggers
}

/**
 * Pre-built workflow templates - Complete catalog from templates.md
 */
export const WORKFLOW_TEMPLATES: WorkflowTemplate[] = [
  // ==================== 🟦 STARTER TIER TEMPLATES ====================
  
  // 1. Customer Intelligence
  {
    id: 'customer_intelligence',
    name: 'Customer Intelligence',
    description: 'Understand customer behavior and identify high-value users.',
    category: 'analytics',
    difficulty: 'beginner',
    estimatedTime: '10 min setup',
    tierRequired: 'starter',
    domainsUsed: ['reverse_engineering', 'causal_engine', 'algorithmic'],
    outputs: ['segments', 'churn_risks', 'behavior_patterns', 'recommendations', 'confidence_scores'],
    dashboardWidgets: ['customer_segments', 'churn_risk_meter', 'behavior_heatmaps', 'retention_suggestions'],
    nodes: [
      {
        id: 'data_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Customer Data', description: 'Import customer profiles and behavior data', config: { source: 'database' } }
      },
      {
        id: 'pattern_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Pattern Analysis', description: 'Identify behavioral patterns and segments', config: { domain: 'reverse_engineering', method: 'clustering' } }
      },
      {
        id: 'causal_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Why This Was Flagged', description: 'Explain what drives customer behavior', config: { domain: 'causal_engine' } }
      },
      {
        id: 'predict_1',
        type: 'prediction',
        position: { x: 700, y: 100 },
        data: { label: 'Possible Outcomes', description: 'Predict churn risk and lifetime value', config: { domain: 'prediction_domain' } }
      },
      {
        id: 'recommend_1',
        type: 'action',
        position: { x: 900, y: 100 },
        data: { label: 'Suggested Actions', description: 'Generate engagement recommendations', config: { action_type: 'campaigns' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'data_1', target: 'pattern_1' },
      { id: 'e2', source: 'pattern_1', target: 'causal_1' },
      { id: 'e3', source: 'causal_1', target: 'predict_1' },
      { id: 'e4', source: 'predict_1', target: 'recommend_1' }
    ],
    tags: ['customers', 'segmentation', 'churn', 'behavior'],
    recommendedFor: 'starter',
    icon: 'users',
    color: 'blue'
  },

  // 2. Predictive Insights
  {
    id: 'predictive_insights',
    name: 'Predictive Insights',
    description: 'Forecast trends and anticipate future changes.',
    category: 'prediction',
    difficulty: 'beginner',
    estimatedTime: '12 min setup',
    tierRequired: 'starter',
    domainsUsed: ['temporal_engine', 'causal_engine', 'prediction_domain'],
    outputs: ['forecasts', 'scenario_models', 'risk_factors', 'confidence_ranges'],
    dashboardWidgets: ['trend_charts', 'forecast_graphs', 'uncertainty_ranges', 'key_influencing_factors'],
    nodes: [
      {
        id: 'data_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Historical Data', description: 'Time-series data for forecasting', config: { source: 'database' } }
      },
      {
        id: 'temporal_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Trend Analysis', description: 'Identify temporal patterns', config: { domain: 'temporal_engine' } }
      },
      {
        id: 'causal_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Key Influencing Factors', description: 'What drives these trends?', config: { domain: 'causal_engine' } }
      },
      {
        id: 'predict_1',
        type: 'prediction',
        position: { x: 700, y: 100 },
        data: { label: 'Possible Outcomes', description: 'Generate forecasts with confidence ranges', config: { domain: 'prediction_domain' } }
      },
      {
        id: 'scenario_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Scenario Models', description: 'Multiple future scenarios', config: { format: 'charts' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'data_1', target: 'temporal_1' },
      { id: 'e2', source: 'temporal_1', target: 'causal_1' },
      { id: 'e3', source: 'causal_1', target: 'predict_1' },
      { id: 'e4', source: 'predict_1', target: 'scenario_1' }
    ],
    tags: ['forecasting', 'trends', 'prediction', 'scenarios'],
    recommendedFor: 'starter',
    icon: 'trending-up',
    color: 'purple'
  },

  // 3. Workflow Automation Assistant
  {
    id: 'workflow_automation',
    name: 'Workflow Automation Assistant',
    description: 'Automate repetitive analysis and operational tasks.',
    category: 'automation',
    difficulty: 'beginner',
    estimatedTime: '8 min setup',
    tierRequired: 'starter',
    domainsUsed: ['nlp_engine', 'algorithmic', 'logic'],
    outputs: ['workflow_actions', 'classifications', 'summaries', 'automation_suggestions'],
    dashboardWidgets: ['automation_status', 'workflow_queue', 'task_insights', 'execution_logs'],
    nodes: [
      {
        id: 'input_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Task Input', description: 'Incoming tasks and requests', config: { source: 'api' } }
      },
      {
        id: 'nlp_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Smart Categorization', description: 'Classify and route tasks intelligently', config: { domain: 'nlp_engine' } }
      },
      {
        id: 'automate_1',
        type: 'automation',
        position: { x: 500, y: 100 },
        data: { label: 'Automation Engine', description: 'Execute automated workflows', config: { domain: 'workflow_orchestrator' } }
      },
      {
        id: 'summarize_1',
        type: 'output',
        position: { x: 700, y: 100 },
        data: { label: 'Auto Summaries', description: 'Generate task summaries automatically', config: { format: 'text' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'input_1', target: 'nlp_1' },
      { id: 'e2', source: 'nlp_1', target: 'automate_1' },
      { id: 'e3', source: 'automate_1', target: 'summarize_1' }
    ],
    tags: ['automation', 'workflow', 'nlp', 'efficiency'],
    recommendedFor: 'starter',
    icon: 'zap',
    color: 'green'
  },

  // 4. Smart Research Assistant
  {
    id: 'smart_research',
    name: 'Smart Research Assistant',
    description: 'Analyze information, identify patterns, and generate insights.',
    category: 'research',
    difficulty: 'intermediate',
    estimatedTime: '15 min setup',
    tierRequired: 'starter',
    domainsUsed: ['nlp_engine', 'reverse_engineering', 'causal_engine'],
    outputs: ['summaries', 'key_findings', 'hypotheses', 'knowledge_graph'],
    dashboardWidgets: ['insight_feed', 'research_graph', 'hypothesis_panel', 'evidence_explorer'],
    nodes: [
      {
        id: 'docs_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Documents & Data', description: 'Research materials and sources', config: { source: 'files' } }
      },
      {
        id: 'nlp_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Document Analysis', description: 'Extract key information and summarize', config: { domain: 'nlp_engine' } }
      },
      {
        id: 'pattern_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Pattern Discovery', description: 'Find relationships and connections', config: { domain: 'reverse_engineering' } }
      },
      {
        id: 'hypothesis_1',
        type: 'intelligence',
        position: { x: 700, y: 100 },
        data: { label: 'Hypothesis Generation', description: 'Generate research hypotheses', config: { domain: 'memory_system' } }
      },
      {
        id: 'report_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Research Report', description: 'Comprehensive findings report', config: { format: 'markdown' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'docs_1', target: 'nlp_1' },
      { id: 'e2', source: 'nlp_1', target: 'pattern_1' },
      { id: 'e3', source: 'pattern_1', target: 'hypothesis_1' },
      { id: 'e4', source: 'hypothesis_1', target: 'report_1' }
    ],
    tags: ['research', 'analysis', 'insights', 'hypotheses'],
    recommendedFor: 'starter',
    icon: 'search',
    color: 'indigo'
  },

  // ==================== 🟪 PROFESSIONAL TIER TEMPLATES ====================

  // 5. Fraud Detection Intelligence
  {
    id: 'fraud_detection',
    name: 'Fraud Detection Intelligence',
    description: 'Detect suspicious activity and reduce operational risk.',
    category: 'fraud',
    difficulty: 'intermediate',
    estimatedTime: '18 min setup',
    tierRequired: 'professional',
    domainsUsed: ['reverse_engineering', 'causal_engine', 'temporal_engine', 'prediction_domain'],
    outputs: ['fraud_alerts', 'risk_scores', 'behavioral_patterns', 'hypotheses', 'uncertainty_scores'],
    dashboardWidgets: ['live_fraud_feed', 'anomaly_graph', 'threat_scoring', 'investigation_panel'],
    nodes: [
      {
        id: 'transactions_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Transaction Stream', description: 'Real-time transaction monitoring', config: { source: 'stream' } }
      },
      {
        id: 'anomaly_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Anomaly Detection', description: 'Detect unusual patterns', config: { domain: 'reverse_engineering' } }
      },
      {
        id: 'pattern_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Fraud Pattern Recognition', description: 'Identify known fraud signatures', config: { domain: 'reverse_engineering' } }
      },
      {
        id: 'score_1',
        type: 'prediction',
        position: { x: 700, y: 100 },
        data: { label: 'Risk Scoring', description: 'Calculate fraud probability', config: { domain: 'prediction_domain' } }
      },
      {
        id: 'explain_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Why This Was Flagged', description: 'Explainable fraud alerts', config: { format: 'detailed_report' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'transactions_1', target: 'anomaly_1' },
      { id: 'e2', source: 'anomaly_1', target: 'pattern_1' },
      { id: 'e3', source: 'pattern_1', target: 'score_1' },
      { id: 'e4', source: 'score_1', target: 'explain_1' }
    ],
    tags: ['fraud', 'security', 'anomaly', 'risk'],
    recommendedFor: 'professional',
    icon: 'shield-alert',
    color: 'red'
  },

  // 6. Operational Monitoring
  {
    id: 'operational_monitoring',
    name: 'Operational Monitoring',
    description: 'Monitor systems, detect anomalies, and prevent downtime.',
    category: 'automation',
    difficulty: 'intermediate',
    estimatedTime: '15 min setup',
    tierRequired: 'professional',
    domainsUsed: ['temporal_engine', 'causal_engine', 'algorithmic'],
    outputs: ['system_health', 'anomalies', 'predicted_failures', 'recommended_actions'],
    dashboardWidgets: ['health_indicators', 'anomaly_timeline', 'prediction_charts', 'operational_insights'],
    nodes: [
      {
        id: 'metrics_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'System Metrics', description: 'Real-time operational data', config: { source: 'monitoring' } }
      },
      {
        id: 'temporal_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Temporal Analysis', description: 'Track system health over time', config: { domain: 'temporal_engine' } }
      },
      {
        id: 'anomaly_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Anomaly Detection', description: 'Detect deviations from normal', config: { domain: 'algorithmic' } }
      },
      {
        id: 'predict_1',
        type: 'prediction',
        position: { x: 700, y: 100 },
        data: { label: 'Failure Prediction', description: 'Predict potential failures', config: { domain: 'prediction_domain' } }
      },
      {
        id: 'actions_1',
        type: 'action',
        position: { x: 900, y: 100 },
        data: { label: 'Recommended Actions', description: 'Preventive maintenance suggestions', config: { action_type: 'maintenance' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'metrics_1', target: 'temporal_1' },
      { id: 'e2', source: 'temporal_1', target: 'anomaly_1' },
      { id: 'e3', source: 'anomaly_1', target: 'predict_1' },
      { id: 'e4', source: 'predict_1', target: 'actions_1' }
    ],
    tags: ['monitoring', 'operations', 'anomaly', 'maintenance'],
    recommendedFor: 'professional',
    icon: 'activity',
    color: 'cyan'
  },

  // 7. Business Intelligence Hub
  {
    id: 'business_intelligence',
    name: 'Business Intelligence Hub',
    description: 'Track business performance and discover hidden insights.',
    category: 'analytics',
    difficulty: 'intermediate',
    estimatedTime: '20 min setup',
    tierRequired: 'professional',
    domainsUsed: ['causal_engine', 'nlp_engine', 'algorithmic', 'temporal_engine'],
    outputs: ['kpis', 'business_drivers', 'trend_analysis', 'executive_summary'],
    dashboardWidgets: ['kpi_board', 'trend_analysis', 'executive_insights', 'opportunity_recommendations'],
    nodes: [
      {
        id: 'data_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Business Data', description: 'KPIs, metrics, and operational data', config: { source: 'warehouse' } }
      },
      {
        id: 'causal_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Driver Analysis', description: 'What explains KPI changes?', config: { domain: 'causal_engine' } }
      },
      {
        id: 'nlp_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Insight Generation', description: 'Generate executive summaries', config: { domain: 'nlp_engine' } }
      },
      {
        id: 'temporal_1',
        type: 'analysis',
        position: { x: 700, y: 100 },
        data: { label: 'Trend Analysis', description: 'Track performance trends', config: { domain: 'temporal_engine' } }
      },
      {
        id: 'dashboard_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Executive Dashboard', description: 'Interactive BI dashboard', config: { format: 'interactive' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'data_1', target: 'causal_1' },
      { id: 'e2', source: 'causal_1', target: 'nlp_1' },
      { id: 'e3', source: 'nlp_1', target: 'temporal_1' },
      { id: 'e4', source: 'temporal_1', target: 'dashboard_1' }
    ],
    tags: ['bi', 'analytics', 'kpi', 'executive'],
    recommendedFor: 'professional',
    icon: 'bar-chart',
    color: 'violet'
  },

  // 8. Team Intelligence Workspace
  {
    id: 'team_intelligence',
    name: 'Team Intelligence Workspace',
    description: 'Collaborate on AI-powered workflows across your organization.',
    category: 'organization',
    difficulty: 'intermediate',
    estimatedTime: '15 min setup',
    tierRequired: 'professional',
    domainsUsed: ['orchestration_layer', 'memory_system', 'workflow_engine'],
    outputs: ['shared_projects', 'team_activity', 'workflow_states', 'collaboration_insights'],
    dashboardWidgets: ['project_tracker', 'team_analytics', 'workflow_status', 'collaboration_metrics'],
    nodes: [
      {
        id: 'workspace_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Shared Workspace', description: 'Team projects and workflows', config: { source: 'collaboration' } }
      },
      {
        id: 'orchestrate_1',
        type: 'intelligence',
        position: { x: 300, y: 100 },
        data: { label: 'Project Orchestration', description: 'Coordinate team workflows', config: { domain: 'orchestration_layer' } }
      },
      {
        id: 'memory_1',
        type: 'intelligence',
        position: { x: 500, y: 100 },
        data: { label: 'Shared Knowledge', description: 'Collective team intelligence', config: { domain: 'memory_system' } }
      },
      {
        id: 'analytics_1',
        type: 'output',
        position: { x: 700, y: 100 },
        data: { label: 'Team Analytics', description: 'Collaboration insights and metrics', config: { format: 'dashboard' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'workspace_1', target: 'orchestrate_1' },
      { id: 'e2', source: 'orchestrate_1', target: 'memory_1' },
      { id: 'e3', source: 'memory_1', target: 'analytics_1' }
    ],
    tags: ['collaboration', 'team', 'workspace', 'shared'],
    recommendedFor: 'professional',
    icon: 'users',
    color: 'teal'
  },

  // ==================== 🟨 ENTERPRISE TIER TEMPLATES ====================

  // 9. Compliance & Governance Intelligence
  {
    id: 'compliance_governance',
    name: 'Compliance & Governance Intelligence',
    description: 'Monitor compliance, track risks, and maintain operational transparency.',
    category: 'organization',
    difficulty: 'advanced',
    estimatedTime: '25 min setup',
    tierRequired: 'enterprise',
    domainsUsed: ['logic', 'causal_engine', 'memory_system', 'explainability_engine'],
    outputs: ['compliance_reports', 'audit_trails', 'risk_assessments', 'governance_alerts'],
    dashboardWidgets: ['compliance_score', 'audit_explorer', 'governance_timeline', 'explainability_viewer'],
    nodes: [
      {
        id: 'operations_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Operational Data', description: 'Business processes and transactions', config: { source: 'systems' } }
      },
      {
        id: 'logic_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Compliance Checking', description: 'Verify regulatory compliance', config: { domain: 'logic' } }
      },
      {
        id: 'causal_1',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Risk Assessment', description: 'Identify governance gaps', config: { domain: 'causal_engine' } }
      },
      {
        id: 'memory_1',
        type: 'intelligence',
        position: { x: 700, y: 100 },
        data: { label: 'Audit Trail Generation', description: 'Create explainable audit records', config: { domain: 'memory_system' } }
      },
      {
        id: 'report_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Compliance Reports', description: 'Regulatory compliance documentation', config: { format: 'pdf' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'operations_1', target: 'logic_1' },
      { id: 'e2', source: 'logic_1', target: 'causal_1' },
      { id: 'e3', source: 'causal_1', target: 'memory_1' },
      { id: 'e4', source: 'memory_1', target: 'report_1' }
    ],
    tags: ['compliance', 'governance', 'audit', 'regulatory'],
    recommendedFor: 'enterprise',
    icon: 'shield-check',
    color: 'slate'
  },

  // 10. Enterprise Decision Intelligence
  {
    id: 'enterprise_decision',
    name: 'Enterprise Decision Intelligence',
    description: 'Support large-scale decision-making with explainable AI insights.',
    category: 'organization',
    difficulty: 'advanced',
    estimatedTime: '30 min setup',
    tierRequired: 'enterprise',
    domainsUsed: ['causal_engine', 'temporal_engine', 'prediction_domain', 'reverse_engineering', 'orchestration'],
    outputs: ['decision_models', 'scenario_analysis', 'tradeoff_maps', 'confidence_assessments'],
    dashboardWidgets: ['decision_matrix', 'scenario_comparison', 'tradeoff_visualizer', 'confidence_dashboard'],
    nodes: [
      {
        id: 'context_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Decision Context', description: 'Strategic objectives and constraints', config: { source: 'strategy' } }
      },
      {
        id: 'causal_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Causal Modeling', description: 'Model decision impacts', config: { domain: 'causal_engine' } }
      },
      {
        id: 'scenario_1',
        type: 'prediction',
        position: { x: 500, y: 100 },
        data: { label: 'Scenario Analysis', description: 'Evaluate multiple outcomes', config: { domain: 'prediction_domain' } }
      },
      {
        id: 'tradeoff_1',
        type: 'analysis',
        position: { x: 700, y: 100 },
        data: { label: 'Tradeoff Analysis', description: 'Explain decision tradeoffs', config: { domain: 'reverse_engineering' } }
      },
      {
        id: 'recommend_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Decision Recommendations', description: 'Optimal decisions with explanations', config: { format: 'strategic_report' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'context_1', target: 'causal_1' },
      { id: 'e2', source: 'causal_1', target: 'scenario_1' },
      { id: 'e3', source: 'scenario_1', target: 'tradeoff_1' },
      { id: 'e4', source: 'tradeoff_1', target: 'recommend_1' }
    ],
    tags: ['decision-making', 'strategy', 'enterprise', 'scenarios'],
    recommendedFor: 'enterprise',
    icon: 'target',
    color: 'amber'
  },

  // 11. Historical Reconstruction Engine (WOW FACTOR)
  {
    id: 'historical_reconstruction',
    name: 'Historical Reconstruction Engine',
    description: 'Explore lost technologies and generate evidence-based reconstruction hypotheses.',
    category: 'research',
    difficulty: 'advanced',
    estimatedTime: '35 min setup',
    tierRequired: 'enterprise',
    domainsUsed: ['reverse_engineering', 'causal_engine', 'memory_system', 'evolution_engine'],
    outputs: ['hypotheses', 'confidence_scores', 'evidence_gaps', 'reconstruction_models', 'recommended_experiments'],
    dashboardWidgets: ['hypothesis_explorer', 'evidence_graph', 'reconstruction_timeline', 'confidence_visualization'],
    nodes: [
      {
        id: 'evidence_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Available Evidence', description: 'Fragments, artifacts, historical records', config: { source: 'archives' } }
      },
      {
        id: 'pattern_1',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Pattern Reconstruction', description: 'Reconstruct incomplete systems', config: { domain: 'reverse_engineering' } }
      },
      {
        id: 'hypothesis_1',
        type: 'intelligence',
        position: { x: 500, y: 100 },
        data: { label: 'Competing Hypotheses', description: 'Generate multiple reconstruction theories', config: { domain: 'memory_system' } }
      },
      {
        id: 'evolve_1',
        type: 'intelligence',
        position: { x: 700, y: 100 },
        data: { label: 'Hypothesis Evolution', description: 'Refine models through simulation', config: { domain: 'evolution_engine' } }
      },
      {
        id: 'experiment_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Discriminating Experiments', description: 'Design experiments to test hypotheses', config: { format: 'experimental_design' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'evidence_1', target: 'pattern_1' },
      { id: 'e2', source: 'pattern_1', target: 'hypothesis_1' },
      { id: 'e3', source: 'hypothesis_1', target: 'evolve_1' },
      { id: 'e4', source: 'evolve_1', target: 'experiment_1' }
    ],
    tags: ['reconstruction', 'hypotheses', 'research', 'discovery'],
    recommendedFor: 'enterprise',
    icon: 'compass',
    color: 'rose'
  },

  // 12. Autonomous Discovery Lab (Future High-End)
  {
    id: 'autonomous_discovery',
    name: 'Autonomous Discovery Lab',
    description: 'Generate hypotheses, run experiments, and discover new insights autonomously.',
    category: 'research',
    difficulty: 'advanced',
    estimatedTime: '40 min setup',
    tierRequired: 'enterprise',
    domainsUsed: ['all_domains', 'evolution_engine', 'orchestration', 'autonomous_scientist'],
    outputs: ['research_goals', 'experiment_plans', 'hypothesis_rankings', 'discovered_patterns', 'next_actions'],
    dashboardWidgets: ['discovery_progress', 'hypothesis_leaderboard', 'experiment_status', 'insight_stream'],
    nodes: [
      {
        id: 'goal_1',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Research Objectives', description: 'Define discovery goals', config: { source: 'objectives' } }
      },
      {
        id: 'hypothesize_1',
        type: 'intelligence',
        position: { x: 300, y: 100 },
        data: { label: 'Autonomous Hypothesis Generation', description: 'AI generates novel hypotheses', config: { domain: 'all_domains' } }
      },
      {
        id: 'experiment_1',
        type: 'automation',
        position: { x: 500, y: 100 },
        data: { label: 'Experiment Design & Execution', description: 'Plan and run discriminating experiments', config: { domain: 'orchestration' } }
      },
      {
        id: 'learn_1',
        type: 'intelligence',
        position: { x: 700, y: 100 },
        data: { label: 'Learning from Outcomes', description: 'Update knowledge from results', config: { domain: 'evolution_engine' } }
      },
      {
        id: 'discover_1',
        type: 'output',
        position: { x: 900, y: 100 },
        data: { label: 'Discovered Insights', description: 'Novel patterns and breakthrough discoveries', config: { format: 'research_paper' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'goal_1', target: 'hypothesize_1' },
      { id: 'e2', source: 'hypothesize_1', target: 'experiment_1' },
      { id: 'e3', source: 'experiment_1', target: 'learn_1' },
      { id: 'e4', source: 'learn_1', target: 'discover_1' },
      { id: 'e5', source: 'discover_1', target: 'hypothesize_1' }
    ],
    tags: ['autonomous', 'discovery', 'research', 'ai-scientist'],
    recommendedFor: 'enterprise',
    icon: 'flask-conical',
    color: 'fuchsia'
  },
  
  // ==================== ⚽ SPORTS PREDICTION TEMPLATES ====================
  
  // 13. Match Winner Prediction
  {
    id: 'match_winner_prediction',
    name: 'Match Winner Prediction',
    description: 'Predict football match outcomes using real-time momentum, odds movements, and news impact analysis.',
    category: 'prediction',
    difficulty: 'beginner',
    estimatedTime: '5 min setup',
    tierRequired: 'professional',
    domainsUsed: ['prediction_engine', 'feature_engineering'],
    outputs: ['win_probabilities', 'confidence_score', 'chaos_level', 'key_drivers', 'risk_assessment'],
    dashboardWidgets: ['probability_gauge', 'momentum_chart', 'chaos_indicator', 'value_detector', 'news_impact_feed'],
    nodes: [
      {
        id: 'match_input',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Match Data', description: 'Enter teams or select live match', config: { input_type: 'match_selector' } }
      },
      {
        id: 'feature_eng',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Feature Engineering', description: 'Calculate momentum, chaos index, odds velocity', config: { domain: 'feature_engineering', formulas: ['momentum_index', 'chaos_index', 'odds_velocity', 'news_impact'] } }
      },
      {
        id: 'predict_outcome',
        type: 'prediction',
        position: { x: 500, y: 100 },
        data: { label: 'Outcome Prediction', description: 'Generate win/draw/loss probabilities', config: { domain: 'prediction_engine', task: 'sports_prediction' } }
      },
      {
        id: 'intelligence',
        type: 'analysis',
        position: { x: 700, y: 100 },
        data: { label: 'Match Intelligence', description: 'Chaos level, value signals, key drivers', config: { output_type: 'intelligence_report' } }
      },
      {
        id: 'recommendation',
        type: 'action',
        position: { x: 900, y: 100 },
        data: { label: 'Betting Recommendation', description: 'Risk assessment and suggested actions', config: { action_type: 'betting_advice' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'match_input', target: 'feature_eng' },
      { id: 'e2', source: 'feature_eng', target: 'predict_outcome' },
      { id: 'e3', source: 'predict_outcome', target: 'intelligence' },
      { id: 'e4', source: 'intelligence', target: 'recommendation' }
    ],
    tags: ['sports', 'football', 'prediction', 'momentum', 'chaos-index'],
    recommendedFor: 'professional',
    icon: 'trophy',
    color: 'green'
  },
  
  // 14. Jackpot Match Optimizer
  {
    id: 'jackpot_optimizer',
    name: 'Jackpot Match Optimizer',
    description: 'Identify high-variance matches perfect for jackpot betting systems using Chaos Index and volatility analysis.',
    category: 'prediction',
    difficulty: 'intermediate',
    estimatedTime: '8 min setup',
    tierRequired: 'professional',
    domainsUsed: ['prediction_engine', 'feature_engineering', 'causal_engine'],
    outputs: ['chaos_scores', 'jackpot_potential', 'volatility_ranking', 'hedging_suggestions', 'risk_matrix'],
    dashboardWidgets: ['chaos_heatmap', 'jackpot_matches_list', 'volatility_chart', 'risk_meter'],
    nodes: [
      {
        id: 'match_batch',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Match Batch', description: 'Select multiple matches to analyze', config: { input_type: 'batch_selector', max_matches: 20 } }
      },
      {
        id: 'chaos_calc',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Chaos Index Calculation', description: 'Compute unpredictability for each match', config: { domain: 'feature_engineering', formula: 'chaos_index' } }
      },
      {
        id: 'volatility_analysis',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Volatility Analysis', description: 'Rank matches by odds volatility and news conflict', config: { metrics: ['odds_volatility', 'news_conflict', 'momentum_swings'] } }
      },
      {
        id: 'jackpot_filter',
        type: 'filter',
        position: { x: 700, y: 100 },
        data: { label: 'Jackpot Filter', description: 'Filter high-chaos matches (CI > 0.6)', config: { threshold: 0.6, sort_by: 'chaos_desc' } }
      },
      {
        id: 'optimization',
        type: 'action',
        position: { x: 900, y: 100 },
        data: { label: 'Portfolio Optimization', description: 'Suggest optimal jackpot combinations', config: { strategy: 'diversification', risk_tolerance: 'high' } }
      }
    ],
    edges: [
      { id: 'e1', source: 'match_batch', target: 'chaos_calc' },
      { id: 'e2', source: 'chaos_calc', target: 'volatility_analysis' },
      { id: 'e3', source: 'volatility_analysis', target: 'jackpot_filter' },
      { id: 'e4', source: 'jackpot_filter', target: 'optimization' }
    ],
    tags: ['sports', 'jackpot', 'chaos', 'volatility', 'portfolio'],
    recommendedFor: 'professional',
    icon: 'sparkles',
    color: 'purple'
  },
  
  // 15. Live Betting Edge Detector
  {
    id: 'live_bet_edge',
    name: 'Live Betting Edge Detector',
    description: 'Detect value bets in real-time by comparing model predictions vs market odds during live matches.',
    category: 'prediction',
    difficulty: 'advanced',
    estimatedTime: '10 min setup',
    tierRequired: 'enterprise',
    domainsUsed: ['prediction_engine', 'feature_engineering', 'real_time_streaming'],
    outputs: ['value_signals', 'mis_scores', 'entry_timing', 'exit_strategy', 'live_alerts'],
    dashboardWidgets: ['live_odds_tracker', 'value_alerts', 'mis_gauge', 'timing_recommendations', 'profit_tracker'],
    automationRules: ['alert_on_value_opportunity', 'auto_update_every_30s', 'notify_on_chaos_spike'],
    nodes: [
      {
        id: 'live_match',
        type: 'input',
        position: { x: 100, y: 100 },
        data: { label: 'Live Match Stream', description: 'Connect to live match data feed', config: { input_type: 'websocket_stream', update_interval: 30 } }
      },
      {
        id: 'realtime_features',
        type: 'analysis',
        position: { x: 300, y: 100 },
        data: { label: 'Real-Time Features', description: 'Continuously update momentum, odds velocity, news', config: { domain: 'feature_engineering', streaming: true } }
      },
      {
        id: 'market_comparison',
        type: 'analysis',
        position: { x: 500, y: 100 },
        data: { label: 'Market Inefficiency Detection', description: 'Compare model probs vs market odds', config: { metric: 'market_inefficiency_score', threshold: 0.1 } }
      },
      {
        id: 'edge_detector',
        type: 'filter',
        position: { x: 700, y: 100 },
        data: { label: 'Edge Detection', description: 'Identify significant value opportunities', config: { min_mis: 0.1, min_confidence: 0.6 } }
      },
      {
        id: 'execution',
        type: 'action',
        position: { x: 900, y: 100 },
        data: { label: 'Trade Execution Signals', description: 'Entry/exit timing with risk management', config: { action_type: 'trading_signals', include_stop_loss: true } }
      }
    ],
    edges: [
      { id: 'e1', source: 'live_match', target: 'realtime_features' },
      { id: 'e2', source: 'realtime_features', target: 'market_comparison' },
      { id: 'e3', source: 'market_comparison', target: 'edge_detector' },
      { id: 'e4', source: 'edge_detector', target: 'execution' }
    ],
    tags: ['sports', 'live-betting', 'value-detection', 'real-time', 'arbitrage'],
    recommendedFor: 'enterprise',
    icon: 'zap',
    color: 'orange'
  }
]

/**
 * Get template by ID
 */
export function getTemplateById(id: string): WorkflowTemplate | undefined {
  return WORKFLOW_TEMPLATES.find(t => t.id === id)
}

/**
 * Get templates by category
 */
export function getTemplatesByCategory(category: WorkflowTemplate['category']): WorkflowTemplate[] {
  return WORKFLOW_TEMPLATES.filter(t => t.category === category)
}

/**
 * Get templates by difficulty
 */
export function getTemplatesByDifficulty(difficulty: WorkflowTemplate['difficulty']): WorkflowTemplate[] {
  return WORKFLOW_TEMPLATES.filter(t => t.difficulty === difficulty)
}

/**
 * Get templates recommended for user tier
 */
export function getTemplatesForTier(tier: 'starter' | 'professional' | 'enterprise'): WorkflowTemplate[] {
  if (tier === 'enterprise') {
    return WORKFLOW_TEMPLATES // Enterprise gets all
  }
  if (tier === 'professional') {
    return WORKFLOW_TEMPLATES.filter(t => t.recommendedFor === 'starter' || t.recommendedFor === 'professional')
  }
  return WORKFLOW_TEMPLATES.filter(t => t.recommendedFor === 'starter')
}

/**
 * Check if user can access template based on tier
 */
export function canAccessTemplate(template: WorkflowTemplate, userTier: 'starter' | 'professional' | 'enterprise'): boolean {
  if (!template.tierRequired) return true
  const tierLevels = { starter: 1, professional: 2, enterprise: 3 }
  return tierLevels[userTier] >= tierLevels[template.tierRequired]
}

/**
 * Search templates by keyword
 */
export function searchTemplates(query: string): WorkflowTemplate[] {
  const lowercaseQuery = query.toLowerCase()
  return WORKFLOW_TEMPLATES.filter(t =>
    t.name.toLowerCase().includes(lowercaseQuery) ||
    t.description.toLowerCase().includes(lowercaseQuery) ||
    t.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery))
  )
}

/**
 * Get all available categories
 */
export function getTemplateCategories(): string[] {
  const categories = new Set(WORKFLOW_TEMPLATES.map(t => t.category))
  return Array.from(categories)
}

/**
 * Get all available tags
 */
export function getTemplateTags(): string[] {
  const tags = new Set<string>()
  WORKFLOW_TEMPLATES.forEach(t => t.tags.forEach(tag => tags.add(tag)))
  return Array.from(tags)
}

/**
 * Get templates by tier requirement
 */
export function getTemplatesByTier(tier: 'starter' | 'professional' | 'enterprise'): WorkflowTemplate[] {
  return WORKFLOW_TEMPLATES.filter(t => t.tierRequired === tier || !t.tierRequired)
}
