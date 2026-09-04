-- Refinamento das telas de dogfooding: cadastra os vision_field de cada visão
-- fw_* (até aqui elas usavam o default "todos os campos"). A grid mostra só o
-- essencial, o formulário mantém tudo em ordem lógica, e os campos-chave viram
-- filtro. As próprias telas do framework passam a ser exemplo do refinamento
-- que qualquer tela cadastrada pode receber.
--
-- Colunas do bloco de dados: vis (visão), fld (campo), g (na grid),
-- f (no form), flt (é filtro), comp (componente), og/ofr (ordem grid/form).

INSERT INTO `vision_field`
    (nr_seq_vision, nr_seq_table_field, ie_show_in_grid, ie_show_in_form, ie_filter,
     ie_component, nr_order_grid, nr_order_form)
SELECT v.nr_sequence, tf.nr_sequence, d.g, d.f, d.flt, d.comp, d.og, d.ofr
FROM (
  -- ---------------- fw_dominios (domain) ----------------
  SELECT 'fw_dominios' AS vis, 'nm_domain' AS fld, 1 AS g, 1 AS f, 1 AS flt,
         CAST(NULL AS CHAR(30)) AS comp, 1 AS og, 1 AS ofr
  UNION ALL SELECT 'fw_dominios', 'ds_domain', 1, 1, 0, NULL, 2, 2
  UNION ALL SELECT 'fw_dominios', 'ie_active', 1, 1, 0, NULL, 3, 3

  -- ---------------- fw_dominio_valores (domain_value) ----------------
  UNION ALL SELECT 'fw_dominio_valores', 'nr_seq_domain', 0, 1, 0, NULL, NULL, 1
  UNION ALL SELECT 'fw_dominio_valores', 'vl_value',      1, 1, 0, NULL, 1, 2
  UNION ALL SELECT 'fw_dominio_valores', 'ds_label',      1, 1, 0, NULL, 2, 3
  UNION ALL SELECT 'fw_dominio_valores', 'nr_order',      1, 1, 0, NULL, 3, 4
  UNION ALL SELECT 'fw_dominio_valores', 'ds_color',      1, 1, 0, NULL, 4, 5
  UNION ALL SELECT 'fw_dominio_valores', 'ie_active',     1, 1, 0, NULL, 5, 6

  -- ---------------- fw_tabelas (tables) ----------------
  UNION ALL SELECT 'fw_tabelas', 'nm_table',          1, 1, 1, NULL, 1, 1
  UNION ALL SELECT 'fw_tabelas', 'ds_table',          1, 1, 0, NULL, 2, 2
  UNION ALL SELECT 'fw_tabelas', 'ds_table_plural',   1, 1, 0, NULL, 3, 3
  UNION ALL SELECT 'fw_tabelas', 'nm_label_field',    0, 1, 0, NULL, NULL, 4
  UNION ALL SELECT 'fw_tabelas', 'ie_audit',          1, 1, 0, NULL, 4, 5
  UNION ALL SELECT 'fw_tabelas', 'ie_logical_delete', 1, 1, 0, NULL, 5, 6
  UNION ALL SELECT 'fw_tabelas', 'ie_active',         1, 1, 0, NULL, 6, 7

  -- ---------------- fw_campos (table_field) ----------------
  UNION ALL SELECT 'fw_campos', 'nr_seq_table',     0, 1, 0, NULL, NULL, 1
  UNION ALL SELECT 'fw_campos', 'nm_field',         1, 1, 0, NULL, 1, 2
  UNION ALL SELECT 'fw_campos', 'ds_label',         1, 1, 0, NULL, 2, 3
  UNION ALL SELECT 'fw_campos', 'ie_type',          1, 1, 1, NULL, 3, 4
  UNION ALL SELECT 'fw_campos', 'nr_seq_domain',    0, 1, 0, NULL, NULL, 5
  UNION ALL SELECT 'fw_campos', 'nr_seq_table_ref', 0, 1, 0, NULL, NULL, 6
  UNION ALL SELECT 'fw_campos', 'ie_required',      1, 1, 0, NULL, 4, 7
  UNION ALL SELECT 'fw_campos', 'ie_unique',        1, 1, 0, NULL, 5, 8
  UNION ALL SELECT 'fw_campos', 'qt_size',          0, 1, 0, NULL, NULL, 9
  UNION ALL SELECT 'fw_campos', 'qt_scale',         0, 1, 0, NULL, NULL, 10
  UNION ALL SELECT 'fw_campos', 'vl_min',           0, 1, 0, NULL, NULL, 11
  UNION ALL SELECT 'fw_campos', 'vl_max',           0, 1, 0, NULL, NULL, 12
  UNION ALL SELECT 'fw_campos', 'ds_regex',         0, 1, 0, NULL, NULL, 13
  UNION ALL SELECT 'fw_campos', 'vl_default',       0, 1, 0, NULL, NULL, 14
  UNION ALL SELECT 'fw_campos', 'ds_hint',          0, 1, 0, NULL, NULL, 15
  UNION ALL SELECT 'fw_campos', 'ds_formula',       0, 1, 0, NULL, NULL, 16
  UNION ALL SELECT 'fw_campos', 'nr_order',         1, 1, 0, NULL, 6, 17
  UNION ALL SELECT 'fw_campos', 'ie_active',        1, 1, 0, NULL, 7, 18

  -- ---------------- fw_visoes (vision) ----------------
  UNION ALL SELECT 'fw_visoes', 'nm_vision',            1, 1, 0, NULL, 1, 1
  UNION ALL SELECT 'fw_visoes', 'ds_title',             1, 1, 0, NULL, 2, 2
  UNION ALL SELECT 'fw_visoes', 'nr_seq_table',         1, 1, 0, NULL, 3, 3
  UNION ALL SELECT 'fw_visoes', 'ie_type',              1, 1, 1, NULL, 4, 4
  UNION ALL SELECT 'fw_visoes', 'nr_seq_vision_parent', 0, 1, 0, NULL, NULL, 5
  UNION ALL SELECT 'fw_visoes', 'nm_parent_fk_field',   0, 1, 0, NULL, NULL, 6
  UNION ALL SELECT 'fw_visoes', 'ie_read_only',         0, 1, 0, NULL, NULL, 7
  UNION ALL SELECT 'fw_visoes', 'ie_allow_create',      0, 1, 0, NULL, NULL, 8
  UNION ALL SELECT 'fw_visoes', 'ie_allow_update',      0, 1, 0, NULL, NULL, 9
  UNION ALL SELECT 'fw_visoes', 'ie_allow_delete',      0, 1, 0, NULL, NULL, 10
  UNION ALL SELECT 'fw_visoes', 'nm_component',         0, 1, 0, NULL, NULL, 11
  UNION ALL SELECT 'fw_visoes', 'nm_icon',              0, 1, 0, NULL, NULL, 12
  UNION ALL SELECT 'fw_visoes', 'ds_icon_color',        0, 1, 0, NULL, NULL, 13
  UNION ALL SELECT 'fw_visoes', 'nr_seq_menu_group',    0, 1, 0, NULL, NULL, 14
  UNION ALL SELECT 'fw_visoes', 'nr_order',             1, 1, 0, NULL, 5, 15
  UNION ALL SELECT 'fw_visoes', 'ie_active',            1, 1, 0, NULL, 6, 16

  -- ---------------- fw_visao_campos (vision_field) ----------------
  UNION ALL SELECT 'fw_visao_campos', 'nr_seq_vision',       0, 1, 0, NULL, NULL, 1
  UNION ALL SELECT 'fw_visao_campos', 'nr_seq_table_field',  1, 1, 0, NULL, 1, 2
  UNION ALL SELECT 'fw_visao_campos', 'ds_label',            1, 1, 0, NULL, 2, 3
  UNION ALL SELECT 'fw_visao_campos', 'ie_component',        1, 1, 0, NULL, 3, 4
  UNION ALL SELECT 'fw_visao_campos', 'ie_show_in_grid',     1, 1, 0, NULL, 4, 5
  UNION ALL SELECT 'fw_visao_campos', 'ie_show_in_form',     1, 1, 0, NULL, 5, 6
  UNION ALL SELECT 'fw_visao_campos', 'ie_read_only',        0, 1, 0, NULL, NULL, 7
  UNION ALL SELECT 'fw_visao_campos', 'ie_filter',           1, 1, 0, NULL, 6, 8
  UNION ALL SELECT 'fw_visao_campos', 'nr_order_grid',       1, 1, 0, NULL, 7, 9
  UNION ALL SELECT 'fw_visao_campos', 'nr_order_form',       0, 1, 0, NULL, NULL, 10
  UNION ALL SELECT 'fw_visao_campos', 'qt_width',            0, 1, 0, NULL, NULL, 11
  UNION ALL SELECT 'fw_visao_campos', 'ds_format',           0, 1, 0, NULL, NULL, 12
  UNION ALL SELECT 'fw_visao_campos', 'nm_ref_filter_field', 0, 1, 0, NULL, NULL, 13
  UNION ALL SELECT 'fw_visao_campos', 'ie_active',           0, 1, 0, NULL, NULL, 14

  -- ---------------- fw_visao_restricoes (vision_restriction) ----------------
  UNION ALL SELECT 'fw_visao_restricoes', 'nr_seq_vision',       0, 1, 0, NULL, NULL, 1
  UNION ALL SELECT 'fw_visao_restricoes', 'ie_restriction_type', 1, 1, 0, NULL, 1, 2
  UNION ALL SELECT 'fw_visao_restricoes', 'nm_field',            1, 1, 0, NULL, 2, 3
  UNION ALL SELECT 'fw_visao_restricoes', 'ie_operator',         1, 1, 0, NULL, 3, 4
  UNION ALL SELECT 'fw_visao_restricoes', 'vl_value',            1, 1, 0, NULL, 4, 5
  UNION ALL SELECT 'fw_visao_restricoes', 'nm_role',             1, 1, 0, NULL, 5, 6
  UNION ALL SELECT 'fw_visao_restricoes', 'ie_operation',        1, 1, 0, NULL, 6, 7
  UNION ALL SELECT 'fw_visao_restricoes', 'ds_message',          0, 1, 0, NULL, NULL, 8
  UNION ALL SELECT 'fw_visao_restricoes', 'ds_expression',       0, 1, 0, NULL, NULL, 9
  UNION ALL SELECT 'fw_visao_restricoes', 'ie_active',           1, 1, 0, NULL, 7, 10

  -- ---------------- fw_visao_widgets (dashboard_widget) ----------------
  UNION ALL SELECT 'fw_visao_widgets', 'nr_seq_vision',  0, 1, 0, NULL, NULL, 1
  UNION ALL SELECT 'fw_visao_widgets', 'ds_title',       1, 1, 0, NULL, 1, 2
  UNION ALL SELECT 'fw_visao_widgets', 'ie_widget_type', 1, 1, 0, NULL, 2, 3
  UNION ALL SELECT 'fw_visao_widgets', 'nr_seq_table',   1, 1, 0, NULL, 3, 4
  UNION ALL SELECT 'fw_visao_widgets', 'nm_field_x',     0, 1, 0, NULL, NULL, 5
  UNION ALL SELECT 'fw_visao_widgets', 'nm_fields_y',    0, 1, 0, NULL, NULL, 6
  UNION ALL SELECT 'fw_visao_widgets', 'ie_aggregation', 1, 1, 0, NULL, 4, 7
  UNION ALL SELECT 'fw_visao_widgets', 'ie_group_by',    1, 1, 0, NULL, 5, 8
  UNION ALL SELECT 'fw_visao_widgets', 'nm_group_field', 0, 1, 0, NULL, NULL, 9
  UNION ALL SELECT 'fw_visao_widgets', 'ie_use_period',  0, 1, 0, NULL, NULL, 10
  UNION ALL SELECT 'fw_visao_widgets', 'qt_limit',       0, 1, 0, NULL, NULL, 11
  UNION ALL SELECT 'fw_visao_widgets', 'nr_order',       1, 1, 0, NULL, 6, 12
  UNION ALL SELECT 'fw_visao_widgets', 'ie_active',      0, 1, 0, NULL, NULL, 13

  -- ---------------- fw_funcoes (function) ----------------
  UNION ALL SELECT 'fw_funcoes', 'nm_function',      1, 1, 0, NULL, 1, 1
  UNION ALL SELECT 'fw_funcoes', 'ds_label',         0, 1, 0, NULL, NULL, 2
  UNION ALL SELECT 'fw_funcoes', 'ie_function_type', 1, 1, 1, NULL, 2, 3
  UNION ALL SELECT 'fw_funcoes', 'nr_seq_vision',    0, 1, 0, NULL, NULL, 4
  UNION ALL SELECT 'fw_funcoes', 'nr_seq_table',     0, 1, 0, NULL, NULL, 5
  UNION ALL SELECT 'fw_funcoes', 'ie_moment',        0, 1, 0, NULL, NULL, 6
  UNION ALL SELECT 'fw_funcoes', 'ie_placement',     0, 1, 0, NULL, NULL, 7
  UNION ALL SELECT 'fw_funcoes', 'nm_handler',       1, 1, 0, NULL, 3, 8
  UNION ALL SELECT 'fw_funcoes', 'ie_confirm',       0, 1, 0, NULL, NULL, 9
  UNION ALL SELECT 'fw_funcoes', 'ds_success_msg',   0, 1, 0, NULL, NULL, 10
  UNION ALL SELECT 'fw_funcoes', 'nm_role',          1, 1, 0, NULL, 4, 11
  UNION ALL SELECT 'fw_funcoes', 'ie_active',        1, 1, 0, NULL, 5, 12

  -- ---------------- fw_usuarios (app_user) ----------------
  UNION ALL SELECT 'fw_usuarios', 'nm_user',            1, 1, 1, NULL, 1, 1
  UNION ALL SELECT 'fw_usuarios', 'cd_login',           1, 1, 0, NULL, 2, 2
  UNION ALL SELECT 'fw_usuarios', 'ds_password_hash',   0, 1, 0, NULL, NULL, 3
  UNION ALL SELECT 'fw_usuarios', 'ie_active',          1, 1, 0, NULL, 3, 4
  UNION ALL SELECT 'fw_usuarios', 'qt_failed_attempts', 0, 1, 0, NULL, NULL, 5
  UNION ALL SELECT 'fw_usuarios', 'nr_lock_level',      1, 1, 0, NULL, 4, 6
  UNION ALL SELECT 'fw_usuarios', 'dt_locked_until',    0, 1, 0, NULL, NULL, 7
  UNION ALL SELECT 'fw_usuarios', 'nr_seq_table_ref',   0, 1, 0, NULL, NULL, 8
  UNION ALL SELECT 'fw_usuarios', 'nr_seq_record',      0, 1, 0, NULL, NULL, 9

  -- ---------------- fw_usuario_papeis (user_role) ----------------
  -- MULTI_SELECT: o botão "Selecionar…" marca papéis numa lista de switches
  UNION ALL SELECT 'fw_usuario_papeis', 'nr_seq_app_user', 0, 1, 0, NULL, NULL, 1
  UNION ALL SELECT 'fw_usuario_papeis', 'nr_seq_role',     1, 1, 0, 'MULTI_SELECT', 1, 2
  UNION ALL SELECT 'fw_usuario_papeis', 'ie_active',       1, 1, 0, NULL, 2, 3
) d
JOIN `vision` v ON v.nm_vision = d.vis
JOIN `table_field` tf ON tf.nr_seq_table = v.nr_seq_table AND tf.nm_field = d.fld;

-- fw_menu, fw_papeis e fw_config ficam no default (3 campos cada — a visão
-- gerada automaticamente já é a tela certa; cadastrar vision_field ali seria
-- a "armadilha do meta-framework" da seção 9 da especificação).
