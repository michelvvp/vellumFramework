package com.vellum.meta;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Lê o dicionário completo do banco e monta o MetaModel. Qualquer
 * inconsistência estrutural é acumulada e derruba o boot com relatório
 * legível (fail-fast da especificação, seção 5).
 */
@Component
public class MetadataLoader {

    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;

    public MetadataLoader(JdbcTemplate jdbc, ObjectMapper mapper) {
        this.jdbc = jdbc;
        this.mapper = mapper;
    }

    public MetaModel load() {
        List<String> erros = new ArrayList<>();

        // ---------- domínios ----------
        Map<Long, String> domainNameById = new HashMap<>();
        Map<String, MetaModel.Domain> domains = new LinkedHashMap<>();
        for (Map<String, Object> d : jdbc.queryForList(
                "SELECT nr_sequence, nm_domain, ds_domain FROM `domain` WHERE ie_active ORDER BY nm_domain")) {
            long id = ((Number) d.get("nr_sequence")).longValue();
            String nome = (String) d.get("nm_domain");
            List<MetaModel.DomainValue> valores = jdbc.query(
                    "SELECT vl_value, ds_label, nr_order, ds_color FROM `domain_value` " +
                    "WHERE nr_seq_domain = ? AND ie_active ORDER BY nr_order, nr_sequence",
                    (rs, i) -> new MetaModel.DomainValue(
                            rs.getString("vl_value"), rs.getString("ds_label"),
                            rs.getInt("nr_order"), rs.getString("ds_color")),
                    id);
            domainNameById.put(id, nome);
            domains.put(nome, new MetaModel.Domain(id, nome, (String) d.get("ds_domain"), valores));
        }

        // ---------- tabelas e campos ----------
        Map<Long, String> tableNameById = new HashMap<>();
        for (Map<String, Object> t : jdbc.queryForList(
                "SELECT nr_sequence, nm_table FROM `tables` WHERE ie_active")) {
            tableNameById.put(((Number) t.get("nr_sequence")).longValue(), (String) t.get("nm_table"));
        }

        Map<String, MetaModel.Table> tables = new LinkedHashMap<>();
        for (Map<String, Object> t : jdbc.queryForList(
                "SELECT * FROM `tables` WHERE ie_active ORDER BY nm_table")) {
            long id = ((Number) t.get("nr_sequence")).longValue();
            String nome = (String) t.get("nm_table");
            Map<String, MetaModel.Field> fields = new LinkedHashMap<>();
            for (Map<String, Object> f : jdbc.queryForList(
                    "SELECT * FROM `table_field` WHERE nr_seq_table = ? AND ie_active " +
                    "ORDER BY nr_order, nr_sequence", id)) {
                String tipo = (String) f.get("ie_type");
                Long domId = numero(f.get("nr_seq_domain"));
                Long refId = numero(f.get("nr_seq_table_ref"));
                String nmField = (String) f.get("nm_field");
                if ("DOMAIN".equals(tipo) && (domId == null || !domainNameById.containsKey(domId)))
                    erros.add(nome + "." + nmField + ": tipo DOMAIN sem domínio válido");
                if ("ENTITY".equals(tipo) && (refId == null || !tableNameById.containsKey(refId)))
                    erros.add(nome + "." + nmField + ": tipo ENTITY sem tabela referenciada válida");
                fields.put(nmField, new MetaModel.Field(
                        ((Number) f.get("nr_sequence")).longValue(), nmField,
                        (String) f.get("ds_label"), tipo,
                        domId == null ? null : domainNameById.get(domId),
                        refId == null ? null : tableNameById.get(refId),
                        bool(f.get("ie_required")), bool(f.get("ie_unique")),
                        inteiro(f.get("qt_size")), inteiro(f.get("qt_scale")),
                        (String) f.get("vl_min"), (String) f.get("vl_max"),
                        (String) f.get("ds_regex"), (String) f.get("vl_default"),
                        (String) f.get("ds_hint"), (String) f.get("ds_formula"),
                        f.get("nr_order") == null ? 0 : ((Number) f.get("nr_order")).intValue()));
            }
            List<String> labelFields = new ArrayList<>();
            String labelCsv = (String) t.get("nm_label_field");
            if (labelCsv != null) for (String lf : labelCsv.split(",")) {
                String limpo = lf.trim();
                if (limpo.isEmpty()) continue;
                if (!fields.containsKey(limpo))
                    erros.add(nome + ": nm_label_field aponta para campo inexistente '" + limpo + "'");
                labelFields.add(limpo);
            }
            tables.put(nome, new MetaModel.Table(id, nome,
                    (String) t.get("ds_table"), (String) t.get("ds_table_plural"),
                    labelFields, bool(t.get("ie_audit")), bool(t.get("ie_logical_delete")), fields));
        }

        // ---------- grupos de menu ----------
        Map<Long, String> menuGroupById = new HashMap<>();
        List<MetaModel.MenuGroup> menuGroups = new ArrayList<>();
        for (Map<String, Object> g : jdbc.queryForList(
                "SELECT nr_sequence, ds_label, nr_order FROM `menu_group` WHERE ie_active ORDER BY nr_order, nr_sequence")) {
            menuGroupById.put(((Number) g.get("nr_sequence")).longValue(), (String) g.get("ds_label"));
            menuGroups.add(new MetaModel.MenuGroup((String) g.get("ds_label"),
                    ((Number) g.get("nr_order")).intValue()));
        }

        // ---------- funções (anexadas às visões depois) ----------
        Map<Long, String> visionKeyById = new HashMap<>();
        for (Map<String, Object> v : jdbc.queryForList(
                "SELECT nr_sequence, nm_vision FROM `vision` WHERE ie_active")) {
            visionKeyById.put(((Number) v.get("nr_sequence")).longValue(), (String) v.get("nm_vision"));
        }

        List<MetaModel.Function> functions = new ArrayList<>();
        for (Map<String, Object> f : jdbc.queryForList("SELECT * FROM `function` WHERE ie_active")) {
            Long visId = numero(f.get("nr_seq_vision"));
            Long tabId = numero(f.get("nr_seq_table"));
            functions.add(new MetaModel.Function(
                    ((Number) f.get("nr_sequence")).longValue(),
                    (String) f.get("nm_function"), (String) f.get("ds_label"),
                    (String) f.get("ie_function_type"),
                    visId == null ? null : visionKeyById.get(visId),
                    tabId == null ? null : tableNameById.get(tabId),
                    (String) f.get("ie_moment"), (String) f.get("ie_placement"),
                    (String) f.get("nm_handler"), bool(f.get("ie_confirm")),
                    (String) f.get("ds_success_msg"), (String) f.get("nm_role")));
        }

        // ---------- visões ----------
        Map<String, MetaModel.Vision> visions = new LinkedHashMap<>();
        List<Map<String, Object>> visRows = jdbc.queryForList(
                "SELECT * FROM `vision` WHERE ie_active ORDER BY nr_order IS NULL, nr_order, nr_sequence");
        for (Map<String, Object> v : visRows) {
            long id = ((Number) v.get("nr_sequence")).longValue();
            String key = (String) v.get("nm_vision");
            String tipo = (String) v.get("ie_type");
            Long tableId = numero(v.get("nr_seq_table"));
            String tableName = tableId == null ? null : tableNameById.get(tableId);
            MetaModel.Table tabela = tableName == null ? null : tables.get(tableName);

            if (tableId != null && tabela == null)
                erros.add("visão " + key + ": tabela base inexistente/inativa");
            if (tableId == null && !("DASHBOARD".equals(tipo) || "CUSTOM".equals(tipo)))
                erros.add("visão " + key + ": tipo " + tipo + " exige tabela base");
            if ("CUSTOM".equals(tipo) && v.get("nm_component") == null)
                erros.add("visão " + key + ": tipo CUSTOM exige nm_component");

            // campos da visão; sem nenhum cadastrado, todos os campos da tabela
            // entram com defaults (mitigação da "armadilha do meta-framework")
            List<MetaModel.VisionField> vFields = new ArrayList<>();
            List<Map<String, Object>> vfRows = jdbc.queryForList(
                    "SELECT vf.*, tf.nm_field FROM `vision_field` vf " +
                    "JOIN `table_field` tf ON tf.nr_sequence = vf.nr_seq_table_field " +
                    "WHERE vf.nr_seq_vision = ? AND vf.ie_active " +
                    "ORDER BY COALESCE(vf.nr_order_grid, vf.nr_order_form, tf.nr_order), vf.nr_sequence", id);
            if (vfRows.isEmpty() && tabela != null) {
                for (MetaModel.Field f : tabela.fields().values()) {
                    vFields.add(new MetaModel.VisionField(f.name(), null, null,
                            true, !f.computed(), f.computed(), false, null, null, null, null, null));
                }
            } else {
                for (Map<String, Object> vf : vfRows) {
                    String nmField = (String) vf.get("nm_field");
                    if (tabela != null && !tabela.fields().containsKey(nmField))
                        erros.add("visão " + key + ": campo '" + nmField + "' não pertence à tabela " + tableName);
                    vFields.add(new MetaModel.VisionField(nmField,
                            (String) vf.get("ds_label"), (String) vf.get("ie_component"),
                            bool(vf.get("ie_show_in_grid")), bool(vf.get("ie_show_in_form")),
                            bool(vf.get("ie_read_only")), bool(vf.get("ie_filter")),
                            inteiro(vf.get("nr_order_grid")), inteiro(vf.get("nr_order_form")),
                            inteiro(vf.get("qt_width")), (String) vf.get("ds_format"),
                            (String) vf.get("nm_ref_filter_field")));
                }
            }

            List<MetaModel.Restriction> restrictions = jdbc.query(
                    "SELECT * FROM `vision_restriction` WHERE nr_seq_vision = ? AND ie_active",
                    (rs, i) -> new MetaModel.Restriction(
                            rs.getString("ie_restriction_type"), rs.getString("nm_field"),
                            rs.getString("ie_operator"), rs.getString("vl_value"),
                            rs.getString("nm_role"), rs.getString("ie_operation"),
                            rs.getString("ds_message"), rs.getString("ds_expression")),
                    id);

            List<String> children = jdbc.queryForList(
                    "SELECT nm_vision FROM `vision` WHERE nr_seq_vision_parent = ? AND ie_active " +
                    "ORDER BY nr_order IS NULL, nr_order, nr_sequence", String.class, id);

            List<MetaModel.Function> actions = functions.stream()
                    .filter(fn -> "ACTION".equals(fn.type()) && key.equals(fn.visionKey()))
                    .toList();

            List<MetaModel.Widget> widgets = jdbc.query(
                    "SELECT * FROM `dashboard_widget` WHERE nr_seq_vision = ? AND ie_active " +
                    "ORDER BY nr_order, nr_sequence",
                    (rs, i) -> {
                        long wt = rs.getLong("nr_seq_table");
                        List<String> ys = new ArrayList<>();
                        String csv = rs.getString("nm_fields_y");
                        if (csv != null) for (String y : csv.split(",")) if (!y.isBlank()) ys.add(y.trim());
                        Integer limite = rs.getObject("qt_limit") == null ? null : rs.getInt("qt_limit");
                        return new MetaModel.Widget(rs.getLong("nr_sequence"), rs.getString("ds_title"),
                                rs.getString("ie_widget_type"), tableNameById.get(wt),
                                rs.getString("nm_field_x"), ys, rs.getString("ie_aggregation"),
                                rs.getString("ie_group_by"), rs.getString("nm_group_field"),
                                rs.getBoolean("ie_use_period"), limite, rs.getInt("nr_order"));
                    }, id);

            Long parentId = numero(v.get("nr_seq_vision_parent"));
            Long groupId = numero(v.get("nr_seq_menu_group"));
            visions.put(key, new MetaModel.Vision(id, key, (String) v.get("ds_title"),
                    tableName, tipo,
                    parentId == null ? null : visionKeyById.get(parentId),
                    (String) v.get("nm_parent_fk_field"),
                    bool(v.get("ie_read_only")), bool(v.get("ie_allow_create")),
                    bool(v.get("ie_allow_update")), bool(v.get("ie_allow_delete")),
                    (String) v.get("nm_component"), (String) v.get("nm_icon"),
                    (String) v.get("ds_icon_color"),
                    groupId == null ? null : menuGroupById.get(groupId),
                    inteiro(v.get("nr_order")),
                    vFields, restrictions, children, actions, widgets));
        }

        // ciclo de visões (pai→filho) derruba o boot
        for (MetaModel.Vision v : visions.values()) {
            String atual = v.parentKey();
            int passos = 0;
            while (atual != null && passos++ < 50) {
                if (atual.equals(v.key())) { erros.add("ciclo de visões envolvendo '" + v.key() + "'"); break; }
                MetaModel.Vision pai = visions.get(atual);
                atual = pai == null ? null : pai.parentKey();
            }
        }

        Map<String, String> config = new LinkedHashMap<>();
        for (Map<String, Object> c : jdbc.queryForList(
                "SELECT nm_key, vl_value FROM `app_config` WHERE ie_active")) {
            config.put((String) c.get("nm_key"), (String) c.get("vl_value"));
        }

        if (!erros.isEmpty()) {
            throw new IllegalStateException("Dicionário inconsistente:\n - " + String.join("\n - ", erros));
        }

        return new MetaModel(domains, tables, visions, functions, menuGroups, config,
                hash(domains, tables, visions, functions, menuGroups, config));
    }

    /** Hash do conteúdo do dicionário — o front cacheia o /api/meta por ele. */
    private String hash(Object... partes) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            for (Object p : partes) md.update(mapper.writeValueAsBytes(p));
            return HexFormat.of().formatHex(md.digest()).substring(0, 12);
        } catch (Exception e) {
            throw new IllegalStateException("falha ao calcular hash do dicionário", e);
        }
    }

    private static boolean bool(Object o) {
        return o != null && (o instanceof Boolean b ? b : ((Number) o).intValue() != 0);
    }

    private static Long numero(Object o) {
        return o == null ? null : ((Number) o).longValue();
    }

    private static Integer inteiro(Object o) {
        return o == null ? null : ((Number) o).intValue();
    }
}
