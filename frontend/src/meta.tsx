import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { api } from './api'
import type { Meta } from './types'

/*
 * Carrega o /api/meta uma vez por sessão e aplica a identidade do app:
 * as 4 variáveis de tema do contrato do design system (vindas do cadastro
 * app_config) são injetadas num <style> — trocar a identidade do sistema
 * é um cadastro, não um deploy.
 */
const MetaContext = createContext<{ meta: Meta; refresh: () => Promise<void> }>(null as any)

function aplicarTema(meta: Meta) {
  const t = meta.app.theme
  let el = document.getElementById('app-theme') as HTMLStyleElement | null
  if (!el) {
    el = document.createElement('style')
    el.id = 'app-theme'
    document.head.appendChild(el)
  }
  // o seletor com [data-theme] garante que o accent sobreviva à alternância
  // manual de tema (os blocos data-theme do DS têm especificidade maior que :root)
  el.textContent = `:root, :root[data-theme="dark"], :root[data-theme="light"] {
  --accent: ${t.accent};
  --accent-hover: ${t.accentHover};
  --accent-tint: ${t.accentTint};
  --on-accent: ${t.onAccent};
}`
  document.title = meta.app.name
}

export function MetaProvider({ children, fallback }: { children: ReactNode; fallback?: ReactNode }) {
  const [meta, setMeta] = useState<Meta | null>(null)
  const [erro, setErro] = useState('')

  async function carregar() {
    const m: Meta = await api.get('/meta')
    aplicarTema(m)
    setMeta(m)
  }

  useEffect(() => {
    carregar().catch(e => setErro(e.message))
  }, [])

  if (erro) {
    return (
      <div className="page page--center">
        <div className="card" style={{ width: 'min(480px, 100%)' }}>
          <div className="alert alert--danger">
            <div><span className="alert-title">Não foi possível carregar o sistema</span><p>{erro}</p></div>
          </div>
        </div>
      </div>
    )
  }
  if (!meta) return <>{fallback ?? null}</>

  return (
    <MetaContext.Provider value={{ meta, refresh: carregar }}>
      {children}
    </MetaContext.Provider>
  )
}

export function useMeta() {
  return useContext(MetaContext)
}

/** Visão pela chave (as visões do /api/meta já vêm filtradas por papel). */
export function useVision(key: string) {
  const { meta } = useMeta()
  return meta.visions.find(v => v.key === key)
}
