package com.framework.function;

import com.framework.auth.AuthTokenFilter;
import com.framework.auth.CurrentUser;
import com.framework.meta.MetaModel;
import com.framework.meta.MetaService;
import com.framework.meta.Permissions;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

/**
 * Executa functions ACTION (botões de visão) e ENDPOINT (API pura, ex.: o
 * motor /integrate do integrator plugado por cadastro).
 */
@RestController
public class FunctionController {

    private final MetaService meta;
    private final FunctionRegistry registry;
    private final JdbcTemplate jdbc;

    public FunctionController(MetaService meta, FunctionRegistry registry, JdbcTemplate jdbc) {
        this.meta = meta;
        this.registry = registry;
        this.jdbc = jdbc;
    }

    public record Chamada(String visionKey, Long recordId, Map<String, Object> params) {}

    @PostMapping("/api/function/{name}")
    public Object executar(@PathVariable String name, @RequestBody(required = false) Chamada corpo,
                           HttpServletRequest req) {
        CurrentUser user = AuthTokenFilter.usuarioAtual(req);
        MetaModel.Function fn = meta.get().functions.stream()
                .filter(f -> f.name().equals(name))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "function '" + name + "' não cadastrada"));

        if (!"ACTION".equals(fn.type()) && !"ENDPOINT".equals(fn.type()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "function '" + name + "' não é executável diretamente (tipo " + fn.type() + ")");
        if (fn.role() != null && !user.hasRole(fn.role()))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "requer papel " + fn.role());

        // ACTION vive numa visão: quem não pode ler a visão não executa a ação
        if ("ACTION".equals(fn.type()) && fn.visionKey() != null) {
            MetaModel.Vision v = meta.get().visions.get(fn.visionKey());
            if (v == null || !Permissions.podeLer(v, user))
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "sem acesso à visão da ação");
        }

        Chamada c = corpo == null ? new Chamada(null, null, Map.of()) : corpo;
        Object resultado = registry.handler(fn.handler()).execute(new FunctionContext(
                user, c.visionKey() != null ? c.visionKey() : fn.visionKey(), fn.table(),
                fn.type(), c.recordId(), null,
                c.params() == null ? Map.of() : c.params(), jdbc));
        return resultado == null ? Map.of("ok", true) : resultado;
    }
}
