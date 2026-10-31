import { useEffect, useRef, useState } from 'react'
import { DOW, MESES, formatarData, ymd } from './format'

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
