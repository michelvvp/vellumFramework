package com.vellum.function;

import com.vellum.auth.CurrentUser;
import com.vellum.meta.MetaModel;
import com.vellum.meta.MetaService;
import org.springframework.context.ApplicationContext;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

/**
 * Resolve nm_handler → bean FunctionHandler e dispara hooks/autorizações.
 * Handler cadastrado sem bean correspondente falha na primeira chamada com
 * mensagem clara (o dicionário pode ser editado em runtime, então isto não
 * é checado no boot).
 */
@Component
public class FunctionRegistry {

    private final ApplicationContext spring;
    private final MetaService meta;
    private final JdbcTemplate jdbc;

    public FunctionRegistry(ApplicationContext spring, MetaService meta, JdbcTemplate jdbc) {
        this.spring = spring;
        this.meta = meta;
        this.jdbc = jdbc;
    }

    public FunctionHandler handler(String nome) {
        try {
            return spring.getBean(nome, FunctionHandler.class);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.NOT_IMPLEMENTED,
                    "handler '" + nome + "' não registrado no backend");
        }
    }

    /** Dispara os HOOKs da tabela para o momento (BEFORE_CREATE, AFTER_DELETE...). */
    public void hooks(String table, String moment, CurrentUser user, Long recordId,
                      Map<String, Object> payload) {
        for (MetaModel.Function f : meta.get().functions) {
            if (!"HOOK".equals(f.type())) continue;
            if (!table.equals(f.table()) || !moment.equals(f.moment())) continue;
            handler(f.handler()).execute(new FunctionContext(
                    user, null, table, moment, recordId, payload, Map.of(), jdbc));
        }
    }

    /** Autorização plugável: roda as functions AUTH da visão; negar = lançar 403. */
    public void autorizar(MetaModel.Vision vision, CurrentUser user, String operation,
                          Long recordId, Map<String, Object> payload) {
        for (MetaModel.Function f : meta.get().functions) {
            if (!"AUTH".equals(f.type()) || !vision.key().equals(f.visionKey())) continue;
            handler(f.handler()).execute(new FunctionContext(
                    user, vision.key(), vision.table(), operation, recordId, payload, Map.of(), jdbc));
        }
    }
}
