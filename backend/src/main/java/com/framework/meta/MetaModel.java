package com.framework.meta;

import java.util.List;
import java.util.Map;

/**
 * Modelo em memória do dicionário. Carregado no boot (e no /api/meta/reload),
 * imutável depois de montado — é a fonte de onde saem o JSON de definição,
 * o SQL do CRUD genérico e as validações.
 */
public class MetaModel {

    public record DomainValue(String value, String label, int order, String color) {}

    public record Domain(long id, String name, String description, List<DomainValue> values) {}

    public record Field(
            long id, String name, String label, String type,
            String domain, String refTable,
            boolean required, boolean unique,
            Integer size, Integer scale, String min, String max,
            String regex, String defaultValue, String hint, String formula,
            int order) {

        public boolean computed() {
            return formula != null && !formula.isBlank();
        }
    }

    public record Table(
            long id, String name, String label, String labelPlural,
            List<String> labelFields, boolean audit, boolean logicalDelete,
            Map<String, Field> fields) {}

    public record VisionField(
            String field, String label, String component,
            boolean showInGrid, boolean showInForm, boolean readOnly, boolean filter,
            Integer orderGrid, Integer orderForm, Integer width,
            String format, String refFilterField) {}

    public record Restriction(
            String type,       // FILTER, PERMISSION, VALIDATION
            String field, String operator, String value,
            String role, String operation, String message, String expression) {}

    public record Widget(
            long id, String title, String type, String table,
            String fieldX, List<String> fieldsY, String aggregation,
            String groupBy, String groupField, boolean usePeriod,
            Integer limit, int order) {}

    public record Function(
            long id, String name, String label, String type,
            String visionKey, String table, String moment, String placement,
            String handler, boolean confirm, String successMsg, String role) {}

    public record Vision(
            long id, String key, String title, String table, String type,
            String parentKey, String parentFkField,
            boolean readOnly, boolean allowCreate, boolean allowUpdate, boolean allowDelete,
            String component, String icon, String iconColor,
            String menuGroup, Integer menuOrder,
            List<VisionField> fields, List<Restriction> restrictions,
            List<String> children, List<Function> actions, List<Widget> widgets) {}

    public record MenuGroup(String label, int order) {}

    public final Map<String, Domain> domains;       // por nm_domain
    public final Map<String, Table> tables;         // por nm_table
    public final Map<String, Vision> visions;       // por nm_vision
    public final List<Function> functions;          // todas (ACTION já anexada às visões)
    public final List<MenuGroup> menuGroups;
    public final Map<String, String> config;        // app_config chave/valor
    public final String version;                    // hash do dicionário

    public MetaModel(Map<String, Domain> domains, Map<String, Table> tables,
                     Map<String, Vision> visions, List<Function> functions,
                     List<MenuGroup> menuGroups, Map<String, String> config, String version) {
        this.domains = domains;
        this.tables = tables;
        this.visions = visions;
        this.functions = functions;
        this.menuGroups = menuGroups;
        this.config = config;
        this.version = version;
    }
}
