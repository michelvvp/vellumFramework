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
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Login sobre a tabela `person`. A senha nunca é persistida — apenas o hash
 * bcrypt.
 *
 * O token é "personId.establishmentId.permissionVersion.emitidoEm.assinatura",
 * assinado com HMAC-SHA256 do segredo do servidor: stateless, sem expiração —
 * a sessão dura até o logoff. establishmentId = 0 é o token de escolha, emitido
 * quando a pessoa tem mais de um estabelecimento: só serve para listar e
 * escolher, e o AuthTokenFilter barra o resto da API com ele.
 *
 * A permissão efetiva no estabelecimento ativo é a INTERSEÇÃO entre o que os
 * perfis da pessoa liberam e o que o estabelecimento habilita. Mudar qualquer
 * uma das duas pontas sobe a nr_permission_version do estabelecimento, e o
 * token emitido antes disso passa a ser recusado — a alteração de permissão
 * vale na hora, sem esperar a sessão morrer.
 *
 * Força bruta: 4 erros bloqueiam por 30 min; depois cada erro escala (1h, 3h,
 * 12h, 1 dia) até o bloqueio definitivo, que só um administrador desfaz.
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

    public record Establishment(long id, String name, String color) {}

    public AuthService(JdbcTemplate jdbc, @Value("${auth.token-secret}") String segredo) {
        this.jdbc = jdbc;
        this.segredo = segredo.getBytes(StandardCharsets.UTF_8);
    }

    /* ================================ login ================================= */

    /** Confere as credenciais e devolve o id da pessoa. Não escolhe estabelecimento. */
    public long autenticar(String login, String senha) {
        if (login == null || senha == null) throw credenciaisInvalidas();
        Map<String, Object> u;
        try {
            u = jdbc.queryForMap("SELECT * FROM `person` WHERE cd_login = ?", login.trim());
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

        jdbc.update("UPDATE `person` SET qt_failed_attempts = 0, nr_lock_level = 0, dt_locked_until = NULL " +
                "WHERE nr_sequence = ?", id);
        return id;
    }

    /** Estabelecimentos ativos em que a pessoa pode entrar. */
    public List<Establishment> estabelecimentos(long personId) {
        return jdbc.query(
                "SELECT e.nr_sequence, e.nm_establishment, e.ds_primary_color " +
                "FROM `person_establishment` pe " +
                "JOIN `establishment` e ON e.nr_sequence = pe.nr_seq_establishment AND e.ie_active " +
                "WHERE pe.nr_seq_person = ? AND pe.ie_active " +
                "ORDER BY e.nm_establishment",
                (rs, i) -> new Establishment(rs.getLong("nr_sequence"),
                        rs.getString("nm_establishment"), rs.getString("ds_primary_color")),
                personId);
    }

    /**
     * Entra num estabelecimento. Recusa se a pessoa não tiver vínculo com ele —
     * é aqui que a lista de person_establishment vira a fronteira de verdade.
     */
    public CurrentUser entrar(long personId, long establishmentId) {
        boolean vinculada = estabelecimentos(personId).stream().anyMatch(e -> e.id() == establishmentId);
        if (!vinculada) throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "sem vínculo com este estabelecimento");
        return carregar(personId, establishmentId)
                .orElseThrow(AuthService::credenciaisInvalidas);
    }

    private void registrarFalha(long id, int nivel, int tentativas) {
        if (nivel == 0) {
            int novas = tentativas + 1;
            if (novas >= TENTATIVAS_LIVRES) {
                jdbc.update("UPDATE `person` SET qt_failed_attempts = ?, nr_lock_level = 1, dt_locked_until = ? " +
                        "WHERE nr_sequence = ?", novas, LocalDateTime.now().plus(BLOQUEIOS[0]), id);
            } else {
                jdbc.update("UPDATE `person` SET qt_failed_attempts = ? WHERE nr_sequence = ?", novas, id);
            }
        } else {
            // já esteve bloqueada: agora é uma tentativa por vez, escalando o nível
            int novo = nivel + 1;
            LocalDateTime ate = novo >= NIVEL_DEFINITIVO ? null : LocalDateTime.now().plus(BLOQUEIOS[novo - 1]);
            jdbc.update("UPDATE `person` SET nr_lock_level = ?, dt_locked_until = ? WHERE nr_sequence = ?",
                    novo, ate, id);
        }
    }

    /* ================================ token ================================= */

    public String gerarToken(CurrentUser user) {
        String corpo = user.id() + "." + user.establishmentId() + "." + user.permissionVersion()
                + "." + System.currentTimeMillis();
        return corpo + "." + assinar(corpo);
    }

    /** Token de escolha de estabelecimento: identifica a pessoa e não dá mais nada. */
    public String gerarTokenDeEscolha(long personId) {
        String corpo = personId + ".0.0." + System.currentTimeMillis();
        return corpo + "." + assinar(corpo);
    }

    /**
     * Valida assinatura e devolve a pessoa do token. Recusa quando a conta foi
     * desativada, quando o vínculo com o estabelecimento sumiu, ou quando a
     * permissão do estabelecimento mudou desde a emissão.
     */
    public Optional<CurrentUser> validarToken(String token) {
        if (token == null) return Optional.empty();
        int corte = token.lastIndexOf('.');
        if (corte <= 0) return Optional.empty();
        String corpo = token.substring(0, corte);
        String assinatura = token.substring(corte + 1);
        if (!MessageDigest.isEqual(assinar(corpo).getBytes(StandardCharsets.UTF_8),
                assinatura.getBytes(StandardCharsets.UTF_8))) return Optional.empty();

        String[] partes = corpo.split("\\.");
        if (partes.length != 4) return Optional.empty();
        try {
            long personId = Long.parseLong(partes[0]);
            long establishmentId = Long.parseLong(partes[1]);
            int versao = Integer.parseInt(partes[2]);

            if (establishmentId == 0) return carregarSemEstabelecimento(personId);

            // vínculo pode ter sido removido depois da emissão
            if (estabelecimentos(personId).stream().noneMatch(e -> e.id() == establishmentId))
                return Optional.empty();
            Integer atual = jdbc.queryForObject(
                    "SELECT nr_permission_version FROM `establishment` WHERE nr_sequence = ? AND ie_active",
                    Integer.class, establishmentId);
            if (atual == null || atual != versao) return Optional.empty();

            return carregar(personId, establishmentId);
        } catch (RuntimeException e) {
            return Optional.empty();
        }
    }

    /* =============================== carga ================================== */

    /** Pessoa ativa + permissão efetiva no estabelecimento. */
    public Optional<CurrentUser> carregar(long personId, long establishmentId) {
        try {
            Map<String, Object> u = jdbc.queryForMap(
                    "SELECT * FROM `person` WHERE nr_sequence = ? AND ie_active", personId);
            Map<String, Object> e = jdbc.queryForMap(
                    "SELECT nm_establishment, nr_permission_version FROM `establishment` " +
                    "WHERE nr_sequence = ? AND ie_active", establishmentId);
            return Optional.of(new CurrentUser(personId,
                    (String) u.get("nm_person"), (String) u.get("cd_login"),
                    establishmentId, (String) e.get("nm_establishment"),
                    ((Number) e.get("nr_permission_version")).intValue(),
                    funcoes(personId, establishmentId),
                    numero(u.get("nr_seq_table_ref")), numero(u.get("nr_seq_record"))));
        } catch (EmptyResultDataAccessException ex) {
            return Optional.empty();
        }
    }

    private Optional<CurrentUser> carregarSemEstabelecimento(long personId) {
        try {
            Map<String, Object> u = jdbc.queryForMap(
                    "SELECT * FROM `person` WHERE nr_sequence = ? AND ie_active", personId);
            return Optional.of(new CurrentUser(personId,
                    (String) u.get("nm_person"), (String) u.get("cd_login"),
                    0, null, 0, Set.of(),
                    numero(u.get("nr_seq_table_ref")), numero(u.get("nr_seq_record"))));
        } catch (EmptyResultDataAccessException ex) {
            return Optional.empty();
        }
    }

    /**
     * Funções efetivas: união dos perfis da pessoa NESTE estabelecimento,
     * interseccionada com as funções que o estabelecimento habilita. Um perfil
     * de outro estabelecimento não entra na conta — é o join com profile que
     * garante isso.
     */
    public Set<String> funcoes(long personId, long establishmentId) {
        return new HashSet<>(jdbc.queryForList(
                "SELECT DISTINCT f.cd_function " +
                "FROM `person_profile` pp " +
                "JOIN `profile` p ON p.nr_sequence = pp.nr_seq_profile AND p.ie_active " +
                "                AND p.nr_seq_establishment = ? " +
                "JOIN `function_profile` fp ON fp.nr_seq_profile = p.nr_sequence AND fp.ie_active " +
                "JOIN `function` f ON f.nr_sequence = fp.nr_seq_function AND f.ie_active " +
                "JOIN `function_establishment` fe ON fe.nr_seq_function = f.nr_sequence " +
                "                               AND fe.nr_seq_establishment = ? AND fe.ie_active " +
                "WHERE pp.nr_seq_person = ? AND pp.ie_active",
                String.class, establishmentId, establishmentId, personId));
    }

    /**
     * Sobe a versão de permissão do estabelecimento: invalida na hora todo
     * token emitido antes. Chame depois de mexer em function_establishment ou
     * function_profile.
     */
    public void invalidarPermissoes(long establishmentId) {
        jdbc.update("UPDATE `establishment` SET nr_permission_version = nr_permission_version + 1 " +
                "WHERE nr_sequence = ?", establishmentId);
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

    private static Long numero(Object o) {
        return o == null ? null : ((Number) o).longValue();
    }

    private static boolean bool(Object o) {
        return o != null && (o instanceof Boolean b ? b : ((Number) o).intValue() != 0);
    }
}
