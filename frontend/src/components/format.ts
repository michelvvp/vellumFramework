export const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
export const DOW = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']

export function ymd(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export function formatarData(iso: string) {
  const [a, m, d] = iso.split('-')
  return `${d}/${m}/${a}`
}

/* ---------- Avatar com iniciais ---------- */

export function iniciais(nome: string | undefined) {
  return (nome || '?')
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map(p => p[0])
    .join('')
    .toUpperCase()
}
