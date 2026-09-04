import { data } from '../api'
import { useMeta } from '../meta'
import { resolve } from '../registry'
import type { VisionDef } from '../types'

/* Tela CUSTOM: componente registrado por nome no ComponentRegistry, vivendo
   dentro do shell (menu, permissão e tema vêm do framework de graça). */
export default function CustomVision({ vision, parentId }: { vision: VisionDef; parentId?: number }) {
  const { meta } = useMeta()
  const Component = resolve(vision.component)

  if (!Component) {
    return (
      <div className="alert alert--warning">
        <div>
          <span className="alert-title">Componente não registrado</span>
          <p>A visão "{vision.title}" aponta para o componente "{vision.component}", que ainda não
            foi registrado no front (src/custom/index.ts).</p>
        </div>
      </div>
    )
  }

  return <Component vision={vision} meta={meta} data={data} user={meta.user}
    params={{ parentId }} />
}
