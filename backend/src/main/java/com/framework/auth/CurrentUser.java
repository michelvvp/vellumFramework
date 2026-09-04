package com.framework.auth;

import java.util.Set;

/** Usuário autenticado do request: identidade + papéis, resolvidos pelo AuthTokenFilter. */
public record CurrentUser(long id, String name, String login, Set<String> roles,
                          Long linkedTable, Long linkedRecord) {

    public boolean hasRole(String role) {
        return role != null && roles.contains(role);
    }
}
