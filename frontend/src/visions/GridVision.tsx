import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { data } from '../api'
import { useMeta } from '../meta'
import {
  ConfirmModal, DatePicker, DragHandle, Popup, SelecaoModal, SwipeRow,
  formatarData, useArrastarOrdem, useIsMobile, useToast, type PopupOption,
} from '../ui'
import FormModal from './FormModal'
import type { ActionDef, ColumnDef, Row, VisionDef, VisionColumnDef } from '../types'

/*
 * A listagem genérica — o arquétipo consolidado do gym: tabela no desktop,
 * .list-group + swipe no mobile, filtros no cabeçalho, form modal de
 * criar/editar, exclusão em duas etapas, menu de contexto por linha com as
 * visões-filhas (MASTER_DETAIL) e as ações cadastradas.
 */
export default function GridVision({ vision, parentId, onOpenChild }: {
  vision: VisionDef
  parentId?: number
  onOpenChild: (childKey: string, row: Row) => void
}) {
  const { meta } = useMeta()
  const toast = useToast()
  const mobile = useIsMobile()
  const tabela = meta.tables[vision.table!]

  const [rows, setRows] = useState<Row[]>([])
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState('')
  const [filtros, setFiltros] = useState<Record<string, any>>({})
  const [editando, setEditando] = useState<Row | null>(null)
  const [excluindo, setExcluindo] = useState<Row | null>(null)
  const [confirmandoAcao, setConfirmandoAcao] = useState<{ acao: ActionDef; row?: Row } | null>(null)
  const [menuAberto, setMenuAberto] = useState<number | null>(null) // nr_sequence da linha
  const [selecaoAberta, setSelecaoAberta] = useState(false)
  const [opcoesSelecao, setOpcoesSelecao] = useState<{ id: number; nome: string }[]>([])
  const [opcoesFiltro, setOpcoesFiltro] = useState<Record<string, PopupOption[]>>({})

  const colunas = useMemo(() => vision.columns
    .filter(f => f.grid)
    .filter(f => tabela.columns[f.column] && tabela.columns[f.column].type !== 'PASSWORD')
    .filter(f => !(vision.parentFkColumn === f.column && parentId !== undefined))
    .sort((a, b) => (a.orderGrid ?? 999) - (b.orderGrid ?? 999)), [vision, parentId, tabela])

  const camposFiltro = useMemo(() => vision.columns.filter(f => f.filter), [vision])

  // reordenação por arrasto: habilitada quando algum campo da visão pede DRAG_ORDER
  const arrastavel = vision.columns.some(f => f.component === 'DRAG_ORDER') && vision.allow.update
  // seleção N:N: campo ENTITY com MULTI_SELECT numa visão-filha (tabela de ligação)
  const campoMulti = useMemo(() => {
    if (parentId === undefined) return undefined
    const vf = vision.columns.find(f => f.component === 'MULTI_SELECT')
    if (!vf) return undefined
    const def = tabela.columns[vf.column]
    return def?.type === 'ENTITY' && def.refTable ? { vf, def } : undefined
  }, [vision, parentId, tabela])

  const carregar = useCallback(async () => {
    setErro('')
    try {
      const params: Record<string, any> = {}
      if (vision.parentFkColumn && parentId !== undefined) params[vision.parentFkColumn] = parentId
      for (const [campo, v] of Object.entries(filtros)) {
        if (v === '' || v === null || v === undefined) continue
        const def = tabela.columns[campo.replace(/__(gte|lte|like)$/, '')]
        if (!def) continue
        params[campo] = v
      }
      setRows(await data.list(vision.table!, vision.key, params))
    } catch (e: any) {
      setErro(e.message)
    } finally {
      setCarregando(false)
    }
  }, [vision, parentId, JSON.stringify(filtros)]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { carregar() }, [carregar])

  // opções dos filtros ENTITY (combos do cabeçalho)
  useEffect(() => {
    for (const vf of camposFiltro) {
      const def = tabela.columns[vf.column]
      if (def?.type !== 'ENTITY' || !def.refTable) continue
      data.lookup(def.refTable, vision.key)
        .then(r => setOpcoesFiltro(prev => ({
          ...prev, [vf.column]: r.map(x => ({ value: String(x.id), label: x.label || `#${x.id}` })),
        })))
        .catch(() => {})
    }
  }, [camposFiltro, tabela])

  // menu de contexto fecha em clique fora
  useEffect(() => {
    if (menuAberto === null) return
    const fechar = () => setMenuAberto(null)
    document.addEventListener('pointerdown', fechar)
    return () => document.removeEventListener('pointerdown', fechar)
  }, [menuAberto])

  const drag = useArrastarOrdem(setRows, lista => {
    data.reorder(vision.table!, vision.key, lista.map(r => r.nr_sequence))
      .then(() => toast('Ordem salva'))
      .catch(e => { toast(e.message, 'danger'); carregar() })
  })

  async function excluir() {
    const row = excluindo!
    setExcluindo(null)
    try {
      await data.remove(vision.table!, row.nr_sequence, vision.key)
      toast(`${tabela.label} excluído`)
      carregar()
    } catch (e: any) {
      toast(e.message, 'danger')
    }
  }

  async function executarAcao(acao: ActionDef, row?: Row) {
    try {
      await data.execute(acao.name, { visionKey: vision.key, recordId: row?.nr_sequence })
      toast(acao.successMsg || 'Feito')
      carregar()
    } catch (e: any) {
      toast(e.message, 'danger')
    }
  }

  function dispararAcao(acao: ActionDef, row?: Row) {
    if (acao.confirm) setConfirmandoAcao({ acao, row })
    else executarAcao(acao, row)
  }

  async function abrirSelecao() {
    try {
      const opcoes = await data.lookup(campoMulti!.def.refTable!, vision.key)
      setOpcoesSelecao(opcoes.map(o => ({ id: o.id, nome: o.label || `#${o.id}` })))
      setSelecaoAberta(true)
    } catch (e: any) {
      toast(e.message, 'danger')
    }
  }

  /* N:N por seleção: diff entre os marcados e as linhas atuais da ligação */
  async function salvarSelecao(ids: number[]) {
    const { vf } = campoMulti!
    const atuais = new Map(rows.map(r => [Number(r[vf.column]), r.nr_sequence]))
    try {
      for (const id of ids) {
        if (!atuais.has(id)) {
          await data.create(vision.table!, vision.key, {
            [vf.column]: id, [vision.parentFkColumn!]: parentId,
          })
        }
      }
      for (const [id, seq] of atuais) {
        if (!ids.includes(id)) await data.remove(vision.table!, seq, vision.key)
      }
      setSelecaoAberta(false)
      toast('Seleção salva')
      carregar()
    } catch (e: any) {
      toast(e.message, 'danger')
    }
  }

  const temMenuLinha = vision.children.length > 0
    || vision.actions.some(a => a.placement === 'ROW')
    || vision.allow.update || vision.allow.delete

  function celula(vf: VisionColumnDef, row: Row) {
    const def = tabela.columns[vf.column]
    return formatarCelula(def, vf, row, meta.domains)
  }

  function rotuloLinha(row: Row): string {
    const partes = (tabela.labelFields ?? [])
      .map(lf => row[lf])
      .filter(x => x !== null && x !== undefined && x !== '')
    return partes.join(' · ') || `#${row.nr_sequence}`
  }

  /* menu de contexto da linha (filhos, ações, editar, excluir) */
  function menuLinha(row: Row) {
    return (
      <span className="row-menu" onPointerDown={e => e.stopPropagation()}>
        <button className="icon-btn" type="button" data-tooltip="Opções"
          aria-label={`Opções de ${rotuloLinha(row)}`} aria-haspopup="menu"
          aria-expanded={menuAberto === row.nr_sequence}
          onClick={() => setMenuAberto(m => m === row.nr_sequence ? null : row.nr_sequence)}>
          <svg viewBox="0 0 24 24" fill="currentColor" width="16" height="16">
            <circle cx="5" cy="12" r="1.8" /><circle cx="12" cy="12" r="1.8" /><circle cx="19" cy="12" r="1.8" />
          </svg>
        </button>
        <div className="menu" role="menu" hidden={menuAberto !== row.nr_sequence}>
          {vision.children.map(childKey => {
            const filho = meta.visions.find(v => v.key === childKey)
            return (
              <button className="menu-item" type="button" role="menuitem" key={childKey}
                onClick={() => { setMenuAberto(null); onOpenChild(childKey, row) }}>
                <span className="menu-check">›</span>{filho?.title ?? childKey}
              </button>
            )
          })}
          {vision.actions.filter(a => a.placement === 'ROW').map(a => (
            <button className="menu-item" type="button" role="menuitem" key={a.name}
              onClick={() => { setMenuAberto(null); dispararAcao(a, row) }}>
              <span className="menu-check">⚡</span>{a.label ?? a.name}
            </button>
          ))}
          {(vision.children.length > 0 || vision.actions.some(a => a.placement === 'ROW'))
            && (vision.allow.update || vision.allow.delete) && <div className="menu-divider"></div>}
          {vision.allow.update && (
            <button className="menu-item" type="button" role="menuitem"
              onClick={() => { setMenuAberto(null); setEditando(row) }}>
              <span className="menu-check">✎</span>Editar
            </button>
          )}
          {vision.allow.delete && (
            <button className="menu-item" type="button" role="menuitem"
              onClick={() => { setMenuAberto(null); setExcluindo(row) }}>
              <span className="menu-check">✕</span>Excluir
            </button>
          )}
        </div>
      </span>
    )
  }

  function controleFiltro(vf: VisionColumnDef) {
    const def = tabela.columns[vf.column]
    const rotulo = vf.label || def.label
    if (def.type === 'DATE' || def.type === 'DATETIME') {
      return (
        <span className="row" style={{ gap: 'var(--space-xs)' }} key={vf.column}>
          <DatePicker value={filtros[`${vf.column}__gte`] ?? ''} placeholder={`${rotulo} de`}
            ariaLabel={`${rotulo} a partir de`} onChange={v => setFiltros(f => ({ ...f, [`${vf.column}__gte`]: v }))} />
          <DatePicker value={filtros[`${vf.column}__lte`] ?? ''} placeholder={`${rotulo} até`}
            ariaLabel={`${rotulo} até`} onChange={v => setFiltros(f => ({ ...f, [`${vf.column}__lte`]: v }))} />
        </span>
      )
    }
    if (def.type === 'DOMAIN') {
      const opcoes = (meta.domains[def.domain ?? ''] ?? []).map(v => ({ value: v.value, label: v.label }))
      return <Popup key={vf.column} value={filtros[vf.column] ?? ''} ariaLabel={`Filtrar por ${rotulo}`}
        options={[{ value: '', label: `${rotulo}: todos` }, ...opcoes]}
        onChange={v => setFiltros(f => ({ ...f, [vf.column]: v }))} />
    }
    if (def.type === 'ENTITY') {
      return <Popup key={vf.column} value={filtros[vf.column] ?? ''} ariaLabel={`Filtrar por ${rotulo}`}
        options={[{ value: '', label: `${rotulo}: todos` }, ...(opcoesFiltro[vf.column] ?? [])]}
        onChange={v => setFiltros(f => ({ ...f, [vf.column]: v }))} />
    }
    if (def.type === 'BOOLEAN') {
      return <Popup key={vf.column} value={filtros[vf.column] ?? ''} ariaLabel={`Filtrar por ${rotulo}`}
        options={[{ value: '', label: `${rotulo}: todos` }, { value: 'true', label: 'Sim' }, { value: 'false', label: 'Não' }]}
        onChange={v => setFiltros(f => ({ ...f, [vf.column]: v }))} />
    }
    return <input key={vf.column} className="input input--sm" type="search" placeholder={rotulo}
      aria-label={`Filtrar por ${rotulo}`} value={filtros[`${vf.column}__like`] ?? ''}
      onChange={e => setFiltros(f => ({ ...f, [`${vf.column}__like`]: e.target.value }))}
      style={{ width: 160 }} />
  }

  const skeleton = (
    <div className="stack" style={{ gap: 'var(--space-sm)' }}>
      {[0, 1, 2].map(i => <span key={i} className="skeleton skeleton--text" style={{ width: `${80 - i * 15}%` }}></span>)}
    </div>
  )

  const listaMobile = (
    <div className="list-group" style={{ border: 0, borderRadius: 0 }}>
      {rows.map((row, i) => {
        const conteudo = (
          <div className="list-row" {...(arrastavel ? {} : {})}>
            {arrastavel && <DragHandle onPointerDown={e => drag.iniciar(e, i, rows.length)} />}
            <span className="list-label">
              {rotuloLinha(row)}
              <span className="list-sub">{subtituloLinha(colunas, tabela.columns, row, meta.domains)}</span>
            </span>
            <span className="list-trailing">
              {badgeLinha(colunas, tabela.columns, row, meta.domains)}
              {temMenuLinha && menuLinha(row)}
            </span>
          </div>
        )
        return vision.allow.delete && !arrastavel
          ? <SwipeRow key={row.nr_sequence} ariaLabel={`Excluir ${rotuloLinha(row)}`}
              onDelete={() => setExcluindo(row)}>{conteudo}</SwipeRow>
          : <div key={row.nr_sequence} {...(arrastavel ? drag.itemProps(i) : {})}>{conteudo}</div>
      })}
      {rows.length === 0 && (
        <div className="list-row"><span className="list-label text-muted">Nenhum registro.</span></div>
      )}
    </div>
  )

  return (
    <>
      <div className="content-header">
        <h1>{vision.title}</h1>
        <div className="row" style={{ gap: 'var(--space-sm)' }}>
          {camposFiltro.map(controleFiltro)}
          {vision.actions.filter(a => a.placement !== 'ROW').map(a => (
            <button key={a.name} className="btn btn--secondary" type="button" onClick={() => dispararAcao(a)}>
              {a.label ?? a.name}
            </button>
          ))}
          {campoMulti && vision.allow.create && (
            <button className="btn btn--secondary" type="button" onClick={abrirSelecao}>
              Selecionar…
            </button>
          )}
          {vision.allow.create && (
            <button className="add-btn" type="button" aria-label={`Adicionar ${tabela.label.toLowerCase()}`}
              onClick={() => setEditando({})}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M12 5v14M5 12h14" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {erro && (
        <div className="alert alert--danger" style={{ marginBottom: 'var(--space-md)' }}>
          <div><span className="alert-title">Erro ao carregar</span><p>{erro}</p></div>
        </div>
      )}

      {carregando ? skeleton : (
        <div className="card card--solid" style={{ padding: 0, overflow: 'hidden' }}>
          {/* com arrasto habilitado, desktop e mobile usam a lista (é onde vive o pegador) */}
          {!arrastavel && !mobile && (
            <div className="table-wrap desktop-only">
              <table className="table">
                <thead>
                  <tr>
                    {colunas.map(c => {
                      const def = tabela.columns[c.column]
                      const numerica = def.type === 'INTEGER' || def.type === 'DECIMAL'
                      return <th key={c.column} className={numerica ? 'numeric' : undefined}>{c.label}</th>
                    })}
                    {temMenuLinha && <th style={{ width: 48 }}></th>}
                  </tr>
                </thead>
                <tbody>
                  {rows.map(row => (
                    <tr key={row.nr_sequence}>
                      {colunas.map(c => {
                        const def = tabela.columns[c.column]
                        const numerica = def.type === 'INTEGER' || def.type === 'DECIMAL'
                        return <td key={c.column} className={numerica ? 'numeric' : undefined}>{celula(c, row)}</td>
                      })}
                      {temMenuLinha && <td style={{ textAlign: 'right' }}>{menuLinha(row)}</td>}
                    </tr>
                  ))}
                  {rows.length === 0 && (
                    <tr><td colSpan={colunas.length + 1} className="text-muted">Nenhum registro.</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
          {(arrastavel || mobile) ? listaMobile : <div className="mobile-list">{listaMobile}</div>}
        </div>
      )}

      <FormModal vision={vision} registro={editando} parentId={parentId}
        onFechar={() => setEditando(null)}
        onSalvo={() => { setEditando(null); toast('Salvo'); carregar() }} />

      <ConfirmModal aberto={excluindo !== null}
        titulo={`Excluir ${tabela.label.toLowerCase()}?`}
        texto={excluindo ? `"${rotuloLinha(excluindo)}" será excluído. Não dá para desfazer.` : ''}
        onConfirmar={excluir} onCancelar={() => setExcluindo(null)} />

      <ConfirmModal aberto={confirmandoAcao !== null}
        titulo={confirmandoAcao ? `${confirmandoAcao.acao.label ?? confirmandoAcao.acao.name}?` : ''}
        texto="Confirma executar esta ação?" confirmar="Executar"
        onConfirmar={() => { const c = confirmandoAcao!; setConfirmandoAcao(null); executarAcao(c.acao, c.row) }}
        onCancelar={() => setConfirmandoAcao(null)} />

      {campoMulti && (
        <SelecaoModal aberto={selecaoAberta} titulo={vision.title}
          itens={opcoesSelecao}
          selecionados={rows.map(r => Number(r[campoMulti.vf.column])).filter(Boolean)}
          onSalvar={salvarSelecao} onFechar={() => setSelecaoAberta(false)} />
      )}
    </>
  )
}

/* ---------- formatação de células ---------- */

function formatarCelula(def: ColumnDef, vf: VisionColumnDef, row: Row,
                        domains: Record<string, { value: string; label: string; color?: string | null }[]>) {
  const v = row[vf.column]
  if (v === null || v === undefined || v === '') return <span className="text-muted">—</span>
  switch (def.type) {
    case 'BOOLEAN':
      return v ? '✓' : <span className="text-muted">—</span>
    case 'DOMAIN': {
      const item = (domains[def.domain ?? ''] ?? []).find(d => d.value === String(v))
      const cor = item?.color ? ` badge--${item.color}` : ''
      return <span className={`badge${cor}`}>{item?.label ?? String(v)}</span>
    }
    case 'ENTITY':
      return row[`${vf.column}__label`] ?? `#${v}`
    case 'DATE':
      return formatarData(String(v).slice(0, 10))
    case 'DATETIME': {
      const s = String(v).replace('T', ' ')
      return `${formatarData(s.slice(0, 10))} ${s.slice(11, 16)}`
    }
    default:
      return String(v)
  }
}

/* No mobile o registro vira uma linha: rótulo + detalhes no .list-sub + badge à direita */
function subtituloLinha(colunas: VisionColumnDef[], fields: Record<string, ColumnDef>, row: Row,
                        domains: Record<string, any>) {
  return colunas
    .filter(c => fields[c.column].type !== 'DOMAIN')
    .map(c => {
      const v = row[c.column]
      if (v === null || v === undefined || v === '' || typeof v === 'boolean') return null
      if (fields[c.column].type === 'ENTITY') return row[`${c.column}__label`] ?? null
      if (fields[c.column].type === 'DATE') return formatarData(String(v).slice(0, 10))
      return String(v)
    })
    .filter(Boolean)
    .slice(1, 4) // o primeiro já é o rótulo da linha
    .join(' · ')
}

function badgeLinha(colunas: VisionColumnDef[], fields: Record<string, ColumnDef>, row: Row,
                    domains: Record<string, { value: string; label: string; color?: string | null }[]>) {
  const c = colunas.find(c => fields[c.column].type === 'DOMAIN' && row[c.column])
  if (!c) return null
  const def = fields[c.column]
  const item = (domains[def.domain ?? ''] ?? []).find(d => d.value === String(row[c.column]))
  return <span className={`badge${item?.color ? ` badge--${item.color}` : ''}`}>{item?.label ?? row[c.column]}</span>
}
