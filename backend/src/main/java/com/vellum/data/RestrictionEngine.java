package com.vellum.data;

import com.vellum.auth.CurrentUser;
import com.vellum.meta.MetaModel;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Traduz as restrições FILTER de uma visão em fragmentos de WHERE com
 * parâmetros posicionais. As variáveis de contexto são resolvidas aqui,
 * no backend — nunca confiadas ao front (seção 3.7 da especificação):
 *   :person_id        — id da person logada
 *   :person_record    — id do registro de negócio vinculado a ela
 *                       (person.nr_seq_record)
 *   :person_functions — funções efetivas no estabelecimento (para operador IN)
 *   :establishment_id — estabelecimento ativo da sessão
 *   :hoje / :agora    — data/data-hora do servidor
 *   :parent_id        — id do registro pai (MASTER_DETAIL)
 */
@Component
public class RestrictionEngine {

    private static final java.util.regex.Pattern IDENT =
            java.util.regex.Pattern.compile("^[A-Za-z_][A-Za-z0-9_]{0,63}$");

    public record Where(String sql, List<Object> params) {}

    public Where filtros(MetaModel.Vision vision, CurrentUser user, Long parentId) {
        List<String> clausulas = new ArrayList<>();
        List<Object> params = new ArrayList<>();

        for (MetaModel.Restriction r : vision.restrictions()) {
            if (!"FILTER".equals(r.type())) continue;
            String coluna = "t.`" + ident(r.column()) + "`";
            String operador = r.operator() == null ? "EQ" : r.operator();
            switch (operador) {
                case "IS_NULL" -> clausulas.add(coluna + " IS NULL");
                case "NOT_NULL" -> clausulas.add(coluna + " IS NOT NULL");
                case "IN" -> {
                    List<Object> valores = new ArrayList<>();
                    for (String parte : String.valueOf(r.value()).split(",")) {
                        Object v = resolver(parte.trim(), user, parentId);
                        if (v instanceof List<?> lista) valores.addAll(lista);
                        else valores.add(v);
                    }
                    if (valores.isEmpty()) { clausulas.add("1=0"); break; }
                    clausulas.add(coluna + " IN (" + "?,".repeat(valores.size() - 1) + "?)");
                    params.addAll(valores);
                }
                case "BETWEEN" -> {
                    String[] partes = String.valueOf(r.value()).split(",");
                    clausulas.add(coluna + " BETWEEN ? AND ?");
                    params.add(resolver(partes[0].trim(), user, parentId));
                    params.add(resolver(partes[1].trim(), user, parentId));
                }
                case "LIKE" -> {
                    clausulas.add(coluna + " LIKE ?");
                    params.add(resolver(r.value(), user, parentId));
                }
                default -> {
                    String op = switch (operador) {
                        case "EQ" -> "="; case "NE" -> "!="; case "GT" -> ">";
                        case "GE" -> ">="; case "LT" -> "<"; case "LE" -> "<=";
                        default -> throw new IllegalArgumentException("operador desconhecido: " + operador);
                    };
                    Object v = resolver(r.value(), user, parentId);
                    if (v == null) {
                        // contexto ausente (ex.: usuário sem registro vinculado): não vaza nada
                        clausulas.add("1=0");
                    } else {
                        clausulas.add(coluna + " " + op + " ?");
                        params.add(v);
                    }
                }
            }
        }
        return new Where(String.join(" AND ", clausulas), params);
    }

    /**
     * O MetadataLoader já recusa filtro em coluna que não existe na tabela;
     * esta é a segunda tranca, porque o valor entra no SQL sem parâmetro.
     */
    private static String ident(String nome) {
        if (nome == null || !IDENT.matcher(nome).matches())
            throw new IllegalArgumentException("coluna inválida em restrição: " + nome);
        return nome;
    }

    private Object resolver(String valor, CurrentUser user, Long parentId) {
        if (valor == null) return null;
        return switch (valor) {
            case ":person_id" -> user.id();
            case ":person_record" -> user.linkedRecord();
            case ":person_functions" -> new ArrayList<>(user.functions());
            case ":establishment_id" -> user.establishmentId();
            case ":hoje" -> LocalDate.now();
            case ":agora" -> LocalDateTime.now();
            case ":parent_id" -> parentId;
            default -> valor;
        };
    }
}
