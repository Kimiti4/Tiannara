'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import { Mail, Shield, CheckCircle, AlertCircle, Loader2, ArrowLeft } from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import { apiClient } from '@/lib/api'

export default function EmailVerificationPage() {
  const searchParams = useSearchParams()
  const { user, refreshProfile } = useAuth()
  const [email, setEmail] = useState('')
  const [otpSent, setOtpSent] = useState(false)
  const [otpCode, setOtpCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [countdown, setCountdown] = useState(0)

  useEffect(() => {
    // Get new email from query parameter or user object
    const newEmailParam = searchParams.get('newEmail')
    if (newEmailParam) {
      setEmail(decodeURIComponent(newEmailParam))
    } else if (user) {
      setEmail(user.email ?? '')
    }
  }, [user, searchParams])

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)
      return () => clearTimeout(timer)
    }
  }, [countdown])

  const sendVerificationOTP = async () => {
    if (!email || !email.includes('@')) {
      setError('Please enter a valid email address')
      return
    }

    try {
      setLoading(true)
      setError('')
      
      const response = await apiClient.sendEmailChangeOTP(email)
      if (response.success) {
        setOtpSent(true)
        setCountdown(60)
        setSuccess('Verification code sent to your email')
      } else {
        setError(response.error || 'Failed to send verification code')
      }
    } catch (err) {
      setError('Failed to send verification code')
    } finally {
      setLoading(false)
    }
  }

  const verifyAndChangeEmail = async () => {
    if (!otpCode || otpCode.length !== 6) {
      setError('Please enter a valid 6-digit code')
      return
    }

    try {
      setLoading(true)
      setError('')
      
      const response = await apiClient.verifyEmailChangeOTP(email, otpCode)
      if (response.success) {
        setSuccess('Email updated successfully!')
        await refreshProfile()
        setOtpCode('')
        setOtpSent(false)
      } else {
        setError(response.error || 'Invalid verification code')
      }
    } catch (err) {
      setError('Failed to verify email')
    } finally {
      setLoading(false)
    }
  }

  const resendOTP = async () => {
    if (countdown > 0) return
    await sendVerificationOTP()
  }

  return (
    <div className="p-8 max-w-2xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <button
          onClick={() => window.history.back()}
          className="flex items-center gap-2 text-slate-400 hover:text-white mb-4 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Settings
        </button>
        <h1 className="text-2xl font-bold text-white mb-2">Email Verification</h1>
        <p className="text-slate-400">Verify your new email address to complete the change</p>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-4 flex items-center gap-3 mb-6">
          <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
          <p className="text-red-400 text-sm">{error}</p>
        </div>
      )}

      {success && (
        <div className="bg-green-500/10 border border-green-500/20 rounded-xl p-4 flex items-center gap-3 mb-6">
          <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
          <p className="text-green-400 text-sm">{success}</p>
        </div>
      )}

      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        {/* Current Email */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-slate-300 mb-2">
            Current Email
          </label>
          <div className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-slate-400">
            {user?.email}
          </div>
        </div>

        {/* New Email Input */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-slate-300 mb-2">
            New Email Address
          </label>
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={otpSent}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-10 pr-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 transition-colors disabled:opacity-50"
              placeholder="your-new-email@example.com"
            />
          </div>
        </div>

        {/* Send OTP Button */}
        {!otpSent ? (
          <button
            onClick={sendVerificationOTP}
            disabled={loading || !email}
            className="w-full px-6 py-3 bg-purple-600 hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium rounded-xl transition-colors flex items-center justify-center gap-2"
          >
            {loading ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Shield className="w-4 h-4" />
            )}
            {loading ? 'Sending...' : 'Send Verification Code'}
          </button>
        ) : (
          <div className="space-y-6">
            {/* OTP Input */}
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">
                Enter Verification Code
              </label>
              <input
                type="text"
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                maxLength={6}
                placeholder="000000"
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 transition-colors text-center text-2xl font-mono tracking-widest"
              />
              <p className="text-xs text-slate-500 mt-2">
                A 6-digit code was sent to {email}
              </p>
            </div>

            {/* Verify Button */}
            <button
              onClick={verifyAndChangeEmail}
              disabled={loading || otpCode.length !== 6}
              className="w-full px-6 py-3 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium rounded-xl transition-colors flex items-center justify-center gap-2"
            >
              {loading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <CheckCircle className="w-4 h-4" />
              )}
              {loading ? 'Verifying...' : 'Verify & Change Email'}
            </button>

            {/* Resend OTP */}
            <div className="text-center">
              <button
                onClick={resendOTP}
                disabled={countdown > 0}
                className="text-sm text-purple-400 hover:text-purple-300 disabled:text-slate-600 disabled:cursor-not-allowed transition-colors"
              >
                {countdown > 0 ? `Resend code in ${countdown}s` : 'Resend verification code'}
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Security Notice */}
      <div className="mt-6 bg-blue-500/10 border border-blue-500/20 rounded-xl p-4">
        <div className="flex items-start gap-3">
          <Shield className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-blue-400 font-medium mb-1">Security Notice</p>
            <p className="text-xs text-blue-300">
              For security purposes, a verification code has been sent to your new email address. 
              A notification will also be sent to your current email address ({user?.email}).
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
