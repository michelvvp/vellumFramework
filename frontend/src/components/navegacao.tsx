import { createContext, useContext } from 'react'

/* Navegação do shell exposta aos componentes: o efeito OPEN_VISION de uma
   ação usa isto para abrir outra visão (e, opcionalmente, um registro dela). */
export interface Navegacao {
  abrirVisao: (visionKey: string, recordId?: number) => void
}

export const NavegacaoContext = createContext<Navegacao>({ abrirVisao: () => {} })

export function useNavegacao() {
  return useContext(NavegacaoContext)
}
