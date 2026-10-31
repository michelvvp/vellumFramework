import type { PointerEvent as ReactPointerEvent } from 'react'

export function DragHandle({ onPointerDown, ariaLabel = 'Arraste para reordenar' }: {
  onPointerDown: (e: ReactPointerEvent) => void
  ariaLabel?: string
}) {
  return (
    <span className="drag-handle" role="button" aria-label={ariaLabel} onPointerDown={onPointerDown}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" width="16" height="16">
        <path d="M4 7h16M4 12h16M4 17h16" />
      </svg>
    </span>
  )
}
