import GridVision from './GridVision'
import DashboardVision from './DashboardVision'
import CustomVision from './CustomVision'
import type { Row, VisionDef } from '../types'

/* Decide o arquétipo pela vision.ie_type (seção 3.5 da especificação). */
export default function VisionRenderer({ vision, parentId, onOpenChild }: {
  vision: VisionDef
  parentId?: number
  onOpenChild: (childKey: string, row: Row) => void
}) {
  switch (vision.type) {
    case 'DASHBOARD':
      return <DashboardVision vision={vision} />
    case 'CUSTOM':
      return <CustomVision vision={vision} parentId={parentId} />
    default: // GRID e MASTER_DETAIL compartilham a listagem; o pai abre filhos
      return <GridVision vision={vision} parentId={parentId} onOpenChild={onOpenChild} />
  }
}
