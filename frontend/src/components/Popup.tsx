import { useEffect, useRef, useState } from 'react'

/* ---------- Popup (seletor do design system) ---------- */

export interface PopupOption { value: string; label: string }

export function Popup({ value, onChange, options, placeholder = 'Selecione…', ariaLabel, menuLeft = false }: {
  value: string
  onChange: (v: string) => void
  options: PopupOption[]
  placeholder?: string
  ariaLabel?: string
  menuLeft?: boolean
}) {
  const [open, setOpen] = useState(false)
  const raiz = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLButtonElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    const fora = (e: Event) => { if (!raiz.current?.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('pointerdown', fora)
    return () => document.removeEventListener('pointerdown', fora)
  }, [open])

  const atual = options.find(o => String(o.value) === String(value))

  function escolher(v: string) {
    setOpen(false)
    triggerRef.current?.focus()
    onChange(v)
  }

  const itens = () => [...(menuRef.current?.querySelectorAll('.menu-item') ?? [])] as HTMLElement[]

  // Contrato de teclado do DS: setas no trigger abrem o menu já focando um item
  function teclaTrigger(e: React.KeyboardEvent) {
    if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return
    e.preventDefault()
    setOpen(true)
    requestAnimationFrame(() => {
      const els = itens()
      if (!els.length) return
      const sel = els.find(el => el.getAttribute('aria-selected') === 'true')
      ;(e.key === 'ArrowUp' ? els[els.length - 1] : (sel || els[0])).focus()
    })
  }

  // Dentro do menu: setas circulam, Home/End saltam, Esc fecha devolvendo o
  // foco ao trigger, Tab fecha
  function teclaMenu(e: React.KeyboardEvent) {
    const els = itens()
    const idx = els.indexOf(document.activeElement as HTMLElement)
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault()
      const prox = e.key === 'ArrowDown' ? idx + 1 : idx - 1
      els[(prox + els.length) % els.length]?.focus()
    } else if (e.key === 'Home' || e.key === 'End') {
      e.preventDefault()
      els[e.key === 'Home' ? 0 : els.length - 1]?.focus()
    } else if (e.key === 'Escape') {
      e.stopPropagation()
      setOpen(false)
      triggerRef.current?.focus()
    } else if (e.key === 'Tab') {
      setOpen(false)
    }
  }

  return (
    <div className={`popup${open ? ' is-open' : ''}`} ref={raiz}>
      <button className="popup-trigger" type="button" aria-haspopup="listbox" aria-expanded={open}
        aria-label={ariaLabel} ref={triggerRef} onClick={() => setOpen(o => !o)} onKeyDown={teclaTrigger}>
        <span className="popup-value" style={atual ? undefined : { color: 'var(--muted)' }}>
          {atual ? atual.label : placeholder}
        </span>
        <span className="popup-chevron">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M7 9.5 12 4.5l5 5M7 14.5l5 5 5-5" />
          </svg>
        </span>
      </button>
      <div className={`menu${menuLeft ? ' menu--left' : ''}`} role="listbox" hidden={!open}
        ref={menuRef} onKeyDown={teclaMenu} style={{ maxHeight: 320, overflowY: 'auto' }}>
        {options.map(o => (
          <button className="menu-item" type="button" role="option" key={o.value}
            aria-selected={String(o.value) === String(value)} onClick={() => escolher(o.value)}>
            <span className="menu-check">✓</span>{o.label}
          </button>
        ))}
      </div>
    </div>
  )
}
