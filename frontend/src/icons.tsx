import type { ReactNode } from 'react'

/* Glifos SVG dos tiles da sidebar (stroke currentColor, branco sobre o tile
   colorido — contrato do design system). O nome cadastrado em vision.nm_icon
   escolhe o glifo; nome desconhecido cai no ponto. */

const stroke = { fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' } as const

export const ICONS: Record<string, ReactNode> = {
  list: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01" /></svg>
  ),
  table: (
    <svg viewBox="0 0 24 24" {...stroke}><rect x="3" y="4" width="18" height="16" rx="2" /><path d="M3 10h18M9 10v10" /></svg>
  ),
  screen: (
    <svg viewBox="0 0 24 24" {...stroke}><rect x="3" y="4" width="18" height="14" rx="2" /><path d="M8 21h8M12 18v3" /></svg>
  ),
  function: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="m8 6-5 6 5 6M16 6l5 6-5 6" /></svg>
  ),
  menu: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="M4 7h16M4 12h16M4 17h10" /></svg>
  ),
  users: (
    <svg viewBox="0 0 24 24" {...stroke}><circle cx="9" cy="8" r="3.5" /><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6" /><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8M17.5 14.6c2 .8 3.5 2.9 3.5 5.4" /></svg>
  ),
  shield: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="M12 3 5 6v5c0 4.5 3 8.2 7 10 4-1.8 7-5.5 7-10V6l-7-3Z" /><path d="m9 12 2 2 4-4" /></svg>
  ),
  settings: (
    <svg viewBox="0 0 24 24" {...stroke}><circle cx="12" cy="12" r="3" /><path d="M19 12c0-.6.5-1.2.4-1.8l1.4-1.6-2-3.4-2 .6c-.5-.3-1.1-.7-1.7-.9L14.5 3h-5l-.6 1.9c-.6.2-1.2.6-1.7.9l-2-.6-2 3.4L4.6 10c-.1.6.4 1.4.4 2s-.5 1.4-.4 2l-1.4 1.6 2 3.4 2-.6c.5.3 1.1.7 1.7.9L9.5 21h5l.6-1.9c.6-.2 1.2-.6 1.7-.9l2 .6 2-3.4-1.4-1.6c.1-.6-.4-1.2-.4-1.8Z" /></svg>
  ),
  tag: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="M3 12V4h8l10 10-8 8L3 12Z" /><circle cx="8" cy="9" r="1.5" /></svg>
  ),
  chart: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="M4 19V5" /><path d="M4 19h16" /><path d="m7 14 3.5-4 3 2.5L18 7" /></svg>
  ),
  folder: (
    <svg viewBox="0 0 24 24" {...stroke}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7Z" /></svg>
  ),
  dot: (
    <svg viewBox="0 0 24 24" {...stroke}><circle cx="12" cy="12" r="3" /></svg>
  ),
}

export function icone(nome?: string): ReactNode {
  return ICONS[nome || ''] ?? ICONS.dot
}
