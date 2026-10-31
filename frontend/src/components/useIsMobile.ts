import { useEffect, useState } from 'react'

/* ---------- Breakpoint mobile (≤640px, mesmo corte do design system) ---------- */

export function useIsMobile() {
  const [mobile, setMobile] = useState(() => window.matchMedia('(max-width: 640px)').matches)
  useEffect(() => {
    const mq = window.matchMedia('(max-width: 640px)')
    const ouvir = (e: MediaQueryListEvent) => setMobile(e.matches)
    mq.addEventListener('change', ouvir)
    return () => mq.removeEventListener('change', ouvir)
  }, [])
  return mobile
}
