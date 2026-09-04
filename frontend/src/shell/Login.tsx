import { useState } from 'react'
import { useAuth } from '../auth'

export default function Login() {
  const { login } = useAuth()
  const [form, setForm] = useState({ login: '', senha: '' })
  const [erro, setErro] = useState('')
  const [entrando, setEntrando] = useState(false)

  async function entrar(e: React.FormEvent) {
    e.preventDefault()
    setErro(''); setEntrando(true)
    try {
      await login(form.login.trim(), form.senha)
    } catch (err: any) {
      setErro(err.message)
      setEntrando(false)
    }
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
