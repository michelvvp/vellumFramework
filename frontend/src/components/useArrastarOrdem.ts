import { useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'

/*
 * Hook de reordenação vertical. A linha arrastada segue o ponteiro (translateY)
 * e troca de posição ao cruzar o meio da vizinha; ao soltar, chama aoSoltar(lista).
 */
export function useArrastarOrdem<T>(setItens: React.Dispatch<React.SetStateAction<T[]>>,
                                    aoSoltar: (lista: T[]) => void) {
  const [dragIdx, setDragIdx] = useState<number | null>(null)
  const [offset, setOffset] = useState(0)
  const refs = useRef<(HTMLElement | null)[]>([])
  const estado = useRef<{ idx: number; total: number; y: number; mudou: boolean } | null>(null)

  function iniciar(e: ReactPointerEvent, idx: number, total: number) {
    if (estado.current) return
    e.preventDefault(); e.stopPropagation()
    estado.current = { idx, total, y: e.clientY, mudou: false }
    setDragIdx(idx); setOffset(0)
    document.body.style.userSelect = 'none'

    const altura = (j: number) => refs.current[j]?.offsetHeight || 48
    const mover = (ev: globalThis.PointerEvent) => {
      const st = estado.current
      if (!st) return
      let delta = ev.clientY - st.y
      let i = st.idx, trocou = false
      while (i < st.total - 1 && delta > altura(i + 1) / 2) {
        delta -= altura(i + 1); st.y += altura(i + 1); i++; trocou = true
      }
      while (i > 0 && delta < -altura(i - 1) / 2) {
        delta += altura(i - 1); st.y -= altura(i - 1); i--; trocou = true
      }
      if (trocou) {
        const de = st.idx
        setItens(prev => {
          const a = [...prev]
          const [movido] = a.splice(de, 1)
          a.splice(i, 0, movido)
          return a
        })
        st.idx = i; st.mudou = true
        setDragIdx(i)
      }
      setOffset(delta)
    }
    const soltar = () => {
      const st = estado.current
      estado.current = null
      window.removeEventListener('pointermove', mover)
      window.removeEventListener('pointerup', soltar)
      window.removeEventListener('pointercancel', soltar)
      document.body.style.userSelect = ''
      setDragIdx(null); setOffset(0)
      // lê a lista final do estado para persistir fora do render
      if (st?.mudou) setItens(prev => { Promise.resolve().then(() => aoSoltar(prev)); return prev })
    }
    window.addEventListener('pointermove', mover)
    window.addEventListener('pointerup', soltar)
    window.addEventListener('pointercancel', soltar)
  }

  const itemProps = (i: number) => ({
    ref: (el: HTMLElement | null) => { refs.current[i] = el },
    className: i === dragIdx ? 'is-dragging' : undefined,
    style: i === dragIdx ? { transform: `translateY(${offset}px)` } : undefined,
  })

  return { iniciar, itemProps }
}
