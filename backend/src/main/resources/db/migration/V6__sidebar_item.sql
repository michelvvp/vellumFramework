-- ============================================================================
-- V6 — sidebar em três níveis: sidebar_group → sidebar_item → vision
--
-- Até aqui a visão apontava direto para o grupo (nr_seq_sidebar_group) e a
-- posição no menu era a própria nr_order da visão. Isso impede que uma entrada
-- do menu reúna várias telas. `sidebar_item` é a entrada do menu: tem rótulo,
-- ícone e cor próprios, e uma ou mais visões penduradas nela.
--
-- Ordem da migration (importa): cria o novo → copia o estado atual → só então
-- derruba as colunas antigas da visão. Produção tem visões cadastradas pela
-- tela, por isso a cópia é INSERT … SELECT, nunca lista fixa.
--
-- `nm_icon` e `ds_icon_color` FICAM em `vision`: o cabeçalho da tela usa.
-- ============================================================================

-- --------------------------- DDL ---------------------------------------------

CREATE TABLE `sidebar_item` (
    nr_sequence          BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active            BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_sidebar_group BIGINT       NOT NULL,
    ds_label             VARCHAR(120) NOT NULL,
    nm_icon              VARCHAR(60),
    ds_icon_color        VARCHAR(20),
    nr_order             INT          NOT NULL DEFAULT 0,
    -- só existe durante esta migration: casa o item criado com a visão de origem
    nr_seq_vision_origem BIGINT,
    -- item não faz sentido sem o grupo: sai junto com ele
    CONSTRAINT fk_sidebar_item_group FOREIGN KEY (nr_seq_sidebar_group) REFERENCES `sidebar_group` (nr_sequence) ON DELETE CASCADE,
    -- a sidebar lista os itens de um grupo em ordem
    INDEX ix_sidebar_item_order (nr_seq_sidebar_group, nr_order)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

ALTER TABLE `vision`
    ADD COLUMN nr_seq_sidebar_item BIGINT NULL, -- null = visão fora do menu (filha, ou só alcançada por link)
    ADD COLUMN nr_order_item       INT    NULL, -- ordem da visão dentro do item
    ADD CONSTRAINT fk_vision_sidebar_item FOREIGN KEY (nr_seq_sidebar_item) REFERENCES `sidebar_item` (nr_sequence) ON DELETE SET NULL;

-- --------------------------- cópia do estado atual ---------------------------
-- Cada visão que hoje aparece no menu (grupo e ordem preenchidos) vira um item
-- com o mesmo grupo, rótulo (ds_title), ícone, cor e ordem, e é ligada a ele.

INSERT INTO `sidebar_item` (nr_seq_sidebar_group, ds_label, nm_icon, ds_icon_color, nr_order, ie_active, nr_seq_vision_origem)
SELECT v.nr_seq_sidebar_group, v.ds_title, v.nm_icon, v.ds_icon_color, v.nr_order, v.ie_active, v.nr_sequence
  FROM `vision` v
 WHERE v.nr_seq_sidebar_group IS NOT NULL
   AND v.nr_order IS NOT NULL;

UPDATE `vision` v
  JOIN `sidebar_item` i ON i.nr_seq_vision_origem = v.nr_sequence
   SET v.nr_seq_sidebar_item = i.nr_sequence,
       v.nr_order_item = 1;

ALTER TABLE `sidebar_item` DROP COLUMN nr_seq_vision_origem;

-- --------------------------- colunas antigas ---------------------------------

ALTER TABLE `vision` DROP FOREIGN KEY fk_vision_sidebar_group;
ALTER TABLE `vision` DROP COLUMN nr_seq_sidebar_group, DROP COLUMN nr_order;

-- --------------------------- dicionário --------------------------------------
-- O boot valida dicionário × schema: os cadastros abaixo acompanham o DDL.

INSERT INTO `table` (nm_table, ds_table, ds_table_plural, nm_label_field, ie_system)
VALUES ('sidebar_item', 'Item da sidebar', 'Itens da sidebar', 'ds_label', TRUE);

SET @t_sidebar_item  := (SELECT nr_sequence FROM `table` WHERE nm_table = 'sidebar_item');
SET @t_sidebar_group := (SELECT nr_sequence FROM `table` WHERE nm_table = 'sidebar_group');
SET @t_vision        := (SELECT nr_sequence FROM `table` WHERE nm_table = 'vision');

-- nm_icon / ds_icon_color do item copiam tipo, tamanho e ajuda das colunas da visão
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, qt_size, vl_default, ds_hint, nr_order)
VALUES (@t_sidebar_item, 'nr_seq_sidebar_group', 'Grupo da sidebar', 'ENTITY', @t_sidebar_group, TRUE, NULL, NULL, NULL, 1),
       (@t_sidebar_item, 'ds_label', 'Rótulo', 'STRING', NULL, TRUE, 120, NULL, NULL, 2);

INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, qt_size, vl_default, ds_hint, nr_order)
SELECT @t_sidebar_item, c.nm_column, c.ds_label, c.ie_type, c.nr_seq_table_ref, c.ie_required, c.qt_size, c.vl_default, c.ds_hint,
       CASE c.nm_column WHEN 'nm_icon' THEN 3 ELSE 4 END
  FROM `column` c
 WHERE c.nr_seq_table = @t_vision AND c.nm_column IN ('nm_icon', 'ds_icon_color');

INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_sidebar_item, 'nr_order', 'Ordem', 'INTEGER', NULL, FALSE, NULL, '0', NULL, 5),
  (@t_sidebar_item, 'ie_active', 'Ativo', 'BOOLEAN', NULL, FALSE, NULL, 'true', NULL, 6);

-- vision: entram item e ordem no item; saem grupo e ordem
-- (ie_active da visão fica em 16; os dois novos tomam o lugar dos antigos, 14 e 15)
INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_vision, 'nr_seq_sidebar_item', 'Item da sidebar', 'ENTITY', @t_sidebar_item, FALSE, NULL, NULL, 'Vazio = fora do menu (só como filha)', 14),
  (@t_vision, 'nr_order_item', 'Ordem no item', 'INTEGER', NULL, FALSE, NULL, NULL, 'Ordem da visão dentro do item da sidebar', 15);

-- se alguma visão tem vision_column explícito para os campos antigos, os novos
-- herdam a configuração (grupo → item, ordem → ordem no item)
INSERT INTO `vision_column` (nr_seq_vision, nr_seq_column, ds_label, ie_component, ie_show_in_grid, ie_show_in_form,
                             ie_read_only, ie_filter, nr_order_grid, nr_order_form, qt_width, ds_format, nm_ref_filter_column)
SELECT vc.nr_seq_vision, nc.nr_sequence, NULL, vc.ie_component, vc.ie_show_in_grid, vc.ie_show_in_form,
       vc.ie_read_only, vc.ie_filter, vc.nr_order_grid, vc.nr_order_form, vc.qt_width, NULL, NULL
  FROM `vision_column` vc
  JOIN `column` oc ON oc.nr_sequence = vc.nr_seq_column
                  AND oc.nr_seq_table = @t_vision AND oc.nm_column IN ('nr_seq_sidebar_group', 'nr_order')
  JOIN `column` nc ON nc.nr_seq_table = @t_vision
                  AND nc.nm_column = IF(oc.nm_column = 'nr_order', 'nr_order_item', 'nr_seq_sidebar_item');

-- vision_column dos antigos sai por CASCADE da FK ao apagar a coluna
DELETE FROM `column`
 WHERE nr_seq_table = @t_vision AND nm_column IN ('nr_seq_sidebar_group', 'nr_order');

-- --------------------------- visão filha -------------------------------------
-- Filha só aparece sob pai MASTER_DETAIL, então `sidebar_groups` deixa de ser GRID.

UPDATE `vision` SET ie_type = 'MASTER_DETAIL' WHERE nm_vision = 'sidebar_groups';

SET @v_sidebar_groups := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'sidebar_groups');

INSERT INTO `vision` (nm_vision, ds_title, nr_seq_table, ie_type, nr_seq_vision_parent, nm_parent_fk_column)
VALUES ('sidebar_items', 'Itens da sidebar', @t_sidebar_item, 'GRID', @v_sidebar_groups, 'nr_seq_sidebar_group');

-- mesmas permissões das outras visões do dicionário
INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'DICTIONARY_VIEW', 'READ' FROM `vision`
 WHERE nm_vision = 'sidebar_items';

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'DICTIONARY_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision = 'sidebar_items';
