-- Dogfooding (seção 8 da especificação): o dicionário é editado por visões do
-- próprio framework. Este seed cadastra as tabelas do dicionário em
-- tables/table_field e cria as telas de administração — a partir daqui,
-- criar um sistema novo é só cadastro.

-- ============================== domínios =====================================

INSERT INTO `domain` (nm_domain, ds_domain) VALUES
  ('FIELD_TYPE',       'Tipos de campo de entidade'),
  ('VISION_TYPE',      'Arquétipos de visão'),
  ('COMPONENT',        'Catálogo de componentes de campo'),
  ('RESTRICTION_TYPE', 'Naturezas de restrição de visão'),
  ('OPERATOR',         'Operadores de filtro'),
  ('OPERATION',        'Operações de CRUD'),
  ('FUNCTION_TYPE',    'Tipos de function'),
  ('MOMENT',           'Momentos de hook'),
  ('PLACEMENT',        'Posição de uma ação na visão'),
  ('WIDGET_TYPE',      'Tipos de widget de dashboard'),
  ('AGGREGATION',      'Agregações de widget'),
  ('GROUP_BY',         'Agrupamentos de widget'),
  ('BADGE_COLOR',      'Tokens semânticos de cor do design system');

SET @d_field_type       := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'FIELD_TYPE');
SET @d_vision_type      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'VISION_TYPE');
SET @d_component        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'COMPONENT');
SET @d_restriction_type := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'RESTRICTION_TYPE');
SET @d_operator         := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'OPERATOR');
SET @d_operation        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'OPERATION');
SET @d_function_type    := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'FUNCTION_TYPE');
SET @d_moment           := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'MOMENT');
SET @d_placement        := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'PLACEMENT');
SET @d_widget_type      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'WIDGET_TYPE');
SET @d_aggregation      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'AGGREGATION');
SET @d_group_by         := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'GROUP_BY');
SET @d_badge_color      := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'BADGE_COLOR');

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
  (@d_restriction_type, 'PERMISSION', 'Permissão por papel', 2),
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

  (@d_function_type, 'ACTION',   'Ação de visão', 1),
  (@d_function_type, 'HOOK',     'Hook de CRUD', 2),
  (@d_function_type, 'AUTH',     'Autorização custom', 3),
  (@d_function_type, 'JOB',      'Job agendado', 4),
  (@d_function_type, 'ENDPOINT', 'Endpoint de API', 5),

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
  (@d_badge_color, 'danger',  'Perigo', 4);

-- ============================ config do app ==================================

INSERT INTO `app_config` (nm_key, vl_value) VALUES
  ('app.name',          'Vellum'),
  ('theme.accent',      '#0a84ff'),
  ('theme.accentHover', '#3396ff'),
  ('theme.accentTint',  'rgba(10, 132, 255, 0.18)'),
  ('theme.onAccent',    '#ffffff');

-- =========================== entidades (tables) ==============================

INSERT INTO `tables` (nm_table, ds_table, ds_table_plural, nm_label_field) VALUES
  ('domain',             'Domínio',            'Domínios',              'nm_domain'),
  ('domain_value',       'Valor de domínio',   'Valores de domínio',    'ds_label'),
  ('tables',             'Tabela',             'Tabelas',               'nm_table'),
  ('table_field',        'Campo',              'Campos',                'nm_field'),
  ('menu_group',         'Grupo de menu',      'Grupos de menu',        'ds_label'),
  ('vision',             'Visão',              'Visões',                'nm_vision'),
  ('vision_field',       'Campo da visão',     'Campos da visão',       NULL),
  ('vision_restriction', 'Restrição',          'Restrições',            NULL),
  ('function',           'Função',             'Funções',               'nm_function'),
  ('dashboard_widget',   'Widget',             'Widgets',               'ds_title'),
  ('role',               'Papel',              'Papéis',                'nm_role'),
  ('app_user',           'Usuário',            'Usuários',              'nm_user'),
  ('user_role',          'Papel do usuário',   'Papéis do usuário',     NULL),
  ('app_config',         'Configuração',       'Configurações',         'nm_key');

SET @t_domain             := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'domain');
SET @t_domain_value       := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'domain_value');
SET @t_tables             := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'tables');
SET @t_table_field        := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'table_field');
SET @t_menu_group         := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'menu_group');
SET @t_vision             := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'vision');
SET @t_vision_field       := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'vision_field');
SET @t_vision_restriction := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'vision_restriction');
SET @t_function           := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'function');
SET @t_dashboard_widget   := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'dashboard_widget');
SET @t_role               := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'role');
SET @t_app_user           := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'app_user');
SET @t_user_role          := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'user_role');
SET @t_app_config         := (SELECT nr_sequence FROM `tables` WHERE nm_table = 'app_config');

-- ------------------------------- campos --------------------------------------

-- domain
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, ie_required, ie_unique, qt_size, ds_hint, nr_order) VALUES
  (@t_domain, 'nm_domain', 'Nome', 'STRING', TRUE, TRUE, 60, 'Ex.: GRUPO_MUSCULAR — é como os campos referenciam o domínio', 1),
  (@t_domain, 'ds_domain', 'Descrição', 'STRING', FALSE, FALSE, 255, NULL, 2),
  (@t_domain, 'ie_active', 'Ativo', 'BOOLEAN', FALSE, FALSE, NULL, NULL, 3);

-- domain_value
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_domain_value, 'nr_seq_domain', 'Domínio', 'ENTITY', @t_domain, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_domain_value, 'vl_value', 'Valor', 'STRING', NULL, NULL, TRUE, 60, NULL, 'Valor persistido no dado (ex.: PEITO)', 2),
  (@t_domain_value, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, TRUE, 120, NULL, 'O que aparece na interface', 3),
  (@t_domain_value, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 4),
  (@t_domain_value, 'ds_color', 'Cor do badge', 'DOMAIN', NULL, @d_badge_color, FALSE, NULL, NULL, NULL, 5),
  (@t_domain_value, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 6);

-- tables
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_tables, 'nm_table', 'Nome físico', 'STRING', TRUE, TRUE, 60, NULL, 'Nome da tabela no banco', 1),
  (@t_tables, 'ds_table', 'Rótulo singular', 'STRING', TRUE, FALSE, 120, NULL, NULL, 2),
  (@t_tables, 'ds_table_plural', 'Rótulo plural', 'STRING', TRUE, FALSE, 120, NULL, NULL, 3),
  (@t_tables, 'nm_label_field', 'Campo(s) de rótulo', 'STRING', FALSE, FALSE, 60, NULL, 'CSV de campos usados como rótulo em combos', 4),
  (@t_tables, 'ie_audit', 'Auditoria', 'BOOLEAN', FALSE, FALSE, NULL, 'false', 'Mantém dt_created/dt_updated e usuário automaticamente', 5),
  (@t_tables, 'ie_logical_delete', 'Exclusão lógica', 'BOOLEAN', FALSE, FALSE, NULL, 'false', 'Marca ie_active=false em vez de excluir', 6),
  (@t_tables, 'ie_active', 'Ativa', 'BOOLEAN', FALSE, FALSE, NULL, 'true', NULL, 7);

-- table_field
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_table_field, 'nr_seq_table', 'Tabela', 'ENTITY', @t_tables, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_table_field, 'nm_field', 'Nome físico', 'STRING', NULL, NULL, TRUE, 60, NULL, 'Nome da coluna no banco', 2),
  (@t_table_field, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, TRUE, 120, NULL, NULL, 3),
  (@t_table_field, 'ie_type', 'Tipo', 'DOMAIN', NULL, @d_field_type, TRUE, NULL, NULL, NULL, 4),
  (@t_table_field, 'nr_seq_domain', 'Domínio', 'ENTITY', @t_domain, NULL, FALSE, NULL, NULL, 'Obrigatório quando o tipo é Domínio', 5),
  (@t_table_field, 'nr_seq_table_ref', 'Tabela referenciada', 'ENTITY', @t_tables, NULL, FALSE, NULL, NULL, 'Obrigatório quando o tipo é Entidade (FK)', 6),
  (@t_table_field, 'ie_required', 'Obrigatório', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 7),
  (@t_table_field, 'ie_unique', 'Único', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 8),
  (@t_table_field, 'qt_size', 'Tamanho', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, 'Máximo de caracteres (texto)', 9),
  (@t_table_field, 'qt_scale', 'Casas decimais', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 10),
  (@t_table_field, 'vl_min', 'Mínimo', 'STRING', NULL, NULL, FALSE, 30, NULL, NULL, 11),
  (@t_table_field, 'vl_max', 'Máximo', 'STRING', NULL, NULL, FALSE, 30, NULL, NULL, 12),
  (@t_table_field, 'ds_regex', 'Regex de validação', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 13),
  (@t_table_field, 'vl_default', 'Valor padrão', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 14),
  (@t_table_field, 'ds_hint', 'Texto de ajuda', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 15),
  (@t_table_field, 'ds_formula', 'Fórmula (campo calculado)', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Expressão sobre campos da própria linha; deixa o campo somente leitura', 16),
  (@t_table_field, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 17),
  (@t_table_field, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 18);

-- menu_group
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, ie_required, qt_size, vl_default, nr_order) VALUES
  (@t_menu_group, 'ds_label', 'Rótulo', 'STRING', TRUE, 120, NULL, 1),
  (@t_menu_group, 'nr_order', 'Ordem', 'INTEGER', FALSE, NULL, '0', 2),
  (@t_menu_group, 'ie_active', 'Ativo', 'BOOLEAN', FALSE, NULL, 'true', 3);

-- vision
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision, 'nm_vision', 'Chave', 'STRING', NULL, NULL, TRUE, TRUE, 60, NULL, 'Identificador único da tela (ex.: exercicios)', 1),
  (@t_vision, 'ds_title', 'Título', 'STRING', NULL, NULL, TRUE, FALSE, 120, NULL, NULL, 2),
  (@t_vision, 'nr_seq_table', 'Tabela base', 'ENTITY', @t_tables, NULL, FALSE, FALSE, NULL, NULL, 'Vazia só para DASHBOARD/CUSTOM', 3),
  (@t_vision, 'ie_type', 'Tipo', 'DOMAIN', NULL, @d_vision_type, TRUE, FALSE, NULL, 'GRID', NULL, 4),
  (@t_vision, 'nr_seq_vision_parent', 'Visão pai', 'ENTITY', @t_vision, NULL, FALSE, FALSE, NULL, NULL, 'Preenchida = esta visão abre a partir do pai', 5),
  (@t_vision, 'nm_parent_fk_field', 'Campo FK do pai', 'STRING', NULL, NULL, FALSE, FALSE, 60, NULL, 'Campo desta tabela que guarda a FK do registro pai', 6),
  (@t_vision, 'ie_read_only', 'Somente leitura', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'false', NULL, 7),
  (@t_vision, 'ie_allow_create', 'Permite criar', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 8),
  (@t_vision, 'ie_allow_update', 'Permite editar', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 9),
  (@t_vision, 'ie_allow_delete', 'Permite excluir', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 10),
  (@t_vision, 'nm_component', 'Componente (CUSTOM)', 'STRING', NULL, NULL, FALSE, FALSE, 120, NULL, 'Nome registrado no ComponentRegistry do front', 11),
  (@t_vision, 'nm_icon', 'Ícone', 'STRING', NULL, NULL, FALSE, FALSE, 60, NULL, 'Nome do ícone do menu (list, table, screen, users...)', 12),
  (@t_vision, 'ds_icon_color', 'Cor do ícone', 'STRING', NULL, NULL, FALSE, FALSE, 20, NULL, 'Hex do tile do ícone (ex.: #0a84ff)', 13),
  (@t_vision, 'nr_seq_menu_group', 'Grupo do menu', 'ENTITY', @t_menu_group, NULL, FALSE, FALSE, NULL, NULL, NULL, 14),
  (@t_vision, 'nr_order', 'Ordem no menu', 'INTEGER', NULL, NULL, FALSE, FALSE, NULL, NULL, 'Vazio = fora do menu (só como filha)', 15),
  (@t_vision, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 16);

-- vision_field
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision_field, 'nr_seq_vision', 'Visão', 'ENTITY', @t_vision, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_vision_field, 'nr_seq_table_field', 'Campo', 'ENTITY', @t_table_field, NULL, TRUE, NULL, NULL, NULL, 2),
  (@t_vision_field, 'ds_label', 'Rótulo (sobrescreve)', 'STRING', NULL, NULL, FALSE, 120, NULL, NULL, 3),
  (@t_vision_field, 'ie_component', 'Componente', 'DOMAIN', NULL, @d_component, FALSE, NULL, NULL, 'Vazio = default do tipo do campo', 4),
  (@t_vision_field, 'ie_show_in_grid', 'Na listagem', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 5),
  (@t_vision_field, 'ie_show_in_form', 'No formulário', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 6),
  (@t_vision_field, 'ie_read_only', 'Somente leitura', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 7),
  (@t_vision_field, 'ie_filter', 'É filtro', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', 'Vira filtro no cabeçalho da listagem', 8),
  (@t_vision_field, 'nr_order_grid', 'Ordem na listagem', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 9),
  (@t_vision_field, 'nr_order_form', 'Ordem no formulário', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 10),
  (@t_vision_field, 'qt_width', 'Largura relativa', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 11),
  (@t_vision_field, 'ds_format', 'Formato', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Ex.: dd/MM/yyyy', 12),
  (@t_vision_field, 'nm_ref_filter_field', 'Filtrar combo por', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Campo do form cujo valor filtra as opções deste combo', 13),
  (@t_vision_field, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 14);

-- vision_restriction
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision_restriction, 'nr_seq_vision', 'Visão', 'ENTITY', @t_vision, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_vision_restriction, 'ie_restriction_type', 'Natureza', 'DOMAIN', NULL, @d_restriction_type, TRUE, NULL, NULL, NULL, 2),
  (@t_vision_restriction, 'nm_field', 'Campo alvo', 'STRING', NULL, NULL, FALSE, 60, NULL, NULL, 3),
  (@t_vision_restriction, 'ie_operator', 'Operador', 'DOMAIN', NULL, @d_operator, FALSE, NULL, NULL, NULL, 4),
  (@t_vision_restriction, 'vl_value', 'Valor', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Literal ou variável: :usuario_id, :usuario_record, :hoje, :agora, :parent_id', 5),
  (@t_vision_restriction, 'nm_role', 'Papel exigido', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Para PERMISSION', 6),
  (@t_vision_restriction, 'ie_operation', 'Operação', 'DOMAIN', NULL, @d_operation, FALSE, NULL, NULL, NULL, 7),
  (@t_vision_restriction, 'ds_message', 'Mensagem de erro', 'STRING', NULL, NULL, FALSE, 255, NULL, 'Para VALIDATION', 8),
  (@t_vision_restriction, 'ds_expression', 'Expressão', 'STRING', NULL, NULL, FALSE, 500, NULL, 'Ex.: reps_max >= reps_min', 9),
  (@t_vision_restriction, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 10);

-- function
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_function, 'nm_function', 'Chave', 'STRING', NULL, NULL, TRUE, TRUE, 60, NULL, NULL, 1),
  (@t_function, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, FALSE, FALSE, 120, NULL, 'Texto do botão (para ACTION)', 2),
  (@t_function, 'ie_function_type', 'Tipo', 'DOMAIN', NULL, @d_function_type, TRUE, FALSE, NULL, NULL, NULL, 3),
  (@t_function, 'nr_seq_vision', 'Visão', 'ENTITY', @t_vision, NULL, FALSE, FALSE, NULL, NULL, 'Onde aparece (ACTION) ou o que protege (AUTH)', 4),
  (@t_function, 'nr_seq_table', 'Tabela', 'ENTITY', @t_tables, NULL, FALSE, FALSE, NULL, NULL, 'Tabela alvo (HOOK)', 5),
  (@t_function, 'ie_moment', 'Momento', 'DOMAIN', NULL, @d_moment, FALSE, FALSE, NULL, NULL, 'Para HOOK', 6),
  (@t_function, 'ie_placement', 'Posição', 'DOMAIN', NULL, @d_placement, FALSE, FALSE, NULL, NULL, 'Para ACTION', 7),
  (@t_function, 'nm_handler', 'Handler Java', 'STRING', NULL, NULL, TRUE, FALSE, 120, NULL, 'Nome do bean registrado no FunctionRegistry', 8),
  (@t_function, 'ie_confirm', 'Pede confirmação', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'false', NULL, 9),
  (@t_function, 'ds_success_msg', 'Mensagem de sucesso', 'STRING', NULL, NULL, FALSE, FALSE, 255, NULL, NULL, 10),
  (@t_function, 'nm_role', 'Papel mínimo', 'STRING', NULL, NULL, FALSE, FALSE, 60, NULL, NULL, 11),
  (@t_function, 'ie_active', 'Ativa', 'BOOLEAN', NULL, NULL, FALSE, FALSE, NULL, 'true', NULL, 12);

-- dashboard_widget
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_dashboard_widget, 'nr_seq_vision', 'Dashboard', 'ENTITY', @t_vision, NULL, TRUE, NULL, NULL, 'Visão de tipo DASHBOARD dona do widget', 1),
  (@t_dashboard_widget, 'ds_title', 'Título', 'STRING', NULL, NULL, TRUE, 120, NULL, NULL, 2),
  (@t_dashboard_widget, 'ie_widget_type', 'Tipo', 'DOMAIN', NULL, @d_widget_type, TRUE, NULL, NULL, NULL, 3),
  (@t_dashboard_widget, 'nr_seq_table', 'Fonte de dados', 'ENTITY', @t_tables, NULL, TRUE, NULL, NULL, NULL, 4),
  (@t_dashboard_widget, 'nm_field_x', 'Campo do eixo X', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Tipicamente um campo de data', 5),
  (@t_dashboard_widget, 'nm_fields_y', 'Série(s) do eixo Y', 'STRING', NULL, NULL, FALSE, 255, NULL, 'CSV; aceita campos calculados', 6),
  (@t_dashboard_widget, 'ie_aggregation', 'Agregação', 'DOMAIN', NULL, @d_aggregation, FALSE, NULL, NULL, NULL, 7),
  (@t_dashboard_widget, 'ie_group_by', 'Agrupamento', 'DOMAIN', NULL, @d_group_by, FALSE, NULL, NULL, NULL, 8),
  (@t_dashboard_widget, 'nm_group_field', 'Campo de agrupamento', 'STRING', NULL, NULL, FALSE, 60, NULL, 'Quando o agrupamento é Por campo', 9),
  (@t_dashboard_widget, 'ie_use_period', 'Respeita período', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 10),
  (@t_dashboard_widget, 'qt_limit', 'Limite', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, 'Para widgets de últimos registros', 11),
  (@t_dashboard_widget, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 12),
  (@t_dashboard_widget, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 13);

-- role
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, ie_required, ie_unique, qt_size, vl_default, nr_order) VALUES
  (@t_role, 'nm_role', 'Nome', 'STRING', TRUE, TRUE, 60, NULL, 1),
  (@t_role, 'ds_role', 'Descrição', 'STRING', FALSE, FALSE, 120, NULL, 2),
  (@t_role, 'ie_active', 'Ativo', 'BOOLEAN', FALSE, FALSE, NULL, 'true', 3);

-- app_user
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, ie_required, ie_unique, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_app_user, 'nm_user', 'Nome', 'STRING', NULL, TRUE, FALSE, 120, NULL, NULL, 1),
  (@t_app_user, 'cd_login', 'Login', 'STRING', NULL, TRUE, TRUE, 60, NULL, NULL, 2),
  (@t_app_user, 'ds_password_hash', 'Senha', 'PASSWORD', NULL, TRUE, FALSE, 100, NULL, 'Na edição, deixe em branco para manter a atual', 3),
  (@t_app_user, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, FALSE, NULL, 'true', 'Desativar derruba a sessão do usuário', 4),
  (@t_app_user, 'qt_failed_attempts', 'Tentativas falhas', 'INTEGER', NULL, FALSE, FALSE, NULL, '0', NULL, 5),
  (@t_app_user, 'nr_lock_level', 'Nível de bloqueio', 'INTEGER', NULL, FALSE, FALSE, NULL, '0', 'Zere para desbloquear a conta', 6),
  (@t_app_user, 'dt_locked_until', 'Bloqueada até', 'DATETIME', NULL, FALSE, FALSE, NULL, NULL, NULL, 7),
  (@t_app_user, 'nr_seq_table_ref', 'Tabela vinculada', 'ENTITY', @t_tables, FALSE, FALSE, NULL, NULL, 'Tabela de negócio do registro vinculado (ex.: pessoa)', 8),
  (@t_app_user, 'nr_seq_record', 'Registro vinculado', 'INTEGER', NULL, FALSE, FALSE, NULL, NULL, 'Id do registro de negócio deste usuário', 9);

-- user_role
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, nr_seq_table_ref, ie_required, vl_default, nr_order) VALUES
  (@t_user_role, 'nr_seq_app_user', 'Usuário', 'ENTITY', @t_app_user, TRUE, NULL, 1),
  (@t_user_role, 'nr_seq_role', 'Papel', 'ENTITY', @t_role, TRUE, NULL, 2),
  (@t_user_role, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, 'true', 3);

-- app_config
INSERT INTO `table_field` (nr_seq_table, nm_field, ds_label, ie_type, ie_required, ie_unique, qt_size, ds_hint, nr_order) VALUES
  (@t_app_config, 'nm_key', 'Chave', 'STRING', TRUE, TRUE, 60, 'app.name, theme.accent, theme.accentHover, theme.accentTint, theme.onAccent', 1),
  (@t_app_config, 'vl_value', 'Valor', 'STRING', FALSE, FALSE, 500, NULL, 2),
  (@t_app_config, 'ie_active', 'Ativa', 'BOOLEAN', FALSE, FALSE, NULL, NULL, 3);

-- ============================== menu e visões ================================

INSERT INTO `menu_group` (ds_label, nr_order) VALUES ('Framework', 99);
SET @g_framework := (SELECT nr_sequence FROM `menu_group` WHERE ds_label = 'Framework');

INSERT INTO `vision` (nm_vision, ds_title, nr_seq_table, ie_type, nr_seq_menu_group, nr_order, nm_icon, ds_icon_color) VALUES
  ('fw_dominios', 'Domínios', @t_domain, 'MASTER_DETAIL', @g_framework, 1, 'tag', '#ff9f0a'),
  ('fw_tabelas',  'Tabelas',  @t_tables, 'MASTER_DETAIL', @g_framework, 2, 'table', '#0a84ff'),
  ('fw_visoes',   'Visões',   @t_vision, 'MASTER_DETAIL', @g_framework, 3, 'screen', '#bf5af2'),
  ('fw_funcoes',  'Funções',  @t_function, 'GRID', @g_framework, 4, 'function', '#ff6482'),
  ('fw_menu',     'Menu',     @t_menu_group, 'GRID', @g_framework, 5, 'menu', '#64d2ff'),
  ('fw_usuarios', 'Usuários', @t_app_user, 'MASTER_DETAIL', @g_framework, 6, 'users', '#30d158'),
  ('fw_papeis',   'Papéis',   @t_role, 'GRID', @g_framework, 7, 'shield', '#ffd60a'),
  ('fw_config',   'Configurações', @t_app_config, 'GRID', @g_framework, 8, 'settings', '#98989d');

SET @v_dominios := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'fw_dominios');
SET @v_tabelas  := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'fw_tabelas');
SET @v_visoes   := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'fw_visoes');
SET @v_usuarios := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'fw_usuarios');

-- filhas (fora do menu: nr_order nulo)
INSERT INTO `vision` (nm_vision, ds_title, nr_seq_table, ie_type, nr_seq_vision_parent, nm_parent_fk_field) VALUES
  ('fw_dominio_valores', 'Valores do domínio', @t_domain_value, 'GRID', @v_dominios, 'nr_seq_domain'),
  ('fw_campos', 'Campos da tabela', @t_table_field, 'GRID', @v_tabelas, 'nr_seq_table'),
  ('fw_visao_campos', 'Campos da visão', @t_vision_field, 'GRID', @v_visoes, 'nr_seq_vision'),
  ('fw_visao_restricoes', 'Restrições da visão', @t_vision_restriction, 'GRID', @v_visoes, 'nr_seq_vision'),
  ('fw_visao_widgets', 'Widgets do dashboard', @t_dashboard_widget, 'GRID', @v_visoes, 'nr_seq_vision'),
  ('fw_usuario_papeis', 'Papéis do usuário', @t_user_role, 'GRID', @v_usuarios, 'nr_seq_app_user');

-- só ADMIN enxerga e mexe no dicionário
INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, nm_role, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'ADMIN', 'ALL' FROM `vision` WHERE nm_vision LIKE 'fw\_%';
