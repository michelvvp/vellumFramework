import { useAuth } from './auth'
import { MetaProvider } from './meta'
import Login from './shell/Login'
import Shell from './shell/Shell'

export default function App() {
  const { auth } = useAuth()

  if (!auth) return <Login />

  return (
    <MetaProvider fallback={
      <div className="page page--center">
        <span className="spinner spinner--lg" role="status" aria-label="Carregando"></span>
      </div>
    }>
      <Shell />
    </MetaProvider>
  )
}
