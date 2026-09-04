import { useEffect, useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { data } from '../api'
import { useMeta } from '../meta'
import { useIsMobile } from '../ui'
import FieldInput from './FieldInput'
import type { PopupOption } from '../ui'
import type { Row, VisionDef } from '../types'

/*
 * Formulário genérico de criar/editar (modal no desktop, sheet no mobile),
 * montado a partir de vision_field. Erros de validação do backend chegam
 * estruturados ({field, code, message}) e caem no .field-error de cada campo.
 */
export default function FormModal({ vision, registro, parentId, onFechar, onSalvo }: {
  vision: VisionDef
  registro: Row | null   // null = fechado; {} = novo; com nr_sequence = edição
  parentId?: number
  onFechar: () => void
  onSalvo: () => void
}) {
  const { meta } = useMeta()
  const mobile = useIsMobile()
  const aberto = registro !== null
  const edicao = !!registro?.nr_sequence
  const tabela = meta.tables[vision.table!]

  const campos = useMemo(() => vision.fields
    .filter(f => f.form)
    // o FK do pai é preenchido automaticamente quando se navega a partir dele
    .filter(f => !(vision.parentFkField === f.field && parentId !== undefined))
    .sort((a, b) => (a.orderForm ?? 999) - (b.orderForm ?? 999)), [vision, parentId])

  const [values, setValues] = useState<Row>({})
  const [erros, setErros] = useState<Record<string, string>>({})
  const [erroGeral, setErroGeral] = useState('')
  const [salvando, setSalvando] = useState(false)
  const [opcoes, setOpcoes] = useState<Record<string, PopupOption[]>>({})
  const dialogo = useRef<HTMLDivElement>(null)
  const abriu = useRef<Element | null>(null)

  // contrato de foco do DS + reset do estado a cada abertura
  useEffect(() => {
    if (aberto) {
      setValues({ ...registro })
      setErros({}); setErroGeral(''); setSalvando(false)
      abriu.current = document.activeElement
      requestAnimationFrame(() => dialogo.current?.focus())
    } else if (abriu.current) {
      (abriu.current as HTMLElement).focus?.()
      abriu.current = null
    }
  }, [aberto]) // eslint-disable-line react-hooks/exhaustive-deps

  // opções dos combos ENTITY; nm_ref_filter_field filtra pelas mudanças do form
  useEffect(() => {
    if (!aberto) return
    for (const vf of campos) {
      const def = tabela.fields[vf.field]
      if (def?.type !== 'ENTITY' || !def.refTable) continue
      const params: Record<string, any> = {}
      if (vf.refFilterField) {
        const filtro = values[vf.refFilterField]
        if (filtro === null || filtro === undefined || filtro === '') {
          setOpcoes(prev => ({ ...prev, [vf.field]: [] }))
          continue
        }
        params[vf.refFilterField] = filtro
      }
      data.lookup(def.refTable, params)
        .then(rows => setOpcoes(prev => ({
          ...prev,
          [vf.field]: rows.map(r => ({ value: String(r.id), label: r.label || `#${r.id}` })),
        })))
        .catch(() => setOpcoes(prev => ({ ...prev, [vf.field]: [] })))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [aberto, ...campos.map(vf => vf.refFilterField ? values[vf.refFilterField] : null)])

  function set(campo: string, v: any) {
    setValues(prev => ({ ...prev, [campo]: v }))
    setErros(prev => {
      if (!prev[campo]) return prev
      const novo = { ...prev }
      delete novo[campo]
      return novo
    })
  }

  async function salvar(e: React.FormEvent) {
    e.preventDefault()
    setSalvando(true); setErroGeral(''); setErros({})
    try {
      const payload: Row = {}
      for (const vf of campos) {
        if (vf.readOnly) continue
        const def = tabela.fields[vf.field]
        let v = values[vf.field]
        if (def.type === 'ENTITY' && v !== null && v !== undefined && v !== '') v = Number(v)
        payload[vf.field] = v === undefined ? null : v
      }
      if (vision.parentFkField && parentId !== undefined && !edicao) {
        payload[vision.parentFkField] = parentId
      }
      if (edicao) await data.update(vision.table!, registro!.nr_sequence, vision.key, payload)
      else await data.create(vision.table!, vision.key, payload)
      onSalvo()
    } catch (err: any) {
      if (err.errors?.length) {
        const porCampo: Record<string, string> = {}
        for (const fe of err.errors) {
          if (fe.field) porCampo[fe.field] = fe.message
          else setErroGeral(fe.message)
        }
        setErros(porCampo)
        const semCampo = err.errors.filter((fe: any) => !fe.field || !campos.some(c => c.field === fe.field))
        if (semCampo.length) setErroGeral(semCampo.map((fe: any) => fe.message).join('; '))
      } else {
        setErroGeral(err.message)
      }
      setSalvando(false)
    }
  }

  return createPortal(
    <div className={`modal-overlay${mobile ? ' modal-overlay--sheet' : ''}`} hidden={!aberto} onClick={onFechar}
      onKeyDown={e => { if (e.key === 'Escape') onFechar() }}>
      <div className={`modal${mobile ? ' modal--sheet' : ''}`} role="dialog" aria-modal="true"
        aria-labelledby="form-titulo" tabIndex={-1} ref={dialogo} onClick={e => e.stopPropagation()}>
        {mobile && <div className="sheet-grabber"></div>}
        <h3 id="form-titulo">{edicao ? 'Editar' : 'Novo'} — {tabela?.label ?? vision.title}</h3>
        {erroGeral && (
          <div className="alert alert--danger" style={{ marginTop: 'var(--space-md)' }}>
            <div><span className="alert-title">Não foi possível salvar</span><p>{erroGeral}</p></div>
          </div>
        )}
        {aberto && (
          <form className="stack" style={{ gap: 'var(--space-md)', marginTop: 'var(--space-md)' }} onSubmit={salvar}>
            {campos.map(vf => {
              const def = tabela.fields[vf.field]
              if (!def) return null
              return (
                <FieldInput key={vf.field} vf={vf} def={def}
                  value={values[vf.field] ?? null}
                  onChange={v => set(vf.field, v)}
                  error={erros[vf.field]}
                  entityOptions={opcoes[vf.field]}
                  disabled={vf.readOnly || !!def.computed} />
              )
            })}
            <div className="row" style={{ justifyContent: 'flex-end' }}>
              <button className="btn btn--ghost" type="button" onClick={onFechar}>Cancelar</button>
              <button className="btn" type="submit" disabled={salvando}>
                {salvando ? 'Salvando…' : 'Salvar'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>,
    document.body,
  )
}
