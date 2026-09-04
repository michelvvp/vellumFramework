package com.vellum.function;

import com.vellum.auth.CurrentUser;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Map;

/**
 * Contexto entregue a um FunctionHandler.
 *
 * @param user      quem chamou
 * @param visionKey visão de origem (ACTION/AUTH; null em HOOK/ENDPOINT direto)
 * @param table     tabela alvo (HOOK e AUTH de visão com tabela)
 * @param operation ACTION | BEFORE_CREATE | AFTER_UPDATE | ... | READ/CREATE/UPDATE/DELETE (AUTH)
 * @param recordId  registro alvo, quando houver
 * @param payload   corpo da operação (mutável nos HOOKs before)
 * @param params    parâmetros livres enviados pelo front
 * @param jdbc      acesso ao banco para o handler
 */
public record FunctionContext(
        CurrentUser user, String visionKey, String table, String operation,
        Long recordId, Map<String, Object> payload, Map<String, Object> params,
        JdbcTemplate jdbc) {}
