-- ============================================================================
-- V5 — parâmetros de handler e o tipo de campo HANDLER_BEAN
--
-- Uma ação (handler ACTION) passa a ter parâmetros cadastráveis: o botão abre
-- um modal, coleta os valores e os manda em `params` (ex.: "convidar por CPF"
-- pede o CPF). `handler_param` define esses campos com as mesmas colunas de
-- definição de `column`, sem o que é exclusivo de coluna física (unique,
-- escala, min/max, regex, fórmula).
--
-- HANDLER_BEAN é o tipo de campo para `handler.nm_bean`: no banco continua
-- string (VARCHAR(120)); o backend o trata como popup dos beans Java existentes.
-- ============================================================================

CREATE TABLE `handler_param` (
    nr_sequence      BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_handler   BIGINT       NOT NULL,
    nm_param         VARCHAR(60)  NOT NULL, -- chave do valor dentro de `params`
    ds_label         VARCHAR(120) NOT NULL,
    ie_type          VARCHAR(20)  NOT NULL, -- domínio FIELD_TYPE
    nr_seq_domain    BIGINT,                -- obrigatório quando ie_type = DOMAIN
    nr_seq_table_ref BIGINT,                -- obrigatório quando ie_type = ENTITY
    ie_required      BOOLEAN      NOT NULL DEFAULT FALSE,
    qt_size          INT,
    vl_default       VARCHAR(255),
    ds_hint          VARCHAR(255),
    nr_order         INT          NOT NULL DEFAULT 0,
    CONSTRAINT fk_handler_param_handler FOREIGN KEY (nr_seq_handler) REFERENCES `handler` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_handler_param_domain FOREIGN KEY (nr_seq_domain) REFERENCES `domain` (nr_sequence),
    CONSTRAINT fk_handler_param_ref FOREIGN KEY (nr_seq_table_ref) REFERENCES `table` (nr_sequence),
    CONSTRAINT uk_handler_param UNIQUE (nr_seq_handler, nm_param),
    -- o modal lista os parâmetros de um handler em ordem
    INDEX ix_handler_param_order (nr_seq_handler, nr_order)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------- dicionário -------------------------------------

INSERT INTO `table` (nm_table, ds_table, ds_table_plural, nm_label_field, ie_system)
VALUES ('handler_param', 'Parâmetro', 'Parâmetros', 'ds_label', TRUE);

SET @t_handler_param := (SELECT nr_sequence FROM `table` WHERE nm_table = 'handler_param');
SET @t_handler       := (SELECT nr_sequence FROM `table` WHERE nm_table = 'handler');
SET @t_domain        := (SELECT nr_sequence FROM `table` WHERE nm_table = 'domain');
SET @t_table         := (SELECT nr_sequence FROM `table` WHERE nm_table = 'table');
SET @d_field_type    := (SELECT nr_sequence FROM `domain` WHERE nm_domain = 'FIELD_TYPE');

INSERT INTO `column` (nr_seq_table, nm_column, ds_label, ie_type, nr_seq_table_ref, nr_seq_domain, ie_required, qt_size, vl_default, ds_hint, nr_order) VALUES
  (@t_handler_param, 'nr_seq_handler', 'Handler', 'ENTITY', @t_handler, NULL, TRUE, NULL, NULL, NULL, 1),
  (@t_handler_param, 'nm_param', 'Nome', 'STRING', NULL, NULL, TRUE, 60, NULL, 'Chave do valor em params. Ex.: cpf', 2),
  (@t_handler_param, 'ds_label', 'Rótulo', 'STRING', NULL, NULL, TRUE, 120, NULL, 'Texto do campo no modal', 3),
  (@t_handler_param, 'ie_type', 'Tipo', 'DOMAIN', NULL, @d_field_type, TRUE, NULL, NULL, NULL, 4),
  (@t_handler_param, 'nr_seq_domain', 'Domínio', 'ENTITY', @t_domain, NULL, FALSE, NULL, NULL, 'Obrigatório quando o tipo é Domínio', 5),
  (@t_handler_param, 'nr_seq_table_ref', 'Tabela referenciada', 'ENTITY', @t_table, NULL, FALSE, NULL, NULL, 'Obrigatório quando o tipo é Entidade', 6),
  (@t_handler_param, 'ie_required', 'Obrigatório', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'false', NULL, 7),
  (@t_handler_param, 'qt_size', 'Tamanho', 'INTEGER', NULL, NULL, FALSE, NULL, NULL, NULL, 8),
  (@t_handler_param, 'vl_default', 'Valor padrão', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 9),
  (@t_handler_param, 'ds_hint', 'Texto de ajuda', 'STRING', NULL, NULL, FALSE, 255, NULL, NULL, 10),
  (@t_handler_param, 'nr_order', 'Ordem', 'INTEGER', NULL, NULL, FALSE, NULL, '0', NULL, 11),
  (@t_handler_param, 'ie_active', 'Ativo', 'BOOLEAN', NULL, NULL, FALSE, NULL, 'true', NULL, 12);

-- HANDLER_BEAN: novo tipo de campo; nm_bean passa a usá-lo
INSERT INTO `domain_value` (nr_seq_domain, vl_value, ds_label, nr_order)
VALUES (@d_field_type, 'HANDLER_BEAN', 'Bean de handler', 13);

UPDATE `column` SET ie_type = 'HANDLER_BEAN'
 WHERE nr_seq_table = @t_handler AND nm_column = 'nm_bean';

-- --------------------------- visão filha ------------------------------------
-- Filha só aparece sob um pai MASTER_DETAIL (como `domains` → `domain_values`),
-- então `handlers`, que era GRID, vira MASTER_DETAIL.

UPDATE `vision` SET ie_type = 'MASTER_DETAIL' WHERE nm_vision = 'handlers';

SET @v_handlers := (SELECT nr_sequence FROM `vision` WHERE nm_vision = 'handlers');

INSERT INTO `vision` (nm_vision, ds_title, nr_seq_table, ie_type, nr_seq_vision_parent, nm_parent_fk_column)
VALUES ('handler_params', 'Parâmetros do handler', @t_handler_param, 'GRID', @v_handlers, 'nr_seq_handler');

-- mesmas permissões das outras visões do dicionário
INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'DICTIONARY_VIEW', 'READ' FROM `vision`
 WHERE nm_vision = 'handler_params';

INSERT INTO `vision_restriction` (nr_seq_vision, ie_restriction_type, cd_function, ie_operation)
SELECT nr_sequence, 'PERMISSION', 'DICTIONARY_EDIT', op.ie_operation FROM `vision`
 CROSS JOIN (SELECT 'CREATE' AS ie_operation UNION ALL SELECT 'UPDATE' UNION ALL SELECT 'DELETE') op
 WHERE nm_vision = 'handler_params';
