package com.framework.auth;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    public record LoginRequest(String login, String senha) {}

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody LoginRequest req) {
        CurrentUser user = auth.autenticar(req.login(), req.senha());
        return Map.of("token", auth.gerarToken(user), "user", dto(user));
    }

    @GetMapping("/me")
    public Map<String, Object> me(HttpServletRequest request) {
        return dto(AuthTokenFilter.usuarioAtual(request));
    }

    private static Map<String, Object> dto(CurrentUser u) {
        return Map.of("id", u.id(), "name", u.name(), "login", u.login(), "roles", u.roles());
    }
}
