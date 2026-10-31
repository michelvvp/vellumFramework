import { useEffect, useRef } from 'react'
import { noBody } from './noBody'
import { useIsMobile } from './useIsMobile'

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
