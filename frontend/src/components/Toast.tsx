import { createContext, useCallback, useContext, useRef, useState, type ReactNode } from 'react'

type ToastFn = (texto: string, tipo?: 'success' | 'danger' | 'warning') => void

const ToastContext = createContext<ToastFn>(() => {})

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toast, setToast] = useState<{ texto: string; tipo: string } | null>(null)
  const timer = useRef<ReturnType<typeof setTimeout>>()

  const show = useCallback<ToastFn>((texto, tipo = 'success') => {
    clearTimeout(timer.current)
    setToast(null)
    // reinicia a transição quando um toast substitui outro
    requestAnimationFrame(() => {
      setToast({ texto, tipo })
      timer.current = setTimeout(() => setToast(null), 2200)
    })
  }, [])

  return (
    <ToastContext.Provider value={show}>
      {children}
      <div className={`toast toast--${toast?.tipo || 'success'}${toast ? ' show' : ''}`} role="status">
        <span className="toast-dot"></span>{toast?.texto}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  return useContext(ToastContext)
}
