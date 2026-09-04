package com.vellum.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Primeiro boot: sem nenhuma pessoa cadastrada, monta o escopo raiz —
 * grupo "Administrador", estabelecimento de mesmo nome, um perfil com todas as
 * funções do catálogo e a pessoa "admin" vinculada a ele. É de dentro desse
 * escopo que se cadastram os grupos e estabelecimentos de verdade. Depois
 * disso nunca mais mexe.
 */
@Component
@Order(1)
public class AdminSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminSeeder.class);

    private final JdbcTemplate jdbc;
    private final AuthService auth;
    private final String senhaInicial;

    public AdminSeeder(JdbcTemplate jdbc, AuthService auth,
                       @Value("${bootstrap.admin-password}") String senhaInicial) {
        this.jdbc = jdbc;
        this.auth = auth;
        this.senhaInicial = senhaInicial;
    }

    @Override
    public void run(ApplicationArguments args) {
        Integer pessoas = jdbc.queryForObject("SELECT COUNT(*) FROM `person`", Integer.class);
        if (pessoas != null && pessoas > 0) return;

        jdbc.update("INSERT INTO `group` (nm_group, ie_root) VALUES ('Administrador', TRUE)");
        Long grupoId = jdbc.queryForObject(
                "SELECT nr_sequence FROM `group` WHERE nm_group = 'Administrador'", Long.class);

        jdbc.update("INSERT INTO `establishment` (nr_seq_group, nm_establishment) VALUES (?, 'Administrador')",
                grupoId);
        Long estabId = jdbc.queryForObject(
                "SELECT nr_sequence FROM `establishment` WHERE nm_establishment = 'Administrador'", Long.class);

        // o estabelecimento raiz habilita todo o catálogo
        jdbc.update("INSERT INTO `function_establishment` (nr_seq_establishment, nr_seq_function) " +
                "SELECT ?, nr_sequence FROM `function`", estabId);

        jdbc.update("INSERT INTO `profile` (nr_seq_establishment, nm_profile) VALUES (?, 'Administrador')",
                estabId);
        Long perfilId = jdbc.queryForObject(
                "SELECT nr_sequence FROM `profile` WHERE nr_seq_establishment = ? AND nm_profile = 'Administrador'",
                Long.class, estabId);
        jdbc.update("INSERT INTO `function_profile` (nr_seq_profile, nr_seq_function) " +
                "SELECT ?, nr_sequence FROM `function`", perfilId);

        jdbc.update("INSERT INTO `person` (nm_person, cd_login, ds_password_hash) VALUES (?, ?, ?)",
                "Administrador", "admin", auth.hash(senhaInicial));
        Long pessoaId = jdbc.queryForObject(
                "SELECT nr_sequence FROM `person` WHERE cd_login = 'admin'", Long.class);

        jdbc.update("INSERT INTO `person_establishment` (nr_seq_person, nr_seq_establishment) VALUES (?, ?)",
                pessoaId, estabId);
        jdbc.update("INSERT INTO `person_profile` (nr_seq_person, nr_seq_profile) VALUES (?, ?)",
                pessoaId, perfilId);

        log.info("Escopo raiz criado: grupo/estabelecimento 'Administrador', login 'admin' " +
                "(troque a senha no primeiro acesso)");
    }
}
