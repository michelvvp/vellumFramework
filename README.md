# Framework Metadata-Driven

Sistemas de cadastro **sem escrever telas**: o modelo de dados, as visões e as
regras são cadastrados em tabelas de metadados; o backend publica um JSON de
definição (`/api/meta`) e o front genérico (React + Design System Liquid Glass)
renderiza tudo a partir dele. Especificação completa em `ESPECIFICACAO.md`.

## Subir

```bash
# backend (porta 8081; cria o banco `framework` no MySQL local)
cd backend && mvn -DskipTests package && java -jar target/framework-backend-0.0.1-SNAPSHOT.jar

# frontend (porta 5174, proxy /api → 8081)
cd frontend && npm install && npm run dev
```

Login inicial: **admin / admin** (criado no primeiro boot; senha em
`ADMIN_PASSWORD`). Variáveis: `MYSQL_HOST/PORT/DATABASE/USER/PASSWORD`,
`SERVER_PORT`, `AUTH_TOKEN_SECRET`.

## Como criar um sistema novo (só cadastro)

O seed de dogfooding entrega o grupo **Framework** no menu — o dicionário é
editado pelas próprias telas do framework:

1. **Migration** — crie a tabela física do negócio (PK `nr_sequence`;
   convenções `ds_`, `nm_`, `ie_`, `vl_`, `dt_`, `qt_`, `cd_`, FK
   `nr_seq_<tabela>`). Na v1 o DDL vem de migration; o boot valida dicionário ×
   schema e falha com relatório se divergirem.
2. **Domínios** — enums cadastráveis (valor, rótulo, cor de badge).
3. **Tabelas** — registre a entidade e seus **Campos** (tipo, obrigatório,
   único, tamanho, faixa, regex, default, fórmula para campo calculado).
4. **Visões** — a tela: GRID, MASTER_DETAIL (visão-filha com `Campo FK do pai`),
   DASHBOARD (com **Widgets**) ou CUSTOM (componente React registrado).
   Sem `Campos da visão` cadastrados, todos os campos entram com defaults.
5. **Restrições** — `FILTER` (segurança de dados com `:usuario_id`,
   `:usuario_record`, `:parent_id`, `:hoje`, `:agora`), `PERMISSION` (por
   papel/operação) e `VALIDATION` (expressões como `reps_max >= reps_min`).
6. **Configurações** — `app.name` + as 4 variáveis de tema do design system
   (`theme.accent`, `theme.accentHover`, `theme.accentTint`, `theme.onAccent`).
7. **Recarregar dicionário** (botão na sidebar) — a tela nova está no ar.

## Pontos de extensão (código, não tela)

- **`function`** (tabela do dicionário) + `FunctionHandler` (bean Java cujo
  nome é o `nm_handler`): `ACTION` (botão em visão), `HOOK`
  (before/after create/update/delete), `AUTH` (autorização por vínculo),
  `ENDPOINT` (API pura — ex.: o motor do integrator).
- **Telas CUSTOM**: `register('nome', Componente)` em
  `frontend/src/custom/index.ts`; o componente recebe `{ vision, meta, data,
  user, params }` e compõe o catálogo (`src/ui.tsx`) — CSS nunca, HTML mínimo.

## Design system

`frontend/src/design-system.css` é **cópia literal** do canônico
(`~/Projects/design-system`) — não edite; atualize copiando de novo. Extras
estruturais do shell ficam em `frontend/src/theme.css`. O accent vem do
cadastro (`app_config`) e é injetado em runtime.

## Segurança

Toda operação de dados leva a visão de contexto (`?_vision=`): filtros,
permissões e validações são **sempre reaplicados no backend** — o JSON do
front é cortesia de UX, nunca autoridade. Auth por token HMAC stateless
(BCrypt + bloqueio progressivo de login).
