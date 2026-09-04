package com.vellum.dashboard;

import com.vellum.auth.CurrentUser;
import com.vellum.data.RestrictionEngine;
import com.vellum.meta.MetaModel;
import com.vellum.meta.MetaService;
import com.vellum.meta.Permissions;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Dashboards cadastráveis (seção 3.10): calcula os dados de cada
 * dashboard_widget de uma visão DASHBOARD. O dashboard herda as restrições
 * FILTER da visão (ex.: pessoa_id = :usuario_record), então "Histórico do
 * atleta" é o mesmo cadastro para todos, filtrado por contexto.
 */
@Service
public class DashboardService {

    private static final Pattern IDENT = Pattern.compile("^[A-Za-z_][A-Za-z0-9_]{0,63}$");

    private final JdbcTemplate jdbc;
    private final MetaService meta;
    private final RestrictionEngine restriction;

    public DashboardService(JdbcTemplate jdbc, MetaService meta, RestrictionEngine restriction) {
        this.jdbc = jdbc;
        this.meta = meta;
        this.restriction = restriction;
    }

    public Map<String, Object> dados(String visionKey, CurrentUser user, String from, String to) {
        MetaModel.Vision v = meta.get().visions.get(visionKey);
        if (v == null || !"DASHBOARD".equals(v.type()))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "dashboard não cadastrado");
        if (!Permissions.podeLer(v, user))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "sem acesso ao dashboard");

        Map<String, Object> saida = new LinkedHashMap<>();
        List<Map<String, Object>> widgets = new ArrayList<>();
        for (MetaModel.Widget w : v.widgets()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", w.id());
            item.put("title", w.title());
            item.put("type", w.type());
            item.put("data", calcular(v, w, user, from, to));
            if (!w.fieldsY().isEmpty()) item.put("series", w.fieldsY());
            widgets.add(item);
        }
        saida.put("widgets", widgets);
        return saida;
    }

    private Object calcular(MetaModel.Vision v, MetaModel.Widget w, CurrentUser user,
                            String from, String to) {
        MetaModel.Table t = meta.get().tables.get(w.table());
        if (t == null) throw new IllegalArgumentException("widget aponta para tabela inexistente");

        List<Object> args = new ArrayList<>();
        List<String> where = new ArrayList<>();
        if (t.logicalDelete()) where.add("t.ie_active");
        RestrictionEngine.Where filtros = restriction.filtros(v, user, null);
        if (!filtros.sql().isEmpty()) {
            where.add(filtros.sql());
            args.addAll(filtros.params());
        }
        if (w.usePeriod() && w.fieldX() != null) {
            if (from != null && !from.isBlank()) { where.add(campo(t, w.fieldX()) + " >= ?"); args.add(from); }
            if (to != null && !to.isBlank()) { where.add(campo(t, w.fieldX()) + " <= ?"); args.add(to + " 23:59:59"); }
        }
        String whereSql = where.isEmpty() ? "" : " WHERE " + String.join(" AND ", where);

        return switch (w.type()) {
            case "VALUE" -> {
                String expr = w.fieldsY().isEmpty() ? "COUNT(*)"
                        : agregar(w.aggregation(), campo(t, w.fieldsY().get(0)));
                yield jdbc.queryForObject("SELECT " + expr + " FROM `" + t.name() + "` t" + whereSql,
                        Object.class, args.toArray());
            }
            case "CHART_LINE", "CHART_BAR" -> {
                String grupoExpr = switch (w.groupBy() == null ? "NONE" : w.groupBy()) {
                    case "DAY" -> "DATE_FORMAT(" + campo(t, w.fieldX()) + ", '%Y-%m-%d')";
                    case "WEEK" -> "DATE_FORMAT(DATE_SUB(" + campo(t, w.fieldX())
                            + ", INTERVAL WEEKDAY(" + campo(t, w.fieldX()) + ") DAY), '%Y-%m-%d')";
                    case "MONTH" -> "DATE_FORMAT(" + campo(t, w.fieldX()) + ", '%Y-%m')";
                    case "FIELD" -> campo(t, w.groupField());
                    default -> null;
                };
                List<String> cols = new ArrayList<>();
                StringBuilder sql = new StringBuilder("SELECT ");
                if (grupoExpr != null) {
                    cols.add(grupoExpr + " AS x");
                    for (String y : w.fieldsY()) cols.add(agregar(w.aggregation(), campo(t, y))
                            + " AS `" + ident(y) + "`");
                    sql.append(String.join(", ", cols))
                            .append(" FROM `").append(t.name()).append("` t").append(whereSql)
                            .append(" GROUP BY x ORDER BY x");
                } else {
                    cols.add(campo(t, w.fieldX()) + " AS x");
                    for (String y : w.fieldsY()) cols.add(campo(t, y) + " AS `" + ident(y) + "`");
                    sql.append(String.join(", ", cols))
                            .append(" FROM `").append(t.name()).append("` t").append(whereSql)
                            .append(" ORDER BY x");
                }
                yield jdbc.queryForList(sql.toString(), args.toArray());
            }
            case "LIST" -> {
                String rotulo = t.labelFields().isEmpty() ? "CAST(t.nr_sequence AS CHAR)"
                        : "CONCAT_WS(' · ', " + String.join(", ",
                                t.labelFields().stream().map(lf -> "t.`" + ident(lf) + "`").toList()) + ")";
                String ordem = w.fieldX() != null ? campo(t, w.fieldX()) : "t.nr_sequence";
                int limite = w.limit() == null ? 5 : w.limit();
                yield jdbc.queryForList("SELECT t.nr_sequence AS id, " + rotulo + " AS label, "
                                + ordem + " AS x FROM `" + t.name() + "` t" + whereSql
                                + " ORDER BY " + ordem + " DESC LIMIT " + limite,
                        args.toArray());
            }
            default -> throw new IllegalArgumentException("tipo de widget desconhecido: " + w.type());
        };
    }

    /** Campo do widget: físico vira t.`nome`; calculado vira a fórmula (já validada no boot). */
    private String campo(MetaModel.Table t, String nome) {
        MetaModel.Field f = t.fields().get(nome);
        if (f == null) throw new IllegalArgumentException(
                "widget usa campo inexistente: " + t.name() + "." + nome);
        return f.computed() ? "(" + f.formula() + ")" : "t.`" + ident(nome) + "`";
    }

    private static String agregar(String agg, String expr) {
        return switch (agg == null ? "NONE" : agg) {
            case "SUM" -> "SUM(" + expr + ")";
            case "AVG" -> "AVG(" + expr + ")";
            case "MAX" -> "MAX(" + expr + ")";
            case "MIN" -> "MIN(" + expr + ")";
            case "COUNT" -> "COUNT(" + expr + ")";
            default -> expr;
        };
    }

    private static String ident(String nome) {
        if (!IDENT.matcher(nome).matches())
            throw new IllegalArgumentException("identificador inválido: " + nome);
        return nome;
    }
}
