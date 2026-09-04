package com.vellum.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;

/**
 * Primeiro boot: sem nenhum usuário cadastrado, cria o papel ADMIN e o usuário
 * "admin" (senha em bootstrap.admin-password, default "admin") para dar acesso
 * às telas de dogfooding do dicionário. Depois disso nunca mais mexe.
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
        Integer usuarios = jdbc.queryForObject("SELECT COUNT(*) FROM `app_user`", Integer.class);
        if (usuarios != null && usuarios > 0) return;

        jdbc.update("INSERT IGNORE INTO `role` (nm_role, ds_role) VALUES ('ADMIN', 'Administrador do sistema')");
        Long roleId = jdbc.queryForObject("SELECT nr_sequence FROM `role` WHERE nm_role = 'ADMIN'", Long.class);
        jdbc.update("INSERT INTO `app_user` (nm_user, cd_login, ds_password_hash) VALUES (?, ?, ?)",
                "Administrador", "admin", auth.hash(senhaInicial));
        Long userId = jdbc.queryForObject("SELECT nr_sequence FROM `app_user` WHERE cd_login = 'admin'", Long.class);
        jdbc.update("INSERT INTO `user_role` (nr_seq_app_user, nr_seq_role) VALUES (?, ?)", userId, roleId);
        log.info("Usuário inicial criado: login 'admin' (troque a senha no primeiro acesso)");
    }
}
