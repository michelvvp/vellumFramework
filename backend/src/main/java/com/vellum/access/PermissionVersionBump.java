package com.vellum.access;

import com.vellum.auth.AuthService;
import com.vellum.handler.Handler;
import com.vellum.handler.HandlerContext;
import org.springframework.stereotype.Component;

/**
 * Sobe a nr_permission_version do estabelecimento sempre que a permissão dele
 * muda — habilitar/desabilitar uma função no estabelecimento, ou conceder/tirar
 * uma função de um perfil. É isso que faz a alteração valer na hora: o token
 * carrega a versão da emissão e o AuthService recusa quem está atrás.
 *
 * Cadastrado como HOOK em function_establishment e function_profile
 * (AFTER_CREATE, AFTER_UPDATE e BEFORE_DELETE — no delete a linha precisa ser
 * lida antes de sumir).
 */
@Component("permission_version_bump")
public class PermissionVersionBump implements Handler {

    private final AuthService auth;

    public PermissionVersionBump(AuthService auth) {
        this.auth = auth;
    }

    @Override
    public Object execute(HandlerContext ctx) {
        Long establishmentId = switch (ctx.table()) {
            case "function_establishment" -> establecimentoDireto(ctx);
            case "function_profile" -> estabelecimentoDoPerfil(ctx);
            default -> null;
        };
        if (establishmentId != null) auth.invalidarPermissoes(establishmentId);
        return null;
    }

    private Long establecimentoDireto(HandlerContext ctx) {
        Object doPayload = ctx.payload() == null ? null : ctx.payload().get("nr_seq_establishment");
        if (doPayload instanceof Number n) return n.longValue();
        if (ctx.recordId() == null) return null;
        return ctx.jdbc().queryForObject(
                "SELECT nr_seq_establishment FROM `function_establishment` WHERE nr_sequence = ?",
                Long.class, ctx.recordId());
    }

    private Long estabelecimentoDoPerfil(HandlerContext ctx) {
        Object doPayload = ctx.payload() == null ? null : ctx.payload().get("nr_seq_profile");
        Long profileId = doPayload instanceof Number n ? n.longValue() : null;
        if (profileId == null && ctx.recordId() != null) {
            profileId = ctx.jdbc().queryForObject(
                    "SELECT nr_seq_profile FROM `function_profile` WHERE nr_sequence = ?",
                    Long.class, ctx.recordId());
        }
        if (profileId == null) return null;
        return ctx.jdbc().queryForObject(
                "SELECT nr_seq_establishment FROM `profile` WHERE nr_sequence = ?", Long.class, profileId);
    }
}
