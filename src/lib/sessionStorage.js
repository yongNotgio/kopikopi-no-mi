// Session storage helpers using localStorage
// Stores both Supabase session backup AND user profile data

const SESSION_KEY = 'ikape-session-backup'
const USER_SESSION_KEY = 'ikape-user-session'
const SESSION_MAX_AGE = 24 * 60 * 60 * 1000 // 24 hours

// ===== Supabase Session Backup =====

export const saveSession = (session) => {
  try {
    if (session?.access_token && session?.user) {
      const sessionData = {
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        expires_at: session.expires_at,
        user: session.user,
        timestamp: Date.now()
      }
      localStorage.setItem(SESSION_KEY, JSON.stringify(sessionData))
      return true
    }
  } catch (e) {
    console.error('Failed to save session:', e)
  }
  return false
}

export const loadSession = () => {
  try {
    const stored = localStorage.getItem(SESSION_KEY)
    if (stored) {
      const session = JSON.parse(stored)
      const sessionAge = Date.now() - session.timestamp

      if (sessionAge < 7 * 24 * 60 * 60 * 1000) {
        return session
      } else {
        clearSession()
      }
    }
  } catch (e) {
    console.error('Failed to load session:', e)
  }
  return null
}

export const clearSession = () => {
  try {
    localStorage.removeItem(SESSION_KEY)
  } catch (e) {
    console.error('Failed to clear session:', e)
  }
}

// ===== User + Profile Session (for AuthContext) =====

export const saveUserSession = (userData, profileData) => {
  try {
    if (!userData || !profileData) return false
    const data = {
      user: userData,
      profile: profileData,
      timestamp: Date.now(),
    }
    localStorage.setItem(USER_SESSION_KEY, JSON.stringify(data))
    console.log('💾 Session saved to localStorage')
    return true
  } catch (e) {
    console.error('Failed to save user session:', e)
    return false
  }
}

export const loadUserSession = () => {
  try {
    const stored = localStorage.getItem(USER_SESSION_KEY)
    if (!stored) return null

    const data = JSON.parse(stored)
    const sessionAge = Date.now() - data.timestamp

    if (sessionAge > SESSION_MAX_AGE) {
      console.log('⏰ User session expired')
      clearUserSession()
      return null
    }

    return { user: data.user, profile: data.profile }
  } catch (e) {
    console.error('Failed to load user session:', e)
    return null
  }
}

export const clearUserSession = () => {
  try {
    localStorage.removeItem(USER_SESSION_KEY)
    console.log('🗑️ User session cleared from localStorage')
  } catch (e) {
    console.error('Failed to clear user session:', e)
  }
}

/**
 * Synchronous check: does a user session key exist in localStorage?
 * Used to instantly decide whether to show loading or redirect.
 */
export const hasStoredSession = () => {
  try {
    return localStorage.getItem(USER_SESSION_KEY) !== null
  } catch {
    return false
  }
}
