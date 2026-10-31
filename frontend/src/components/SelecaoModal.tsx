import { useEffect, useRef, useState } from 'react'
import { noBody } from './noBody'

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
