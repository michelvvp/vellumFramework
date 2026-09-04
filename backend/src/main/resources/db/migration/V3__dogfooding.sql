-- Dogfooding (seção 8 da especificação): o dicionário é editado por visões do
-- próprio Vellum. Este seed cadastra as tabelas do dicionário e do modelo de
-- acesso em `table`/`column` e cria as telas de administração — a partir daqui,
-- criar um sistema novo é cadastro.

-- ============================== domínios =====================================

INSERT INTO `domain` (nm_domain, ds_domain) VALUES
  ('FIELD_TYPE',       'Tipos de coluna de entidade'),
  ('VISION_TYPE',      'Arquétipos de visão'),
  ('COMPONENT',        'Catálogo de componentes de campo'),
  ('RESTRICTION_TYPE', 'Naturezas de restrição de visão'),
  ('OPERATOR',         'Operadores de filtro'),
  ('OPERATION',        'Operações de CRUD'),
  ('HANDLER_TYPE',     'Tipos de handler'),
  ('MOMENT',           'Momentos de hook'),
  ('PLACEMENT',        'Posição de uma ação na visão'),
  ('WIDGET_TYPE',      'Tipos de widget de dashboard'),
  ('AGGREGATION',      'Agregações de widget'),
  ('GROUP_BY',         'Agrupamentos de widget'),
  ('BADGE_COLOR',      'Tokens semânticos de cor do design system'),
  ('CONSTRAINT_TYPE',  'Naturezas de constraint'),
  ('ON_DELETE',        'Ação de exclusão em cascata de FK');

SET @d_field_type       := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'FIELD_TYPE');
SET @d_vision_type      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'VISION_TYPE');
SET @d_component        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'COMPONENT');
SET @d_restriction_type := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'RESTRICTION_TYPE');
SET @d_operator         := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'OPERATOR');
SET @d_operation        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'OPERATION');
SET @d_handler_type     := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'HANDLER_TYPE');
SET @d_moment           := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'MOMENT');
SET @d_placement        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'PLACEMENT');
SET @d_widget_type      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'WIDGET_TYPE');
SET @d_aggregation      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'AGGREGATION');
SET @d_group_by         := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'GROUP_BY');
SET @d_badge_color      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'BADGE_COLOR');
SET @d_constraint_type  := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'CONSTRAINT_TYPE');
SET @d_on_delete        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'ON_DELETE');

INSERT INTO `domain_value` (nr_seq_domain, vl_value, ds_label, nr_order) VALUES
  (@d_field_type, 'STRING',   'Texto curto', 1),
  (@d_field_type, 'TEXT',     'Texto longo', 2),
  (@d_field_type, 'INTEGER',  'Inteiro', 3),
  (@d_field_type, 'DECIMAL',  'Decimal', 4),
  (@d_field_type, 'BOOLEAN',  'Sim/Não', 5),
  (@d_field_type, 'DATE',     'Data', 6),
  (@d_field_type, 'DATETIME', 'Data e hora', 7),
  (@d_field_type, 'TIME',     'Hora', 8),
  (@d_field_type, 'DOMAIN',   'Domínio', 9),
  (@d_field_type, 'ENTITY',   'Entidade (FK)', 10),
  (@d_field_type, 'PASSWORD', 'Senha', 11),
  (@d_field_type, 'JSON',     'JSON', 12),

  (@d_vision_type, 'GRID',          'Listagem', 1),
  (@d_vision_type, 'MASTER_DETAIL', 'Pai e filhos', 2),
  (@d_vision_type, 'DASHBOARD',     'Dashboard', 3),
  (@d_vision_type, 'CUSTOM',        'Componente custom', 4),

  (@d_component, 'INPUT',           'Input', 1),
  (@d_component, 'TEXTAREA',        'Textarea', 2),
  (@d_component, 'PASSWORD',        'Senha', 3),
  (@d_component, 'SWITCH',          'Switch', 4),
  (@d_component, 'CHECKBOX',        'Checkbox', 5),
  (@d_component, 'POPUP',           'Seletor (popup)', 6),
  (@d_component, 'SEGMENTED',       'Segmentado', 7),
  (@d_component, 'RADIO',           'Radio', 8),
  (@d_component, 'DATE_PICKER',     'Calendário', 9),
  (@d_component, 'DATETIME_PICKER', 'Calendário + hora', 10),
  (@d_component, 'SLIDER',          'Slider', 11),
  (@d_component, 'MULTI_SELECT',    'Seleção múltipla (N:N)', 12),
  (@d_component, 'BADGE',           'Badge (grid)', 13),
  (@d_component, 'AVATAR',          'Avatar (grid)', 14),
  (@d_component, 'DRAG_ORDER',      'Reordenar por arrasto', 15),

  (@d_restriction_type, 'FILTER',     'Filtro de dados', 1),
  (@d_restriction_type, 'PERMISSION', 'Permissão por função', 2),
  (@d_restriction_type, 'VALIDATION', 'Validação declarativa', 3),

  (@d_operator, 'EQ', 'Igual', 1),
  (@d_operator, 'NE', 'Diferente', 2),
  (@d_operator, 'GT', 'Maior', 3),
  (@d_operator, 'GE', 'Maior ou igual', 4),
  (@d_operator, 'LT', 'Menor', 5),
  (@d_operator, 'LE', 'Menor ou igual', 6),
  (@d_operator, 'IN', 'Em (lista)', 7),
  (@d_operator, 'LIKE', 'Contém', 8),
  (@d_operator, 'BETWEEN', 'Entre', 9),
  (@d_operator, 'IS_NULL', 'É nulo', 10),
  (@d_operator, 'NOT_NULL', 'Não é nulo', 11),

  (@d_operation, 'READ',   'Leitura', 1),
  (@d_operation, 'CREATE', 'Criação', 2),
  (@d_operation, 'UPDATE', 'Alteração', 3),
  (@d_operation, 'DELETE', 'Exclusão', 4),
  (@d_operation, 'ALL',    'Todas', 5),

  (@d_handler_type, 'ACTION',   'Ação de visão', 1),
  (@d_handler_type, 'HOOK',     'Hook de CRUD', 2),
  (@d_handler_type, 'AUTH',     'Autorização custom', 3),
  (@d_handler_type, 'JOB',      'Job agendado', 4),
  (@d_handler_type, 'ENDPOINT', 'Endpoint de API', 5),

  (@d_moment, 'BEFORE_CREATE', 'Antes de criar', 1),
  (@d_moment, 'AFTER_CREATE',  'Depois de criar', 2),
  (@d_moment, 'BEFORE_UPDATE', 'Antes de alterar', 3),
  (@d_moment, 'AFTER_UPDATE',  'Depois de alterar', 4),
  (@d_moment, 'BEFORE_DELETE', 'Antes de excluir', 5),
  (@d_moment, 'AFTER_DELETE',  'Depois de excluir', 6),

  (@d_placement, 'ROW',    'Na linha', 1),
  (@d_placement, 'HEADER', 'No cabeçalho', 2),

  (@d_widget_type, 'VALUE',      'Número', 1),
  (@d_widget_type, 'CHART_LINE', 'Gráfico de linha', 2),
  (@d_widget_type, 'CHART_BAR',  'Gráfico de barras', 3),
  (@d_widget_type, 'LIST',       'Últimos registros', 4),

  (@d_aggregation, 'SUM',   'Soma', 1),
  (@d_aggregation, 'AVG',   'Média', 2),
  (@d_aggregation, 'MAX',   'Máximo', 3),
  (@d_aggregation, 'MIN',   'Mínimo', 4),
  (@d_aggregation, 'COUNT', 'Contagem', 5),
  (@d_aggregation, 'NONE',  'Sem agregação', 6),

  (@d_group_by, 'DAY',   'Por dia', 1),
  (@d_group_by, 'WEEK',  'Por semana', 2),
  (@d_group_by, 'MONTH', 'Por mês', 3),
  (@d_group_by, 'FIELD', 'Por campo', 4),
  (@d_group_by, 'NONE',  'Sem agrupamento', 5),

  (@d_badge_color, 'accent',  'Destaque', 1),
  (@d_badge_color, 'success', 'Sucesso', 2),
  (@d_badge_color, 'warning', 'Atenção', 3),
  (@d_badge_color, 'danger',  'Perigo', 4),

  (@d_constraint_type, 'PRIMARY_KEY', 'Chave primária', 1),
  (@d_constraint_type, 'FOREIGN_KEY', 'Chave estrangeira', 2),
  (@d_constraint_type, 'UNIQUE',      'Única', 3),
  (@d_constraint_type, 'CHECK',       'Verificação', 4),

  (@d_on_delete, 'RESTRICT', 'Impedir exclusão', 1),
  (@d_on_delete, 'CASCADE',  'Excluir em cascata', 2),
  (@d_on_delete, 'SET_NULL', 'Anular a referência', 3);

-- ============================ config do app ==================================

INSERT INTO `app_config` (nm_key, vl_value) VALUES
  ('app.name',          'Vellum'),
  ('theme.accent',      '#0a84ff'),
  ('theme.accentHover', '#3396ff'),
  ('theme.accentTint',  'rgba(10, 132, 255, 0.18)'),
  ('theme.onAccent',    '#ffffff');

-- ===================== tabelas do próprio Vellum =============================
-- ie_system = TRUE: são configuração do produto, não dado de cliente, e por
-- isso ficam fora do escopo por estabelecimento.

INSERT INTO `table` (nm_table, ds_table, ds_table_plural, nm_label_field, ie_system) VALUES
  ('domain',                 'Domínio',              'Domínios',                'nm_domain',        TRUE),
  ('domain_value',           'Valor',                'Valores',                 'ds_label',         TRUE),
  ('table',                  'Tabela',               'Tabelas',                 'ds_table',         TRUE),
  ('column',                 'Coluna',               'Colunas',                 'ds_label',         TRUE),
  ('index',                  'Índice',               'Índices',                 'nm_index',         TRUE),
  ('constraint',             'Constraint',           'Constraints',             'nm_constraint',    TRUE),
  ('menu_group',             'Grupo de menu',        'Grupos de menu',          'ds_label',         TRUE),
  ('vision',                 'Visão',                'Visões',                  'ds_title',         TRUE),
  ('vision_column',          'Campo da visão',       'Campos da visão',         NULL,               TRUE),
  ('vision_restriction',     'Restrição',            'Restrições',              NULL,               TRUE),
  ('handler',                'Handler',              'Handlers',                'nm_handler',       TRUE),
  ('dashboard_widget',       'Widget',               'Widgets',                 'ds_title',         TRUE),
  ('app_config',             'Configuração',         'Configurações',           'nm_key',           TRUE),
  ('group',                  'Grupo',                'Grupos',                  'nm_group',         TRUE),
  ('establishment',          'Estabelecimento',      'Estabelecimentos',        'nm_establishment', TRUE),
  ('function',               'Função',               'Funções',                 'ds_function',      TRUE),
  ('function_establishment', 'Função habilitada',    'Funções do estabelecimento', NULL,            TRUE),
  ('profile',                'Perfil',               'Perfis',                  'nm_profile',       TRUE),
  ('function_profile',       'Função do perfil',     'Funções do perfil',       NULL,               TRUE),
  ('person',                 'Pessoa',               'Pessoas',                 'nm_person',        TRUE),
  ('person_establishment',   'Estabelecimento',      'Estabelecimentos da pessoa', NULL,            TRUE),
  ('person_profile',         'Perfil da pessoa',     'Perfis da pessoa',        NULL,               TRUE);

SET @t_domain       := (SELECT nr_sequence FROM `table` WHERE nm_table = 'domain');
SET @t_domain_value := (SELECT nr_sequence FROM `table` WHERE nm_table = 'domain_value');
SET @t_table        := (SELECT nr_sequence FROM `table` WHERE nm_table = 'table');
SET @t_column       := (SELECT nr_sequence FROM `table` WHERE nm_table = 'column');
SET @t_index        := (SELECT nr_sequence FROM `table` WHERE nm_table = 'index');
SET @t_constraint   := (SELECT nr_sequence FROM `table` WHERE nm_table = 'constraint');
SET @t_menu_group   := (SELECT nr_sequence FROM `table` WHERE nm_table = 'menu_group');
SET @t_vision       := (SELECT nr_sequence FROM `table` WHERE nm_table = 'vision');
SET @t_vision_col   := (SELECT nr_sequence FROM `table` WHERE nm_table = 'vision_column');
SET @t_vision_restr := (SELECT nr_sequence FROM `table` WHERE nm_table = 'vision_restriction');
SET @t_handler      := (SELECT nr_sequence FROM `table` WHERE nm_table = 'handler');
SET @t_widget       := (SELECT nr_sequence FROM `table` WHERE nm_table = 'dashboard_widget');
SET @t_app_config   := (SELECT nr_sequence FROM `table` WHERE nm_table = 'app_config');
SET @t_group        := (SELECT nr_sequence FROM `table` WHERE nm_table = 'group');
SET @t_establishment:= (SELECT nr_sequence FROM `table` WHERE nm_table = 'establishment');
SET @t_function     := (SELECT nr_sequence FROM `table` WHERE nm_table = 'function');
SET @t_func_estab   := (SELECT nr_sequence FROM `table` WHERE nm_table = 'function_establishment');
SET @t_profile      := (SELECT nr_sequence FROM `table` WHERE nm_table = 'profile');
SET @t_func_profile := (SELECT nr_sequence FROM `table` WHERE nm_table = 'function_profile');
SET @t_person       := (SELECT nr_sequence FROM `table` WHERE nm_table = 'person');
SET @t_person_estab := (SELECT nr_sequence FROM `table` WHERE nm_table = 'person_establishment');
SET @t_person_prof  := (SELECT nr_sequence FROM `table` WHERE nm_table = 'person_profile');

-- =============================== colunas =====================================
-- Só o que as telas de administração precisam: o SchemaValidator exige que toda
-- coluna cadastrada exista no banco, mas não exige o contrário.

-- domain
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, ie_unique, qt_size, ds_hint, nr_order) VALUES
  (@t_domain, 'nm_domain', 'Nome', 'STRING', TRUE, TRUE, 60, 'Ex.: GRUPO_MUSCULAR — é como as colunas referenciam o domínio', 1),
  (@t_domain, 'ds_domain', 'Descrição', 'STRING', FALSE, FALSE, 255, NULL, 2),
  (@t_domain, 'ie_active', 'Ativo', 'BOOLEAN', FALSE, FALSE, NULL, NULL, 3);

-- domain_value
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_domain_value, 'nr_seq_domain', 'Domínio', 'ENTITY', @t_domain, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_domain_value, 'vl_value', 'Valor', 'STRING', NULL, NULL, TRUE, 60, NULL, 'Valor persistido no dado (ex.: PEITO)', 2),
  (@t_domain_value, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, TRUE, 120, NULL, 'O que aparece na interface', 3),
  (@t_domain_value, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 4),
  (@t_domain_value, 'ds_color', 'Cor do badge', 'DOMAIN', NULL, @d_badge_color, FALSE, NULL, NULL, NULL, 5),
  (@t_domain_value, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 6);

-- table
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_table, 'nm_table', 'Nome físico', 'STRING', TRUE, TRUE, 60, NULL, 'Nome da tabela no banco', 1),
  (@t_table, 'ds_table', 'Rótulo', 'STRING', TRUE, FALSE, 120, NULL, 'Singular: "Exercício"', 2),
  (@t_table, 'ds_table_plural', 'Rótulo plural', 'STRING', TRUE, FALSE, 120, NULL, 'Plural: "Exercícios"', 3),
  (@t_table, 'nm_label_field', 'Coluna de rótulo', 'STRING', FALSE, FALSE, 120, NULL, 'Coluna(s) que identificam o registro em combos (CSV)', 4),
  (@t_table, 'ie_audit', 'Auditoria', 'BOOLEAN', FALSE, FALSE, NULL, 'false', 'Mantém dt_created/dt_updated e o usuário', 5),
  (@t_table, 'ie_logical_delete', 'Exclusão lógica', 'BOOLEAN', FALSE, FALSE, NULL, 'false', 'Excluir marca ie_active = false', 6),
  (@t_table, 'ie_system', 'Tabela do sistema', 'BOOLEAN', FALSE, FALSE, NULL, 'false', 'Tabela do próprio Vellum: fora do escopo por estabelecimento', 7),
  (@t_table, 'ie_active', 'Ativa', 'BOOLEAN', FALSE, FALSE, NULL, 'true', NULL, 8);

-- column
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_column, 'nr_seq_table', 'Tabela', 'ENTITY', @t_table, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_column, 'nm_column', 'Nome físico', 'STRING', NULL, NULL, TRUE, 60, NULL, 'Nome da coluna no banco', 2),
  (@t_column, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, TRUE, 120, NULL, NULL, 3),
  (@t_column, 'ie_type', 'Tipo', 'DOMAIN', NULL, @d_field_type, TRUE, NULL, NULL, NULL, 4),
  (@t_column, 'nr_seq_domain', 'Domínio', 'ENTITY', @t_domain, NULL, FALSE, NULL, NULL, 'Obrigatório quando o tipo é Domínio', 5),
  (@t_column, 'nr_seq_table_ref', 'Tabela referenciada', 'ENTITY', @t_table, NULL, FALSE, NULL, NULL, 'Obrigatório quando o tipo é Entidade', 6),
  (@t_column, 'ie_required', 'Obrigatória', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 7),
  (@t_column, 'ie_unique', 'Única', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 8),
  (@t_column, 'qt_size', 'Tamanho', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 9),
  (@t_column, 'qt_scale', 'Casas decimais', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 10),
  (@t_column, 'vl_min', 'Mínimo', 'STRING', NULL, NULL, FALSE, 30, NULL, NULL, 11),
  (@t_column, 'vl_max', 'Máximo', 'STRING', NULL, NULL, FALSE, 30, NULL, NULL, 12),
  (@t_column, 'ds_regex', 'Expressão regular', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 13),
  (@t_column, 'vl_default', 'Valor padrão', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 14),
  (@t_column, 'ds_hint', 'Texto de ajuda', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 15),
  (@t_column, 'ds_formula', 'Fórmula', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Campo calculado, não persistido. Só colunas da própria tabela', 16),
  (@t_column, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 17),
  (@t_column, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 18);

-- index
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_index, 'nr_seq_table', 'Tabela', 'ENTITY', @t_table, TRUE, FALSE, NULL, NULL, NULL, 1),
  (@t_index, 'nm_index', 'Nome', 'STRING', NULL, TRUE, TRUE, 64, NULL, NULL, 2),
  (@t_index, 'ds_columns', 'Colunas', 'STRING', NULL, TRUE, FALSE, 255, NULL, 'Nomes das colunas na ordem, separados por vírgula', 3),
  (@t_index, 'ie_unique', 'Único', 'BOOLEAN', NULL, FALSE, FALSE, NULL, 'false', NULL, 4),
  (@t_index, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, FALSE, NULL, 'true', NULL, 5);

-- constraint
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_constraint, 'nr_seq_table', 'Tabela', 'ENTITY', @t_table, NULL, TRUE, FALSE, NULL, NULL, NULL, 1),
  (@t_constraint, 'nm_constraint', 'Nome', 'STRING', NULL, NULL, TRUE, TRUE, 64, NULL, NULL, 2),
  (@t_constraint, 'ie_constraint_type', 'Natureza', 'DOMAIN', NULL, @d_constraint_type, TRUE, FALSE, NULL, NULL, NULL, 3),
  (@t_constraint, 'ds_columns', 'Colunas', 'STRING', NULL, NULL, FALSE, FALSE, 255, NULL, 'Separadas por vírgula', 4),
  (@t_constraint, 'nr_seq_table_ref', 'Tabela referenciada', 'ENTITY', @t_table, NULL, FALSE, FALSE, NULL, NULL, 'Só para chave estrangeira', 5),
  (@t_constraint, 'ds_columns_ref', 'Colunas referenciadas', 'STRING', NULL, NULL, FALSE, FALSE, 255, NULL, 'Só para chave estrangeira', 6),
  (@t_constraint, 'ie_on_delete', 'Ao excluir', 'DOMAIN', NULL, @d_on_delete, FALSE, FALSE, NULL, NULL, NULL, 7),
  (@t_constraint, 'ds_expression', 'Expressão', 'STRING', NULL, NULL, FALSE, FALSE, 500, NULL, 'Só para verificação (CHECK)', 8),
  (@t_constraint, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 9);

-- menu_group
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, qt_size, vl_default, nr_order) VALUES
  (@t_menu_group, 'ds_label', 'Rótulo', 'STRING', TRUE, 120, NULL, 1),
  (@t_menu_group, 'nr_order', 'Ordem', 'INTEGER', FALSE, NULL, '0', 2),
  (@t_menu_group, 'ie_active', 'Ativo', 'BOOLEAN', FALSE, NULL, 'true', 3);

-- vision
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision, 'nm_vision', 'Chave', 'STRING', NULL, NULL, TRUE, TRUE, 60, NULL, 'Identificador da tela na API e na rota', 1),
  (@t_vision, 'ds_title', 'Título', 'STRING', NULL, NULL, TRUE, FALSE, 120, NULL, NULL, 2),
  (@t_vision, 'nr_seq_table', 'Tabela', 'ENTITY', @t_table, NULL, FALSE, FALSE, NULL, NULL, 'Vazia só para Dashboard e Custom', 3),
  (@t_vision, 'ie_type', 'Arquétipo', 'DOMAIN', NULL, @d_vision_type, TRUE, FALSE, NULL, NULL, NULL, 4),
  (@t_vision, 'nr_seq_vision_parent', 'Visão pai', 'ENTITY', @t_vision, NULL, FALSE, FALSE, NULL, NULL, 'Preenchida faz desta uma visão-filha', 5),
  (@t_vision, 'nm_parent_fk_column', 'Coluna da FK do pai', 'STRING', NULL, NULL, FALSE, FALSE, 60, NULL, 'Coluna desta tabela que guarda o id do pai', 6),
  (@t_vision, 'ie_read_only', 'Somente leitura', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'false', NULL, 7),
  (@t_vision, 'ie_allow_create', 'Permite criar', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 8),
  (@t_vision, 'ie_allow_update', 'Permite alterar', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 9),
  (@t_vision, 'ie_allow_delete', 'Permite excluir', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 10),
  (@t_vision, 'nm_component', 'Componente', 'STRING', NULL, NULL, FALSE, FALSE, 120, NULL, 'Só para Custom: nome registrado no front', 11),
  (@t_vision, 'nm_icon', 'Ícone', 'STRING', NULL, NULL, FALSE, FALSE, 60, NULL, NULL, 12),
  (@t_vision, 'ds_icon_color', 'Cor do ícone', 'STRING', NULL, NULL, FALSE, FALSE, 20, NULL, NULL, 13),
  (@t_vision, 'nr_seq_menu_group', 'Grupo de menu', 'ENTITY', @t_menu_group, NULL, FALSE, FALSE, NULL, NULL, NULL, 14),
  (@t_vision, 'nr_order', 'Ordem no menu', 'INTEGER', NULL, NULL, FALSE, FALSE, NULL, NULL, 'Vazia = fora do menu (só como filha)', 15),
  (@t_vision, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 16);

-- vision_column
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision_col, 'nr_seq_vision', 'Visão', 'ENTITY', @t_vision, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_vision_col, 'nr_seq_column', 'Coluna', 'ENTITY', @t_column, NULL, TRUE, NULL, NULL, NULL, 2),
  (@t_vision_col, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, FALSE, 120, NULL, 'Vazio usa o rótulo da coluna', 3),
  (@t_vision_col, 'ie_component', 'Componente', 'DOMAIN', NULL, @d_component, FALSE, NULL, NULL, 'Vazio usa o padrão do tipo', 4),
  (@t_vision_col, 'ie_show_in_grid', 'Na listagem', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 5),
  (@t_vision_col, 'ie_show_in_form', 'No formulário', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 6),
  (@t_vision_col, 'ie_read_only', 'Somente leitura', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 7),
  (@t_vision_col, 'ie_filter', 'Vira filtro', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 8),
  (@t_vision_col, 'nr_order_grid', 'Ordem na listagem', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 9),
  (@t_vision_col, 'nr_order_form', 'Ordem no formulário', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 10),
  (@t_vision_col, 'qt_width', 'Largura', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 11),
  (@t_vision_col, 'ds_format', 'Formato', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Ex.: dd/MM/yyyy', 12),
  (@t_vision_col, 'nm_ref_filter_column', 'Filtra pelo campo', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Filtra as opções do combo por outro campo do formulário', 13),
  (@t_vision_col, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 14);

-- vision_restriction
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision_restr, 'nr_seq_vision', 'Visão', 'ENTITY', @t_vision, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_vision_restr, 'ie_restriction_type', 'Natureza', 'DOMAIN', NULL, @d_restriction_type, TRUE, NULL, NULL, NULL, 2),
  (@t_vision_restr, 'nm_column', 'Coluna alvo', 'STRING', NULL, NULL, FALSE, 60, NULL, NULL, 3),
  (@t_vision_restr, 'ie_operator', 'Operador', 'DOMAIN', NULL, @d_operator, FALSE, NULL, NULL, NULL, 4),
  (@t_vision_restr, 'vl_value', 'Valor', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Literal ou variável: :person_id, :person_record, :establishment_id, :hoje, :agora, :parent_id', 5),
  (@t_vision_restr, 'cd_function', 'Função exigida', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Para permissão: o código da função', 6),
  (@t_vision_restr, 'ie_operation', 'Operação', 'DOMAIN', NULL, @d_operation, FALSE, NULL, NULL, NULL, 7),
  (@t_vision_restr, 'ds_message', 'Mensagem de erro', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Para validação', 8),
  (@t_vision_restr, 'ds_expression', 'Expressão', 'STRING', NULL, NULL, FALSE, 500, NULL, 'Ex.: reps_max >= reps_min', 9),
  (@t_vision_restr, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 10);

-- handler
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_handler, 'nm_handler', 'Chave', 'STRING', NULL, NULL, TRUE, TRUE, 60, NULL, 'Nome chamado pela API', 1),
  (@t_handler, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, FALSE, FALSE, 120, NULL, 'Texto do botão (para ação)', 2),
  (@t_handler, 'ie_handler_type', 'Tipo', 'DOMAIN', NULL, @d_handler_type, TRUE, FALSE, NULL, NULL, NULL, 3),
  (@t_handler, 'nr_seq_vision', 'Visão', 'ENTITY', @t_vision, NULL, FALSE, FALSE, NULL, NULL, 'Onde o botão aparece (ação) ou o que protege (autorização)', 4),
  (@t_handler, 'nr_seq_table', 'Tabela', 'ENTITY', @t_table, NULL, FALSE, FALSE, NULL, NULL, 'Tabela alvo (hook)', 5),
  (@t_handler, 'ie_moment', 'Momento', 'DOMAIN', NULL, @d_moment, FALSE, FALSE, NULL, NULL, 'Quando o hook dispara', 6),
  (@t_handler, 'ie_placement', 'Posição', 'DOMAIN', NULL, @d_placement, FALSE, FALSE, NULL, NULL, NULL, 7),
  (@t_handler, 'nm_bean', 'Bean Java', 'STRING', NULL, NULL, TRUE, FALSE, 120, NULL, 'Nome do bean registrado no HandlerRegistry', 8),
  (@t_handler, 'ie_confirm', 'Pede confirmação', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'false', NULL, 9),
  (@t_handler, 'ds_success_msg', 'Mensagem de sucesso', 'STRING', NULL, NULL, FALSE, FALSE, 255, NULL, NULL, 10),
  (@t_handler, 'cd_function', 'Função exigida', 'STRING', NULL, NULL, FALSE, FALSE, 60, NULL, NULL, 11),
  (@t_handler, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 12);

-- dashboard_widget
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_widget, 'nr_seq_vision', 'Dashboard', 'ENTITY', @t_vision, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_widget, 'ds_title', 'Título', 'STRING', NULL, NULL, TRUE, 120, NULL, NULL, 2),
  (@t_widget, 'ie_widget_type', 'Tipo', 'DOMAIN', NULL, @d_widget_type, TRUE, NULL, NULL, NULL, 3),
  (@t_widget, 'nr_seq_table', 'Tabela', 'ENTITY', @t_table, NULL, TRUE, NULL, NULL, NULL, 4),
  (@t_widget, 'nm_column_x', 'Eixo X', 'STRING', NULL, NULL, FALSE, 60, NULL, NULL, 5),
  (@t_widget, 'nm_columns_y', 'Séries (Y)', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Separadas por vírgula', 6),
  (@t_widget, 'ie_aggregation', 'Agregação', 'DOMAIN', NULL, @d_aggregation, FALSE, NULL, NULL, NULL, 7),
  (@t_widget, 'ie_group_by', 'Agrupamento', 'DOMAIN', NULL, @d_group_by, FALSE, NULL, NULL, NULL, 8),
  (@t_widget, 'nm_group_column', 'Coluna de agrupamento', 'STRING', NULL, NULL, FALSE, 60, NULL, NULL, 9),
  (@t_widget, 'ie_use_period', 'Usa o período', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 10),
  (@t_widget, 'qt_limit', 'Limite', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 11),
  (@t_widget, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 12),
  (@t_widget, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 13);

-- app_config
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, ie_unique, qt_size, ds_hint, nr_order) VALUES
  (@t_app_config, 'nm_key', 'Chave', 'STRING', TRUE, TRUE, 60, 'app.name, theme.accent, theme.accentHover, theme.accentTint, theme.onAccent', 1),
  (@t_app_config, 'vl_value', 'Valor', 'STRING', FALSE, FALSE, 500, NULL, 2),
  (@t_app_config, 'ie_active', 'Ativa', 'BOOLEAN', FALSE, FALSE, NULL, NULL, 3);

-- ------------------------- modelo de acesso ----------------------------------

-- group
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_group, 'nm_group', 'Nome', 'STRING', TRUE, TRUE, 120, NULL, NULL, 1),
  (@t_group, 'ie_root', 'Grupo raiz', 'BOOLEAN', FALSE, FALSE, NULL, 'false', 'É de dentro dele que se cadastram grupos e estabelecimentos novos', 2),
  (@t_group, 'ie_active', 'Ativo', 'BOOLEAN', FALSE, FALSE, NULL, 'true', NULL, 3);

-- establishment
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_establishment, 'nr_seq_group', 'Grupo', 'ENTITY', @t_group, TRUE, FALSE, NULL, NULL, NULL, 1),
  (@t_establishment, 'nm_establishment', 'Nome', 'STRING', NULL, TRUE, TRUE, 120, NULL, NULL, 2),
  (@t_establishment, 'cd_document', 'Documento', 'STRING', NULL, FALSE, FALSE, 14, NULL, NULL, 3),
  (@t_establishment, 'ds_primary_color', 'Cor da marca', 'STRING', NULL, FALSE, FALSE, 7, '#0a84ff', 'Hover, tint e cor de texto derivam dela', 4),
  (@t_establishment, 'nr_permission_version', 'Versão da permissão', 'INTEGER', NULL, FALSE, FALSE, NULL, '1', 'Sobe a cada mudança de permissão e invalida os tokens antigos', 5),
  (@t_establishment, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, FALSE, NULL, 'true', NULL, 6);

-- function
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_function, 'cd_function', 'Código', 'STRING', TRUE, TRUE, 60, NULL, 'É o que aparece no token e nas checagens (ex.: PROFILE_EDIT)', 1),
  (@t_function, 'ds_function', 'Nome', 'STRING', TRUE, FALSE, 120, NULL, NULL, 2),
  (@t_function, 'nm_module', 'Módulo', 'STRING', TRUE, FALSE, 60, NULL, 'Só agrupa as caixinhas na tela', 3),
  (@t_function, 'nr_order', 'Ordem', 'INTEGER', FALSE, FALSE, NULL, '0', NULL, 4),
  (@t_function, 'ie_active', 'Ativa', 'BOOLEAN', FALSE, FALSE, NULL, 'true', NULL, 5);

-- function_establishment
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, vl_default, nr_order) VALUES
  (@t_func_estab, 'nr_seq_establishment', 'Estabelecimento', 'ENTITY', @t_establishment, TRUE, NULL, 1),
  (@t_func_estab, 'nr_seq_function', 'Função', 'ENTITY', @t_function, TRUE, NULL, 2),
  (@t_func_estab, 'ie_active', 'Ativa', 'BOOLEAN', NULL, FALSE, 'true', 3);

-- profile
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, qt_size, vl_default, nr_order) VALUES
  (@t_profile, 'nr_seq_establishment', 'Estabelecimento', 'ENTITY', @t_establishment, TRUE, NULL, NULL, 1),
  (@t_profile, 'nm_profile', 'Nome', 'STRING', NULL, TRUE, 120, NULL, 2),
  (@t_profile, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, NULL, 'true', 3);

-- function_profile
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, vl_default, nr_order) VALUES
  (@t_func_profile, 'nr_seq_profile', 'Perfil', 'ENTITY', @t_profile, TRUE, NULL, 1),
  (@t_func_profile, 'nr_seq_function', 'Função', 'ENTITY', @t_function, TRUE, NULL, 2),
  (@t_func_profile, 'ie_active', 'Ativa', 'BOOLEAN', NULL, FALSE, 'true', 3);

-- person
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_person, 'nm_person', 'Nome', 'STRING', NULL, TRUE, FALSE, 120, NULL, NULL, 1),
  (@t_person, 'cd_login', 'Login', 'STRING', NULL, TRUE, TRUE, 60, NULL, NULL, 2),
  (@t_person, 'ds_password_hash', 'Senha', 'PASSWORD', NULL, TRUE, FALSE, 100, NULL, 'Na edição, deixe em branco para manter a atual', 3),
  (@t_person, 'ie_active', 'Ativa', 'BOOLEAN', NULL, FALSE, FALSE, NULL, 'true', 'Desativar derruba a sessão da pessoa', 4),
  (@t_person, 'qt_failed_attempts', 'Tentativas falhas', 'INTEGER', NULL, FALSE, FALSE, NULL, '0', NULL, 5),
  (@t_person, 'nr_lock_level', 'Nível de bloqueio', 'INTEGER', NULL, FALSE, FALSE, NULL, '0', 'Zere para desbloquear a conta', 6),
  (@t_person, 'dt_locked_until', 'Bloqueada até', 'DATETIME', NULL, FALSE, FALSE, NULL, NULL, NULL, 7),
  (@t_person, 'nr_seq_table_ref', 'Tabela vinculada', 'ENTITY', @t_table, FALSE, FALSE, NULL, NULL, 'Tabela de negócio do registro vinculado', 8),
  (@t_person, 'nr_seq_record', 'Registro vinculado', 'INTEGER', NULL, FALSE, FALSE, NULL, NULL, 'Id do registro de negócio desta pessoa', 9);

-- person_establishment
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, vl_default, ds_hint, nr_order) VALUES
  (@t_person_estab, 'nr_seq_person', 'Pessoa', 'ENTITY', @t_person, TRUE, NULL, NULL, 1),
  (@t_person_estab, 'nr_seq_establishment', 'Estabelecimento', 'ENTITY', @t_establishment, TRUE, NULL, 'Mais de um: o login pergunta em qual entrar', 2),
  (@t_person_estab, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, 'true', NULL, 3);

-- person_profile
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, vl_default, ds_hint, nr_order) VALUES
  (@t_person_prof, 'nr_seq_person', 'Pessoa', 'ENTITY', @t_person, TRUE, NULL, NULL, 1),
  (@t_person_prof, 'nr_seq_profile', 'Perfil', 'ENTITY', @t_profile, TRUE, NULL, 'O perfil precisa ser de um estabelecimento onde a pessoa tem vínculo', 2),
  (@t_person_prof, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, 'true', NULL, 3);

-- ======================= catálogo de funções =================================

INSERT INTO `function` (cd_function, ds_function, nm_module, nr_order) VALUES
  ('DICTIONARY_VIEW',      'Ver o dicionário',                'Dicionário', 10),
  ('DICTIONARY_EDIT',      'Editar o dicionário',             'Dicionário', 20),
  ('GROUP_VIEW',           'Ver grupos',                      'Acesso',     10),
  ('GROUP_EDIT',           'Criar e editar grupos',           'Acesso',     20),
  ('ESTABLISHMENT_VIEW',   'Ver estabelecimentos',            'Acesso',     30),
  ('ESTABLISHMENT_EDIT',   'Criar e editar estabelecimentos', 'Acesso',     40),
  ('ESTABLISHMENT_FUNCTIONS', 'Funções do estabelecimento',   'Acesso',     50),
  ('PROFILE_VIEW',         'Ver perfis',                      'Acesso',     60),
  ('PROFILE_EDIT',         'Criar e editar perfis',           'Acesso',     70),
  ('PROFILE_FUNCTIONS',    'Funções do perfil',               'Acesso',     80),
  ('PERSON_VIEW',          'Ver pessoas',                     'Acesso',     90),
  ('PERSON_EDIT',          'Criar e editar pessoas',          'Acesso',    100),
  ('SYSTEM_CONFIG',        'Configurações do sistema',        'Sistema',    10);

-- ========================== menu e visões ====================================

INSERT INTO `menu_group` (ds_label, nr_order) VALUES ('Dicionário', 97), ('Acesso', 98), ('Sistema', 99);
SET @g_dictionary := (SELECT nr_sequence FROM `menu_group` WHERE ds_label = 'Dicionário');
SET @g_access     := (SELECT nr_sequence FROM `menu_group` WHERE ds_label = 'Acesso');
SET @g_system     := (SELECT nr_sequence FROM `menu_group` WHERE ds_label = 'Sistema');

INSERT INTO `vision` (nm_vision, ds_title, nr_seq_table, ie_type, nr_seq_menu_group, nr_order, nm_icon, ds_icon_color) VALUES
  ('domains',        'Domínios',        @t_domain,        'MASTER_DETAIL', @g_dictionary, 1, 'tag',      '#ff9f0a'),
  ('tables',         'Tabelas',         @t_table,         'MASTER_DETAIL', @g_dictionary, 2, 'table',    '#0a84ff'),
  ('visions',        'Visões',          @t_vision,        'MASTER_DETAIL', @g_dictionary, 3, 'screen',   '#bf5af2'),
  ('handlers',       'Handlers',        @t_handler,       'GRID',          @g_dictionary, 4, 'function', '#ff6482'),
  ('menu_groups',    'Menu',            @t_menu_group,    'GRID',          @g_dictionary, 5, 'menu',     '#64d2ff'),
  ('groups',         'Grupos',          @t_group,         'MASTER_DETAIL', @g_access,     1, 'layers',   '#5e5ce6'),
  ('establishments', 'Estabelecimentos',@t_establishment, 'MASTER_DETAIL', @g_access,     2, 'building', '#30d158'),
  ('functions',      'Funções',         @t_function,      'GRID',          @g_access,     3, 'shield',   '#ffd60a'),
  ('profiles',       'Perfis',          @t_profile,       'MASTER_DETAIL', @g_access,     4, 'badge',    '#ff9f0a'),
  ('people',         'Pessoas',         @t_person,        'MASTER_DETAIL', @g_access,     5, 'users',    '#0a84ff'),
  ('settings',       'Configurações',   @t_app_config,    'GRID',          @g_system,     1, 'settings', '#98989d');

SET @v_domains        := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'domains');
SET @v_tables         := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'tables');
SET @v_visions        := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'visions');
SET @v_groups         := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'groups');
SET @v_establishments := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'establishments');
SET @v_profiles       := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'profiles');
SET @v_people         := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'people');

-- filhas (fora do menu: nr_order nulo)
INSERT INTO `vision` (nm_vision, ds_title, nr_seq_table, ie_type, nr_seq_vision_parent, nm_parent_fk_column) VALUES
  ('domain_values',        'Valores do domínio',   @t_domain_value, 'GRID', @v_domains,        'nr_seq_domain'),
  ('table_columns',        'Colunas da tabela',    @t_column,       'GRID', @v_tables,         'nr_seq_table'),
  ('table_indexes',        'Índices da tabela',    @t_index,        'GRID', @v_tables,         'nr_seq_table'),
  ('table_constraints',    'Constraints da tabela',@t_constraint,   'GRID', @v_tables,         'nr_seq_table'),
  ('vision_columns',       'Campos da visão',      @t_vision_col,   'GRID', @v_visions,        'nr_seq_vision'),
  ('vision_restrictions',  'Restrições da visão',  @t_vision_restr, 'GRID', @v_visions,        'nr_seq_vision'),
  ('vision_widgets',       'Widgets do dashboard', @t_widget,       'GRID', @v_visions,        'nr_seq_vision'),
  ('group_establishments', 'Estabelecimentos',     @t_establishment,'GRID', @v_groups,         'nr_seq_group'),
  ('establishment_functions','Funções habilitadas',@t_func_estab,   'GRID', @v_establishments, 'nr_seq_establishment'),
  ('establishment_profiles','Perfis',              @t_profile,      'GRID', @v_establishments, 'nr_seq_establishment'),
  ('profile_functions',    'Funções do perfil',    @t_func_profile, 'GRID', @v_profiles,       'nr_seq_profile'),
  ('person_establishments','Estabelecimentos',     @t_person_estab, 'GRID', @v_people,         'nr_seq_person'),
  ('person_profiles',      'Perfis',               @t_person_prof,  'GRID', @v_people,         'nr_seq_person');

-- =========================== permissões ======================================
-- As telas do dicionário exigem DICTIONARY_*; as de acesso, as funções do
-- módulo Acesso. Sem nenhuma linha PERMISSION a visão é liberada para qualquer
-- autenticado — por isso toda visão de administração precisa das suas.

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'DICTIONARY_VIEW', 'READ' FROM `vision`
 WHERE nm_vision IN ('domains','tables','visions','handlers','menu_groups','domain_values',
                     'table_columns','table_indexes','table_constraints','vision_columns',
                     'vision_restrictions','vision_widgets');

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'DICTIONARY_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision IN ('domains','tables','visions','handlers','menu_groups','domain_values',
                     'table_columns','table_indexes','table_constraints','vision_columns',
                     'vision_restrictions','vision_widgets');

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation) VALUES
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'groups'), 'PERMISSION', 'GROUP_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'establishments'), 'PERMISSION', 'ESTABLISHMENT_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'group_establishments'), 'PERMISSION', 'ESTABLISHMENT_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'functions'), 'PERMISSION', 'PROFILE_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'establishment_functions'), 'PERMISSION', 'ESTABLISHMENT_FUNCTIONS', 'ALL'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'profiles'), 'PERMISSION', 'PROFILE_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'establishment_profiles'), 'PERMISSION', 'PROFILE_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'profile_functions'), 'PERMISSION', 'PROFILE_FUNCTIONS', 'ALL'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'people'), 'PERMISSION', 'PERSON_VIEW', 'READ'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'person_establishments'), 'PERMISSION', 'PERSON_EDIT', 'ALL'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'person_profiles'), 'PERMISSION', 'PERSON_EDIT', 'ALL'),
  ((SELECT nr_sequence FROM `vision` WHERE nm_vision = 'settings'), 'PERMISSION', 'SYSTEM_CONFIG', 'ALL');

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'GROUP_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision = 'groups';

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'ESTABLISHMENT_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision IN ('establishments','group_establishments');

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'PROFILE_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision IN ('profiles','establishment_profiles','functions');

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'PERSON_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision = 'people';
