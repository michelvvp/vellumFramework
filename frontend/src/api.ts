import type { Row } from './types'

const AUTH_KEY = 'vellum.auth'

export function lerAuth(): { token: string; user: any } | null {
  try { return JSON.parse(localStorage.getItem(AUTH_KEY) || 'null') } catch { return null }
}

export function gravarAuth(auth: { token: string; user: any } | null) {
  if (auth) localStorage.setItem(AUTH_KEY, JSON.stringify(auth))
  else localStorage.removeItem(AUTH_KEY)
}

async function req(path: string, options: RequestInit = {}): Promise<any> {
  const t = lerAuth()?.token
  const res = await fetch('/api' + path, {
    headers: {
      'Content-Type': 'application/json',
      ...(t ? { Authorization: `Bearer ${t}` } : {}),
    },
    ...options,
  })
  if (res.status === 401 && path !== '/auth/login') {
    // sessão inválida: derruba o login persistido e avisa o app
    gravarAuth(null)
    window.dispatchEvent(new Event('vellum:unauthorized'))
  }
  if (!res.ok) {
    let corpo: any = null
    try { corpo = await res.json() } catch { /* não era JSON */ }
    const erro: any = new Error(corpo?.message || `${res.status} ${res.statusText}`)
    erro.status = res.status
    erro.errors = corpo?.errors // [{ field, code, message }]
    throw erro
  }
  if (res.status === 204) return null
  return res.json()
}

export const api = {
  get: (p: string) => req(p),
  post: (p: string, body?: any) => req(p, { method: 'POST', body: JSON.stringify(body ?? {}) }),
  put: (p: string, body?: any) => req(p, { method: 'PUT', body: JSON.stringify(body ?? {}) }),
  del: (p: string) => req(p, { method: 'DELETE' }),
}

function query(params: Record<string, any>): string {
  const q = new URLSearchParams()
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  }
  const s = q.toString()
  return s ? '?' + s : ''
}

/* DataClient genérico sobre /api/data, /api/lookup, /api/function e /api/dashboard.
   Toda operação de dados leva a visão de contexto (_vision) — o backend tira
   dela filtros, permissões e validações. */
export const data = {
  list: (table: string, vision: string, params: Record<string, any> = {}): Promise<Row[]> =>
    api.get(`/data/${table}${query({ ...params, _vision: vision })}`),
  get: (table: string, id: number, vision: string): Promise<Row> =>
    api.get(`/data/${table}/${id}${query({ _vision: vision })}`),
  create: (table: string, vision: string, payload: Row): Promise<Row> =>
    api.post(`/data/${table}${query({ _vision: vision })}`, payload),
  update: (table: string, id: number, vision: string, payload: Row): Promise<Row> =>
    api.put(`/data/${table}/${id}${query({ _vision: vision })}`, payload),
  remove: (table: string, id: number, vision: string): Promise<void> =>
    api.del(`/data/${table}/${id}${query({ _vision: vision })}`),
  reorder: (table: string, vision: string, ids: number[]): Promise<void> =>
    api.put(`/data/${table}/ordem${query({ _vision: vision })}`, { ids }),
  lookup: (table: string, params: Record<string, any> = {}): Promise<{ id: number; label: string }[]> =>
    api.get(`/lookup/${table}${query(params)}`),
  execute: (name: string, corpo: { visionKey?: string; recordId?: number; params?: any } = {}) =>
    api.post(`/function/${name}`, corpo),
  dashboard: (visionKey: string, from?: string, to?: string) =>
    api.get(`/dashboard/${visionKey}${query({ from, to })}`),
}

export type DataClient = typeof data
