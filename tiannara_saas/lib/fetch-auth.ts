/**
 * Authenticated fetch — uses HttpOnly cookies via same-origin /api/v1 proxy.
 */

export function getApiBaseUrl(): string {
  return process.env.NEXT_PUBLIC_API_BASE_URL || '/api/v1'
}

export async function authFetch(
  path: string,
  options: RequestInit = {}
): Promise<Response> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }
  return fetch(`${getApiBaseUrl()}${path}`, {
    ...options,
    credentials: 'include',
    headers,
  })
}

export async function checkSession(): Promise<boolean> {
  try {
    const res = await authFetch('/auth/me')
    if (!res.ok) return false
    const data = await res.json()
    return Boolean(data?.user || data?.success)
  } catch {
    return false
  }
}
