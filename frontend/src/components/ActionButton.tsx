import { useCallback, useEffect, useRef, useState } from 'react'
import { data } from '../api'
import { useMeta } from '../meta'
import FieldInput from '../visions/FieldInput'
import type { PopupOption } from './Popup'
import { ConfirmModal } from './ConfirmModal'
import { noBody } from './noBody'
import { useNavegacao } from './navegacao'
import { useToast } from './Toast'
import { useIsMobile } from './useIsMobile'
import type { ActionDef, ActionParamDef, ActionResult, Row } from '../types'

interface Contexto {
  visionKey: string
  recordId?: number
  params?: Row
}

/*
 * Lógica única de execução de ação (POST /api/function/{name}): toast de
 * sucesso/erro e efeito do ActionResult. Telas CUSTOM usam este hook quando
 * precisam disparar uma ação sem o botão. Em erro, avisa com a mensagem do
 * backend e relança (o chamador pode ler err.errors, por campo).
 * Devolve o resultado, ou null se o efeito foi RELOAD/ausente (use onReload).
 */
export function useAction() {
  const toast = useToast()
  const { abrirVisao } = useNavegacao()

  return useCallback(async (acao: ActionDef, ctx: Contexto): Promise<ActionResult> => {
    let res: ActionResult
    try {
      const corpo = await data.execute(acao.name, ctx)
      // handler que devolve outro objeto (ou nada) é tratado como RELOAD
      res = corpo && typeof corpo === 'object' ? corpo : { ok: true }
    } catch (e: any) {
      toast(e.message, 'danger')
      throw e
    }
    toast(res.message || acao.successMsg || 'Feito')
    const efeito = res.effect ?? 'RELOAD'
    if (efeito === 'OPEN_VISION' && res.vision) abrirVisao(res.vision, res.recordId)
    else if (efeito === 'OPEN_URL' && res.url) window.open(res.url, '_blank', 'noopener')
    else if (efeito === 'DOWNLOAD' && res.contentBase64) baixar(res)
    return { ...res, effect: efeito }
  }, [toast, abrirVisao])
}

function baixar(res: ActionResult) {
  const bin = atob(res.contentBase64!)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
  const url = URL.createObjectURL(new Blob([bytes], { type: res.mime || 'application/octet-stream' }))
  const a = document.createElement('a')
  a.href = url
  a.download = res.filename || 'arquivo'
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}

/*
 * Botão de ação padronizado: confirmação (se `confirm`), modal de parâmetros
 * (se `params`), loading, toasts e efeito do retorno. `onDone('reload')` avisa
 * a tela para recarregar os dados. `onBusy` informa quando há diálogo/chamada
 * em curso (o menu de contexto da grade usa isso para não desmontar o botão).
 */
export function ActionButton({ action, visionKey, recordId, onDone, onBusy, variant = 'secondary' }: {
  action: ActionDef
  visionKey: string
  recordId?: number
  onDone?: (efeito: 'reload') => void
  onBusy?: (ocupado: boolean) => void
  variant?: 'secondary' | 'primary' | 'ghost' | 'menu'
}) {
  const executar = useAction()
  const { meta } = useMeta()
  const mobile = useIsMobile()
  const params = action.params ?? []
  const rotulo = action.label ?? action.name

  const [confirmando, setConfirmando] = useState(false)
  const [modal, setModal] = useState(false)
  const [executando, setExecutando] = useState(false)
  const [values, setValues] = useState<Row>({})
  const [erros, setErros] = useState<Record<string, string>>({})
  const [erroGeral, setErroGeral] = useState('')
  const [opcoes, setOpcoes] = useState<Record<string, PopupOption[]>>({})
  const dialogo = useRef<HTMLDivElement>(null)

  const ocupado = confirmando || modal || executando
  const ocupadoAntes = useRef(false)
  useEffect(() => {
    if (ocupadoAntes.current !== ocupado) onBusy?.(ocupado) // só mudanças, não a montagem
    ocupadoAntes.current = ocupado
  }, [ocupado]) // eslint-disable-line react-hooks/exhaustive-deps

  // opções dos parâmetros ENTITY (mesmo lookup dos campos de formulário)
  useEffect(() => {
    if (!modal) return
    for (const p of params) {
      if (p.type !== 'ENTITY' || !p.refTable) continue
      data.lookup(p.refTable, visionKey)
        .then(rows => setOpcoes(prev => ({
          ...prev, [p.name]: rows.map(r => ({ value: String(r.id), label: r.label || `#${r.id}` })),
        })))
        .catch(() => setOpcoes(prev => ({ ...prev, [p.name]: [] })))
    }
  }, [modal]) // eslint-disable-line react-hooks/exhaustive-deps

  function iniciar() {
    if (action.confirm) setConfirmando(true)
    else seguir()
  }

  function seguir() {
    if (params.length) {
      const inicial: Row = {}
      for (const p of params) inicial[p.name] = valorInicial(p)
      setValues(inicial); setErros({}); setErroGeral(''); setModal(true)
      requestAnimationFrame(() => dialogo.current?.focus())
    } else {
      rodar()
    }
  }

  async function rodar(payload?: Row) {
    setExecutando(true); setErros({}); setErroGeral('')
    try {
      await executar(action, { visionKey, recordId, params: payload })
      setModal(false)
      onDone?.('reload')
    } catch (err: any) {
      if (err.errors?.length) {
        const porCampo: Record<string, string> = {}
        const gerais: string[] = []
        for (const fe of err.errors) {
          if (fe.field && params.some(p => p.name === fe.field)) porCampo[fe.field] = fe.message
          else gerais.push(fe.message)
        }
        setErros(porCampo)
        setErroGeral(gerais.join('; '))
      } else {
        setErroGeral(err.message)
      }
    } finally {
      setExecutando(false)
    }
  }

  function enviar(e: React.FormEvent) {
    e.preventDefault()
    const payload: Row = {}
    for (const p of params) {
      let v = values[p.name]
      if (p.type === 'ENTITY' && v !== null && v !== undefined && v !== '') v = Number(v)
      payload[p.name] = v === undefined ? null : v
    }
    rodar(payload)
  }

  function set(nome: string, v: any) {
    setValues(prev => ({ ...prev, [nome]: v }))
    setErros(prev => {
      if (!prev[nome]) return prev
      const novo = { ...prev }
      delete novo[nome]
      return novo
    })
  }

  const fechar = () => { if (!executando) setModal(false) }

  const botao = variant === 'menu'
    ? (
      <button className="menu-item" type="button" role="menuitem" disabled={executando} onClick={iniciar}>
        <span className="menu-check">⚡</span>{rotulo}
      </button>
    )
    : (
      <button className={variant === 'primary' ? 'btn' : `btn btn--${variant}`} type="button"
        disabled={executando} aria-busy={executando} onClick={iniciar}>
        {executando && !modal && <span className="spinner" role="status" aria-label="Executando"></span>} {rotulo}
      </button>
    )

  return (
    <>
      {botao}
      <ConfirmModal aberto={confirmando} titulo={`${rotulo}?`}
        texto="Confirma executar esta ação?" confirmar="Executar"
        onConfirmar={() => { setConfirmando(false); seguir() }}
        onCancelar={() => setConfirmando(false)} />
      {noBody(
        <div className={`modal-overlay${mobile ? ' modal-overlay--sheet' : ''}`} hidden={!modal} onClick={fechar}
          onKeyDown={e => { if (e.key === 'Escape') { e.stopPropagation(); fechar() } }}>
          <div className={`modal${mobile ? ' modal--sheet' : ''}`} role="dialog" aria-modal="true"
            aria-label={rotulo} tabIndex={-1} ref={dialogo} onClick={e => e.stopPropagation()}>
            {mobile && <div className="sheet-grabber"></div>}
            <h3>{rotulo}</h3>
            {erroGeral && (
              <div className="alert alert--danger" style={{ marginTop: 'var(--space-md)' }}>
                <div><span className="alert-title">Não foi possível executar</span><p>{erroGeral}</p></div>
              </div>
            )}
            {modal && (
              <form className="stack" style={{ gap: 'var(--space-md)', marginTop: 'var(--space-md)' }} onSubmit={enviar}>
                {params.map(p => (
                  <FieldInput key={p.name}
                    vf={{ column: p.name, label: p.label, grid: false, form: true }}
                    def={p} value={values[p.name] ?? null} onChange={v => set(p.name, v)}
                    error={erros[p.name]} entityOptions={opcoes[p.name]} disabled={executando} />
                ))}
                <div className="row" style={{ justifyContent: 'flex-end' }}>
                  <button className="btn btn--ghost" type="button" disabled={executando} onClick={fechar}>Cancelar</button>
                  <button className="btn" type="submit" disabled={executando}>
                    {executando ? 'Executando…' : 'Executar'}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>,
      )}
    </>
  )
}

function valorInicial(p: ActionParamDef): any {
  if (p.default === undefined || p.default === null || p.default === '') return null
  if (p.type === 'INTEGER' || p.type === 'DECIMAL') return Number(p.default)
  if (p.type === 'BOOLEAN') return p.default === 'true' || p.default === '1'
  return p.default
}
