package com.framework.auth;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.Optional;

/**
 * Exige "Authorization: Bearer <token>" em toda a API (/api/**), exceto o
 * login. O usuário autenticado vai em um atributo do request.
 */
@Component
public class AuthTokenFilter extends OncePerRequestFilter {

    public static final String ATTR_USER = "auth.user";

    private final AuthService auth;

    public AuthTokenFilter(AuthService auth) {
        this.auth = auth;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/")
                || request.getRequestURI().equals("/api/auth/login")
                || "OPTIONS".equals(request.getMethod()); // preflight CORS não carrega Authorization
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        String token = header != null && header.startsWith("Bearer ") ? header.substring(7).trim() : null;
        Optional<CurrentUser> user = auth.validarToken(token);
        if (user.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"message\":\"não autenticado\"}");
            return;
        }
        request.setAttribute(ATTR_USER, user.get());
        chain.doFilter(request, response);
    }

    /* ---------- Helpers para os controllers ---------- */

    public static CurrentUser usuarioAtual(HttpServletRequest request) {
        return (CurrentUser) request.getAttribute(ATTR_USER);
    }

    /** 403 se o usuário logado não tiver o papel ADMIN. */
    public static CurrentUser exigirAdmin(HttpServletRequest request) {
        CurrentUser u = usuarioAtual(request);
        if (!u.hasRole("ADMIN"))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "requer papel ADMIN");
        return u;
    }
}
