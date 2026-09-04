package com.vellum.meta;

import com.vellum.auth.CurrentUser;

import java.util.List;

/**
 * Leitura das restrições PERMISSION de uma visão. Regra: sem nenhuma linha
 * PERMISSION para a operação, a visão é liberada para qualquer autenticado;
 * havendo linhas, basta um papel do usuário bater (OU entre elas). Isto roda
 * sempre no backend — o JSON do front é cortesia de UX, nunca autoridade.
 */
public final class Permissions {

    private Permissions() {}

    public static boolean pode(MetaModel.Vision vision, CurrentUser user, String operation) {
        List<MetaModel.Restriction> regras = vision.restrictions().stream()
                .filter(r -> "PERMISSION".equals(r.type()))
                .filter(r -> r.operation() == null || "ALL".equals(r.operation())
                        || operation.equals(r.operation()))
                .toList();
        if (regras.isEmpty()) return true;

        // regras da própria operação têm precedência sobre as ALL genéricas
        List<MetaModel.Restriction> especificas = regras.stream()
                .filter(r -> operation.equals(r.operation())).toList();
        List<MetaModel.Restriction> aplicaveis = especificas.isEmpty() ? regras : especificas;
        return aplicaveis.stream().anyMatch(r -> user.hasRole(r.role()));
    }

    public static boolean podeLer(MetaModel.Vision vision, CurrentUser user) {
        return pode(vision, user, "READ");
    }
}
