import type { ComponentType } from 'react'
import type { DataClient } from './api'
import type { Meta, VisionDef } from './types'

/*
 * ComponentRegistry — o escape hatch de primeira classe (seção 3.5/6 da
 * especificação). Telas CUSTOM são componentes React registrados por nome e
 * referenciados em vision.nm_component: recebem menu, permissão e tema do
 * framework de graça e compõem o catálogo (ui.tsx) — nunca CSS novo.
 *
 *   register('treinar', TreinarPage)
 */
export interface CustomProps {
  vision: VisionDef
  meta: Meta
  data: DataClient
  user: Meta['user']
  params: Record<string, any>
}

const registry = new Map<string, ComponentType<CustomProps>>()

export function register(name: string, component: ComponentType<CustomProps>) {
  registry.set(name, component)
}

export function resolve(name?: string): ComponentType<CustomProps> | undefined {
  return name ? registry.get(name) : undefined
}
