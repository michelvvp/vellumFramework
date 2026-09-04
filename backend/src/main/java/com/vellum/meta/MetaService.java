package com.vellum.meta;

import com.vellum.auth.CurrentUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Guarda o MetaModel em memória (cache do boot) e monta o JSON de definição
 * (seção 4 da especificação) filtrado pelos papéis do usuário: o front só
 * conhece visões que pode ler.
 */
@Service
@Order(2) // depois do AdminSeeder
public class MetaService implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(MetaService.class);

    private final MetadataLoader loader;
    private final SchemaValidator schema;
    private volatile MetaModel meta;

    public MetaService(MetadataLoader loader, SchemaValidator schema) {
        this.loader = loader;
        this.schema = schema;
    }

    /** Boot fail-fast: dicionário inconsistente derruba a aplicação. */
    @Override
    public void run(ApplicationArguments args) {
        reload();
    }

    public synchronized void reload() {
        MetaModel novo = loader.load();
        schema.validar(novo);
        this.meta = novo;
        log.info("Dicionário carregado: {} tabelas, {} visões, versão {}",
                novo.tables.size(), novo.visions.size(), novo.version);
    }

    public MetaModel get() {
        MetaModel m = meta;
        if (m == null) throw new IllegalStateException("dicionário ainda não carregado");
        return m;
    }

    /* ---------- JSON de definição ---------- */

    public Map<String, Object> definicaoPara(CurrentUser user) {
        MetaModel m = get();
        Map<String, Object> raiz = new LinkedHashMap<>();
        raiz.put("version", m.version);
        raiz.put("app", Map.of(
                "name", m.config.getOrDefault("app.name", "Vellum"),
                "theme", Map.of(
                        "accent", m.config.getOrDefault("theme.accent", "#0a84ff"),
                        "accentHover", m.config.getOrDefault("theme.accentHover", "#3396ff"),
                        "accentTint", m.config.getOrDefault("theme.accentTint", "rgba(10,132,255,.18)"),
                        "onAccent", m.config.getOrDefault("theme.onAccent", "#ffffff"))));

        Map<String, Object> domains = new LinkedHashMap<>();
        m.domains.forEach((nome, d) -> domains.put(nome, d.values().stream()
                .map(v -> mapa("value", v.value(), "label", v.label(), "color", v.color()))
                .toList()));
        raiz.put("domains", domains);

        Map<String, Object> tables = new LinkedHashMap<>();
        m.tables.forEach((nome, t) -> {
            Map<String, Object> fields = new LinkedHashMap<>();
            t.fields().forEach((fn, f) -> fields.put(fn, mapa(
                    "type", f.type(), "label", f.label(),
                    "domain", f.domain(), "refTable", f.refTable(),
                    "required", f.required(), "unique", f.unique(),
                    "size", f.size(), "scale", f.scale(),
                    "min", f.min(), "max", f.max(),
                    "default", f.defaultValue(), "hint", f.hint(),
                    "computed", f.computed() ? true : null)));
            tables.put(nome, mapa(
                    "label", t.label(), "labelPlural", t.labelPlural(),
                    "labelFields", t.labelFields(), "fields", fields));
        });
        raiz.put("tables", tables);

        List<Map<String, Object>> visions = new ArrayList<>();
        for (MetaModel.Vision v : m.visions.values()) {
            if (!Permissions.podeLer(v, user)) continue;
            visions.add(visaoJson(m, v, user));
        }
        raiz.put("visions", visions);

        raiz.put("menuGroups", m.menuGroups.stream()
                .map(g -> mapa("label", g.label(), "order", g.order())).toList());
        raiz.put("user", mapa("id", user.id(), "name", user.name(),
                "login", user.login(), "roles", user.roles()));
        return raiz;
    }

    private Map<String, Object> visaoJson(MetaModel m, MetaModel.Vision v, CurrentUser user) {
        List<Map<String, Object>> fields = v.fields().stream().map(f -> {
            MetaModel.Field def = v.table() == null ? null
                    : m.tables.get(v.table()).fields().get(f.field());
            return mapa(
                    "field", f.field(),
                    "label", f.label() != null ? f.label() : (def != null ? def.label() : f.field()),
                    "component", f.component(),
                    "grid", f.showInGrid(), "form", f.showInForm(),
                    "readOnly", f.readOnly() || (def != null && def.computed()),
                    "filter", f.filter(),
                    "orderGrid", f.orderGrid(), "orderForm", f.orderForm(),
                    "width", f.width(), "format", f.format(),
                    "refFilterField", f.refFilterField());
        }).toList();

        List<Map<String, Object>> actions = v.actions().stream()
                .filter(a -> a.role() == null || user.hasRole(a.role()))
                .map(a -> mapa("name", a.name(), "label", a.label(),
                        "placement", a.placement(), "confirm", a.confirm(),
                        "successMsg", a.successMsg()))
                .toList();

        // filhas que o usuário pode ler (o menu de contexto do pai vem daqui)
        List<String> children = v.children().stream()
                .filter(c -> {
                    MetaModel.Vision filho = m.visions.get(c);
                    return filho != null && Permissions.podeLer(filho, user);
                }).toList();

        List<Map<String, Object>> widgets = v.widgets().stream()
                .map(w -> mapa("id", w.id(), "title", w.title(), "type", w.type(),
                        "usePeriod", w.usePeriod()))
                .toList();

        // validações vão ao front para pré-validação (UX); filtros e permissões
        // são aplicados no backend e não precisam ser expostos
        List<Map<String, Object>> validations = v.restrictions().stream()
                .filter(r -> "VALIDATION".equals(r.type()))
                .map(r -> mapa("field", r.field(), "expression", r.expression(),
                        "message", r.message()))
                .toList();

        return mapa(
                "key", v.key(), "title", v.title(), "table", v.table(),
                "type", v.type(),
                "parent", v.parentKey(), "parentFkField", v.parentFkField(),
                "component", v.component(),
                "icon", v.icon(), "iconColor", v.iconColor(),
                "menuGroup", v.menuGroup(), "order", v.menuOrder(),
                "readOnly", v.readOnly(),
                "allow", mapa(
                        "create", !v.readOnly() && v.allowCreate() && Permissions.pode(v, user, "CREATE"),
                        "update", !v.readOnly() && v.allowUpdate() && Permissions.pode(v, user, "UPDATE"),
                        "delete", !v.readOnly() && v.allowDelete() && Permissions.pode(v, user, "DELETE")),
                "fields", fields, "children", children, "actions", actions,
                "widgets", widgets, "validations", validations);
    }

    /** LinkedHashMap tolerante a null (Map.of não aceita) — nulls ficam de fora do JSON. */
    private static Map<String, Object> mapa(Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) {
            if (kv[i + 1] != null) m.put((String) kv[i], kv[i + 1]);
        }
        return m;
    }
}
