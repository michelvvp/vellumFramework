-- Dicionário de metadados do Vellum (ESPECIFICACAO.md, seção 3).
--
-- Convenções: PK nr_sequence; FK nr_seq_<tabela>; toda tabela tem ie_active e
-- dt_created.
--
-- ATENÇÃO — palavras reservadas: `table`, `column`, `index` e `constraint` são
-- reservadas no MySQL 8. O runtime referencia toda tabela entre crases, então
-- funciona; qualquer SQL escrito à mão daqui em diante também precisa das
-- crases. É o preço de chamar as coisas pelo nome certo.

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
--
-- ie_system marca as tabelas do próprio Vellum (dicionário e modelo de acesso):
-- são configuração do produto, não dado de cliente, e por isso ficam fora do
-- escopo por estabelecimento. Toda tabela de negócio (ie_system = FALSE) é
-- escopada por estabelecimento — não é opcional.
CREATE TABLE `table` (
    nr_sequence       BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_table          VARCHAR(60)  NOT NULL UNIQUE,
    ds_table          VARCHAR(120) NOT NULL,
    ds_table_plural   VARCHAR(120) NOT NULL,
    nm_label_field    VARCHAR(120),
    ie_audit          BOOLEAN      NOT NULL DEFAULT FALSE,
    ie_logical_delete BOOLEAN      NOT NULL DEFAULT FALSE,
    ie_system         BOOLEAN      NOT NULL DEFAULT FALSE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.4 colunas de uma entidade
CREATE TABLE `column` (
    nr_sequence      BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_table     BIGINT       NOT NULL,
    nm_column        VARCHAR(60)  NOT NULL,
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
    CONSTRAINT fk_column_table FOREIGN KEY (nr_seq_table) REFERENCES `table` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_column_domain FOREIGN KEY (nr_seq_domain) REFERENCES `domain` (nr_sequence),
    CONSTRAINT fk_column_ref FOREIGN KEY (nr_seq_table_ref) REFERENCES `table` (nr_sequence),
    CONSTRAINT uk_column UNIQUE (nr_seq_table, nm_column)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Índices de uma entidade. ds_columns é a lista de colunas, na ordem, separada
-- por vírgula — é dela que sai o CREATE INDEX.
CREATE TABLE `index` (
    nr_sequence  BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_table BIGINT       NOT NULL,
    nm_index     VARCHAR(64)  NOT NULL,
    ds_columns   VARCHAR(255) NOT NULL,
    ie_unique    BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_index_table FOREIGN KEY (nr_seq_table) REFERENCES `table` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_index UNIQUE (nm_index)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Constraints de uma entidade: PK, FK, UNIQUE e CHECK.
-- FOREIGN_KEY usa nr_seq_table_ref + ds_columns_ref + ie_on_delete;
-- CHECK usa ds_expression.
CREATE TABLE `constraint` (
    nr_sequence         BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_table        BIGINT       NOT NULL,
    nm_constraint       VARCHAR(64)  NOT NULL,
    ie_constraint_type  VARCHAR(20)  NOT NULL, -- domínio CONSTRAINT_TYPE
    ds_columns          VARCHAR(255),
    nr_seq_table_ref    BIGINT,                -- FOREIGN_KEY
    ds_columns_ref      VARCHAR(255),          -- FOREIGN_KEY
    ie_on_delete        VARCHAR(20),           -- domínio ON_DELETE (FOREIGN_KEY)
    ds_expression       VARCHAR(500),          -- CHECK
    CONSTRAINT fk_constraint_table FOREIGN KEY (nr_seq_table) REFERENCES `table` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_constraint_ref FOREIGN KEY (nr_seq_table_ref) REFERENCES `table` (nr_sequence),
    CONSTRAINT uk_constraint UNIQUE (nm_constraint)
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
    nm_parent_fk_column  VARCHAR(60),
    ie_read_only         BOOLEAN      NOT NULL DEFAULT FALSE,
    ie_allow_create      BOOLEAN      NOT NULL DEFAULT TRUE,
    ie_allow_update      BOOLEAN      NOT NULL DEFAULT TRUE,
    ie_allow_delete      BOOLEAN      NOT NULL DEFAULT TRUE,
    nm_component         VARCHAR(120),          -- só para CUSTOM
    nm_icon              VARCHAR(60),
    ds_icon_color        VARCHAR(20),
    nr_seq_menu_group    BIGINT,
    nr_order             INT,                   -- null = fora do menu (só como filha)
    CONSTRAINT fk_vision_table FOREIGN KEY (nr_seq_table) REFERENCES `table` (nr_sequence),
    CONSTRAINT fk_vision_parent FOREIGN KEY (nr_seq_vision_parent) REFERENCES `vision` (nr_sequence),
    CONSTRAINT fk_vision_menu_group FOREIGN KEY (nr_seq_menu_group) REFERENCES `menu_group` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.6 campos de uma visão
CREATE TABLE `vision_column` (
    nr_sequence         BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    dt_created          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_vision       BIGINT      NOT NULL,
    nr_seq_column       BIGINT      NOT NULL,
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
    nm_ref_filter_column VARCHAR(60),
    CONSTRAINT fk_vision_column_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_vision_column_column FOREIGN KEY (nr_seq_column) REFERENCES `column` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_vision_column UNIQUE (nr_seq_vision, nr_seq_column)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.7 restrições da visão (FILTER, PERMISSION, VALIDATION)
-- PERMISSION agora exige um código de `function` (catálogo de permissão), não
-- mais um papel solto.
CREATE TABLE `vision_restriction` (
    nr_sequence         BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_vision       BIGINT       NOT NULL,
    ie_restriction_type VARCHAR(20)  NOT NULL, -- domínio RESTRICTION_TYPE
    nm_column           VARCHAR(60),
    ie_operator         VARCHAR(20),           -- domínio OPERATOR
    vl_value            VARCHAR(255),          -- literal ou variável de contexto
    cd_function         VARCHAR(60),           -- para PERMISSION: function.cd_function
    ie_operation        VARCHAR(20),           -- READ, CREATE, UPDATE, DELETE, ALL
    ds_message          VARCHAR(255),          -- para VALIDATION
    ds_expression       VARCHAR(500),          -- validações compostas
    CONSTRAINT fk_vision_restriction_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.8 handlers: código Java plugado no runtime (ACTION, HOOK, AUTH, JOB, ENDPOINT).
-- Chamava-se `function` até o modelo de acesso chegar; `function` agora é o
-- catálogo de permissão (V2), e este aqui passou a se chamar pelo que é.
CREATE TABLE `handler` (
    nr_sequence     BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_handler      VARCHAR(60)  NOT NULL UNIQUE, -- chave chamada pela API
    ds_label        VARCHAR(120),
    ie_handler_type VARCHAR(20)  NOT NULL, -- domínio HANDLER_TYPE
    nr_seq_vision   BIGINT,                -- onde aparece (ACTION) ou protege (AUTH)
    nr_seq_table    BIGINT,                -- tabela alvo (HOOK)
    ie_moment       VARCHAR(20),           -- BEFORE/AFTER_CREATE/UPDATE/DELETE (HOOK)
    ie_placement    VARCHAR(20),           -- ROW ou HEADER (ACTION)
    nm_bean         VARCHAR(120) NOT NULL, -- bean Java no HandlerRegistry
    ie_confirm      BOOLEAN      NOT NULL DEFAULT FALSE,
    ds_success_msg  VARCHAR(255),
    cd_function     VARCHAR(60),           -- permissão exigida para executar
    CONSTRAINT fk_handler_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_handler_table FOREIGN KEY (nr_seq_table) REFERENCES `table` (nr_sequence)
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
    nm_column_x    VARCHAR(60),
    nm_columns_y   VARCHAR(255),
    ie_aggregation VARCHAR(20),           -- SUM, AVG, MAX, MIN, COUNT, NONE
    ie_group_by    VARCHAR(20),           -- DAY, WEEK, MONTH, FIELD, NONE
    nm_group_column VARCHAR(60),
    ie_use_period  BOOLEAN      NOT NULL DEFAULT TRUE,
    qt_limit       INT,
    nr_order       INT          NOT NULL DEFAULT 0,
    CONSTRAINT fk_widget_vision FOREIGN KEY (nr_seq_vision) REFERENCES `vision` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_widget_table FOREIGN KEY (nr_seq_table) REFERENCES `table` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3.9 configuração chave/valor (nome do app, 4 variáveis de tema, ...)
CREATE TABLE `app_config` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_key      VARCHAR(60)  NOT NULL UNIQUE,
    vl_value    VARCHAR(500)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
