import { useMeta } from '../meta'
import { DatePicker, Popup, type PopupOption } from '../ui'
import type { ColumnDef, VisionColumnDef } from '../types'

/*
 * Um campo do formulário genérico: escolhe o widget pelo ie_component da
 * visão (ou pelo default do tipo) e mapeia 1:1 para as classes do design
 * system (catálogo da seção 3.6 da especificação).
 */
export default function FieldInput({ vf, def, value, onChange, error, entityOptions, disabled }: {
  vf: VisionColumnDef
  def: ColumnDef
  value: any
  onChange: (v: any) => void
  error?: string
  entityOptions?: PopupOption[]  // opções carregadas pelo FormModal (ENTITY)
  disabled?: boolean
}) {
  const { meta } = useMeta()
  const id = `f-${vf.column}`
  const component = vf.component || defaultComponent(def)
  const texto = value === null || value === undefined ? '' : String(value)

  function controle() {
    switch (component) {
      case 'SWITCH':
      case 'CHECKBOX': {
        const marcado = value === true || value === 'true' || value === 1
        if (component === 'CHECKBOX') {
          return (
            <label className="checkbox">
              <input type="checkbox" checked={marcado} disabled={disabled}
                onChange={e => onChange(e.target.checked)} /> {rotulo(vf, def)}
            </label>
          )
        }
        return (
          <label className="switch">
            <input type="checkbox" checked={marcado} disabled={disabled} aria-label={rotulo(vf, def)}
              onChange={e => onChange(e.target.checked)} />
            <span className="switch-track"></span>
          </label>
        )
      }
      case 'SEGMENTED': {
        const opcoes = dominio()
        return (
          <div className="segmented segmented--full" role="group" aria-label={rotulo(vf, def)}>
            {opcoes.map(o => (
              <button key={o.value} type="button" aria-pressed={texto === o.value} disabled={disabled}
                onClick={() => onChange(o.value)}>{o.label}</button>
            ))}
          </div>
        )
      }
      case 'RADIO': {
        return (
          <div className="stack" style={{ gap: 'var(--space-2xs)' }}>
            {dominio().map(o => (
              <label className="radio" key={o.value}>
                <input type="radio" name={id} checked={texto === o.value} disabled={disabled}
                  onChange={() => onChange(o.value)} /> {o.label}
              </label>
            ))}
          </div>
        )
      }
      case 'POPUP': {
        const opcoes = def.type === 'ENTITY' ? (entityOptions ?? []) : dominio()
        const comVazio: PopupOption[] = def.required ? opcoes : [{ value: '', label: '—' }, ...opcoes]
        return disabled
          ? <input className="input" id={id} value={rotuloDe(opcoes, texto)} disabled />
          : <Popup value={texto} onChange={v => onChange(v === '' ? null : v)}
              options={comVazio} ariaLabel={rotulo(vf, def)} menuLeft />
      }
      case 'DATE_PICKER':
        return disabled
          ? <input className="input" id={id} value={texto} disabled />
          : <DatePicker value={texto.slice(0, 10)} onChange={v => onChange(v || null)}
              ariaLabel={rotulo(vf, def)} />
      case 'DATETIME_PICKER':
        return <input className="input" id={id} type="datetime-local" disabled={disabled}
          value={texto ? texto.slice(0, 16).replace(' ', 'T') : ''}
          onChange={e => onChange(e.target.value || null)} />
      case 'SLIDER': {
        const min = Number(def.min ?? 0), max = Number(def.max ?? 100)
        const atual = Number(texto || min)
        // contrato JS do slider (WebKit): sincroniza --fill com o valor
        const fill = `${((atual - min) / (max - min)) * 100}%`
        return <input className="slider" type="range" min={min} max={max} value={atual} disabled={disabled}
          aria-label={rotulo(vf, def)} style={{ '--fill': fill } as React.CSSProperties}
          onChange={e => onChange(Number(e.target.value))} />
      }
      case 'TEXTAREA':
        return <textarea className="input" id={id} rows={4} value={texto} disabled={disabled}
          maxLength={def.size} onChange={e => onChange(e.target.value)} />
      case 'PASSWORD':
        return <input className="input" id={id} type="password" value={texto} disabled={disabled}
          autoComplete="new-password" placeholder={def.hint ? undefined : '••••••'}
          onChange={e => onChange(e.target.value)} />
      default: { // INPUT
        const numerico = def.type === 'INTEGER' || def.type === 'DECIMAL'
        const tipoInput = numerico ? 'number' : def.type === 'TIME' ? 'time' : 'text'
        return <input className="input" id={id} type={tipoInput} value={texto} disabled={disabled}
          maxLength={def.size} step={def.type === 'DECIMAL' ? 'any' : undefined}
          onChange={e => {
            const v = e.target.value
            onChange(v === '' ? null : numerico ? Number(v) : v)
          }} />
      }
    }
  }

  function dominio(): PopupOption[] {
    return (meta.domains[def.domain ?? ''] ?? []).map(v => ({ value: v.value, label: v.label }))
  }

  const soControle = component === 'CHECKBOX'
  return (
    <div className="field">
      {!soControle && <label className="label" htmlFor={id}>{rotulo(vf, def)}</label>}
      {controle()}
      {error
        ? <span className="field-error">{error}</span>
        : def.hint ? <span className="field-hint">{def.hint}</span> : null}
    </div>
  )
}

function rotulo(vf: VisionColumnDef, def: ColumnDef) {
  return vf.label || def.label
}

function rotuloDe(opcoes: PopupOption[], valor: string) {
  return opcoes.find(o => o.value === valor)?.label ?? valor
}

export function defaultComponent(def: ColumnDef): string {
  switch (def.type) {
    case 'BOOLEAN': return 'SWITCH'
    case 'TEXT': case 'JSON': return 'TEXTAREA'
    case 'PASSWORD': return 'PASSWORD'
    case 'DOMAIN': case 'ENTITY': return 'POPUP'
    case 'DATE': return 'DATE_PICKER'
    case 'DATETIME': return 'DATETIME_PICKER'
    default: return 'INPUT'
  }
}
