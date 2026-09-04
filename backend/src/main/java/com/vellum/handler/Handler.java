package com.vellum.handler;

/**
 * Ponto de extensão em Java (seção 3.8 da especificação): o metadado diz
 * *onde e quando*, o código diz *o quê*. Implemente como um @Component cujo
 * nome de bean é o nm_handler cadastrado na tabela `function`.
 *
 * - ACTION/ENDPOINT: o retorno vira o corpo da resposta.
 * - HOOK: pode mutar ctx.payload() (before) ou reagir (after); lançar exceção aborta.
 * - AUTH: lance ResponseStatusException(403) para negar; retorno é ignorado.
 */
public interface Handler {

    Object execute(HandlerContext ctx);
}
