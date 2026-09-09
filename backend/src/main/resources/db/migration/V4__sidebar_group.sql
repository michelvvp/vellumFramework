-- ============================================================================
-- V4 — "menu_group" vira "sidebar_group" e ganha o recolhimento
--
-- O agrupador é nomeado pelo lugar onde aparece (a sidebar), não por "menu":
-- a tabbar do mobile também consome as mesmas visões e nunca foi um menu.
--
-- `ie_collapsible` diz como o grupo se comporta na sidebar:
--   FALSE (padrão) — rótulo fixo, itens sempre à mostra (o que sempre foi);
--   TRUE           — o rótulo vira botão com seta, o grupo nasce recolhido e
--                    um clique abre.
-- ============================================================================

RENAME TABLE `menu_group` TO `sidebar_group`;

ALTER TABLE `vision` DROP FOREIGN KEY fk_vision_menu_group;
ALTER TABLE `vision` CHANGE COLUMN nr_seq_menu_group nr_seq_sidebar_group BIGINT;
ALTER TABLE `vision` ADD CONSTRAINT fk_vision_sidebar_group
    FOREIGN KEY (nr_seq_sidebar_group) REFERENCES `sidebar_group` (nr_sequence);

ALTER TABLE `sidebar_group`
    ADD COLUMN ie_collapsible BOOLEAN NOT NULL DEFAULT FALSE AFTER nr_order;

-- --------------------------- dicionário -------------------------------------
-- O boot valida dicionário × schema: os cadastros abaixo acompanham o DDL.

UPDATE `table`
   SET nm_table = 'sidebar_group',
       ds_table = 'Grupo da sidebar',
       ds_table_plural = 'Grupos da sidebar'
 WHERE nm_table = 'menu_group';

SET @t_sidebar_group := (SELECT nr_sequence FROM `table` WHERE nm_table = 'sidebar_group');
SET @t_vision        := (SELECT nr_sequence FROM `table` WHERE nm_table = 'vision');

UPDATE `column`
   SET nm_column = 'nr_seq_sidebar_group', ds_label = 'Grupo da sidebar'
 WHERE nr_seq_table = @t_vision AND nm_column = 'nr_seq_menu_group';

-- ie_active desce para o fim; o recolhimento entra junto das outras opções
UPDATE `column` SET nr_order = 4
 WHERE nr_seq_table = @t_sidebar_group AND nm_column = 'ie_active';

INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, ie_required, vl_default, ds_hint, nr_order) VALUES
  (@t_sidebar_group, 'ie_collapsible', 'Recolhível', 'BOOLEAN', FALSE, 'false',
   'Marcado, o grupo nasce fechado na sidebar e abre com um clique', 3);

UPDATE `vision`
   SET nm_vision = 'sidebar_groups', ds_title = 'Grupos da sidebar'
 WHERE nm_vision = 'menu_groups';
