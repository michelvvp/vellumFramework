import { useState } from 'react'
import { useAuth } from '../auth'
import type { EstablishmentDef } from '../types'

export default function Login() {
  const { login, escolherEstabelecimento } = useAuth()
  const [form, setForm] = useState({ login: '', senha: '' })
  const [erro, setErro] = useState('')
  const [entrando, setEntrando] = useState(false)
  // preenchido quando a pessoa tem vínculo com mais de um estabelecimento
  const [estabelecimentos, setEstabelecimentos] = useState<EstablishmentDef[]>([])

  async function entrar(e: React.FormEvent) {
    e.preventDefault()
    setErro(''); setEntrando(true)
    try {
      const escolhas = await login(form.login.trim(), form.senha)
      if (escolhas.length > 0) {
        setEstabelecimentos(escolhas)
        setEntrando(false)
      }
    } catch (err: any) {
      setErro(err.message)
      setEntrando(false)
    }
  }

  async function escolher(id: number) {
    setErro(''); setEntrando(true)
    try {
      await escolherEstabelecimento(id)
    } catch (err: any) {
      setErro(err.message)
      setEntrando(false)
    }
  }

  if (estabelecimentos.length > 0) {
    return (
      <div className="page page--center">
        <h1 className="page-title">Onde você vai entrar</h1>
        <div className="card" style={{ width: 'min(400px, 100%)' }}>
          {erro && (
            <div className="alert alert--danger" style={{ marginBottom: 'var(--space-md)' }}>
              <div><span className="alert-title">Não foi possível entrar</span><p>{erro}</p></div>
            </div>
          )}
          <div className="list-group">
            {estabelecimentos.map(e => (
              <button key={e.id} className="list-item" type="button" disabled={entrando}
                onClick={() => escolher(e.id)}>
                <span className="avatar" style={e.color ? { background: e.color } : undefined}>
                  {e.name.slice(0, 1).toUpperCase()}
                </span>
                <span className="list-item-title">{e.name}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="page page--center">
      <h1 className="page-title">Entrar</h1>
      <div className="card" style={{ width: 'min(400px, 100%)' }}>
        {erro && (
          <div className="alert alert--danger" style={{ marginBottom: 'var(--space-md)' }}>
            <div><span className="alert-title">Não foi possível entrar</span><p>{erro}</p></div>
          </div>
        )}
        <form className="stack" style={{ gap: 'var(--space-md)' }} onSubmit={entrar}>
          <div className="field">
            <label className="label" htmlFor="lg-login">Login</label>
            <input className="input" id="lg-login" autoComplete="username" autoFocus required
              value={form.login} onChange={e => setForm({ ...form, login: e.target.value })} />
          </div>
          <div className="field">
            <label className="label" htmlFor="lg-senha">Senha</label>
            <input className="input" id="lg-senha" type="password" autoComplete="current-password" required
              value={form.senha} onChange={e => setForm({ ...form, senha: e.target.value })} />
          </div>
          <button className="btn" type="submit" disabled={entrando} style={{ width: '100%' }}>
            {entrando ? 'Entrando…' : 'Entrar'}
          </button>
        </form>
      </div>
    </div>
  )
}
