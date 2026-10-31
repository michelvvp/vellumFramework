import { useRef, type ReactNode, type PointerEvent as ReactPointerEvent } from 'react'

const OPEN_W = 72
const THRESHOLD = 10

/*
 * Padrão mobile do design system para excluir: arrastar o conteúdo para a
 * esquerda revela o botão. onDelete só deve abrir a confirmação.
 */
export function SwipeRow({ children, onDelete, ariaLabel, className = '' }: {
  children: ReactNode
  onDelete: () => void
  ariaLabel?: string
  className?: string
}) {
  const itemRef = useRef<HTMLDivElement>(null)
  const contentRef = useRef<HTMLDivElement>(null)
  const actionRef = useRef<HTMLDivElement>(null)
  // idle: sem gesto; pending: ponteiro baixo, direção indefinida; drag: arrasto horizontal; ignored: gesto vertical, deixa a rolagem nativa
  const drag = useRef({ startX: 0, startY: 0, base: 0, last: 0, phase: 'idle' as 'idle' | 'pending' | 'drag' | 'ignored' })

  function reset() {
    contentRef.current!.style.transition = ''
    contentRef.current!.style.transform = ''
    actionRef.current!.style.transition = ''
    actionRef.current!.style.opacity = ''
    actionRef.current!.style.transform = ''
  }

  function onPointerDown(e: ReactPointerEvent) {
    if ((e.target as HTMLElement).closest('button, a, input, select, textarea')) return
    const base = itemRef.current!.classList.contains('is-open') ? -OPEN_W : 0
    drag.current = { startX: e.clientX, startY: e.clientY, base, last: base, phase: 'pending' }
  }

  function onPointerMove(e: ReactPointerEvent) {
    const d = drag.current
    if (d.phase === 'idle' || d.phase === 'ignored') return
    const mx = e.clientX - d.startX
    const my = e.clientY - d.startY
    if (d.phase === 'pending') {
      if (Math.max(Math.abs(mx), Math.abs(my)) < THRESHOLD) return
      if (Math.abs(mx) <= Math.abs(my)) { d.phase = 'ignored'; return }
      d.phase = 'drag'
      contentRef.current!.setPointerCapture(e.pointerId)
      contentRef.current!.style.transition = 'none'
      actionRef.current!.style.transition = 'none'
    }
    const dx = Math.min(0, Math.max(-OPEN_W, d.base + mx))
    d.last = d.base + mx
    contentRef.current!.style.transform = `translateX(${dx}px)`
    const p = -dx / OPEN_W
    actionRef.current!.style.opacity = String(p)
    actionRef.current!.style.transform = `translateY(-50%) scale(${0.4 + 0.6 * p})`
  }

  function onPointerUp(e: ReactPointerEvent) {
    const d = drag.current
    const wasDrag = d.phase === 'drag'
    d.phase = 'idle'
    if (!wasDrag) return
    const dx = d.base + (e.clientX - d.startX)
    reset()
    itemRef.current!.classList.toggle('is-open', dx < -OPEN_W / 2)
  }

  // cancel (ex.: navegador assumiu a rolagem): clientX não vale; mantém o estado anterior
  function onPointerCancel() {
    const wasDrag = drag.current.phase === 'drag'
    drag.current.phase = 'idle'
    if (wasDrag) reset()
  }

  return (
    <div className={`swipe-item${className ? ` ${className}` : ''}`} ref={itemRef}>
      <div className="swipe-action" ref={actionRef}>
        <button className="swipe-delete" type="button" aria-label={ariaLabel} onClick={onDelete}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 7h16M9 7V5.5A1.5 1.5 0 0 1 10.5 4h3A1.5 1.5 0 0 1 15 5.5V7M6.5 7l1 13h9l1-13M10 11v6M14 11v6" />
          </svg>
        </button>
      </div>
      <div className="swipe-content" ref={contentRef}
        onPointerDown={onPointerDown} onPointerMove={onPointerMove}
        onPointerUp={onPointerUp} onPointerCancel={onPointerCancel}>
        {children}
      </div>
    </div>
  )
}
