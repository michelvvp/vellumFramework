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
 *   :usuario_id     — id do app_user logado
 *   :usuario_record — id do registro de negócio vinculado ao usuário
 *                     (app_user.nr_seq_record, ex.: a pessoa do gym)
 *   :usuario_papeis — papéis do usuário (para operador IN)
 *   :hoje / :agora  — data/data-hora do servidor
 *   :parent_id      — id do registro pai (MASTER_DETAIL)
 */
@Component
public class RestrictionEngine {

    public record Where(String sql, List<Object> params) {}

    public Where filtros(MetaModel.Vision vision, CurrentUser user, Long parentId) {
        List<String> clausulas = new ArrayList<>();
        List<Object> params = new ArrayList<>();

        for (MetaModel.Restriction r : vision.restrictions()) {
            if (!"FILTER".equals(r.type())) continue;
            String coluna = "t.`" + r.field() + "`";
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

    private Object resolver(String valor, CurrentUser user, Long parentId) {
        if (valor == null) return null;
        return switch (valor) {
            case ":usuario_id" -> user.id();
            case ":usuario_record" -> user.linkedRecord();
            case ":usuario_papeis" -> new ArrayList<>(user.roles());
            case ":hoje" -> LocalDate.now();
            case ":agora" -> LocalDateTime.now();
            case ":parent_id" -> parentId;
            default -> valor;
        };
    }
}
