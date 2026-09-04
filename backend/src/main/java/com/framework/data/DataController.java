package com.framework.data;

import com.framework.auth.AuthTokenFilter;
import com.framework.auth.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * CRUD genérico: qualquer tabela do dicionário responde aqui. A visão de
 * contexto vai em ?_vision=<nm_vision> — é dela que saem filtros, permissões
 * e validações.
 */
@RestController
public class DataController {

    private final DataService data;

    public DataController(DataService data) {
        this.data = data;
    }

    @GetMapping("/api/data/{table}")
    public List<Map<String, Object>> list(@PathVariable String table,
                                          @RequestParam Map<String, String> params,
                                          HttpServletRequest req) {
        return data.list(table, params.get("_vision"), usuario(req), params);
    }

    @GetMapping("/api/data/{table}/{id}")
    public Map<String, Object> get(@PathVariable String table, @PathVariable long id,
                                   @RequestParam("_vision") String vision,
                                   HttpServletRequest req) {
        return data.get(table, id, vision, usuario(req));
    }

    @PostMapping("/api/data/{table}")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@PathVariable String table,
                                      @RequestParam("_vision") String vision,
                                      @RequestBody Map<String, Object> payload,
                                      HttpServletRequest req) {
        return data.create(table, vision, usuario(req), payload);
    }

    @PutMapping("/api/data/{table}/ordem")
    public void reorder(@PathVariable String table,
                        @RequestParam("_vision") String vision,
                        @RequestBody Map<String, List<Long>> body,
                        HttpServletRequest req) {
        data.reorder(table, vision, usuario(req), body.getOrDefault("ids", List.of()));
    }

    @PutMapping("/api/data/{table}/{id}")
    public Map<String, Object> update(@PathVariable String table, @PathVariable long id,
                                      @RequestParam("_vision") String vision,
                                      @RequestBody Map<String, Object> payload,
                                      HttpServletRequest req) {
        return data.update(table, id, vision, usuario(req), payload);
    }

    @DeleteMapping("/api/data/{table}/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String table, @PathVariable long id,
                       @RequestParam("_vision") String vision,
                       HttpServletRequest req) {
        data.delete(table, id, vision, usuario(req));
    }

    /** Opções de combo (id + rótulo) para campos ENTITY — sem expor a linha inteira. */
    @GetMapping("/api/lookup/{table}")
    public List<Map<String, Object>> lookup(@PathVariable String table,
                                            @RequestParam Map<String, String> params) {
        return data.lookup(table, params);
    }

    private static CurrentUser usuario(HttpServletRequest req) {
        return AuthTokenFilter.usuarioAtual(req);
    }
}
