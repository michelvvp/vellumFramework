package com.vellum.handler;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.Base64;

/**
 * Retorno padronizado de um handler ACTION: o front lê `effect` para saber o
 * que fazer depois (recarregar a grade, abrir outra visão, abrir URL, baixar arquivo).
 * Campos nulos ficam fora do JSON.
 *
 * @param effect NONE | RELOAD | OPEN_VISION | OPEN_URL | DOWNLOAD
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ActionResult(
        boolean ok, String message, String effect,
        String vision, Long recordId,
        String url,
        String filename, String mime, String contentBase64) {

    public static final String NONE = "NONE";
    public static final String RELOAD = "RELOAD";
    public static final String OPEN_VISION = "OPEN_VISION";
    public static final String OPEN_URL = "OPEN_URL";
    public static final String DOWNLOAD = "DOWNLOAD";

    /** Nada a fazer na tela. */
    public static ActionResult none() {
        return new ActionResult(true, null, NONE, null, null, null, null, null, null);
    }

    /** Recarrega a visão de origem. */
    public static ActionResult reload() {
        return new ActionResult(true, null, RELOAD, null, null, null, null, null, null);
    }

    /** Mensagem ao usuário e recarga. */
    public static ActionResult message(String message) {
        return reload().withMessage(message);
    }

    public static ActionResult openVision(String visionKey, Long recordId) {
        return new ActionResult(true, null, OPEN_VISION, visionKey, recordId, null, null, null, null);
    }

    public static ActionResult openUrl(String url) {
        return new ActionResult(true, null, OPEN_URL, null, null, url, null, null, null);
    }

    public static ActionResult download(String filename, String mime, byte[] conteudo) {
        return new ActionResult(true, null, DOWNLOAD, null, null, null, filename, mime,
                Base64.getEncoder().encodeToString(conteudo));
    }

    /** Mesma ação com outra mensagem (o efeito é mantido). */
    public ActionResult withMessage(String message) {
        return new ActionResult(ok, message, effect, vision, recordId, url, filename, mime, contentBase64);
    }
}
