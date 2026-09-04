package com.framework.meta;

import com.framework.auth.AuthTokenFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/meta")
public class MetaController {

    private final MetaService meta;

    public MetaController(MetaService meta) {
        this.meta = meta;
    }

    @GetMapping
    public Map<String, Object> definicao(HttpServletRequest request) {
        return meta.definicaoPara(AuthTokenFilter.usuarioAtual(request));
    }

    /** Recarrega o dicionário sem reiniciar (depois de editar cadastros de tela). */
    @PostMapping("/reload")
    public Map<String, Object> reload(HttpServletRequest request) {
        AuthTokenFilter.exigirAdmin(request);
        meta.reload();
        return Map.of("version", meta.get().version);
    }
}
