package com.vellum.data;

import com.vellum.meta.MetaModel;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Revalidação de autoridade no backend (o front pré-valida só por UX):
 * required, unique, tamanho, faixa, regex do table_field + as VALIDATION
 * declarativas da visão (ds_expression sobre a linha completa).
 */
@Component
public class ValidationEngine {

    private final JdbcTemplate jdbc;

    public ValidationEngine(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * @param linha payload já coagido + (no update) valores atuais dos campos
     *              que não vieram — as expressões enxergam a linha inteira
     * @param id    null na criação; no update exclui o próprio registro do unique
     */
    public void validar(MetaModel.Table table, MetaModel.Vision vision,
                        Map<String, Object> linha, Long id) {
        List<ValidationException.FieldError> erros = new ArrayList<>();

        for (MetaModel.Field f : table.fields().values()) {
            if (f.computed()) continue;
            Object v = linha.get(f.name());
            boolean vazio = v == null || (v instanceof String s && s.isBlank());

            if (f.required() && vazio) {
                erros.add(new ValidationException.FieldError(f.name(), "required",
                        rotulo(vision, f) + " é obrigatório"));
                continue;
            }
            if (vazio) continue;

            if (f.size() != null && v instanceof String s && s.length() > f.size()) {
                erros.add(new ValidationException.FieldError(f.name(), "size",
                        rotulo(vision, f) + " excede " + f.size() + " caracteres"));
            }
            if (f.regex() != null && v instanceof String s && !s.matches(f.regex())) {
                erros.add(new ValidationException.FieldError(f.name(), "regex",
                        rotulo(vision, f) + " em formato inválido"));
            }
            if (f.min() != null && compara(v, f.min()) < 0) {
                erros.add(new ValidationException.FieldError(f.name(), "min",
                        rotulo(vision, f) + " abaixo do mínimo (" + f.min() + ")"));
            }
            if (f.max() != null && compara(v, f.max()) > 0) {
                erros.add(new ValidationException.FieldError(f.name(), "max",
                        rotulo(vision, f) + " acima do máximo (" + f.max() + ")"));
            }
            if (f.unique() && duplicado(table, f, v, id)) {
                erros.add(new ValidationException.FieldError(f.name(), "unique",
                        "já existe um registro com este " + rotulo(vision, f).toLowerCase()));
            }
            if (f.domain() != null && v instanceof String s && !s.isBlank() && !valorDeDominio(vision, f, s)) {
                erros.add(new ValidationException.FieldError(f.name(), "domain",
                        rotulo(vision, f) + " fora do domínio " + f.domain()));
            }
        }

        if (vision != null) {
            for (MetaModel.Restriction r : vision.restrictions()) {
                if (!"VALIDATION".equals(r.type()) || r.expression() == null) continue;
                boolean ok;
                try {
                    ok = ExpressionEvaluator.eval(r.expression(), linha);
                } catch (IllegalArgumentException e) {
                    throw new IllegalArgumentException("expressão de validação inválida na visão "
                            + vision.key() + ": " + e.getMessage());
                }
                if (!ok) {
                    erros.add(new ValidationException.FieldError(r.field(), "expression",
                            r.message() != null ? r.message() : "validação não satisfeita"));
                }
            }
        }

        if (!erros.isEmpty()) throw new ValidationException(erros);
    }

    private boolean duplicado(MetaModel.Table table, MetaModel.Field f, Object v, Long id) {
        String sql = "SELECT COUNT(*) FROM `" + table.name() + "` WHERE `" + f.name() + "` = ?"
                + (id != null ? " AND nr_sequence != ?" : "");
        Integer n = id != null
                ? jdbc.queryForObject(sql, Integer.class, v, id)
                : jdbc.queryForObject(sql, Integer.class, v);
        return n != null && n > 0;
    }

    private boolean valorDeDominio(MetaModel.Vision vision, MetaModel.Field f, String v) {
        // o domínio já está no MetaModel; consulta direta evita segurar referência ao meta aqui
        Integer n = jdbc.queryForObject(
                "SELECT COUNT(*) FROM `domain_value` dv JOIN `domain` d ON d.nr_sequence = dv.nr_seq_domain " +
                "WHERE d.nm_domain = ? AND dv.vl_value = ? AND dv.ie_active", Integer.class, f.domain(), v);
        return n != null && n > 0;
    }

    private static String rotulo(MetaModel.Vision vision, MetaModel.Field f) {
        if (vision != null) {
            for (MetaModel.VisionField vf : vision.fields()) {
                if (vf.field().equals(f.name()) && vf.label() != null) return vf.label();
            }
        }
        return f.label();
    }

    /** Compara valor com limite (numérico quando der, senão lexicográfico — datas ISO ordenam bem). */
    private static int compara(Object v, String limite) {
        try {
            return new BigDecimal(String.valueOf(v)).compareTo(new BigDecimal(limite));
        } catch (NumberFormatException e) {
            return String.valueOf(v).compareTo(limite);
        }
    }
}
