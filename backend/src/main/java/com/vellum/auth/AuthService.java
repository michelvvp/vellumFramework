package com.vellum.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Login + senha sobre a tabela app_user do dicionário. A senha nunca é
 * persistida — apenas o hash bcrypt. O token de sessão é
 * "id.emitidoEm.assinatura" com HMAC-SHA256 do segredo do servidor:
 * stateless, sem expiração — a sessão dura até o logoff no cliente.
 * Proteção contra força bruta idêntica à do gym: 4 erros bloqueiam por
 * 30 min; depois cada erro escala (1h, 3h, 12h, 1 dia) até o bloqueio
 * definitivo, que só um administrador desfaz.
 */
@Service
public class AuthService {

    private final JdbcTemplate jdbc;
    private final BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder();
    private final byte[] segredo;

    private static final Duration[] BLOQUEIOS = {
            Duration.ofMinutes(30), Duration.ofHours(1), Duration.ofHours(3),
            Duration.ofHours(12), Duration.ofDays(1),
    };
    private static final int NIVEL_DEFINITIVO = BLOQUEIOS.length + 1; // 6
    private static final int TENTATIVAS_LIVRES = 4;

    public AuthService(JdbcTemplate jdbc, @Value("${auth.token-secret}") String segredo) {
        this.jdbc = jdbc;
        this.segredo = segredo.getBytes(StandardCharsets.UTF_8);
    }

    public CurrentUser autenticar(String login, String senha) {
        if (login == null || senha == null) throw credenciaisInvalidas();
        Map<String, Object> u;
        try {
            u = jdbc.queryForMap("SELECT * FROM `app_user` WHERE cd_login = ?", login.trim());
        } catch (EmptyResultDataAccessException e) {
            throw credenciaisInvalidas();
        }
        long id = ((Number) u.get("nr_sequence")).longValue();

        // conta desligada não se distingue de login inexistente para quem tenta entrar
        if (!bool(u.get("ie_active"))) throw credenciaisInvalidas();

        int nivel = ((Number) u.get("nr_lock_level")).intValue();
        if (nivel >= NIVEL_DEFINITIVO)
            throw new ResponseStatusException(HttpStatus.LOCKED,
                    "Conta bloqueada definitivamente por excesso de tentativas — peça a um administrador para desbloquear.");
        Object ate = u.get("dt_locked_until");
        if (ate != null) {
            LocalDateTime limite = ((java.sql.Timestamp) ate).toLocalDateTime();
            if (LocalDateTime.now().isBefore(limite))
                throw new ResponseStatusException(HttpStatus.LOCKED,
                        "Conta bloqueada por excesso de tentativas. Tente de novo " + quando(limite) + ".");
        }

        if (!bcrypt.matches(senha, (String) u.get("ds_password_hash"))) {
            registrarFalha(id, nivel, ((Number) u.get("qt_failed_attempts")).intValue());
            throw credenciaisInvalidas();
        }

        jdbc.update("UPDATE `app_user` SET qt_failed_attempts = 0, nr_lock_level = 0, dt_locked_until = NULL " +
                "WHERE nr_sequence = ?", id);
        return carregar(id).orElseThrow(AuthService::credenciaisInvalidas);
    }

    private void registrarFalha(long id, int nivel, int tentativas) {
        if (nivel == 0) {
            int novas = tentativas + 1;
            if (novas >= TENTATIVAS_LIVRES) {
                jdbc.update("UPDATE `app_user` SET qt_failed_attempts = ?, nr_lock_level = 1, dt_locked_until = ? " +
                        "WHERE nr_sequence = ?", novas, LocalDateTime.now().plus(BLOQUEIOS[0]), id);
            } else {
                jdbc.update("UPDATE `app_user` SET qt_failed_attempts = ? WHERE nr_sequence = ?", novas, id);
            }
        } else {
            // já esteve bloqueada: agora é uma tentativa por vez, escalando o nível
            int novo = nivel + 1;
            LocalDateTime ate = novo >= NIVEL_DEFINITIVO ? null : LocalDateTime.now().plus(BLOQUEIOS[novo - 1]);
            jdbc.update("UPDATE `app_user` SET nr_lock_level = ?, dt_locked_until = ? WHERE nr_sequence = ?",
                    novo, ate, id);
        }
    }

    public String gerarToken(CurrentUser user) {
        String corpo = user.id() + "." + System.currentTimeMillis();
        return corpo + "." + assinar(corpo);
    }

    /** Valida assinatura e devolve o usuário do token (se ainda existir e estiver ativo). */
    public Optional<CurrentUser> validarToken(String token) {
        if (token == null) return Optional.empty();
        int corte = token.lastIndexOf('.');
        if (corte <= 0) return Optional.empty();
        String corpo = token.substring(0, corte);
        String assinatura = token.substring(corte + 1);
        if (!MessageDigest.isEqual(assinar(corpo).getBytes(StandardCharsets.UTF_8),
                assinatura.getBytes(StandardCharsets.UTF_8))) return Optional.empty();
        try {
            long id = Long.parseLong(corpo.substring(0, corpo.indexOf('.')));
            return carregar(id);
        } catch (RuntimeException e) {
            return Optional.empty();
        }
    }

    /** Carrega usuário ativo + papéis; inativar derruba na hora quem já estava logado. */
    public Optional<CurrentUser> carregar(long id) {
        try {
            Map<String, Object> u = jdbc.queryForMap(
                    "SELECT * FROM `app_user` WHERE nr_sequence = ? AND ie_active", id);
            Set<String> roles = new HashSet<>(jdbc.queryForList(
                    "SELECT r.nm_role FROM `user_role` ur JOIN `role` r ON r.nr_sequence = ur.nr_seq_role " +
                    "WHERE ur.nr_seq_app_user = ? AND ur.ie_active AND r.ie_active", String.class, id));
            return Optional.of(new CurrentUser(id, (String) u.get("nm_user"), (String) u.get("cd_login"),
                    roles,
                    u.get("nr_seq_table_ref") == null ? null : ((Number) u.get("nr_seq_table_ref")).longValue(),
                    u.get("nr_seq_record") == null ? null : ((Number) u.get("nr_seq_record")).longValue()));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public String hash(String senha) {
        return bcrypt.encode(senha);
    }

    private String assinar(String corpo) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(segredo, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal(corpo.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("falha ao assinar token", e);
        }
    }

    private static ResponseStatusException credenciaisInvalidas() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Login ou senha incorretos");
    }

    private static String quando(LocalDateTime ate) {
        long min = Math.max(1, Duration.between(LocalDateTime.now(), ate).toMinutes());
        if (min < 60) return "em " + min + " min";
        return "às " + ate.format(DateTimeFormatter.ofPattern("HH:mm 'de' dd/MM"));
    }

    private static boolean bool(Object o) {
        return o != null && (o instanceof Boolean b ? b : ((Number) o).intValue() != 0);
    }
}
