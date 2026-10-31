import { useRef, type ReactNode, type PointerEvent as ReactPointerEvent } from 'react'

const OPEN_W = 72

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
  const drag = useRef({ startX: 0, base: 0, dragging: false })

  function onPointerDown(e: ReactPointerEvent) {
    if ((e.target as HTMLElement).closest('button, a, input, select, textarea')) return
    const item = itemRef.current!
    drag.current = { startX: e.clientX, base: item.classList.contains('is-open') ? -OPEN_W : 0, dragging: true }
    contentRef.current!.setPointerCapture(e.pointerId)
    contentRef.current!.style.transition = 'none'
    actionRef.current!.style.transition = 'none'
  }

  function onPointerMove(e: ReactPointerEvent) {
    if (!drag.current.dragging) return
    const dx = Math.min(0, Math.max(-OPEN_W, drag.current.base + (e.clientX - drag.current.startX)))
    contentRef.current!.style.transform = `translateX(${dx}px)`
    const p = -dx / OPEN_W
    actionRef.current!.style.opacity = String(p)
    actionRef.current!.style.transform = `translateY(-50%) scale(${0.4 + 0.6 * p})`
  }

  function release(e: ReactPointerEvent) {
    if (!drag.current.dragging) return
    const dx = drag.current.base + (e.clientX - drag.current.startX)
    drag.current.dragging = false
    contentRef.current!.style.transition = ''
    contentRef.current!.style.transform = ''
    actionRef.current!.style.transition = ''
    actionRef.current!.style.opacity = ''
    actionRef.current!.style.transform = ''
    itemRef.current!.classList.toggle('is-open', dx < -OPEN_W / 2)
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
        onPointerUp={release} onPointerCancel={release}>
        {children}
      </div>
    </div>
  )
}
