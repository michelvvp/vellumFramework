import { useMemo, useState } from 'react'
import { useAuth } from '../auth'
import { api } from '../api'
import { useMeta } from '../meta'
import { icone } from '../icons'
import { iniciais, useToast } from '../ui'
import VisionRenderer from '../visions/VisionRenderer'
import type { Row, VisionDef } from '../types'

/*
 * Casca do app: .window + .sidebar geradas do metadado (menu_group + vision),
 * tabbar no mobile e stack de navegação pai → filho (MASTER_DETAIL, modelo do
 * integrator). Nenhuma tela é escrita à mão aqui — o menu é o cadastro.
 */
interface StackEntry {
  key: string
  parentId?: number
  crumb: string
}

export default function Shell() {
  const { meta, refresh } = useMeta()
  const { auth, logout } = useAuth()
  const toast = useToast()

  const menu = useMemo(() => {
    const raizes = meta.visions.filter(v => v.order !== undefined && v.order !== null && !v.parent)
    const grupos = new Map<string, VisionDef[]>()
    for (const v of raizes) {
      const g = v.menuGroup ?? ''
      if (!grupos.has(g)) grupos.set(g, [])
      grupos.get(g)!.push(v)
    }
    // ordem dos grupos vem de menu_group; visões sem grupo primeiro
    const ordenados: { label: string; visions: VisionDef[] }[] = []
    if (grupos.has('')) ordenados.push({ label: '', visions: grupos.get('')! })
    for (const g of meta.menuGroups) {
      if (grupos.has(g.label)) ordenados.push({ label: g.label, visions: grupos.get(g.label)! })
    }
    return ordenados
  }, [meta])

  const primeira = menu[0]?.visions[0]?.key
  const [stack, setStack] = useState<StackEntry[]>(() =>
    primeira ? [{ key: primeira, crumb: '' }] : [])

  const atual = stack[stack.length - 1]
  const visaoAtual = meta.visions.find(v => v.key === atual?.key)

  function irRaiz(key: string) {
    const v = meta.visions.find(x => x.key === key)!
    setStack([{ key, crumb: v.title }])
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

  const ehAdmin = auth?.user.roles.includes('ADMIN')
  const itensTabbar = menu.flatMap(g => g.visions).slice(0, 4)

  return (
    <div className="window app-window">
      <aside className="sidebar">
        <div className="identity">
          <span className="avatar">{iniciais(auth?.user.name)}</span>
          <span className="identity-name">
            {auth?.user.name}
            <span className="identity-sub">{meta.app.name}</span>
          </span>
        </div>

        {menu.map(grupo => (
          <div key={grupo.label || '_'} style={{ display: 'contents' }}>
            {grupo.label && <p className="sidebar-heading">{grupo.label}</p>}
            {grupo.visions.map(v => (
              <button key={v.key} type="button"
                className={`sidebar-item${stack[0]?.key === v.key ? ' is-active' : ''}`}
                onClick={() => irRaiz(v.key)}>
                <span className="sidebar-icon" style={{ background: v.iconColor || 'var(--accent)' }}>
                  {icone(v.icon)}
                </span>
                {v.title}
              </button>
            ))}
          </div>
        ))}

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
          <VisionRenderer key={atual.key + (atual.parentId ?? '')}
            vision={visaoAtual} parentId={atual.parentId}
            onOpenChild={(childKey, row) => abrirFilho(childKey, row, visaoAtual)} />
        ) : (
          <p className="text-muted">Nenhuma visão cadastrada para o seu papel ainda.</p>
        )}
      </div>

      <nav className="tabbar tabbar--mobile" aria-label="Navegação principal">
        {itensTabbar.map(v => (
          <button key={v.key} type="button"
            className={`tabbar-item${stack[0]?.key === v.key ? ' is-active' : ''}`}
            onClick={() => irRaiz(v.key)}>
            {icone(v.icon)}
            {v.title}
          </button>
        ))}
        <button className="tabbar-item" type="button" onClick={logout}>
          {icone('dot')}
          Sair
        </button>
      </nav>
    </div>
  )
}
