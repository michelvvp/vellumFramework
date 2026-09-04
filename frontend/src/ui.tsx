import {
  createContext, useCallback, useContext, useEffect, useRef, useState,
  type ReactNode, type PointerEvent as ReactPointerEvent,
} from 'react'
import { createPortal } from 'react-dom'

/* Catálogo de componentes do framework — evolução tipada do catálogo do gym.
   É o único lugar do front com conhecimento das classes do design system;
   os contratos de teclado/foco/toque do DS moram aqui. */

/* Modal sempre no body: .card tem backdrop-filter e vira o bloco de contenção
   do overlay fixed — aberto de dentro de um card, o modal ficaria preso na
   caixa do card em vez de cobrir a janela. */
function noBody(overlay: ReactNode) {
  return createPortal(overlay, document.body)
}

/* ---------- Toast ---------- */

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

/* ---------- Modal de confirmação (vira sheet no mobile) ---------- */

export function ConfirmModal({ aberto, titulo, texto, confirmar = 'Excluir', onConfirmar, onCancelar }: {
  aberto: boolean
  titulo: string
  texto: string
  confirmar?: string
  onConfirmar: () => void
  onCancelar: () => void
}) {
  const mobile = useIsMobile()
  const dialogo = useRef<HTMLDivElement>(null)
  const abriu = useRef<Element | null>(null) // quem tinha o foco antes de abrir

  // Contrato de foco do DS: ao abrir, o foco entra no .modal (é o que faz Esc
  // funcionar); ao fechar, volta para o elemento que abriu.
  useEffect(() => {
    if (aberto) {
      abriu.current = document.activeElement
      dialogo.current?.focus()
    } else if (abriu.current) {
      (abriu.current as HTMLElement).focus?.()
      abriu.current = null
    }
  }, [aberto])

  return noBody(
    <div className={`modal-overlay${mobile ? ' modal-overlay--sheet' : ''}`} hidden={!aberto} onClick={onCancelar}
      onKeyDown={e => { if (e.key === 'Escape') onCancelar() }}>
      <div className={`modal${mobile ? ' modal--sheet' : ''}`} role="dialog" aria-modal="true" aria-labelledby="confirm-titulo"
        tabIndex={-1} ref={dialogo} onClick={e => e.stopPropagation()}>
        {mobile && <div className="sheet-grabber"></div>}
        <h3 id="confirm-titulo">{titulo}</h3>
        <p className="text-muted">{texto}</p>
        <div className="row" style={{ justifyContent: 'flex-end' }}>
          <button className="btn btn--ghost" type="button" onClick={onCancelar}>Cancelar</button>
          <button className="btn btn--danger" type="button" onClick={onConfirmar}>{confirmar}</button>
        </div>
      </div>
    </div>,
  )
}

/* ---------- SelecaoModal (marcar itens de uma lista — MULTI_SELECT / N:N) ---------- */

export function SelecaoModal({ aberto, titulo, itens, selecionados, onSalvar, onFechar, salvando = false }: {
  aberto: boolean
  titulo: string
  itens: { id: number; nome: string }[]
  selecionados: number[]
  onSalvar: (ids: number[]) => void
  onFechar: () => void
  salvando?: boolean
}) {
  const [marcados, setMarcados] = useState<Set<number>>(new Set())
  const dialogo = useRef<HTMLDivElement>(null)
  const abriu = useRef<Element | null>(null)

  useEffect(() => {
    if (aberto) {
      setMarcados(new Set(selecionados))
      abriu.current = document.activeElement
      requestAnimationFrame(() => dialogo.current?.focus())
    } else if (abriu.current) {
      (abriu.current as HTMLElement).focus?.()
      abriu.current = null
    }
  }, [aberto]) // eslint-disable-line react-hooks/exhaustive-deps

  function alternar(id: number, on: boolean) {
    setMarcados(prev => {
      const novo = new Set(prev)
      if (on) novo.add(id); else novo.delete(id)
      return novo
    })
  }

  return noBody(
    <div className="modal-overlay" hidden={!aberto} onClick={onFechar}
      onKeyDown={e => { if (e.key === 'Escape') onFechar() }}>
      <div className="modal" role="dialog" aria-modal="true" aria-labelledby="sm-titulo"
        tabIndex={-1} ref={dialogo} onClick={e => e.stopPropagation()}>
        <h3 id="sm-titulo">{titulo}</h3>
        <div className="list-group" style={{ marginTop: 'var(--space-md)', maxHeight: 320, overflowY: 'auto' }}>
          {itens.map(i => (
            <div className="list-row" key={i.id}>
              <span className="list-label">{i.nome}</span>
              <label className="switch">
                <input type="checkbox" checked={marcados.has(i.id)} aria-label={i.nome}
                  onChange={e => alternar(i.id, e.target.checked)} />
                <span className="switch-track" />
              </label>
            </div>
          ))}
          {itens.length === 0 && (
            <div className="list-row"><span className="list-label text-muted">Nada cadastrado ainda.</span></div>
          )}
        </div>
        <div className="row" style={{ justifyContent: 'flex-end', marginTop: 'var(--space-md)' }}>
          <button className="btn btn--ghost" type="button" onClick={onFechar}>Cancelar</button>
          <button className="btn" type="button" disabled={salvando} onClick={() => onSalvar([...marcados])}>Salvar</button>
        </div>
      </div>
    </div>,
  )
}

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

/* ---------- DatePicker (popup + mini calendário do DS) ---------- */

const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
const DOW = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']

function ymd(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export function formatarData(iso: string) {
  const [a, m, d] = iso.split('-')
  return `${d}/${m}/${a}`
}

/*
 * Seletor de data: trigger do pop-up button + .mini-cal dentro do .menu.
 * value: 'YYYY-MM-DD' ou ''. Clicar no dia selecionado limpa (volta a '').
 */
export function DatePicker({ value, onChange, ariaLabel, placeholder = 'Data', menuLeft = false }: {
  value: string
  onChange: (v: string) => void
  ariaLabel?: string
  placeholder?: string
  menuLeft?: boolean
}) {
  const [open, setOpen] = useState(false)
  const [alinhaEsq, setAlinhaEsq] = useState(menuLeft)
  const hoje = ymd(new Date())
  const base = value || hoje
  const [visivel, setVisivel] = useState(base.slice(0, 7)) // 'YYYY-MM'
  const raiz = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLButtonElement>(null)

  // abre o calendário para o lado com mais espaço, senão ele estoura o viewport no mobile
  function alternar() {
    const r = raiz.current?.getBoundingClientRect()
    if (r) setAlinhaEsq(r.left + r.width / 2 < window.innerWidth / 2)
    setOpen(o => !o)
  }

  useEffect(() => {
    if (!open) return
    setVisivel((value || hoje).slice(0, 7))
    const fora = (e: Event) => { if (!raiz.current?.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('pointerdown', fora)
    return () => document.removeEventListener('pointerdown', fora)
  }, [open]) // eslint-disable-line react-hooks/exhaustive-deps

  const [ano, mes] = visivel.split('-').map(Number)

  function mudarMes(delta: number) {
    const d = new Date(ano, mes - 1 + delta, 1)
    setVisivel(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`)
  }

  // grade sempre com linhas completas de 7 dias, incluindo vizinhos
  const primeiro = new Date(ano, mes - 1, 1)
  const inicio = new Date(primeiro)
  inicio.setDate(1 - primeiro.getDay())
  const dias: Date[] = []
  for (let i = 0; i < 42; i++) {
    const d = new Date(inicio)
    d.setDate(inicio.getDate() + i)
    dias.push(d)
  }
  const grade = dias[35].getMonth() === mes - 1 ? dias : dias.slice(0, 35)

  function escolher(d: Date) {
    const iso = ymd(d)
    onChange(iso === value ? '' : iso)
    setOpen(false)
    triggerRef.current?.focus()
  }

  // Contrato de teclado do DS: Esc fecha o popover devolvendo o foco ao trigger
  function tecla(e: React.KeyboardEvent) {
    if (e.key !== 'Escape' || !open) return
    e.stopPropagation()
    setOpen(false)
    triggerRef.current?.focus()
  }

  const Chevron = ({ virado }: { virado?: boolean }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
      style={virado ? { transform: 'scaleX(-1)' } : undefined}>
      <path d="m15 6-6 6 6 6" />
    </svg>
  )

  return (
    <div className={`popup${open ? ' is-open' : ''}`} ref={raiz} onKeyDown={tecla}>
      <button className="popup-trigger" type="button" aria-haspopup="dialog" aria-expanded={open}
        aria-label={ariaLabel} ref={triggerRef} onClick={alternar}>
        <span className="popup-value" style={value ? undefined : { color: 'var(--muted)' }}>
          {value ? formatarData(value) : placeholder}
        </span>
        <span className="popup-chevron">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M7 9.5 12 4.5l5 5M7 14.5l5 5 5-5" />
          </svg>
        </span>
      </button>
      <div className={`menu${alinhaEsq ? ' menu--left' : ''}`} hidden={!open} style={{ minWidth: 0 }}>
        <div className="mini-cal">
          <div className="mini-cal-header">
            <button className="icon-btn" type="button" aria-label="Mês anterior" onClick={() => mudarMes(-1)}>
              <Chevron />
            </button>
            <span className="mini-cal-title">{MESES[mes - 1]} {ano}</span>
            <button className="icon-btn" type="button" aria-label="Próximo mês" onClick={() => mudarMes(1)}>
              <Chevron virado />
            </button>
          </div>
          <div className="mini-cal-grid">
            {DOW.map((d, i) => <span className="dow" key={i}>{d}</span>)}
            {grade.map(d => {
              const iso = ymd(d)
              const cls = ['mini-cal-day']
              if (d.getMonth() !== mes - 1) cls.push('is-muted')
              if (iso === hoje) cls.push('is-today')
              else if (iso === value) cls.push('is-selected')
              return (
                <button className={cls.join(' ')} type="button" key={iso}
                  aria-current={iso === hoje ? 'date' : undefined}
                  onClick={() => escolher(d)}>
                  {d.getDate()}
                </button>
              )
            })}
          </div>
        </div>
      </div>
    </div>
  )
}

/* ---------- Reordenar por arrasto (pegar no ≡ e arrastar) ---------- */

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

/* ---------- SwipeRow (excluir por arrasto no mobile) ---------- */

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

/* ---------- Avatar com iniciais ---------- */

export function iniciais(nome: string | undefined) {
  return (nome || '?')
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map(p => p[0])
    .join('')
    .toUpperCase()
}
