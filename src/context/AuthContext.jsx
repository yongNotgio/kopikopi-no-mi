import { createContext, useContext, useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Fetch user profile from the users table
  const fetchProfile = async (userId) => {
    const { data, error: err } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .maybeSingle()
    if (err) {
      console.error('Error fetching profile:', err.message)
      return null
    }
    return data
  }

  // Listen for auth state changes
  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      if (session?.user) {
        setUser(session.user)
        const p = await fetchProfile(session.user.id)
        setProfile(p)
      }
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (session?.user) {
          setUser(session.user)
          const p = await fetchProfile(session.user.id)
          setProfile(p)
        } else {
          setUser(null)
          setProfile(null)
        }
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const register = async (userData) => {
    setError('')

    // 1. Sign up via Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: userData.email,
      password: userData.password,
    })

    if (authError) {
      setError(authError.message)
      return false
    }

    const userId = authData.user?.id
    if (!userId) {
      setError('Registration failed. Please try again.')
      return false
    }

    // Check if this email is already registered in the users table
    const { data: existing } = await supabase
      .from('users')
      .select('id')
      .eq('email', userData.email)
      .maybeSingle()

    if (existing) {
      setError('An account with this email already exists.')
      return false
    }

    // Check if username is already taken
    const { data: takenUsername } = await supabase
      .from('users')
      .select('id')
      .eq('username', userData.username)
      .maybeSingle()

    if (takenUsername) {
      setError('Username is already taken. Please choose another.')
      return false
    }

    // 2. Insert (or update if already exists) profile row
    //    Uses upsert to handle cases where the auth user was created
    //    but the profile insert failed on a previous attempt.
    const { error: profileError } = await supabase.from('users').upsert({
      id: userId,
      username: userData.username,
      email: userData.email,
      password_hash: 'supabase-auth-managed',
      first_name: userData.firstName,
      last_name: userData.lastName,
      middle_initial: userData.middleInitial || null,
      contact_number: userData.contactNumber,
      age: parseInt(userData.age),
      municipality: userData.municipality,
      province: userData.province,
    }, { onConflict: 'id' })

    if (profileError) {
      console.error('Profile insert error:', profileError.message)
      setError(profileError.message)
      return false
    }

    return true
  }

  const login = async (identifier, password) => {
    setError('')

    let email = identifier

    // If not an email, look up by username
    if (!identifier.includes('@')) {
      const { data: found, error: lookupError } = await supabase
        .from('users')
        .select('email')
        .eq('username', identifier)
        .maybeSingle()

      if (lookupError) {
        console.error('Username lookup error:', lookupError.message)
        setError('Could not look up username. Try logging in with email.')
        return false
      }
      if (!found) {
        setError('Username not found')
        return false
      }
      email = found.email
    }

    // TODO: Replace with real credential check once database is live
    // For now, accept any password — skip signInWithPassword validation
    const { error: loginError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (loginError) {
      // Bypass: create a mock session for development
      // Remove this block once real auth is enforced
      console.warn('Auth bypass active — accepting any password for development')
      const { data: profile } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .maybeSingle()

      if (profile) {
        // Manually set profile for dev bypass
        setProfile(profile)
        setUser({ id: profile.id, email: profile.email })
        return true
      }
      setError(loginError.message)
      return false
    }

    return true
  }

  const logout = async () => {
    await supabase.auth.signOut()
    setUser(null)
    setProfile(null)
  }

  const updateProfile = async (updates) => {
    if (!user) return false
    const { error: err } = await supabase
      .from('users')
      .update({
        first_name: updates.firstName,
        last_name: updates.lastName,
        email: updates.email,
        contact_number: updates.contactNumber,
        municipality: updates.municipality,
        province: updates.province,
      })
      .eq('id', user.id)

    if (err) {
      console.error('Error updating profile:', err.message)
      return false
    }
    const p = await fetchProfile(user.id)
    setProfile(p)
    return true
  }

  const combinedUser = profile
    ? {
        id: profile.id,
        username: profile.username,
        email: profile.email,
        firstName: profile.first_name,
        lastName: profile.last_name,
        middleInitial: profile.middle_initial,
        contactNumber: profile.contact_number,
        age: profile.age,
        municipality: profile.municipality,
        province: profile.province,
      }
    : null

  return (
    <AuthContext.Provider
      value={{
        user: combinedUser,
        authUser: user,
        loading,
        error,
        setError,
        register,
        login,
        logout,
        updateProfile,
      }}
    >
      {!loading && children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}
