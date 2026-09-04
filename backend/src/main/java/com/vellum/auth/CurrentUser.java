package com.vellum.auth;

import java.util.Set;

/**
 * Pessoa autenticada do request, já resolvida no estabelecimento ativo.
 *
 * @param functions         códigos efetivos: a união das funções dos perfis
 *                          dela neste estabelecimento, interseccionada com o
 *                          que o estabelecimento habilita
 * @param establishmentId   0 enquanto o estabelecimento não foi escolhido
 * @param permissionVersion versão de permissão do estabelecimento no momento
 *                          em que o token foi emitido
 */
public record CurrentUser(long id, String name, String login,
                          long establishmentId, String establishmentName, int permissionVersion,
                          Set<String> functions, Long linkedTable, Long linkedRecord) {

    /** Ainda não escolheu em qual estabelecimento entrar. */
    public boolean pendingEstablishment() {
        return establishmentId == 0;
    }

    public boolean can(String function) {
        return function != null && functions.contains(function);
    }
}
