import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { api, gravarAuth, lerAuth } from './api'
import type { EstablishmentDef } from './types'

/*
 * Sessão persistente: { token, user } fica no localStorage até o logoff.
 * O api.ts manda o token em todo request e dispara 'vellum:unauthorized'
 * num 401, o que derruba a sessão aqui e leva de volta ao login.
 */
interface Usuario {
  id: number
  name: string
  login: string
  functions: string[]
  establishmentId?: number
  establishmentName?: string
}

interface AuthState { token: string; user: Usuario }

/**
 * Login em duas etapas: quem tem vínculo com um único estabelecimento entra
 * direto; com mais de um, o backend devolve a lista e um token de escolha, e a
 * sessão só existe de verdade depois do escolherEstabelecimento.
 */
interface AuthContextType {
  auth: AuthState | null
  /** devolve a lista quando a pessoa precisa escolher; vazio quando já entrou */
  login: (login: string, senha: string) => Promise<EstablishmentDef[]>
  escolherEstabelecimento: (id: number) => Promise<void>
  logout: () => void
  /** a pessoa tem a função no estabelecimento ativo? */
  pode: (funcao: string) => boolean
}

const AuthContext = createContext<AuthContextType>(null as any)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState | null>(() => {
    const guardado = lerAuth()
    return guardado?.user ? guardado : null // token de escolha não é sessão
  })

  // revalida a sessão guardada no boot e atualiza nome e funções que mudaram
  useEffect(() => {
    if (!lerAuth()?.user) return
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
    window.addEventListener('vellum:unauthorized', derrubar)
    return () => window.removeEventListener('vellum:unauthorized', derrubar)
  }, [])

  async function login(login: string, senha: string) {
    const r = await api.post('/auth/login', { login, senha })
    if (r.establishments) {
      // token de escolha: guarda para poder chamar /auth/establishment, mas
      // não vira sessão — o Shell continua fora do ar até a escolha
      gravarAuth({ token: r.token, user: null as any })
      return r.establishments as EstablishmentDef[]
    }
    gravarAuth(r)
    setAuth(r)
    return []
  }

  async function escolherEstabelecimento(id: number) {
    const r = await api.post('/auth/establishment', { establishmentId: id })
    gravarAuth(r)
    setAuth(r)
  }

  function pode(funcao: string) {
    return !!auth?.user?.functions?.includes(funcao)
  }

  function logout() {
    gravarAuth(null)
    setAuth(null)
  }

  return (
    <AuthContext.Provider value={{ auth, login, escolherEstabelecimento, logout, pode }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
