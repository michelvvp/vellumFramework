# Vellum — Framework Metadata-Driven

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

Login inicial: **admin / admin** (criado no primeiro boot junto com o grupo e o
estabelecimento "Administrador"; senha em `ADMIN_PASSWORD`). Variáveis:
`MYSQL_HOST/PORT/DATABASE/USER/PASSWORD`, `SERVER_PORT`, `AUTH_TOKEN_SECRET`.

## Modelo de acesso

Multi-estabelecimento: `group` 1:N `establishment`. Quem entra é uma `person`;
`person_establishment` diz **onde** ela pode entrar (uma unidade entra direto,
várias abrem a escolha no login) e `person_profile` diz **o que** ela pode
fazer. `function` é o catálogo global de códigos de permissão; o
estabelecimento habilita um subconjunto (`function_establishment`) e cada
`profile` libera um subconjunto disso (`function_profile`) — o efetivo é a
**interseção** das duas. A pessoa soma as funções de todos os perfis dela no
estabelecimento ativo; não há troca de perfil na interface.

Mexer em `function_establishment` ou `function_profile` deve subir o
`nr_permission_version` do estabelecimento: o token carrega a versão, e o que
foi emitido antes é recusado — a mudança de permissão vale na hora.

**Estabelecimento é o escopo do dado.** Toda tabela de negócio leva
`nr_seq_establishment`, o CRUD genérico filtra por ele sozinho e carimba o
valor da sessão na criação (nunca o do payload). As tabelas do próprio Vellum
são marcadas com `ie_system` e ficam de fora — o boot recusa uma tabela de
negócio sem a coluna.

## Como criar um sistema novo (só cadastro)

O seed de dogfooding entrega o grupo **Framework** no menu — o dicionário é
editado pelas próprias telas do framework:

1. **Migration** — crie a tabela física do negócio (PK `nr_sequence`, FK
   `nr_seq_establishment`; convenções `ds_`, `nm_`, `ie_`, `vl_`, `dt_`, `qt_`,
   `cd_`, FK `nr_seq_<tabela>`). O DDL ainda vem de migration; o boot valida
   dicionário × schema e falha com relatório se divergirem.
2. **Domínios** — enums cadastráveis (valor, rótulo, cor de badge).
3. **Tabelas** — registre a entidade e suas **Colunas** (tipo, obrigatória,
   única, tamanho, faixa, regex, default, fórmula para campo calculado), mais
   **Índices** e **Constraints**.
4. **Visões** — a tela: GRID, MASTER_DETAIL (visão-filha com `Coluna FK do
   pai`), DASHBOARD (com **Widgets**) ou CUSTOM (componente React registrado).
   Sem `Campos da visão` cadastrados, todas as colunas entram com defaults.
5. **Restrições** — `FILTER` (segurança de dados com `:person_id`,
   `:person_record`, `:establishment_id`, `:parent_id`, `:hoje`, `:agora`),
   `PERMISSION` (por função/operação) e `VALIDATION` (expressões como
   `reps_max >= reps_min`).
6. **Funções e perfis** — crie a `function` da tela nova, habilite no
   estabelecimento e libere no perfil.
7. **Configurações** — `app.name` + as 4 variáveis de tema do design system
   (`theme.accent`, `theme.accentHover`, `theme.accentTint`, `theme.onAccent`).
8. **Recarregar dicionário** (botão na sidebar) — a tela nova está no ar.

## Pontos de extensão (código, não tela)

- **`handler`** (tabela do dicionário) + `Handler` (bean Java cujo nome é o
  `nm_bean`): `ACTION` (botão em visão), `HOOK` (before/after
  create/update/delete), `AUTH` (autorização por vínculo), `ENDPOINT` (API pura
  — ex.: o motor do integrator).
- **Telas CUSTOM**: `register('nome', Componente)` em
  `frontend/src/custom/index.ts`; o componente recebe `{ vision, meta, data,
  user, params }` e compõe o catálogo (`src/ui.tsx`) — CSS nunca, HTML mínimo.

## Design system

`frontend/src/design-system.css` é **cópia literal** do canônico
(`~/Projects/design-system`) — não edite; atualize copiando de novo. Extras
estruturais do shell ficam em `frontend/src/theme.css`. O accent vem do
cadastro (`app_config`) e é injetado em runtime.

## Segurança

Toda operação de dados leva a visão de contexto (`?_vision=`), inclusive os
combos de FK (`/api/lookup`): filtros, permissões, escopo por estabelecimento e
validações são **sempre reaplicados no backend** — o JSON do front é cortesia
de UX, nunca autoridade. Auth por token HMAC stateless carregando pessoa +
estabelecimento + versão de permissão (BCrypt + bloqueio progressivo de login).

Palavras reservadas: `table`, `column`, `index`, `constraint` e `group` são
reservadas no MySQL. O runtime referencia toda tabela entre crases — SQL escrito
à mão precisa fazer o mesmo.
