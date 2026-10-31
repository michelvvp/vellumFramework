/* Catálogo público de componentes do framework — evolução tipada do catálogo
   do gym. É o único lugar do front com conhecimento das classes do design
   system; os contratos de teclado/foco/toque do DS moram aqui. */
export { ToastProvider, useToast } from './Toast'
export { useIsMobile } from './useIsMobile'
export { useBarraRetratil } from './useBarraRetratil'
export { ConfirmModal } from './ConfirmModal'
export { SelecaoModal } from './SelecaoModal'
export { Popup, type PopupOption } from './Popup'
export { DatePicker } from './DatePicker'
export { DragHandle } from './DragHandle'
export { useArrastarOrdem } from './useArrastarOrdem'
export { SwipeRow } from './SwipeRow'
export { ActionButton, useAction } from './ActionButton'
export { NavegacaoContext, useNavegacao, type Navegacao } from './navegacao'
export { formatarData, iniciais } from './format'
