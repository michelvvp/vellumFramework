package com.vellum.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vellum.data.ValidationEngine;
import com.vellum.meta.MetaModel;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class AcaoTest {

    private final ObjectMapper json = new ObjectMapper();

    @Test
    void actionResultOmiteNulos() throws Exception {
        assertEquals("{\"ok\":true,\"effect\":\"RELOAD\"}", json.writeValueAsString(ActionResult.reload()));
        assertEquals("{\"ok\":true,\"message\":\"feito\",\"effect\":\"RELOAD\"}",
                json.writeValueAsString(ActionResult.message("feito")));
        assertEquals("{\"ok\":true,\"effect\":\"OPEN_VISION\",\"vision\":\"clientes\",\"recordId\":7}",
                json.writeValueAsString(ActionResult.openVision("clientes", 7L)));
        assertEquals("{\"ok\":true,\"message\":\"x\",\"effect\":\"NONE\"}",
                json.writeValueAsString(ActionResult.none().withMessage("x")));
        assertEquals("QQ==", ActionResult.download("a.txt", "text/plain", new byte[]{'A'}).contentBase64());
    }

    @Test
    void validaParamsDaAcao() {
        MetaModel.Column cpf = new MetaModel.Column(1, "cpf", "CPF", "STRING", null, null,
                true, false, 11, null, null, null, null, null, null, null, 1);
        MetaModel.Column qtd = new MetaModel.Column(2, "qtd", "Quantidade", "INTEGER", null, null,
                false, false, null, null, null, null, null, null, null, null, 2);
        MetaModel.Handler h = new MetaModel.Handler(1, "convidar", "Convidar", "ACTION", "v", null,
                null, "ROW", "bean", false, null, null, List.of(cpf, qtd));
        ValidationEngine v = new ValidationEngine(null, null);

        v.validarParams(h, Map.of("cpf", "12345678901", "qtd", 3));

        ParamsInvalidosException e = assertThrows(ParamsInvalidosException.class,
                () -> v.validarParams(h, Map.of("qtd", "abc")));
        assertEquals(List.of("cpf", "qtd"), e.errors().stream().map(x -> x.field()).sorted().toList());
        assertThrows(ParamsInvalidosException.class,
                () -> v.validarParams(h, Map.of("cpf", "123456789012")));
    }
}
