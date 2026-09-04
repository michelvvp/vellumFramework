package com.framework.meta;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Confere no boot que o dicionário bate com o schema físico (a v1 cria as
 * tabelas de negócio por migration — seção 3.3 da especificação). Divergência
 * derruba o boot com relatório claro. Também valida que ds_formula só
 * referencia campos da própria tabela — é o que permite injetá-la no SELECT
 * sem risco de SQL arbitrário.
 */
@Component
public class SchemaValidator {

    /** identificadores dentro de uma fórmula (ignorando números) */
    private static final Pattern IDENT = Pattern.compile("[a-zA-Z_][a-zA-Z0-9_]*");
    /** funções SQL inofensivas permitidas em fórmulas e agregações */
    private static final Set<String> FUNCOES_PERMITIDAS = Set.of(
            "round", "floor", "ceil", "abs", "coalesce", "nullif", "if",
            "greatest", "least", "concat", "concat_ws", "date_format",
            "timestampdiff", "datediff", "second", "minute", "hour", "day", "week", "month", "year");

    private final JdbcTemplate jdbc;
    private final Map<String, Set<String>> colunasFisicas = new HashMap<>();

    public SchemaValidator(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void validar(MetaModel meta) {
        List<String> erros = new ArrayList<>();
        colunasFisicas.clear();

        for (MetaModel.Table t : meta.tables.values()) {
            Set<String> colunas = colunasDe(t.name());
            if (colunas.isEmpty()) {
                erros.add("tabela '" + t.name() + "' cadastrada no dicionário não existe no banco");
                continue;
            }
            if (!colunas.contains("nr_sequence"))
                erros.add("tabela '" + t.name() + "' sem PK nr_sequence");
            if (t.logicalDelete() && !colunas.contains("ie_active"))
                erros.add("tabela '" + t.name() + "' com exclusão lógica exige coluna ie_active");
            if (t.audit() && !colunas.contains("dt_created"))
                erros.add("tabela '" + t.name() + "' com auditoria exige coluna dt_created");

            for (MetaModel.Field f : t.fields().values()) {
                if (f.computed()) {
                    validarFormula(t, f, erros);
                } else if (!colunas.contains(f.name())) {
                    erros.add("coluna '" + t.name() + "." + f.name() + "' cadastrada no dicionário não existe no banco");
                }
            }
        }

        if (!erros.isEmpty()) {
            throw new IllegalStateException("Dicionário divergente do schema físico:\n - "
                    + String.join("\n - ", erros));
        }
    }

    private void validarFormula(MetaModel.Table t, MetaModel.Field f, List<String> erros) {
        Matcher m = IDENT.matcher(f.formula());
        while (m.find()) {
            String ident = m.group().toLowerCase();
            boolean campo = t.fields().containsKey(ident) && !t.fields().get(ident).computed();
            if (!campo && !FUNCOES_PERMITIDAS.contains(ident)) {
                erros.add("fórmula de '" + t.name() + "." + f.name()
                        + "' usa identificador não permitido: '" + ident + "'");
            }
        }
        // nada de aspas/ponto-e-vírgula/comentários dentro de fórmula
        if (f.formula().matches(".*['\";].*") || f.formula().contains("--") || f.formula().contains("/*")) {
            erros.add("fórmula de '" + t.name() + "." + f.name() + "' contém caracteres proibidos");
        }
    }

    /** Colunas físicas de uma tabela (cache do boot; o CRUD usa para auditoria/ordem). */
    public Set<String> colunasDe(String tabela) {
        return colunasFisicas.computeIfAbsent(tabela, nome -> new HashSet<>(jdbc.queryForList(
                "SELECT LOWER(column_name) FROM information_schema.columns " +
                "WHERE table_schema = DATABASE() AND table_name = ?", String.class, nome)));
    }
}
