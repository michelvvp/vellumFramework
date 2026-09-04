import { useEffect, useState } from 'react'
import {
  Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts'
import { data } from '../api'
import { DatePicker, formatarData } from '../ui'
import type { VisionDef } from '../types'

/*
 * Dashboard cadastrável (dashboard_widget): .grid-cards com .card.widget e
 * gráficos. Cores só dos tokens do design system, nunca hex solto.
 */
const CORES = ['var(--accent)', 'var(--success)', 'var(--warning)', 'var(--danger)']

interface WidgetData {
  id: number
  title: string
  type: string
  data: any
  series?: string[]
}

export default function DashboardVision({ vision }: { vision: VisionDef }) {
  const [widgets, setWidgets] = useState<WidgetData[] | null>(null)
  const [erro, setErro] = useState('')
  const [de, setDe] = useState('')
  const [ate, setAte] = useState('')
  const temPeriodo = vision.widgets.some(w => w.usePeriod)

  useEffect(() => {
    setErro('')
    data.dashboard(vision.key, de || undefined, ate || undefined)
      .then(r => setWidgets(r.widgets))
      .catch(e => setErro(e.message))
  }, [vision.key, de, ate])

  return (
    <>
      <div className="content-header">
        <h1>{vision.title}</h1>
        {temPeriodo && (
          <div className="row" style={{ gap: 'var(--space-sm)' }}>
            <DatePicker value={de} onChange={setDe} placeholder="De" ariaLabel="Período: início" />
            <DatePicker value={ate} onChange={setAte} placeholder="Até" ariaLabel="Período: fim" />
          </div>
        )}
      </div>

      {erro && (
        <div className="alert alert--danger" style={{ marginBottom: 'var(--space-md)' }}>
          <div><span className="alert-title">Erro ao carregar</span><p>{erro}</p></div>
        </div>
      )}

      {!widgets ? (
        <div className="grid-cards">
          {[0, 1, 2].map(i => (
            <div className="card widget" key={i}>
              <span className="skeleton skeleton--text" style={{ width: '50%' }}></span>
              <span className="skeleton skeleton--text" style={{ width: '30%', height: 32 }}></span>
            </div>
          ))}
        </div>
      ) : (
        <div className="grid-cards">
          {widgets.map(w => <Widget key={w.id} w={w} />)}
          {widgets.length === 0 && <p className="text-muted">Nenhum widget cadastrado.</p>}
        </div>
      )}
    </>
  )
}

function Widget({ w }: { w: WidgetData }) {
  switch (w.type) {
    case 'VALUE':
      return (
        <div className="card widget">
          <span className="widget-label">{w.title}</span>
          <p className="widget-value">{formatarNumero(w.data)}</p>
        </div>
      )
    case 'CHART_LINE':
    case 'CHART_BAR': {
      const linhas: any[] = w.data ?? []
      const series = w.series ?? []
      return (
        <div className="card widget-chart">
          <span className="widget-label">{w.title}</span>
          <div className="chart-box">
            <ResponsiveContainer width="100%" height="100%">
              {w.type === 'CHART_LINE' ? (
                <LineChart data={linhas}>
                  <CartesianGrid stroke="var(--glass-border)" vertical={false} />
                  <XAxis dataKey="x" tick={{ fill: 'var(--muted)', fontSize: 12 }} tickFormatter={eixoX}
                    stroke="var(--glass-border)" />
                  <YAxis tick={{ fill: 'var(--muted)', fontSize: 12 }} stroke="var(--glass-border)" width={44} />
                  <Tooltip contentStyle={tooltipStyle} labelFormatter={eixoX} />
                  {series.map((s, i) => (
                    <Line key={s} type="monotone" dataKey={s} stroke={CORES[i % CORES.length]}
                      strokeWidth={2} dot={false} />
                  ))}
                </LineChart>
              ) : (
                <BarChart data={linhas}>
                  <CartesianGrid stroke="var(--glass-border)" vertical={false} />
                  <XAxis dataKey="x" tick={{ fill: 'var(--muted)', fontSize: 12 }} tickFormatter={eixoX}
                    stroke="var(--glass-border)" />
                  <YAxis tick={{ fill: 'var(--muted)', fontSize: 12 }} stroke="var(--glass-border)" width={44} />
                  <Tooltip contentStyle={tooltipStyle} labelFormatter={eixoX} cursor={{ fill: 'var(--glass-fill)' }} />
                  {series.map((s, i) => (
                    <Bar key={s} dataKey={s} fill={CORES[i % CORES.length]} radius={[6, 6, 0, 0]} />
                  ))}
                </BarChart>
              )}
            </ResponsiveContainer>
          </div>
        </div>
      )
    }
    case 'LIST': {
      const itens: any[] = w.data ?? []
      return (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <p className="list-header" style={{ padding: 'var(--space-md) var(--space-md) 0' }}>{w.title}</p>
          <div className="list-group" style={{ border: 0, borderRadius: 0 }}>
            {itens.map(item => (
              <div className="list-row" key={item.id}>
                <span className="list-label">{item.label}
                  {item.x && <span className="list-sub">{eixoX(String(item.x))}</span>}
                </span>
              </div>
            ))}
            {itens.length === 0 && (
              <div className="list-row"><span className="list-label text-muted">Nada por aqui.</span></div>
            )}
          </div>
        </div>
      )
    }
    default:
      return null
  }
}

const tooltipStyle = {
  background: 'var(--glass-strong)',
  border: '1px solid var(--glass-border)',
  borderRadius: 12,
  color: 'var(--text)',
}

function formatarNumero(v: any): string {
  if (v === null || v === undefined) return '—'
  const n = Number(v)
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString('pt-BR', { maximumFractionDigits: 2 })
}

function eixoX(v: string): string {
  const s = String(v)
  if (/^\d{4}-\d{2}-\d{2}/.test(s)) return formatarData(s.slice(0, 10))
  if (/^\d{4}-\d{2}$/.test(s)) return `${s.slice(5, 7)}/${s.slice(0, 4)}`
  return s
}
