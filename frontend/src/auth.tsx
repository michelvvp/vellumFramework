import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { api, gravarAuth, lerAuth } from './api'

/*
 * Sessão persistente: { token, user } fica no localStorage até o logoff.
 * O api.ts manda o token em todo request e dispara 'framework:unauthorized'
 * num 401, o que derruba a sessão aqui e leva de volta ao login.
 */
interface AuthState { token: string; user: { id: number; name: string; login: string; roles: string[] } }

interface AuthContextType {
  auth: AuthState | null
  login: (login: string, senha: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextType>(null as any)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState | null>(lerAuth)

  // revalida a sessão guardada no boot e atualiza nome/papéis que mudaram
  useEffect(() => {
    if (!lerAuth()) return
    api.get('/auth/me').then(user => {
      const atual = lerAuth()
      if (!atual) return
      const novo = { ...atual, user }
      gravarAuth(novo)
      setAuth(novo)
    }).catch(() => {}) // 401 já é tratado pelo evento abaixo
  }, [])

  useEffect(() => {
    const derrubar = () => setAuth(null)
    window.addEventListener('framework:unauthorized', derrubar)
    return () => window.removeEventListener('framework:unauthorized', derrubar)
  }, [])

  async function login(login: string, senha: string) {
    const r = await api.post('/auth/login', { login, senha })
    gravarAuth(r)
    setAuth(r)
  }

  function logout() {
    gravarAuth(null)
    setAuth(null)
  }

  return <AuthContext.Provider value={{ auth, login, logout }}>{children}</AuthContext.Provider>
}

export function useAuth() {
  return useContext(AuthContext)
}
