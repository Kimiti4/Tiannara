'use client'

import { useState, useEffect } from 'react'
import { 
  Shield, Smartphone, CheckCircle, AlertCircle, Loader2, 
  Trash2, RefreshCw, Lock, Key
} from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import { apiClient } from '@/lib/api'

interface MFASetup {
  secret: string
  qr_code_url: string
  backup_codes: string[]
}

export default function MFAPage() {
  const { user } = useAuth()
  const [mfaEnabled, setMfaEnabled] = useState(false)
  const [loading, setLoading] = useState(true)
  const [settingUp, setSettingUp] = useState(false)
  const [verificationCode, setVerificationCode] = useState('')
  const [backupCodes, setBackupCodes] = useState<string[]>([])
  const [mfaSetup, setMfaSetup] = useState<MFASetup | null>(null)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  useEffect(() => {
    checkMFAStatus()
  }, [])

  const checkMFAStatus = async () => {
    try {
      setLoading(true)
      const response = await apiClient.getMFAStatus()
      if (response.success) {
        setMfaEnabled(response.data?.enabled ?? false)
      }
    } catch (err) {
      console.error('Failed to check MFA status:', err)
    } finally {
      setLoading(false)
    }
  }

  const setupMFA = async () => {
    try {
      setSettingUp(true)
      setError('')
      
      const response = await apiClient.setupMFA()
      if (response.success && response.data) {
        setMfaSetup(response.data)
      } else {
        setError(response.error || 'Failed to setup MFA')
      }
    } catch (err) {
      setError('Failed to setup MFA')
    } finally {
      setSettingUp(false)
    }
  }

  const verifyAndEnableMFA = async () => {
    if (!verificationCode || verificationCode.length !== 6) {
      setError('Please enter a valid 6-digit code')
      return
    }

    try {
      setSettingUp(true)
      setError('')
      
      const response = await apiClient.enableMFA(verificationCode)
      if (response.success) {
        setMfaEnabled(true)
        setBackupCodes(mfaSetup?.backup_codes ?? [])
        setMfaSetup(null)
        setVerificationCode('')
        setSuccess('MFA enabled successfully! Save your backup codes.')
      } else {
        setError(response.error || 'Invalid verification code')
      }
    } catch (err) {
      setError('Failed to verify MFA')
    } finally {
      setSettingUp(false)
    }
  }

  const disableMFA = async () => {
    if (!confirm('Are you sure you want to disable MFA? This will reduce your account security.')) {
      return
    }

    try {
      setLoading(true)
      const response = await apiClient.disableMFA()
      if (response.success) {
        setMfaEnabled(false)
        setBackupCodes([])
        setSuccess('MFA disabled')
      } else {
        setError(response.error || 'Failed to disable MFA')
      }
    } catch (err) {
      setError('Failed to disable MFA')
    } finally {
      setLoading(false)
    }
  }

  const regenerateBackupCodes = async () => {
    try {
      const response = await apiClient.regenerateMFABackupCodes()
      if (response.success && response.data) {
        setBackupCodes(response.data.backup_codes)
        setSuccess('New backup codes generated')
      }
    } catch (err) {
      setError('Failed to regenerate backup codes')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
      </div>
    )
  }

  return (
    <div className="p-8 max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white mb-2">Multi-Factor Authentication</h1>
        <p className="text-slate-400">Add an extra layer of security to your account</p>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-4 flex items-center gap-3">
          <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
          <p className="text-red-400 text-sm">{error}</p>
        </div>
      )}

      {success && (
        <div className="bg-green-500/10 border border-green-500/20 rounded-xl p-4 flex items-center gap-3">
          <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
          <p className="text-green-400 text-sm">{success}</p>
        </div>
      )}

      {/* MFA Status */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-4">
            <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
              mfaEnabled ? 'bg-green-500/20' : 'bg-slate-800'
            }`}>
              <Shield className={`w-6 h-6 ${mfaEnabled ? 'text-green-400' : 'text-slate-400'}`} />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-white">
                {mfaEnabled ? 'MFA Enabled' : 'MFA Disabled'}
              </h2>
              <p className="text-sm text-slate-400">
                {mfaEnabled 
                  ? 'Your account is protected with two-factor authentication' 
                  : 'Enable MFA to protect your account'}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            {mfaEnabled ? (
              <button
                onClick={disableMFA}
                disabled={loading}
                className="px-4 py-2 bg-red-500/20 hover:bg-red-500/30 text-red-400 rounded-xl transition-colors flex items-center gap-2"
              >
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
                Disable
              </button>
            ) : (
              <button
                onClick={setupMFA}
                disabled={settingUp}
                className="px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-xl transition-colors flex items-center gap-2"
              >
                {settingUp ? <Loader2 className="w-4 h-4 animate-spin" /> : <Lock className="w-4 h-4" />}
                Enable MFA
              </button>
            )}
          </div>
        </div>

        {/* Setup MFA */}
        {mfaSetup && (
          <div className="space-y-6 pt-6 border-t border-slate-800">
            <div>
              <h3 className="text-base font-semibold text-white mb-3">Setup Authenticator App</h3>
              <p className="text-sm text-slate-400 mb-4">
                Scan the QR code with your authenticator app (Google Authenticator, Authy, etc.)
              </p>
              
              {mfaSetup.qr_code_url && (
                <div className="flex justify-center mb-6">
                  <img 
                    src={mfaSetup.qr_code_url} 
                    alt="MFA QR Code" 
                    className="w-48 h-48 bg-white p-4 rounded-xl"
                  />
                </div>
              )}

              <div className="bg-slate-950 rounded-xl p-4">
                <p className="text-sm text-slate-400 mb-2">Manual entry code:</p>
                <code className="text-lg text-white font-mono">{mfaSetup.secret}</code>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">
                Enter 6-digit verification code
              </label>
              <input
                type="text"
                value={verificationCode}
                onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                maxLength={6}
                placeholder="000000"
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 transition-colors text-center text-2xl font-mono tracking-widest"
              />
            </div>

            <button
              onClick={verifyAndEnableMFA}
              disabled={settingUp || verificationCode.length !== 6}
              className="w-full px-4 py-3 bg-purple-500 hover:bg-purple-600 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl transition-colors flex items-center justify-center gap-2"
            >
              {settingUp ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle className="w-4 h-4" />}
              Verify and Enable
            </button>
          </div>
        )}

        {/* Backup Codes */}
        {backupCodes.length > 0 && (
          <div className="pt-6 border-t border-slate-800">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-semibold text-white flex items-center gap-2">
                <Key className="w-5 h-5 text-yellow-400" />
                Backup Codes
              </h3>
              <button
                onClick={regenerateBackupCodes}
                className="px-3 py-1.5 text-sm bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg transition-colors flex items-center gap-2"
              >
                <RefreshCw className="w-4 h-4" />
                Regenerate
              </button>
            </div>
            <p className="text-sm text-slate-400 mb-4">
              Save these backup codes in a secure place. Each code can only be used once.
            </p>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {backupCodes.map((code, index) => (
                <div 
                  key={index}
                  className="bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-center"
                >
                  <code className="text-sm text-white font-mono">{code}</code>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Security Tips */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <h3 className="text-base font-semibold text-white mb-4 flex items-center gap-2">
          <Shield className="w-5 h-5 text-purple-400" />
          Security Tips
        </h3>
        <ul className="space-y-3 text-sm text-slate-400">
          <li className="flex items-start gap-3">
            <CheckCircle className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
            Keep your backup codes in a safe, offline location
          </li>
          <li className="flex items-start gap-3">
            <CheckCircle className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
            Use an authenticator app like Google Authenticator or Authy
          </li>
          <li className="flex items-start gap-3">
            <CheckCircle className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
            Don't share your verification codes with anyone
          </li>
          <li className="flex items-start gap-3">
            <CheckCircle className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
            Contact support if you lose access to your authenticator app
          </li>
        </ul>
      </div>
    </div>
  )
}
