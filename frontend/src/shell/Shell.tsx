import { useMemo, useState } from 'react'
import { useAuth } from '../auth'
import { api } from '../api'
import { useMeta } from '../meta'
import { icone } from '../icons'
import { iniciais, NavegacaoContext, useBarraRetratil, useToast } from '../components'
import VisionRenderer from '../visions/VisionRenderer'
import type { Row, VisionDef } from '../types'

/*
 * Casca do app: .window + .sidebar geradas do metadado (sidebar_group > sidebar_item > vision),
 * tabbar no mobile e stack de navegação pai → filho (MASTER_DETAIL, modelo do
 * integrator). Nenhuma tela é escrita à mão aqui — o menu é o cadastro.
 */
interface StackEntry {
  key: string
  parentId?: number
  crumb: string
  recordId?: number
}

export default function Shell() {
  const { meta, refresh } = useMeta()
  const { auth, logout, pode } = useAuth()
  const toast = useToast()

  /* O backend já entrega grupo > item > visões filtrado e ordenado; aqui só
     resolve as chaves para VisionDef e descarta o que não existir no payload. */
  const menu = useMemo(() => {
    const porChave = new Map(meta.visions.map(v => [v.key, v]))
    return meta.sidebarGroups
      .map(g => ({
        label: g.label,
        collapsible: g.collapsible,
        items: g.items
          .map(i => ({ ...i, vs: i.visions.map(k => porChave.get(k)).filter((v): v is VisionDef => !!v) }))
          .filter(i => i.vs.length > 0),
      }))
      .filter(g => g.items.length > 0)
  }, [meta])

  type ItemMenu = (typeof menu)[number]['items'][number]
  const primeira = menu[0]?.items[0]?.vs[0]?.key

  const barraCompacta = useBarraRetratil()

  /* Grupo recolhível e item com várias visões nascem fechados; só o que contém a
     tela aberta no boot começa aberto, senão o item ativo ficaria escondido. */
  const [abertos, setAbertos] = useState<Record<string, boolean>>(() => {
    const g = menu.find(x => x.collapsible && x.items.some(i => i.vs.some(v => v.key === primeira)))
    return g ? { [`g:${g.label}`]: true } : {}
  })
  const [itemEscolha, setItemEscolha] = useState<ItemMenu | null>(null)
  const [stack, setStack] = useState<StackEntry[]>(() =>
    primeira ? [{ key: primeira, crumb: '' }] : [])

  const atual = stack[stack.length - 1]
  const visaoAtual = meta.visions.find(v => v.key === atual?.key)

  function irRaiz(key: string) {
    const v = meta.visions.find(x => x.key === key)!
    setStack([{ key, crumb: v.title }])
  }

  /* OPEN_VISION de uma ação: vai para a visão como raiz e, com recordId,
     abre o registro dela no formulário. */
  function abrirVisao(key: string, recordId?: number) {
    const v = meta.visions.find(x => x.key === key)
    if (!v) { toast(`Visão "${key}" não disponível para o seu papel`, 'warning'); return }
    setStack([{ key, crumb: v.title, recordId }])
  }

  function abrirFilho(childKey: string, parentRow: Row, parentVision: VisionDef) {
    const filho = meta.visions.find(v => v.key === childKey)
    if (!filho) return
    const tabela = parentVision.table ? meta.tables[parentVision.table] : undefined
    const rotulo = (tabela?.labelFields ?? [])
      .map(lf => parentRow[lf])
      .filter(x => x !== null && x !== undefined && x !== '')
      .join(' · ') || `#${parentRow.nr_sequence}`
    setStack(s => [...s, { key: childKey, parentId: parentRow.nr_sequence, crumb: `${filho.title} · ${rotulo}` }])
  }

  function voltarPara(i: number) {
    setStack(s => s.slice(0, i + 1))
  }

  async function recarregarDicionario() {
    try {
      await api.post('/meta/reload')
      await refresh()
      toast('Dicionário recarregado')
    } catch (e: any) {
      toast(e.message, 'danger')
    }
  }

  const ehAdmin = pode('DICTIONARY_EDIT')
  const itensTabbar = menu.flatMap(g => g.items).slice(0, 4)
  const raizAtiva = stack[0]?.key

  function clicarItemTabbar(i: ItemMenu) {
    if (i.vs.length === 1) irRaiz(i.vs[0].key)
    else setItemEscolha(i)
  }

  return (
    <NavegacaoContext.Provider value={{ abrirVisao }}>
    <div className="window app-window">
      <aside className="sidebar">
        <div className="identity">
          <span className="avatar">{iniciais(auth?.user.name)}</span>
          <span className="identity-name">
            {auth?.user.name}
            <span className="identity-sub">{meta.app.name}</span>
          </span>
        </div>

        {menu.map(grupo => {
          const chaveGrupo = `g:${grupo.label}`
          const aberto = !grupo.collapsible || !!abertos[chaveGrupo]
          return (
          <div key={chaveGrupo} style={{ display: 'contents' }}>
            {grupo.label && (grupo.collapsible ? (
              <button type="button" aria-expanded={aberto}
                className={`sidebar-heading sidebar-heading--toggle${aberto ? ' is-open' : ''}`}
                onClick={() => setAbertos(a => ({ ...a, [chaveGrupo]: !aberto }))}>
                {grupo.label}
                <svg className="sidebar-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                  strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="m6 9 6 6 6-6" />
                </svg>
              </button>
            ) : <p className="sidebar-heading">{grupo.label}</p>)}
            {aberto && grupo.items.map(item => {
              const tile = (
                <span className="sidebar-icon" style={{ background: item.iconColor || 'var(--accent)' }}>
                  {icone(item.icon)}
                </span>
              )
              if (item.vs.length === 1) {
                const v = item.vs[0]
                return (
                  <button key={item.id} type="button"
                    className={`sidebar-item${raizAtiva === v.key ? ' is-active' : ''}`}
                    onClick={() => irRaiz(v.key)}>
                    {tile}
                    {item.label}
                  </button>
                )
              }
              const chaveItem = `i:${item.id}`
              const contemAtiva = item.vs.some(v => v.key === raizAtiva)
              const itemAberto = contemAtiva || !!abertos[chaveItem]
              return (
                <div key={item.id} style={{ display: 'contents' }}>
                  <button type="button" aria-expanded={itemAberto}
                    className={`sidebar-item sidebar-item--toggle${itemAberto ? ' is-open' : ''}`}
                    onClick={() => setAbertos(a => ({ ...a, [chaveItem]: !itemAberto }))}>
                    {tile}
                    {item.label}
                    <svg className="sidebar-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                      strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </button>
                  {itemAberto && item.vs.map(v => (
                    <button key={v.key} type="button"
                      className={`sidebar-item sidebar-item--sub${raizAtiva === v.key ? ' is-active' : ''}`}
                      onClick={() => irRaiz(v.key)}>
                      {v.title}
                    </button>
                  ))}
                </div>
              )
            })}
          </div>
          )
        })}

        <div className="sidebar-footer stack" style={{ gap: 'var(--space-xs)' }}>
          {ehAdmin && (
            <button className="btn btn--muted" type="button" style={{ width: '100%' }}
              onClick={recarregarDicionario}>
              Recarregar dicionário
            </button>
          )}
          <button className="btn btn--ghost" type="button" style={{ width: '100%' }} onClick={logout}>
            Sair
          </button>
        </div>
      </aside>

      <div className="window-content">
        {stack.length > 1 && (
          <nav className="breadcrumb" aria-label="Caminho">
            {stack.map((entry, i) => (
              <span key={i} style={{ display: 'contents' }}>
                {i > 0 && <span className="sep">/</span>}
                <button className="crumb" type="button"
                  aria-current={i === stack.length - 1 ? 'page' : undefined}
                  onClick={() => i < stack.length - 1 && voltarPara(i)}>
                  {entry.crumb || meta.visions.find(v => v.key === entry.key)?.title}
                </button>
              </span>
            ))}
          </nav>
        )}

        {visaoAtual ? (
          <VisionRenderer key={atual.key + (atual.parentId ?? '') + (atual.recordId ?? '')}
            vision={visaoAtual} parentId={atual.parentId} abrirId={atual.recordId}
            onOpenChild={(childKey, row) => abrirFilho(childKey, row, visaoAtual)} />
        ) : (
          <p className="text-muted">Nenhuma visão cadastrada para o seu papel ainda.</p>
        )}
      </div>

      <nav className={`tabbar tabbar--mobile${barraCompacta ? ' is-compacta' : ''}`} aria-label="Navegação principal">
        {itensTabbar.map(i => (
          <button key={i.id} type="button"
            className={`tabbar-item${i.vs.some(v => v.key === raizAtiva) ? ' is-active' : ''}`}
            aria-haspopup={i.vs.length > 1 ? 'dialog' : undefined}
            onClick={() => clicarItemTabbar(i)}>
            {icone(i.icon)}
            {i.label}
          </button>
        ))}
        <button className="tabbar-item" type="button" onClick={logout}>
          {icone('dot')}
          Sair
        </button>
      </nav>

      <div className="modal-overlay modal-overlay--sheet" hidden={!itemEscolha}
        onClick={() => setItemEscolha(null)}
        onKeyDown={e => { if (e.key === 'Escape') setItemEscolha(null) }}>
        <div className="modal modal--sheet" role="dialog" aria-modal="true" aria-label={itemEscolha?.label}
          onClick={e => e.stopPropagation()}>
          <div className="sheet-grabber"></div>
          <h3>{itemEscolha?.label}</h3>
          <div className="stack" style={{ gap: 'var(--space-xs)' }}>
            {itemEscolha?.vs.map(v => (
              <button key={v.key} type="button"
                className={`btn ${raizAtiva === v.key ? '' : 'btn--ghost'}`}
                style={{ width: '100%' }}
                onClick={() => { irRaiz(v.key); setItemEscolha(null) }}>
                {v.title}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
    </NavegacaoContext.Provider>
  )
}
