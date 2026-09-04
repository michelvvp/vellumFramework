import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './design-system.css'
import './theme.css'
import './custom' // registra as telas CUSTOM do app
import App from './App'
import { AuthProvider } from './auth'
import { ToastProvider } from './ui'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <ToastProvider>
        <App />
      </ToastProvider>
    </AuthProvider>
  </StrictMode>,
)
