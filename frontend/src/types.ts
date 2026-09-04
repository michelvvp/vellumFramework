/* Tipos do JSON de definição (GET /api/meta) — contrato da seção 4 da especificação. */

export type Row = Record<string, any>

export interface DomainValue {
  value: string
  label: string
  color?: string | null
}

export interface FieldDef {
  type: string
  label: string
  domain?: string
  refTable?: string
  required?: boolean
  unique?: boolean
  size?: number
  scale?: number
  min?: string
  max?: string
  default?: string
  hint?: string
  computed?: boolean
}

export interface TableDef {
  label: string
  labelPlural: string
  labelFields?: string[]
  fields: Record<string, FieldDef>
}

export interface VisionFieldDef {
  field: string
  label: string
  component?: string
  grid: boolean
  form: boolean
  readOnly?: boolean
  filter?: boolean
  orderGrid?: number
  orderForm?: number
  width?: number
  format?: string
  refFilterField?: string
}

export interface ActionDef {
  name: string
  label?: string
  placement?: 'ROW' | 'HEADER'
  confirm?: boolean
  successMsg?: string
}

export interface WidgetDef {
  id: number
  title: string
  type: 'VALUE' | 'CHART_LINE' | 'CHART_BAR' | 'LIST'
  usePeriod?: boolean
}

export interface ValidationDef {
  field?: string
  expression?: string
  message?: string
}

export interface VisionDef {
  key: string
  title: string
  table?: string
  type: 'GRID' | 'MASTER_DETAIL' | 'DASHBOARD' | 'CUSTOM'
  parent?: string
  parentFkField?: string
  component?: string
  icon?: string
  iconColor?: string
  menuGroup?: string
  order?: number
  readOnly?: boolean
  allow: { create: boolean; update: boolean; delete: boolean }
  fields: VisionFieldDef[]
  children: string[]
  actions: ActionDef[]
  widgets: WidgetDef[]
  validations: ValidationDef[]
}

export interface Meta {
  version: string
  app: {
    name: string
    theme: { accent: string; accentHover: string; accentTint: string; onAccent: string }
  }
  domains: Record<string, DomainValue[]>
  tables: Record<string, TableDef>
  visions: VisionDef[]
  menuGroups: { label: string; order: number }[]
  user: { id: number; name: string; login: string; roles: string[] }
}
