# Framework Metadata-Driven de Front-end — Especificação

> Framework para construir sistemas de cadastro **sem escrever telas**: o modelo de dados,
> as visões e as regras são **cadastrados em tabelas de metadados**; o backend, ao subir,
> publica um **JSON de definição** e o front-end genérico (React + Design System Liquid Glass)
> renderiza tudo a partir dele.
>
> Casos de prova: reconstruir o **integrator** e o **gym** usando apenas cadastros
> (mais os pontos de extensão descritos na seção 12).

---

## 1. Conceito e princípios

**Ideia central:** uma tela de cadastro não é código, é dado. O que hoje é um
`Exercicios.jsx` (gym) ou uma entrada no `config.ts` (integrator) vira linhas nas tabelas
`tables`, `table_field`, `vision`, `vision_field` e `vision_restriction`.

**Princípios:**

1. **Metadado é a fonte da verdade.** Entidades, campos, telas, filtros, validações e
   permissões vivem no banco, no *dicionário de dados* do framework.
2. **Um runtime, N sistemas.** O mesmo backend genérico + front genérico rodam o gym, o
   integrator ou qualquer sistema novo — muda só o conteúdo do dicionário e o tema
   (4 variáveis de accent).
3. **Interpretação, não geração de código.** O JSON é interpretado em runtime pelo front.
   Não há scaffolding/codegen a manter sincronizado (mesmo modelo que o motor do
   integrator já usa para montar requests).
4. **Design System como contrato de renderização.** Cada componente do catálogo do front
   mapeia 1:1 para as classes do `design-system.css` (conforme `AGENTS.md` do
   design-system). O framework nunca inventa CSS novo; extras de app vão num `theme.css`.
5. **Escape hatch de primeira classe.** Nem tudo é CRUD (ex.: telas Treinar/Correr do gym,
   dashboards). Telas custom são **componentes registrados por nome** e referenciados no
   metadado — a navegação, permissão e tema continuam vindos do framework.
6. **Convenções de nomenclatura** (herdadas do integrator): PK `nr_sequence`;
   FK `nr_seq_<tabela>`; prefixos `ds_` (descrição), `nm_` (nome), `ie_` (indicador/domínio),
   `vl_` (valor), `dt_` (data), `qt_` (quantidade), `cd_` (código).

---

## 2. Arquitetura

```
┌──────────────────────────── BACKEND (Spring Boot + MySQL) ───────────────────────────┐
│                                                                                      │
│  Dicionário (metadados)          Runtime genérico                                    │
│  ┌─────────────────────┐         ┌──────────────────────────────────────────┐        │
│  │ domain              │  boot   │ MetadataLoader  → valida e monta o JSON  │        │
│  │ domain_value        │ ──────► │ GET /api/meta   → publica definição      │        │
│  │ tables              │         │ /api/data/{table} → CRUD genérico        │        │
│  │ table_field         │         │ ValidationEngine  (regras declarativas)  │        │
│  │ vision              │         │ RestrictionEngine (filtros + permissões) │        │
│  │ vision_field        │         │ FunctionRegistry  (ações custom em Java) │        │
│  │ vision_restriction  │         │ AuthService (login, token, papéis)       │        │
│  │ function            │         └──────────────────────────────────────────┘        │
│  │ (+ seção 3.9)       │                                                             │
│  └─────────────────────┘         Tabelas de negócio (pessoa, partner, treino, ...)   │
└──────────────────────────────────────────────────────────────────────────────────────┘
                        │  GET /api/meta  (JSON de definição, seção 4)
                        ▼
┌──────────────────────────── FRONTEND (React + Vite) ─────────────────────────────────┐
│  design-system.css (cópia literal do canônico)  +  theme.css (4 vars de accent)      │
│                                                                                      │
│  MetaProvider (carrega/cacheia o /api/meta)                                          │
│  Shell: .window + .sidebar (menu vindo do metadado) + tabbar mobile                  │
│  VisionRenderer: decide o arquétipo pela vision.ie_type                              │
│    ├── GRID        → tabela desktop / list-group+swipe mobile, filtros, ações        │
│    ├── FORM        → formulário modal (criar/editar) a partir de vision_field        │
│    ├── MASTER_DETAIL → grid pai + navegação em stack/menu de contexto p/ filhos      │
│    ├── DASHBOARD   → grid-cards de widgets + gráficos                                │
│    └── CUSTOM      → componente React registrado por nome (ComponentRegistry)        │
│  Catálogo de componentes (1:1 com o DS): Input, Popup, Switch, DatePicker,           │
│    SelecaoModal, ConfirmModal, Toast, SwipeRow, DragHandle, Badge, ...               │
│  DataClient genérico: list/get/create/update/delete/execute sobre /api/data e        │
│    /api/function                                                                     │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**Fluxo no boot do backend:**

1. Lê o dicionário completo do banco.
2. Valida consistência (FKs de metadado, domínios existentes, campos órfãos, ciclos).
3. Monta o **JSON de definição** (seção 4), calcula um hash de versão e mantém em memória
   (cache; endpoint `POST /api/meta/reload` para recarregar sem reiniciar).
4. Expõe o CRUD genérico: qualquer tabela cadastrada em `tables` ganha automaticamente
   `GET/POST/PUT/DELETE /api/data/{nm_table}` — elimina os 16 controllers repetidos do
   integrator.

**Fluxo no front:** carrega `/api/meta` uma vez (revalida pelo hash), monta menu e rotas,
e renderiza cada visão sob demanda. Nenhuma tela é escrita à mão além das CUSTOM.

---

## 3. Modelo de metadados (dicionário)

Todas as tabelas do dicionário têm `nr_sequence` (PK auto), `ie_active` (boolean, default
true) e `dt_created`. Abaixo, só os campos específicos.

### 3.1 `domain` — domínios de valores (enums cadastráveis)

Substitui os enums hardcoded (`grupo_muscular` do gym, `authType`/`bodyType` do integrator).

| Campo       | Tipo         | Descrição                                    |
|-------------|--------------|----------------------------------------------|
| `nm_domain` | varchar(60)  | Nome único, ex.: `GRUPO_MUSCULAR`, `HTTP_METHOD` |
| `ds_domain` | varchar(255) | Descrição para o administrador               |

### 3.2 `domain_value` — valores de um domínio

| Campo           | Tipo         | Descrição                                        |
|-----------------|--------------|--------------------------------------------------|
| `nr_seq_domain` | FK → domain  |                                                  |
| `vl_value`      | varchar(60)  | Valor persistido no dado (ex.: `PEITO`)          |
| `ds_label`      | varchar(120) | Rótulo exibido (ex.: "Peito")                    |
| `nr_order`      | int          | Ordem no select                                  |
| `ds_color`      | varchar(20)  | Opcional: token semântico p/ badge (`accent`, `success`, `warning`, `danger`) |

Único por (`nr_seq_domain`, `vl_value`).

### 3.3 `tables` — entidades do sistema

| Campo            | Tipo         | Descrição                                                  |
|------------------|--------------|-------------------------------------------------------------|
| `nm_table`       | varchar(60)  | Nome físico único (ex.: `exercicio`, `partner`)             |
| `ds_table`       | varchar(120) | Rótulo singular ("Exercício")                               |
| `ds_table_plural`| varchar(120) | Rótulo plural ("Exercícios")                                |
| `nm_label_field` | varchar(60)  | Campo(s) usados como rótulo do registro em combos/FKs (CSV, ex.: `nome` ou `ds_partner`) |
| `ie_audit`       | boolean      | Se true, runtime mantém `dt_created`/`dt_updated`/usuário   |
| `ie_logical_delete` | boolean   | Exclusão lógica (`ie_active=false`) em vez de DELETE físico |

> **DDL:** na v1 as tabelas de negócio continuam criadas por migration (Flyway, como no
> gym). O framework **valida** no boot que cada `tables`/`table_field` bate com o schema
> real e falha com relatório claro se divergir. Geração de DDL a partir do metadado é
> evolução futura (seção 13).

### 3.4 `table_field` — campos de uma entidade

| Campo               | Tipo          | Descrição                                                        |
|---------------------|---------------|-------------------------------------------------------------------|
| `nr_seq_table`      | FK → tables   |                                                                   |
| `nm_field`          | varchar(60)   | Nome físico da coluna                                             |
| `ds_label`          | varchar(120)  | Rótulo padrão (visões podem sobrescrever)                         |
| `ie_type`           | domínio `FIELD_TYPE` | `STRING`, `TEXT`, `INTEGER`, `DECIMAL`, `BOOLEAN`, `DATE`, `DATETIME`, `TIME`, `DOMAIN`, `ENTITY`, `PASSWORD`, `JSON` |
| `nr_seq_domain`     | FK → domain   | Obrigatório quando `ie_type = DOMAIN`                             |
| `nr_seq_table_ref`  | FK → tables   | Obrigatório quando `ie_type = ENTITY` (FK para outra entidade)    |
| `ie_required`       | boolean       | Validação NOT NULL (backend + front)                              |
| `ie_unique`         | boolean       | Unicidade (validada pelo runtime antes do insert/update)          |
| `qt_size`           | int           | Tamanho máx. (string) / precisão                                  |
| `qt_scale`          | int           | Casas decimais (DECIMAL)                                          |
| `vl_min` / `vl_max` | varchar(30)   | Faixa numérica ou data mínima/máxima                              |
| `ds_regex`          | varchar(255)  | Validação por expressão regular (ex.: CPF)                        |
| `vl_default`        | varchar(255)  | Valor default na criação                                          |
| `ds_hint`           | varchar(255)  | Texto de ajuda (`.field-hint`)                                    |
| `ds_formula`        | varchar(255)  | **Campo calculado** (não persistido, read-only): expressão sobre campos da própria linha, ex.: `duracao_seg / (distancia_m / 1000)` (pace). Disponível em grids, filtros e widgets |
| `nr_order`          | int           | Ordem natural dos campos                                          |

Relações **N:N** (academia×equipamento no gym) são modeladas como uma entidade de ligação
em `tables` (ex.: `academia_equipamento` com dois campos `ENTITY`) — a visão decide
apresentá-la como `MULTI_SELECT` (seção 3.6).

Hierarquias (auto-relação `nr_seq_parent` dos params do integrator) são só um campo
`ENTITY` apontando para a própria tabela.

### 3.5 `vision` — visões (telas) do sistema

Uma `vision` é uma tela ligada a uma tabela. Uma mesma tabela pode ter várias visões
(ex.: "Pessoas" para o admin e "Meus Atletas" para o treinador, com restrições diferentes).

| Campo             | Tipo          | Descrição                                                       |
|-------------------|---------------|------------------------------------------------------------------|
| `nm_vision`       | varchar(60)   | Chave única (ex.: `exercicios`, `partner_logs`)                  |
| `ds_title`        | varchar(120)  | Título da tela (`.content-header h1`)                            |
| `nr_seq_table`    | FK → tables   | Entidade base (null permitido para `DASHBOARD`/`CUSTOM`)         |
| `ie_type`         | domínio `VISION_TYPE` | `GRID`, `MASTER_DETAIL`, `DASHBOARD`, `CUSTOM`           |
| `nr_seq_vision_parent` | FK → vision | Se preenchida, é visão-filha: abre a partir do pai            |
| `nm_parent_fk_field`   | varchar(60) | Campo desta tabela que guarda a FK do registro pai (ex.: `nr_seq_partner`) — preenchido automaticamente ao criar filho |
| `ie_read_only`    | boolean       | Sem criar/editar/excluir (ex.: Logs do integrator)               |
| `ie_allow_create` / `ie_allow_update` / `ie_allow_delete` | boolean | Granularidade fina  |
| `nm_component`    | varchar(120)  | Só para `CUSTOM`: nome do componente React registrado            |
| `nm_icon`         | varchar(60)   | Ícone do menu (`.sidebar-icon`)                                  |
| `ds_icon_color`   | varchar(20)   | Cor do tile do ícone                                             |
| `nr_seq_menu_group` | FK → menu_group | Agrupamento na sidebar (seção 3.9)                          |
| `nr_order`        | int           | Ordem no menu (null = não aparece no menu, só como filha)        |

**Arquétipos de renderização** (mapeiam os dois arquétipos do design-system):

- `GRID` / `MASTER_DETAIL` → `.window` + `.sidebar` + `.window-content`; listagem em
  `.table` (desktop) / `.list-group` + swipe (mobile); form em `.modal` (desktop) /
  `.modal--sheet` (mobile).
- `DASHBOARD` → `.grid-cards` com `.card.widget` e gráficos (seção 3.6, componentes
  `CHART_*`).
- `CUSTOM` → componente livre dentro do shell.

### 3.6 `vision_field` — campos de uma visão

Liga a visão aos campos da tabela e define **como** cada um aparece.

| Campo                | Tipo               | Descrição                                                  |
|----------------------|--------------------|-------------------------------------------------------------|
| `nr_seq_vision`      | FK → vision        |                                                             |
| `nr_seq_table_field` | FK → table_field   |                                                             |
| `ds_label`           | varchar(120)       | Sobrescreve o rótulo padrão (opcional)                      |
| `ie_component`       | domínio `COMPONENT`| Widget a usar (ver catálogo abaixo); null = default do tipo |
| `ie_show_in_grid`    | boolean            | Aparece como coluna da listagem                             |
| `ie_show_in_form`    | boolean            | Aparece no formulário                                       |
| `ie_read_only`       | boolean            | Exibe mas não edita                                         |
| `ie_filter`          | boolean            | Vira filtro no header da listagem                           |
| `nr_order_grid` / `nr_order_form` | int   | Ordenação independente                                      |
| `qt_width`           | int                | Largura relativa na grid (opcional)                         |
| `ds_format`          | varchar(60)        | Máscara/formato (ex.: `dd/MM/yyyy`, `#.##0,00`, `pace`)     |
| `nm_ref_filter_field`| varchar(60)        | Para `ENTITY`: filtra as opções do combo pelo valor de outro campo do form (padrão `refFilterParam`/`refFilterSelf` do integrator) |

**Catálogo de componentes** (domínio `COMPONENT`) e mapeamento para o design-system:

| Componente       | Default para tipo | Classes do DS                                        |
|------------------|-------------------|------------------------------------------------------|
| `INPUT`          | STRING/INTEGER/DECIMAL | `.field` + `.label` + `.input` (+ `.field-hint`/`.field-error`) |
| `TEXTAREA`       | TEXT              | `.input` multiline                                   |
| `PASSWORD`       | PASSWORD          | `.input type=password`                               |
| `SWITCH`         | BOOLEAN           | `.switch` + `.switch-track`                          |
| `CHECKBOX`       | —                 | `.checkbox`                                          |
| `POPUP`          | DOMAIN/ENTITY     | `.popup` + `.menu` (contrato de teclado do DS)       |
| `SEGMENTED`      | DOMAIN (≤4 valores)| `.segmented`                                        |
| `RADIO`          | —                 | `.radio`                                             |
| `DATE_PICKER`    | DATE              | popup + `.mini-cal`                                  |
| `DATETIME_PICKER`| DATETIME          | idem + hora                                          |
| `SLIDER`         | —                 | `.slider` (usa `vl_min`/`vl_max`)                    |
| `MULTI_SELECT`   | — (N:N)           | `SelecaoModal` (lista de switches)                   |
| `BADGE`          | — (grid)          | `.badge` com cor do `domain_value.ds_color`          |
| `AVATAR`         | — (grid)          | `.avatar` com iniciais                               |
| `DRAG_ORDER`     | — (grid)          | `DragHandle` + persistência `PUT /api/data/{t}/ordem`|
| `CHART_LINE` / `CHART_BAR` / `WIDGET_VALUE` | — (dashboard) | `recharts` com `stroke="var(--accent)"` etc. |

### 3.7 `vision_restriction` — restrições da visão

Uma tabela, três naturezas de restrição, discriminadas por `ie_restriction_type`
(domínio `RESTRICTION_TYPE`):

| Campo                 | Tipo         | Descrição                                             |
|-----------------------|--------------|--------------------------------------------------------|
| `nr_seq_vision`       | FK → vision  |                                                        |
| `ie_restriction_type` | domínio      | `FILTER`, `PERMISSION`, `VALIDATION`                   |
| `nm_field`            | varchar(60)  | Campo alvo (quando aplicável)                          |
| `ie_operator`         | domínio `OPERATOR` | `EQ`, `NE`, `GT`, `GE`, `LT`, `LE`, `IN`, `LIKE`, `BETWEEN`, `IS_NULL`, `NOT_NULL` |
| `vl_value`            | varchar(255) | Valor literal **ou variável de contexto**              |
| `nm_role`             | varchar(60)  | Papel exigido (para `PERMISSION`)                      |
| `ie_operation`        | domínio      | `READ`, `CREATE`, `UPDATE`, `DELETE`, `ALL`            |
| `ds_message`          | varchar(255) | Mensagem de erro (para `VALIDATION`)                   |
| `ds_expression`       | varchar(500) | Expressão para validações compostas (ex.: `reps_max >= reps_min`) |

**Variáveis de contexto** resolvidas pelo backend em runtime (nunca confiadas ao front):
`:usuario_id`, `:usuario_papeis`, `:hoje`, `:agora`, `:parent_id`.

Exemplos:
- *Logs só do parceiro selecionado* → `FILTER`, `nm_field=nr_seq_partner`, `EQ`, `:parent_id`.
- *Atleta só vê as próprias sessões* → `FILTER`, `nm_field=pessoa_id`, `EQ`, `:usuario_id`
  (aplicado no SQL do CRUD genérico, é segurança de dados, não cosmética).
- *Só admin exclui academias* → `PERMISSION`, `ie_operation=DELETE`, `nm_role=ADMIN`.
- *reps_max ≥ reps_min* → `VALIDATION` com `ds_expression` e `ds_message`.

Permissões complexas por vínculo (o `RelacionamentoService.exigirAcesso` do gym) não são
expressáveis em linhas — usam uma `function` de autorização plugável (seção 3.8),
referenciada por `PERMISSION` com `vl_value = nome_da_function`.

### 3.8 `function` — funções e ações

Registra comportos que vão além do CRUD: ações de tela, endpoints custom, hooks e jobs.

| Campo             | Tipo          | Descrição                                                     |
|-------------------|---------------|----------------------------------------------------------------|
| `nm_function`     | varchar(60)   | Chave única (ex.: `integrar`, `desbloquear_login`)             |
| `ds_label`        | varchar(120)  | Rótulo do botão/ação                                           |
| `ie_function_type`| domínio `FUNCTION_TYPE` | `ACTION` (botão em visão), `HOOK` (before/after create/update/delete), `AUTH` (autorização custom), `JOB` (agendada), `ENDPOINT` (API pura, ex.: `/integrate`) |
| `nr_seq_vision`   | FK → vision   | Onde aparece (para `ACTION`) — em linha ou no header           |
| `ie_placement`    | domínio       | `ROW` (menu de contexto/linha) ou `HEADER`                     |
| `nm_handler`      | varchar(120)  | Nome do bean/handler Java registrado no `FunctionRegistry`     |
| `ie_confirm`      | boolean       | Exige `ConfirmModal` antes de executar                         |
| `ds_success_msg`  | varchar(255)  | Toast de sucesso                                               |
| `nm_role`         | varchar(60)   | Papel mínimo para executar                                     |

O front chama `POST /api/function/{nm_function}` com `{ visionKey, recordId?, params? }`.
A implementação é **código Java registrado** (interface `FunctionHandler`) — o metadado
diz *onde e quando*, o código diz *o quê*. É aqui que vivem o motor do integrator
(`ENDPOINT integrar`) e regras como o bloqueio progressivo de login do gym (`HOOK`).

### 3.9 Tabelas complementares (necessárias, além das 8 pedidas)

Sem estas o framework não fecha os dois casos de prova:

- **`menu_group`** — agrupadores da sidebar (`ds_label`, `nr_order`). A sidebar do shell é
  gerada de `menu_group` + `vision`.
- **`app_user`** — usuário do sistema (`nm_user`, `cd_login` [CPF no gym], `ds_password_hash`,
  `ie_active`, campos de bloqueio progressivo). Pode apontar para uma tabela de negócio
  (`nr_seq_table_ref` + `nr_seq_record`, ex.: a `pessoa` do gym).
- **`role`** e **`user_role`** — papéis (`ADMIN`, `TREINADOR`, `ATLETA`...) e vínculo N:N.
  Os `nm_role` de `vision_restriction`/`function` referenciam `role.nm_role`.
- **`app_config`** — chave/valor do sistema: nome do app, as **4 variáveis de tema**
  (`--accent`, `--accent-hover`, `--accent-tint`, `--on-accent`), logo, título. O front
  aplica o tema a partir do `/api/meta` — trocar a identidade do sistema é um cadastro.

### 3.10 `dashboard_widget` — widgets de uma visão DASHBOARD

Torna dashboards **cadastráveis** (caso Histórico do gym), em vez de sempre custom.
Cada linha é um widget dentro de uma `vision` de tipo `DASHBOARD`.

| Campo              | Tipo          | Descrição                                                        |
|--------------------|---------------|-------------------------------------------------------------------|
| `nr_seq_vision`    | FK → vision   | Dashboard dono (`ie_type = DASHBOARD`)                            |
| `ds_title`         | varchar(120)  | Título do widget (`.widget-label`)                                |
| `ie_widget_type`   | domínio `WIDGET_TYPE` | `VALUE` (número + badge), `CHART_LINE`, `CHART_BAR`, `LIST` (últimos N registros) |
| `nr_seq_table`     | FK → tables   | Fonte de dados                                                    |
| `nm_field_x`       | varchar(60)   | Eixo X (tipicamente um campo data)                                |
| `nm_fields_y`      | varchar(255)  | Série(s) do eixo Y, CSV — aceita campos calculados (`ds_formula`) |
| `ie_aggregation`   | domínio       | `SUM`, `AVG`, `MAX`, `MIN`, `COUNT`, `NONE`                       |
| `ie_group_by`      | domínio       | `DAY`, `WEEK`, `MONTH`, `FIELD`, `NONE`                           |
| `nm_group_field`   | varchar(60)   | Campo de agrupamento quando `FIELD`                               |
| `ie_use_period`    | boolean       | Respeita o filtro de período do dashboard (dois `DATE_PICKER` no header) |
| `qt_limit`         | int           | Limite de registros (para `LIST`)                                 |
| `nr_order`         | int           | Posição no `.grid-cards`                                          |

O dashboard herda as `vision_restriction` de tipo `FILTER` (ex.: `pessoa_id = :usuario_id`),
então "Histórico do atleta" é o mesmo dashboard para todos, filtrado por contexto. Cores e
formatação vêm dos tokens do DS (`var(--accent)`, `var(--warning)`), nunca cadastradas como
hex solto.

---

## 4. Contrato do JSON de definição (`GET /api/meta`)

Gerado no boot, versionado por hash. Esqueleto:

```jsonc
{
  "version": "a1b2c3",                    // hash do dicionário — front cacheia por ele
  "app": {
    "name": "Gym Tracker",
    "theme": { "accent": "#ff6a00", "accentHover": "#ff8a33",
               "accentTint": "rgba(255,106,0,.18)", "onAccent": "#000" }
  },
  "domains": {
    "GRUPO_MUSCULAR": [ { "value": "PEITO", "label": "Peito", "color": null }, ... ]
  },
  "tables": {
    "exercicio": {
      "label": "Exercício", "labelPlural": "Exercícios", "labelField": "nome",
      "fields": {
        "nome":           { "type": "STRING",  "label": "Nome", "required": true, "unique": true, "size": 100 },
        "grupo_muscular": { "type": "DOMAIN",  "domain": "GRUPO_MUSCULAR", "required": true },
        "descricao":      { "type": "TEXT",    "size": 500 },
        "ativo":          { "type": "BOOLEAN", "default": true }
      }
    }
  },
  "visions": [
    {
      "key": "exercicios", "title": "Exercícios", "table": "exercicio",
      "type": "GRID", "icon": "dumbbell", "iconColor": "#ff6a00",
      "menuGroup": "Treinador", "order": 2,
      "allow": { "create": true, "update": true, "delete": true },
      "fields": [
        { "field": "nome", "grid": true, "form": true, "orderGrid": 1, "orderForm": 1 },
        { "field": "grupo_muscular", "component": "POPUP", "grid": true, "form": true, "filter": true,
          "gridComponent": "BADGE" }
      ],
      "children": [],                     // visões-filhas (MASTER_DETAIL)
      "actions": [],                      // functions ACTION desta visão
      "restrictions": { "filters": [...], "validations": [...] }   // permissões ficam só no backend
    }
  ],
  "user": { "id": 1, "name": "Michel", "roles": ["ADMIN", "TREINADOR"] }  // via /api/me
}
```

Observações:
- **Permissões são aplicadas no backend** (o CRUD genérico injeta os `FILTER` no SQL e
  checa `PERMISSION` em cada operação). O JSON leva apenas o suficiente para a UI esconder
  botões — nunca é a barreira de segurança.
- O front só conhece visões que o usuário pode `READ` — o `/api/meta` já vem filtrado por
  papel.

---

## 5. Backend runtime

- **CRUD genérico:** `GET/POST/PUT/DELETE /api/data/{nm_table}` (+ `GET /{id}`,
  `PUT /{nm_table}/ordem` para reordenação). Implementação única sobre JDBC/JPA dinâmico,
  usando o metadado para montar SELECTs (com filtros de restrição e query params
  `?campo=valor`), validar payloads (required/unique/min/max/regex/expression) e resolver
  FKs (payload `{ "exercicio_id": 5 }`).
- **Validação em camadas:** o front pré-valida (UX), o backend revalida sempre
  (autoridade). Erros retornam estruturados: `{ field, code, message }[]` — o front
  distribui em `.field-error` por campo.
- **Auth:** token Bearer próprio (modelo do gym: BCrypt + bloqueio progressivo), filtro em
  `/api/**` exceto `/login` e `/meta` público reduzido. `GET /api/me` devolve usuário+papéis.
- **Auditoria:** `ie_audit` liga `dt_created`/`dt_updated`/`nm_user_created` automáticos.
- **Boot fail-fast:** dicionário inconsistente (campo sem coluna física, domínio faltando,
  ciclo de visões) derruba o boot com relatório legível.

## 6. Frontend runtime

- **Stack:** React 18 + Vite + TypeScript. `design-system.css` **cópia literal do
  canônico** (regra já vigente no gym); tema do app aplicado em runtime a partir de
  `app.theme` do JSON (injeção das 4 variáveis num `<style>`); extras estruturais do shell
  num `theme.css` próprio do framework.
- **Shell:** `.window` + `.sidebar` gerada de `menu_group`/`vision` (ícones em
  `.sidebar-icon`), identidade do usuário (`.identity` + `.avatar`), `.tabbar--mobile`
  ≤640px, breadcrumb + stack de navegação para `MASTER_DETAIL` (modelo do integrator).
- **VisionRenderer:** um componente por arquétipo. O GRID reusa os padrões consolidados do
  gym: tabela desktop / `.list-group` + `SwipeRow` mobile, form modal criar/editar,
  exclusão em 2 etapas com `ConfirmModal`, filtros no `.content-header`, toasts,
  `.skeleton` no loading.
- **Catálogo de componentes:** biblioteca única (evolução do `ui.jsx` do gym) com os
  contratos de acessibilidade do DS (teclado no Popup, foco no Modal, alvos 44px,
  `prefers-reduced-*`). É o único lugar com conhecimento das classes CSS.
- **ComponentRegistry:** `register('treinar', TreinarPage)` — telas `CUSTOM` recebem
  `{ meta, dataClient, user, params }` e vivem dentro do shell (menu/permissão/tema de graça).

---

## 7. Casos de prova

### 7.1 Integrator (aderência ~100% por cadastro)

| Hoje                                  | No framework                                             |
|---------------------------------------|----------------------------------------------------------|
| `config.ts` com 13 telas              | 13 linhas em `vision` + `vision_field`                   |
| 16 controllers CRUD idênticos         | CRUD genérico `/api/data/{table}`                        |
| 5 enums Java + `/api/enums`           | `domain` + `domain_value`                                |
| Pai→filho (`listParam`+`parentFkField`)| `MASTER_DETAIL` (`nr_seq_vision_parent` + `nm_parent_fk_field`) |
| Tela de Logs read-only com filtros    | `vision` `ie_read_only` + `vision_field.ie_filter` (data BETWEEN) |
| Combos FK filtrados (`refFilterParam`) | `vision_field.nm_ref_filter_field`                      |
| Motor `/integrate`                    | `function` tipo `ENDPOINT` (`nm_handler` → serviços atuais do motor, intactos) |
| Sem validação/permissão               | Ganha de graça `VALIDATION`/`PERMISSION`                 |

### 7.2 Gym (aderência ~90% por cadastro + 2 telas em TS)

**Por cadastro (zero código):** Login (nativo do `app_user`, incl. bloqueio progressivo);
Exercícios, Academias, Equipamentos, Pessoas (GRID); Fichas → Dias → Prescrições e
Planos → Treinos → Intervalos (`MASTER_DETAIL` de 3 níveis); N:N academia×equipamento
(`MULTI_SELECT`); reordenação (`DRAG_ORDER`); enums viram domínios; posse do atleta vira
`FILTER :usuario_id`; papéis viram `role` + `PERMISSION`; **Histórico vira `DASHBOARD`
cadastrado** via `dashboard_widget` (pace e volume como campos calculados `ds_formula`,
km/semana como `CHART_BAR` com `ie_group_by = WEEK`); convite por CPF → `function ACTION`.

**Código, mas não tela:** autorização por vínculo treinador↔atleta → `function` tipo
`AUTH` (Java, plugada por cadastro nas visões do atleta).

**TS de verdade (2 telas):** **Treinar** e **Correr** — execução com cronômetro, estado
em andamento, lançamento de séries/parciais. São `CUSTOM`: componentes TS registrados que
**compõem o catálogo do framework** (Popup, DatePicker, ConfirmModal, list-group...) —
portanto sem CSS novo e com HTML mínimo de composição; menu, permissão, tema e dados vêm
do framework.

Essas 2 telas são exatamente o que **nunca** deve virar cadastro — interação rica de
domínio. O contrato do framework é: **CSS nunca; HTML só dentro de `CUSTOM` (e composto
do catálogo); TS só onde há lógica de interação real.**

---

## 8. O que fica fora (por decisão)

- Geração de código/scaffolding — só interpretação em runtime.
- Editor visual de telas (v1 cadastra via as próprias telas do framework — *dogfooding*:
  o dicionário é editado por visões do próprio framework, seeds em SQL).
- Workflow/BPM, relatórios impressos, i18n (labels já são dados; trocar idioma = trocar
  labels — estrutura pronta, feature adiada).
- Multi-banco (v1 = MySQL, como os dois projetos).

## 9. Riscos e mitigações

1. **Armadilha do meta-framework** (cadastro mais complexo que escrever a tela):
   mitigar com defaults agressivos — cadastrar só `tables`+`table_field` já gera uma visão
   GRID default utilizável; `vision_field` é refinamento, não obrigação.
2. **Buraco de expressividade** (a tela real sempre tem um detalhe a mais): o escape hatch
   `CUSTOM`/`function` é de primeira classe desde a v1, não um remendo.
3. **Performance do CRUD dinâmico:** metadado em cache de memória; SQL preparado por
   visão no boot; paginação obrigatória na grid.
4. **Segurança:** restrições sempre reaplicadas no backend; o JSON do front é cortesia
   de UX, nunca autoridade.

## 10. Roadmap sugerido

1. **v0 — Dicionário + CRUD genérico:** tabelas de metadados (migrations), MetadataLoader,
   `/api/meta`, `/api/data`, validações required/unique/size. Prova: 2 telas do integrator.
2. **v1 — Front genérico completo:** shell + GRID + FORM + MASTER_DETAIL + filtros +
   componentes do catálogo + auth/papéis + restrições. Prova: **integrator inteiro por
   cadastro** (motor plugado como `function`).
3. **v2 — Casos ricos:** MULTI_SELECT, DRAG_ORDER, `DASHBOARD` cadastrável
   (`dashboard_widget` + campos calculados), `CUSTOM` + ComponentRegistry, hooks.
   Prova: **gym reconstruído** (só Treinar/Correr em TS).
4. **v3 — Conforto:** editor do dicionário no próprio framework (dogfooding pleno),
   geração de DDL a partir de `tables`, export/import de metadado entre ambientes (JSON),
   i18n.
