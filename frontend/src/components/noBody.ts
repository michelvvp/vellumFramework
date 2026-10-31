import type { ReactNode } from 'react'
import { createPortal } from 'react-dom'

/* Modal sempre no body: .card tem backdrop-filter e vira o bloco de contenção
   do overlay fixed — aberto de dentro de um card, o modal ficaria preso na
   caixa do card em vez de cobrir a janela. */
export function noBody(overlay: ReactNode) {
  return createPortal(overlay, document.body)
}
