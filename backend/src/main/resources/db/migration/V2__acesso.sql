-- Modelo de acesso do Vellum: multi-estabelecimento com permissão por função.
--
-- Hierarquia: group 1:N establishment. Todo estabelecimento nasce dentro de um
-- grupo (grupo de um só, quando não há rede) — assim consolidar por rede um dia
-- é tela e query, nunca migração de dados.
--
-- Permissão: `function` é o catálogo global de códigos do sistema. O
-- estabelecimento habilita um subconjunto (function_establishment) e cada
-- perfil libera um subconjunto do que o estabelecimento habilitou
-- (function_profile). O efetivo é a INTERSEÇÃO das duas — desabilitar no
-- estabelecimento tem que matar em todos os perfis, senão vira furo.
--
-- Pessoa: person_establishment diz onde ela pode entrar (no login, uma unidade
-- entra direto, várias abrem a escolha). person_profile concede perfis, e a
-- pessoa soma as funções de todos os perfis dela no estabelecimento ativo —
-- não há troca de perfil na interface. Conceder um perfil de estabelecimento
-- onde a pessoa não tem vínculo é recusado pelo runtime: sem isso um perfil do
-- estabelecimento B entraria pela porta do A.

CREATE TABLE `group` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_group    VARCHAR(120) NOT NULL UNIQUE,
    ie_root     BOOLEAN      NOT NULL DEFAULT FALSE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ds_primary_color é a identidade visual: só a cor da marca é guardada; hover,
-- tint e cor de texto derivam dela na tela.
--
-- nr_permission_version sobe a cada mudança em function_establishment ou
-- function_profile e viaja dentro do token. Token com versão velha é recusado,
-- o que faz a alteração de permissão valer na hora em vez de esperar a sessão
-- expirar.
CREATE TABLE `establishment` (
    nr_sequence           BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active             BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_group          BIGINT       NOT NULL,
    nm_establishment      VARCHAR(120) NOT NULL UNIQUE,
    cd_document           VARCHAR(14),
    ds_primary_color      VARCHAR(7)   NOT NULL DEFAULT '#0a84ff',
    nr_permission_version INT          NOT NULL DEFAULT 1,
    CONSTRAINT fk_establishment_group FOREIGN KEY (nr_seq_group) REFERENCES `group` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Catálogo global de permissões. cd_function é o que aparece no token e nas
-- checagens; nm_module só agrupa as caixinhas na tela.
CREATE TABLE `function` (
    nr_sequence BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cd_function VARCHAR(60)  NOT NULL UNIQUE,
    ds_function VARCHAR(120) NOT NULL,
    nm_module   VARCHAR(60)  NOT NULL,
    nr_order    INT          NOT NULL DEFAULT 0
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE `function_establishment` (
    nr_sequence        BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active          BOOLEAN  NOT NULL DEFAULT TRUE,
    dt_created         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_function    BIGINT   NOT NULL,
    nr_seq_establishment BIGINT NOT NULL,
    CONSTRAINT fk_fe_function FOREIGN KEY (nr_seq_function) REFERENCES `function` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_fe_establishment FOREIGN KEY (nr_seq_establishment) REFERENCES `establishment` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_function_establishment UNIQUE (nr_seq_function, nr_seq_establishment)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE `profile` (
    nr_sequence          BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active            BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_establishment BIGINT       NOT NULL,
    nm_profile           VARCHAR(120) NOT NULL,
    CONSTRAINT fk_profile_establishment FOREIGN KEY (nr_seq_establishment) REFERENCES `establishment` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_profile UNIQUE (nr_seq_establishment, nm_profile)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE `function_profile` (
    nr_sequence     BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active       BOOLEAN  NOT NULL DEFAULT TRUE,
    dt_created      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_function BIGINT   NOT NULL,
    nr_seq_profile  BIGINT   NOT NULL,
    CONSTRAINT fk_fp_function FOREIGN KEY (nr_seq_function) REFERENCES `function` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_fp_profile FOREIGN KEY (nr_seq_profile) REFERENCES `profile` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_function_profile UNIQUE (nr_seq_function, nr_seq_profile)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Quem entra no sistema. nr_seq_table_ref + nr_seq_record ligam a pessoa a um
-- registro de negócio (ex.: o cliente, o funcionário), quando existir.
CREATE TABLE `person` (
    nr_sequence        BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active          BOOLEAN      NOT NULL DEFAULT TRUE,
    dt_created         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nm_person          VARCHAR(120) NOT NULL,
    cd_login           VARCHAR(60)  NOT NULL UNIQUE,
    ds_password_hash   VARCHAR(100) NOT NULL,
    qt_failed_attempts INT          NOT NULL DEFAULT 0,
    nr_lock_level      INT          NOT NULL DEFAULT 0,
    dt_locked_until    DATETIME,
    nr_seq_table_ref   BIGINT,
    nr_seq_record      BIGINT,
    CONSTRAINT fk_person_table_ref FOREIGN KEY (nr_seq_table_ref) REFERENCES `table` (nr_sequence)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Onde a pessoa pode entrar. Mais de um: o login pergunta qual.
CREATE TABLE `person_establishment` (
    nr_sequence          BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active            BOOLEAN  NOT NULL DEFAULT TRUE,
    dt_created           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_person        BIGINT   NOT NULL,
    nr_seq_establishment BIGINT   NOT NULL,
    CONSTRAINT fk_pe_person FOREIGN KEY (nr_seq_person) REFERENCES `person` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_pe_establishment FOREIGN KEY (nr_seq_establishment) REFERENCES `establishment` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_person_establishment UNIQUE (nr_seq_person, nr_seq_establishment)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Perfis concedidos. O estabelecimento sai do perfil; guardá-lo aqui também
-- abriria a chance de um vínculo apontar para o estabelecimento A com um perfil
-- do B. A coerência com person_establishment é validada no runtime.
CREATE TABLE `person_profile` (
    nr_sequence    BIGINT AUTO_INCREMENT PRIMARY KEY,
    ie_active      BOOLEAN  NOT NULL DEFAULT TRUE,
    dt_created     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nr_seq_person  BIGINT   NOT NULL,
    nr_seq_profile BIGINT   NOT NULL,
    CONSTRAINT fk_pp_person FOREIGN KEY (nr_seq_person) REFERENCES `person` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT fk_pp_profile FOREIGN KEY (nr_seq_profile) REFERENCES `profile` (nr_sequence) ON DELETE CASCADE,
    CONSTRAINT uk_person_profile UNIQUE (nr_seq_person, nr_seq_profile)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
