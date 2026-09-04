package com.vellum.auth;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Login em duas etapas quando faz sentido: as credenciais identificam a
 * pessoa, o estabelecimento define o que ela pode fazer. Com um único
 * estabelecimento vinculado o login já entra nele; com vários, devolve a lista
 * e um token de escolha que só serve para chamar /establishment.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    public record LoginRequest(String login, String senha) {}
    public record EstablishmentRequest(Long establishmentId) {}

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody LoginRequest req) {
        long personId = auth.autenticar(req.login(), req.senha());
        List<AuthService.Establishment> estabelecimentos = auth.estabelecimentos(personId);

        if (estabelecimentos.isEmpty())
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Nenhum estabelecimento vinculado a este acesso. Procure um administrador.");

        if (estabelecimentos.size() == 1) {
            CurrentUser user = auth.entrar(personId, estabelecimentos.get(0).id());
            return Map.of("token", auth.gerarToken(user), "user", dto(user));
        }
        return Map.of(
                "token", auth.gerarTokenDeEscolha(personId),
                "establishments", estabelecimentos.stream().map(AuthController::dto).toList());
    }

    /** Segunda etapa: escolhe o estabelecimento e troca o token de escolha pelo definitivo. */
    @PostMapping("/establishment")
    public Map<String, Object> escolher(@RequestBody EstablishmentRequest req, HttpServletRequest request) {
        CurrentUser atual = AuthTokenFilter.usuarioAtual(request);
        if (req == null || req.establishmentId() == null)
            throw new IllegalArgumentException("establishmentId é obrigatório");
        CurrentUser user = auth.entrar(atual.id(), req.establishmentId());
        return Map.of("token", auth.gerarToken(user), "user", dto(user));
    }

    /** Estabelecimentos disponíveis para quem está logado (troca de unidade sem novo login). */
    @GetMapping("/establishments")
    public List<Map<String, Object>> disponiveis(HttpServletRequest request) {
        return auth.estabelecimentos(AuthTokenFilter.usuarioAtual(request).id())
                .stream().map(AuthController::dto).toList();
    }

    @GetMapping("/me")
    public Map<String, Object> me(HttpServletRequest request) {
        return dto(AuthTokenFilter.usuarioAtual(request));
    }

    private static Map<String, Object> dto(AuthService.Establishment e) {
        return Map.of("id", e.id(), "name", e.name(), "color", e.color());
    }

    private static Map<String, Object> dto(CurrentUser u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.id());
        m.put("name", u.name());
        m.put("login", u.login());
        m.put("functions", u.functions());
        if (!u.pendingEstablishment()) {
            m.put("establishmentId", u.establishmentId());
            m.put("establishmentName", u.establishmentName());
        }
        return m;
    }
}
