/**
 * Tiannara API Client
 * 
 * Centralized API communication layer for the SaaS frontend.
 * Handles authentication, error handling, and request/response formatting.
 */

/** Same-origin proxy in dev (see next.config.ts rewrites). */
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || '/api/v1'

export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

export interface ApiKey {
  id: string
  name: string
  key: string
  created_at: string
  last_used: string | null
  request_count: number
  status: 'active' | 'revoked'
  tier: string
}

export interface UsageMetrics {
  total_requests: number
  success_rate: number
  avg_latency_ms: number
  error_count: number
  daily_usage: Array<{
    date: string
    requests: number
    success: number
    errors: number
  }>
  domain_breakdown: Array<{
    domain: string
    count: number
    percentage: number
  }>
}

export interface UserProfile {
  id: string
  email: string
  name: string
  company?: string
  role?: string
  tier: 'starter' | 'professional' | 'enterprise'
  created_at: string
  api_keys_count: number
}

export interface Subscription {
  id: string
  plan: string
  status: 'active' | 'cancelled' | 'past_due'
  current_period_start: string
  current_period_end: string
  amount: number
  currency: string
}

export interface PaymentHistory {
  id: string
  amount: number
  currency: string
  status: 'paid' | 'pending' | 'failed'
  invoice_number: string
  created_at: string
  download_url?: string
}

export interface Workflow {
  id: string
  name: string
  description: string
  nodes: any[]
  edges: any[]
  status: 'draft' | 'active' | 'paused' | 'archived'
  created_at: string
  updated_at: string
  last_run?: string
  run_count: number
}

export interface Automation {
  id: string
  name: string
  description: string
  trigger_type: 'scheduled' | 'event' | 'threshold'
  trigger_config: any
  workflow_id: string
  status: 'active' | 'paused' | 'disabled'
  last_triggered?: string
  created_at: string
}

export interface Insight {
  id: string
  type: 'root_cause' | 'pattern' | 'forecast' | 'anomaly'
  title: string
  description: string
  confidence: number
  created_at: string
  metadata?: any
}

export interface ApiKeySummary {
  id: string
  name: string
  key_masked: string
  created_at: string
  last_used: string | null
  request_count: number
  status: 'active' | 'revoked'
}

export interface Prediction {
  id: string
  metric: string
  predicted_value: number
  confidence: number
  timeframe: string
  trend: 'up' | 'down' | 'stable'
  created_at: string
}

export interface TeamMember {
  id: string
  user_id: string
  name: string
  email: string
  role: 'owner' | 'admin' | 'developer' | 'analyst' | 'viewer'
  status: 'active' | 'inactive' | 'pending'
  joined_at: string
  last_active?: string
}

export interface SystemCapabilities {
  available_engines: string[]
  max_workflow_nodes: number
  max_api_keys: number
  features: {
    forecasting: boolean
    causal_analysis: boolean
    nlp: boolean
    automation: boolean
    team_collaboration: boolean
  }
}

class ApiClient {
  private baseURL: string

  constructor() {
    this.baseURL = API_BASE_URL
    if (typeof window !== 'undefined') {
      localStorage.removeItem('tiannara_token')
    }
  }

  /** Clear server session cookie. */
  clearToken() {
    /* no-op: auth is cookie-based */
  }

  async logout(): Promise<ApiResponse<void>> {
    const result = await this.request('/auth/logout', { method: 'POST' })
    return result
  }

  /**
   * Make HTTP request with error handling
   */
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      const url = `${this.baseURL}${endpoint}`
      
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      }

      // Merge custom headers if provided
      if (options.headers) {
        Object.assign(headers, options.headers)
      }

      const response = await fetch(url, {
        ...options,
        credentials: 'include',
        headers,
      })

      const data = await response.json()

      if (!response.ok) {
        return {
          success: false,
          error: data.detail || data.message || 'Request failed',
        }
      }

      return {
        success: true,
        data: data.data || data,
        message: data.message,
      }
    } catch (error) {
      console.error('❌ API request failed:', error)
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Network error',
      }
    }
  }

  // ==================== Authentication ====================

  /**
   * Login user
   */
  async login(email: string, password: string): Promise<ApiResponse<{ token: string; user: UserProfile }>> {
    return this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
  }

  /**
   * Register new user
   */
  async signup(name: string, email: string, password: string): Promise<ApiResponse<{ token: string; user: UserProfile }>> {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ name, email, password }),
    })
  }

  /**
   * Get current user profile
   */
  async getProfile(): Promise<ApiResponse<UserProfile>> {
    return this.request('/auth/me')
  }

  /**
   * Update user profile
   */
  async updateProfile(data: Partial<UserProfile>): Promise<ApiResponse<UserProfile>> {
    return this.request('/auth/profile', {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }

  // ==================== API Keys ====================

  /**
   * Get all API keys for current user
   */
  async getApiKeys(): Promise<ApiResponse<ApiKey[]>> {
    return this.request('/keys')
  }

  // ==================== Usage & Analytics ====================

  /**
   * Get usage metrics
   */
  async getUsageMetrics(timeRange: '7d' | '30d' | '90d' = '7d'): Promise<ApiResponse<UsageMetrics>> {
    return this.request(`/usage/metrics?range=${timeRange}`)
  }

  /**
   * Get recent activity logs
   */
  async getActivityLogs(limit: number = 10): Promise<ApiResponse<any[]>> {
    return this.request(`/usage/activity?limit=${limit}`)
  }

  // ==================== Billing & Subscriptions ====================

  /**
   * Get current subscription
   */
  async getSubscription(): Promise<ApiResponse<Subscription>> {
    return this.request('/billing/subscription')
  }

  /**
   * Get payment history
   */
  async getPaymentHistory(): Promise<ApiResponse<PaymentHistory[]>> {
    return this.request('/billing/payments')
  }

  /**
   * Create checkout session for plan upgrade
   */
  async createCheckoutSession(plan: string, successUrl: string, cancelUrl: string): Promise<ApiResponse<{ checkout_url: string }>> {
    return this.request('/payment/subscribe', {
      method: 'POST',
      body: JSON.stringify({
        plan,
        success_url: successUrl,
        cancel_url: cancelUrl,
      }),
    })
  }

  /**
   * List available pricing plans
   */
  async getPricingPlans(): Promise<ApiResponse<any[]>> {
    return this.request('/payment/plans')
  }

  // ==================== Domain Engines ====================

  /**
   * Get available domain engines for user's tier
   */
  async getDomainEngines(): Promise<ApiResponse<any[]>> {
    return this.request('/engines')
  }

  /**
   * Test domain engine
   */
  async testEngine(engine: string, payload: any): Promise<ApiResponse> {
    return this.request(`/engines/${engine}/test`, {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  }

  // ==================== Health Check ====================

  /**
   * Check API health
   */
  async healthCheck(): Promise<ApiResponse<{ status: string; version: string }>> {
    return this.request('/health')
  }

  // ==================== OTP Verification ====================

  /**
   * Send OTP to email
   */
  async sendOTP(email: string): Promise<ApiResponse> {
    return this.request('/auth/send-otp', {
      method: 'POST',
      body: JSON.stringify({ email }),
    })
  }

  /**
   * Verify OTP code
   */
  async verifyOTP(email: string, otpCode: string): Promise<ApiResponse<{ token: string; user: UserProfile }>> {
    return this.request('/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ email, otp_code: otpCode }),
    })
  }

  /**
   * Change password
   */
  async changePassword(currentPassword: string, newPassword: string): Promise<ApiResponse> {
    return this.request('/auth/change-password', {
      method: 'POST',
      body: JSON.stringify({
        current_password: currentPassword,
        new_password: newPassword,
      }),
    })
  }

  /**
   * Send OTP for email change verification
   */
  async sendEmailChangeOTP(email: string): Promise<ApiResponse> {
    return this.request('/auth/email-change/send-otp', {
      method: 'POST',
      body: JSON.stringify({ email }),
    })
  }

  /**
   * Verify OTP and complete email change
   */
  async verifyEmailChangeOTP(email: string, otpCode: string): Promise<ApiResponse> {
    return this.request('/auth/email-change/verify', {
      method: 'POST',
      body: JSON.stringify({ email, otp_code: otpCode }),
    })
  }

  // ==================== Cognitive Analysis ====================

  /**
   * Run comprehensive cognitive analysis across multiple domains
   */
  async runCognitiveAnalysis(
    inputType: 'image' | 'text',
    inputData: string,
    domains: string[] = ['vision', 'web', 'nlp', 'prediction'],
    context: Record<string, any> = {}
  ): Promise<ApiResponse> {
    return this.request('/cognitive/analyze', {
      method: 'POST',
      body: JSON.stringify({
        input_type: inputType,
        input_data: inputData,
        domains,
        context,
      }),
    })
  }

  /**
   * Analyze uploaded image through cognitive domains
   */
  async analyzeImage(
    file: File,
    domains: string[] = ['vision', 'web', 'nlp', 'prediction'],
    context: Record<string, any> = {}
  ): Promise<ApiResponse> {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('domains', domains.join(','))
    formData.append('context', JSON.stringify(context))

    return this.request('/cognitive/analyze-image', {
      method: 'POST',
      body: formData,
      headers: {}, // Don't set Content-Type for FormData
    })
  }

  /**
   * Get status of available cognitive domains
   */
  async getCognitiveDomainsStatus(): Promise<ApiResponse> {
    return this.request('/cognitive/domains/status')
  }

  /**
   * Get pre-built cognitive analysis templates
   */
  async getCognitiveTemplates(): Promise<ApiResponse> {
    return this.request('/cognitive/templates')
  }

  // ==================== Workflow Management ====================

  /**
   * Get all workflows
   */
  async getWorkflows(): Promise<ApiResponse<Workflow[]>> {
    return this.request('/workflows')
  }

  /**
   * Get workflow by ID
   */
  async getWorkflow(id: string): Promise<ApiResponse<Workflow>> {
    return this.request(`/workflows/${id}`)
  }

  /**
   * Create new workflow
   */
  async createWorkflow(data: Partial<Workflow>): Promise<ApiResponse<Workflow>> {
    return this.request('/workflows', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  /**
   * Update workflow
   */
  async updateWorkflow(id: string, data: Partial<Workflow>): Promise<ApiResponse<Workflow>> {
    return this.request(`/workflows/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }

  /**
   * Delete workflow
   */
  async deleteWorkflow(id: string): Promise<ApiResponse> {
    return this.request(`/workflows/${id}`, {
      method: 'DELETE',
    })
  }

  /**
   * Run workflow
   */
  async runWorkflow(id: string, input?: any): Promise<ApiResponse> {
    return this.request(`/workflows/${id}/run`, {
      method: 'POST',
      body: JSON.stringify({ input }),
    })
  }

  /**
   * Create workflow from template
   */
  async createWorkflowFromTemplate(templateId: string): Promise<ApiResponse<{
    success: boolean
    workflow_id: string
    name: string
    message: string
  }>> {
    return this.request('/workflows/from-template', {
      method: 'POST',
      body: JSON.stringify({ template_id: templateId }),
    })
  }

  /**
   * Execute a deployed workflow through Tiannara Core
   */
  async executeWorkflow(
    workflowId: string,
    inputData: Record<string, any> = {},
    executionMode: 'sequential' | 'parallel' | 'hybrid' = 'sequential'
  ): Promise<ApiResponse<{
    success: boolean
    execution_id: string
    status: string
    started_at: string
    completed_at: string
    total_execution_time_ms: number
    nodes: Record<string, any>
    error: string | null
    message: string
  }>> {
    return this.request('/workflows/execute', {
      method: 'POST',
      body: JSON.stringify({
        workflow_id: workflowId,
        input_data: inputData,
        execution_mode: executionMode
      }),
    })
  }

  /**
   * Fetch execution details by execution ID
   */
  async getExecutionDetails(executionId: string): Promise<ApiResponse<{
    execution_id: string
    workflow_id: string
    status: string
    started_at: string
    completed_at: string
    total_execution_time_ms: number
    nodes: Record<string, any>
    error: string | null
  }>> {
    return this.request(`/workflows/executions/${executionId}`)
  }

  // ==================== Automations ====================

  /**
   * Get all automations
   */
  async getAutomations(): Promise<ApiResponse<Automation[]>> {
    return this.request('/automations')
  }

  /**
   * Create automation
   */
  async createAutomation(data: Partial<Automation>): Promise<ApiResponse<Automation>> {
    return this.request('/automations', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  /**
   * Update automation
   */
  async updateAutomation(id: string, data: Partial<Automation>): Promise<ApiResponse<Automation>> {
    return this.request(`/automations/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }

  /**
   * Toggle automation status
   */
  async toggleAutomation(id: string): Promise<ApiResponse<Automation>> {
    return this.request(`/automations/${id}/toggle`, {
      method: 'POST',
    })
  }

  // ==================== Analytics & Insights ====================

  /**
   * Get AI-generated insights
   */
  async getInsights(limit: number = 10): Promise<ApiResponse<Insight[]>> {
    return this.request(`/analytics/insights?limit=${limit}`)
  }

  /**
   * Get predictions
   */
  async getPredictions(metric?: string): Promise<ApiResponse<Prediction[]>> {
    const endpoint = metric
      ? `/analytics/predictions?metric=${metric}`
      : '/analytics/predictions'
    return this.request(endpoint)
  }

  /**
   * Get dashboard metrics summary
   */
  async getDashboardMetrics(): Promise<ApiResponse<{
    total_workflows: number
    active_automations: number
    api_usage_today: number
    accuracy_avg: number
    recent_insights: Insight[]
  }>> {
    return this.request('/analytics/dashboard')
  }

  /**
   * Get comprehensive analytics data
   */
  async getAnalytics(timeRange: '7d' | '30d' | '90d' = '7d'): Promise<ApiResponse<{
    total_requests: number
    success_rate: number
    avg_latency_ms: number
    error_count: number
    daily_usage: Array<{
      date: string
      requests: number
      success: number
      errors: number
    }>
    domain_breakdown: Array<{
      domain: string
      count: number
      percentage: number
    }>
    workflow_performance: Array<{
      workflow_id: string
      name: string
      executions: number
      avg_accuracy: number
      avg_duration_ms: number
      success_rate: number
    }>
    ai_outputs: Array<{
      id: string
      type: string
      timestamp: string
      confidence: number
      result: any
    }>
  }>> {
    return this.request(`/analytics/center?time_range=${timeRange}`)
  }

  // ==================== Team Management ====================

  /**
   * Get team members
   */
  async getTeamMembers(): Promise<ApiResponse<TeamMember[]>> {
    return this.request('/workspaces/members')
  }

  /**
   * Invite team member
   */
  async inviteMember(email: string, role: string): Promise<ApiResponse> {
    return this.request('/workspaces/invite', {
      method: 'POST',
      body: JSON.stringify({ email, role }),
    })
  }

  /**
   * Remove team member
   */
  async removeMember(memberId: string): Promise<ApiResponse> {
    return this.request(`/workspaces/members/${memberId}`, {
      method: 'DELETE',
    })
  }

  /**
   * Update member role
   */
  async updateMemberRole(memberId: string, role: string): Promise<ApiResponse> {
    return this.request(`/workspaces/members/${memberId}/role`, {
      method: 'PUT',
      body: JSON.stringify({ role }),
    })
  }

  /**
   * Get activity feed
   */
  async getActivityFeed(limit: number = 20): Promise<ApiResponse<any[]>> {
    return this.request(`/workspaces/activity?limit=${limit}`)
  }

  // ==================== System Capabilities ====================

  /**
   * Get system capabilities and features
   */
  async getCapabilities(): Promise<ApiResponse<SystemCapabilities>> {
    return this.request('/system/capabilities')
  }

  // ==================== Multi-Factor Authentication ====================

  /**
   * Get MFA status for current user
   */
  async getMFAStatus(): Promise<ApiResponse<{ enabled: boolean }>> {
    return this.request('/auth/mfa/status')
  }

  /**
   * Setup MFA - get QR code and secret
   */
  async setupMFA(): Promise<ApiResponse<{
    secret: string
    qr_code_url: string
    backup_codes: string[]
  }>> {
    return this.request('/auth/mfa/setup', {
      method: 'POST',
    })
  }

  /**
   * Enable MFA with verification code
   */
  async enableMFA(verificationCode: string): Promise<ApiResponse> {
    return this.request('/auth/mfa/enable', {
      method: 'POST',
      body: JSON.stringify({ code: verificationCode }),
    })
  }

  /**
   * Disable MFA
   */
  async disableMFA(): Promise<ApiResponse> {
    return this.request('/auth/mfa/disable', {
      method: 'POST',
    })
  }

  /**
   * Regenerate MFA backup codes
   */
  async regenerateMFABackupCodes(): Promise<ApiResponse<{ backup_codes: string[] }>> {
    return this.request('/auth/mfa/regenerate-backup-codes', {
      method: 'POST',
    })
  }

  // ==================== API Key Management ====================

  /**
   * Create a new API key for a workspace
   * RBAC: Requires workspace ADMIN or OWNER role
   */
  async createApiKey(name: string, workspaceId: string): Promise<ApiResponse<{
    id: string
    name: string
    key: string
    workspace_id: string
    created_by: string
    created_at: string
    last_used: string | null
    request_count: number
    status: string
  }>> {
    return this.request('/api-keys', {
      method: 'POST',
      body: JSON.stringify({ name, workspace_id: workspaceId }),
    })
  }

  /**
   * List all API keys for a workspace
   * RBAC: Any workspace member can view keys (masked)
   */
  async listApiKeys(workspaceId: string): Promise<ApiResponse<ApiKeySummary[]>> {
    return this.request(`/api-keys?workspace_id=${workspaceId}`)
  }

  /**
   * Revoke an API key
   * RBAC: Requires workspace ADMIN or OWNER role
   */
  async revokeApiKey(keyId: string, workspaceId: string): Promise<ApiResponse> {
    return this.request(`/api-keys/${keyId}?workspace_id=${workspaceId}`, {
      method: 'DELETE',
    })
  }

  /**
   * Get API key usage statistics
   * RBAC: Requires workspace ADMIN or OWNER role
   */
  async getApiKeyUsage(keyId: string, workspaceId: string): Promise<ApiResponse<{
    total_requests: number
    requests_today: number
    requests_this_week: number
    requests_this_month: number
    last_request_at: string | null
    endpoints_used: string[]
  }>> {
    return this.request(`/api-keys/${keyId}/usage?workspace_id=${workspaceId}`)
  }
}

// Export singleton instance
export const apiClient = new ApiClient()
