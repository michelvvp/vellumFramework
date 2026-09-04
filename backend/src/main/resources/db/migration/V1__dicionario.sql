-- Dicionário de metadados do framework (ESPECIFICACAO.md, seção 3).
-- Convenções: PK nr_sequence; FK nr_seq_<tabela>; toda tabela tem ie_active e
-- dt_created. `function` é palavra reservada no MySQL 8 — o runtime sempre
-- referencia tabelas entre crases, então o nome da especificação é mantido.

-- 3.1 domínios de valores (enums cadastráveis)
CREATE TABLE `domain` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_domain   VARCHAR(60)  NOT NULL UNIQUE,
    ds_domain   VARCHAR(255)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.2 valores de um domínio
CREATE TABLE `domain_value` (
    nr_sequence   BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_domain BIGINT       NOT NULL,
    vl_value      VARCHAR(60)  NOT NULL,
    ds_label      VARCHAR(120) NOT NULL,
    nr_order      INT          NOT NULL DEFAULT 0,
    ds_color      VARCHAR(20),
    CONSTRAINT fk_domain_value_domain FOREIGN KEY (nr_seq_domain) REFERENCES `domain` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_domain_value UNIQUE (nr_seq_domain, vl_value)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.3 entidades do sistema
CREATE TABLE `tables` (
    nr_sequence       BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_table          VARCHAR(60)  NOT NULL UNIQUE,
    ds_table          VARCHAR(120) NOT NULL,
    ds_table_plural   VARCHAR(120) NOT NULL,
    nm_label_field    VARCHAR(60),
    ie_audit          BOOLEAN      NOT NULL DEFAULT FALSE,
    ie_logical_delete BOOLEAN      NOT NULL DEFAULT FALSE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.4 campos de uma entidade
CREATE TABLE `table_field` (
    nr_sequence      BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_table     BIGINT       NOT NULL,
    nm_field         VARCHAR(60)  NOT NULL,
    ds_label         VARCHAR(120) NOT NULL,
    ie_type          VARCHAR(20)  NOT NULL, -- domínio FIELD_TYPE
    nr_seq_domain    BIGINT,                -- obrigatório quando ie_type = DOMAIN
    nr_seq_table_ref BIGINT,                -- obrigatório quando ie_type = ENTITY
    ie_required      BOOLEAN      NOT NULL DEFAULT FALSE,
    ie_unique        BOOLEAN      NOT NULL DEFAULT FALSE,
    qt_size          INT,
    qt_scale         INT,
    vl_min           VARCHAR(30),
    vl_max           VARCHAR(30),
    ds_regex         VARCHAR(255),
    vl_default       VARCHAR(255),
    ds_hint          VARCHAR(255),
    ds_formula       VARCHAR(255), -- campo calculado (não persistido, read-only)
    nr_order         INT          NOT NULL DEFAULT 0,
    CONSTRAINT fk_table_field_table FOREIGN KEY (nr_seq_table) REFERENCES `tables` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_table_field_domain FOREIGN KEY (nr_seq_domain) REFERENCES `domain` (nr_sequence),
    CONSTRAINT fk_table_field_ref FOREIGN KEY (nr_seq_table_ref) REFERENCES `tables` (nr_sequence),
    CONSTRAINT uk_table_field UNIQUE (nr_seq_table, nm_field)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.9 agrupadores da sidebar
CREATE TABLE `menu_group` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ds_label    VARCHAR(120) NOT NULL,
    nr_order    INT          NOT NULL DEFAULT 0
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.5 visões (telas) do sistema
CREATE TABLE `vision` (
    nr_sequence          BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active            BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_vision            VARCHAR(60)  NOT NULL UNIQUE,
    ds_title             VARCHAR(120) NOT NULL,
    nr_seq_table         BIGINT,                -- null permitido p/ DASHBOARD/CUSTOM
    ie_type              VARCHAR(20)  NOT NULL, -- domínio VISION_TYPE
    nr_seq_vision_parent BIGINT,
    nm_parent_fk_field   VARCHAR(60),
    ie_read_only         BOOLEAN      NOT NULL DEFAULT FALSE,
    ie_allow_create      BOOLEAN      NOT NULL DEFAULT TRUE,
    ie_allow_update      BOOLEAN      NOT NULL DEFAULT TRUE,
    ie_allow_delete      BOOLEAN      NOT NULL DEFAULT TRUE,
    nm_component         VARCHAR(120),          -- só para CUSTOM
    nm_icon              VARCHAR(60),
    ds_icon_color        VARCHAR(20),
    nr_seq_menu_group    BIGINT,
    nr_order             INT,                   -- null = fora do menu (só como filha)
    CONSTRAINT fk_vision_table FOREIGN KEY (nr_seq_table) REFERENCES `tables` (nr_sequence),
    CONSTRAINT fk_vision_parent FOREIGN KEY (nr_seq_vision_parent) REFERENCES `vision` (nr_sequence),
    CONSTRAINT fk_vision_menu_group FOREIGN KEY (nr_seq_menu_group) REFERENCES `menu_group` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.6 campos de uma visão
CREATE TABLE `vision_field` (
    nr_sequence         BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    dt_created          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_vision       BIGINT      NOT NULL,
    nr_seq_table_field  BIGINT      NOT NULL,
    ds_label            VARCHAR(120),
    ie_component        VARCHAR(30),           -- domínio COMPONENT; null = default do tipo
    ie_show_in_grid     BOOLEAN     NOT NULL DEFAULT TRUE,
    ie_show_in_form     BOOLEAN     NOT NULL DEFAULT TRUE,
    ie_read_only        BOOLEAN     NOT NULL DEFAULT FALSE,
    ie_filter           BOOLEAN     NOT NULL DEFAULT FALSE,
    nr_order_grid       INT,
    nr_order_form       INT,
    qt_width            INT,
    ds_format           VARCHAR(60),
    nm_ref_filter_field VARCHAR(60),
    CONSTRAINT fk_vision_field_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_vision_field_field FOREIGN KEY (nr_seq_table_field) REFERENCES `table_field` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_vision_field UNIQUE (nr_seq_vision, nr_seq_table_field)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.7 restrições da visão (FILTER, PERMISSION, VALIDATION)
CREATE TABLE `vision_restriction` (
    nr_sequence         BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_vision       BIGINT       NOT NULL,
    ie_restriction_type VARCHAR(20)  NOT NULL, -- domínio RESTRICTION_TYPE
    nm_field            VARCHAR(60),
    ie_operator         VARCHAR(20),           -- domínio OPERATOR
    vl_value            VARCHAR(255),          -- literal ou variável de contexto (:usuario_id...)
    nm_role             VARCHAR(60),           -- para PERMISSION
    ie_operation        VARCHAR(20),           -- READ, CREATE, UPDATE, DELETE, ALL
    ds_message          VARCHAR(255),          -- para VALIDATION
    ds_expression       VARCHAR(500),          -- validações compostas (reps_max >= reps_min)
    CONSTRAINT fk_vision_restriction_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.8 funções e ações (ACTION, HOOK, AUTH, JOB, ENDPOINT)
-- Extensão sobre a especificação: HOOKs precisam saber a tabela e o momento
-- (nr_seq_table + ie_moment: BEFORE_CREATE, AFTER_UPDATE, ...).
CREATE TABLE `function` (
    nr_sequence      BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_function      VARCHAR(60)  NOT NULL UNIQUE,
    ds_label         VARCHAR(120),
    ie_function_type VARCHAR(20)  NOT NULL, -- domínio FUNCTION_TYPE
    nr_seq_vision    BIGINT,                -- onde aparece (ACTION) ou protege (AUTH)
    nr_seq_table     BIGINT,                -- tabela alvo (HOOK)
    ie_moment        VARCHAR(20),           -- BEFORE/AFTER_CREATE/UPDATE/DELETE (HOOK)
    ie_placement     VARCHAR(20),           -- ROW ou HEADER (ACTION)
    nm_handler       VARCHAR(120) NOT NULL, -- bean Java no FunctionRegistry
    ie_confirm       BOOLEAN      NOT NULL DEFAULT FALSE,
    ds_success_msg   VARCHAR(255),
    nm_role          VARCHAR(60),
    CONSTRAINT fk_function_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_function_table FOREIGN KEY (nr_seq_table) REFERENCES `tables` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.10 widgets de uma visão DASHBOARD
CREATE TABLE `dashboard_widget` (
    nr_sequence    BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_vision  BIGINT       NOT NULL,
    ds_title       VARCHAR(120) NOT NULL,
    ie_widget_type VARCHAR(20)  NOT NULL, -- VALUE, CHART_LINE, CHART_BAR, LIST
    nr_seq_table   BIGINT       NOT NULL,
    nm_field_x     VARCHAR(60),
    nm_fields_y    VARCHAR(255),
    ie_aggregation VARCHAR(20),           -- SUM, AVG, MAX, MIN, COUNT, NONE
    ie_group_by    VARCHAR(20),           -- DAY, WEEK, MONTH, FIELD, NONE
    nm_group_field VARCHAR(60),
    ie_use_period  BOOLEAN      NOT NULL DEFAULT TRUE,
    qt_limit       INT,
    nr_order       INT          NOT NULL DEFAULT 0,
    CONSTRAINT fk_widget_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_widget_table FOREIGN KEY (nr_seq_table) REFERENCES `tables` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.9 papéis e usuários
CREATE TABLE `role` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_role     VARCHAR(60)  NOT NULL UNIQUE,
    ds_role     VARCHAR(120)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE `app_user` (
    nr_sequence        BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active          BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_user            VARCHAR(120) NOT NULL,
    cd_login           VARCHAR(60)  NOT NULL UNIQUE,
    ds_password_hash   VARCHAR(100) NOT NULL,
    qt_failed_attempts INT          NOT NULL DEFAULT 0,
    nr_lock_level      INT          NOT NULL DEFAULT 0,
    dt_locked_until    DATETIME,
    nr_seq_table_ref   BIGINT,      -- vínculo opcional com uma tabela de negócio
    nr_seq_record      BIGINT,      -- (ex.: a pessoa do gym)
    CONSTRAINT fk_app_user_table_ref FOREIGN KEY (nr_seq_table_ref) REFERENCES `tables` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE `user_role` (
    nr_sequence     BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active       BOOLEAN  NOT NULL DEFAULT TRUE,
    dt_created      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_app_user BIGINT   NOT NULL,
    nr_seq_role     BIGINT   NOT NULL,
    CONSTRAINT fk_user_role_user FOREIGN KEY (nr_seq_app_user) REFERENCES `app_user` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_role FOREIGN KEY (nr_seq_role) REFERENCES `role` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_user_role UNIQUE (nr_seq_app_user, nr_seq_role)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.9 configuração chave/valor (nome do app, 4 variáveis de tema, ...)
CREATE TABLE `app_config` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_key      VARCHAR(60)  NOT NULL UNIQUE,
    vl_value    VARCHAR(500)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
