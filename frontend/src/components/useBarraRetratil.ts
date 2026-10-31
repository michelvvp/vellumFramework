import { useEffect, useRef, useState } from 'react'

/* Barra inferior retrátil: devolve true quando o usuário desce a página além de
   `aPartirDe` px e false quando sobe. Deltas menores que `limiar` são ignorados
   para a barra não tremer com rolagem hesitante. */
export function useBarraRetratil({ limiar = 8, aPartirDe = 72 } = {}): boolean {
  const [compacta, setCompacta] = useState(false)
  const ultimoY = useRef(0)

  useEffect(() => {
    ultimoY.current = window.scrollY
    let agendado = false
    function aoRolar() {
      if (agendado) return
      agendado = true
      requestAnimationFrame(() => {
        agendado = false
        const y = window.scrollY
        const delta = y - ultimoY.current
        if (Math.abs(delta) < limiar) return
        ultimoY.current = y
        setCompacta(delta > 0 && y > aPartirDe)
      })
    }
    window.addEventListener('scroll', aoRolar, { passive: true })
    return () => window.removeEventListener('scroll', aoRolar)
  }, [limiar, aPartirDe])

  return compacta
}
