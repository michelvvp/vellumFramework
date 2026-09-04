package com.framework.data;

import com.framework.auth.AuthService;
import com.framework.auth.CurrentUser;
import com.framework.function.FunctionRegistry;
import com.framework.meta.MetaModel;
import com.framework.meta.MetaService;
import com.framework.meta.Permissions;
import com.framework.meta.SchemaValidator;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * CRUD genérico sobre qualquer tabela cadastrada no dicionário
 * (GET/POST/PUT/DELETE /api/data/{nm_table}). Toda operação exige a visão de
 * contexto (_vision): é dela que saem os filtros de segurança (FILTER com
 * variáveis de contexto), as permissões (PERMISSION + functions AUTH) e as
 * validações — sempre reaplicados aqui, nunca confiados ao front.
 */
@Service
public class DataService {

    /** identificadores SQL só podem vir do dicionário e ainda assim são conferidos */
    private static final Pattern IDENT = Pattern.compile("^[A-Za-z_][A-Za-z0-9_]{0,63}$");
    private static final int LIMITE_PADRAO = 1000;

    private final JdbcTemplate jdbc;
    private final MetaService meta;
    private final SchemaValidator schema;
    private final ValidationEngine validation;
    private final RestrictionEngine restriction;
    private final FunctionRegistry functions;
    private final AuthService auth;

    public DataService(JdbcTemplate jdbc, MetaService meta, SchemaValidator schema,
                       ValidationEngine validation, RestrictionEngine restriction,
                       FunctionRegistry functions, AuthService auth) {
        this.jdbc = jdbc;
        this.meta = meta;
        this.schema = schema;
        this.validation = validation;
        this.restriction = restriction;
        this.functions = functions;
        this.auth = auth;
    }

    /* ================================ leitura ================================ */

    public List<Map<String, Object>> list(String table, String visionKey, CurrentUser user,
                                          Map<String, String> params) {
        MetaModel.Table t = tabela(table);
        MetaModel.Vision v = visao(t, visionKey, user, "READ", null, null);
        Long parentId = parentId(v, params);

        StringBuilder sql = new StringBuilder(selectBase(t));
        List<Object> args = new ArrayList<>();
        List<String> where = new ArrayList<>(whereBase(t, v, user, parentId, args));

        // filtros por query param: campo=valor, campo__gte, campo__lte, campo__like
        for (Map.Entry<String, String> p : params.entrySet()) {
            String chave = p.getKey();
            if (chave.startsWith("_") || p.getValue() == null || p.getValue().isBlank()) continue;
            String campo = chave, sufixo = "=";
            if (chave.endsWith("__gte")) { campo = chave.substring(0, chave.length() - 5); sufixo = ">="; }
            else if (chave.endsWith("__lte")) { campo = chave.substring(0, chave.length() - 5); sufixo = "<="; }
            else if (chave.endsWith("__like")) { campo = chave.substring(0, chave.length() - 6); sufixo = "LIKE"; }
            MetaModel.Field f = t.fields().get(campo);
            if (f == null || f.computed()) continue; // param desconhecido é ignorado
            if (sufixo.equals("LIKE")) {
                where.add("t.`" + ident(campo) + "` LIKE ?");
                args.add("%" + p.getValue() + "%");
            } else {
                where.add("t.`" + ident(campo) + "` " + sufixo + " ?");
                args.add(coagir(f, p.getValue()));
            }
        }

        if (!where.isEmpty()) sql.append(" WHERE ").append(String.join(" AND ", where));
        sql.append(orderBy(t));

        int limite = intParam(params.get("_limit"), LIMITE_PADRAO);
        int offset = intParam(params.get("_offset"), 0);
        sql.append(" LIMIT ").append(limite).append(" OFFSET ").append(offset);

        return jdbc.queryForList(sql.toString(), args.toArray());
    }

    public Map<String, Object> get(String table, long id, String visionKey, CurrentUser user) {
        MetaModel.Table t = tabela(table);
        MetaModel.Vision v = visao(t, visionKey, user, "READ", id, null);
        List<Object> args = new ArrayList<>();
        List<String> where = new ArrayList<>(whereBase(t, v, user, null, args));
        where.add("t.nr_sequence = ?");
        args.add(id);
        List<Map<String, Object>> rows = jdbc.queryForList(
                selectBase(t) + " WHERE " + String.join(" AND ", where), args.toArray());
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "registro não encontrado");
        return rows.get(0);
    }

    /* ================================ escrita ================================ */

    @Transactional
    public Map<String, Object> create(String table, String visionKey, CurrentUser user,
                                      Map<String, Object> payload) {
        MetaModel.Table t = tabela(table);
        MetaModel.Vision v = visao(t, visionKey, user, "CREATE", null, payload);

        Map<String, Object> linha = coagirPayload(t, payload, true);
        aplicarDefaults(t, linha);
        functions.hooks(t.name(), "BEFORE_CREATE", user, null, linha);
        validation.validar(t, v, linha, null);

        List<String> colunas = new ArrayList<>();
        List<Object> valores = new ArrayList<>();
        for (Map.Entry<String, Object> e : linha.entrySet()) {
            MetaModel.Field f = t.fields().get(e.getKey());
            if (f == null || f.computed()) continue;
            colunas.add("`" + ident(e.getKey()) + "`");
            valores.add(paraBanco(f, e.getValue()));
        }
        if (t.audit() && schema.colunasDe(t.name()).contains("nm_user_created")) {
            colunas.add("`nm_user_created`");
            valores.add(user.login());
        }
        if (colunas.isEmpty()) throw new IllegalArgumentException("payload vazio");

        String sql = "INSERT INTO `" + t.name() + "` (" + String.join(", ", colunas) + ") VALUES ("
                + "?,".repeat(colunas.size() - 1) + "?)";
        KeyHolder key = new GeneratedKeyHolder();
        jdbc.update(con -> {
            PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            for (int i = 0; i < valores.size(); i++) ps.setObject(i + 1, valores.get(i));
            return ps;
        }, key);
        long id = key.getKey().longValue();

        functions.hooks(t.name(), "AFTER_CREATE", user, id, linha);
        return get(table, id, visionKey, user);
    }

    @Transactional
    public Map<String, Object> update(String table, long id, String visionKey, CurrentUser user,
                                      Map<String, Object> payload) {
        MetaModel.Table t = tabela(table);
        MetaModel.Vision v = visao(t, visionKey, user, "UPDATE", id, payload);
        exigirVisivel(t, v, user, id); // row-level security: só altera o que a visão alcança

        Map<String, Object> mudancas = coagirPayload(t, payload, false);
        // a linha completa (atual + mudanças) é o que as validações enxergam
        Map<String, Object> atual = linhaCrua(t, id);
        Map<String, Object> linha = new LinkedHashMap<>(atual);
        linha.putAll(mudancas);
        functions.hooks(t.name(), "BEFORE_UPDATE", user, id, linha);
        // hooks podem ter mudado a linha; o que difere do atual é o que persiste
        for (Map.Entry<String, Object> e : linha.entrySet()) {
            if (t.fields().containsKey(e.getKey()) && !java.util.Objects.equals(atual.get(e.getKey()), e.getValue())) {
                mudancas.put(e.getKey(), e.getValue());
            }
        }
        validation.validar(t, v, linha, id);

        if (!mudancas.isEmpty()) {
            List<String> sets = new ArrayList<>();
            List<Object> valores = new ArrayList<>();
            for (Map.Entry<String, Object> e : mudancas.entrySet()) {
                MetaModel.Field f = t.fields().get(e.getKey());
                if (f == null || f.computed()) continue;
                sets.add("`" + ident(e.getKey()) + "` = ?");
                valores.add(paraBanco(f, e.getValue()));
            }
            if (!sets.isEmpty()) {
                if (t.audit() && schema.colunasDe(t.name()).contains("dt_updated"))
                    sets.add("`dt_updated` = NOW()");
                if (t.audit() && schema.colunasDe(t.name()).contains("nm_user_updated")) {
                    sets.add("`nm_user_updated` = ?");
                    valores.add(user.login());
                }
                valores.add(id);
                jdbc.update("UPDATE `" + t.name() + "` SET " + String.join(", ", sets)
                        + " WHERE nr_sequence = ?", valores.toArray());
            }
        }

        functions.hooks(t.name(), "AFTER_UPDATE", user, id, linha);
        return get(table, id, visionKey, user);
    }

    @Transactional
    public void delete(String table, long id, String visionKey, CurrentUser user) {
        MetaModel.Table t = tabela(table);
        MetaModel.Vision v = visao(t, visionKey, user, "DELETE", id, null);
        exigirVisivel(t, v, user, id);

        functions.hooks(t.name(), "BEFORE_DELETE", user, id, null);
        if (t.logicalDelete()) {
            jdbc.update("UPDATE `" + t.name() + "` SET ie_active = FALSE WHERE nr_sequence = ?", id);
        } else {
            jdbc.update("DELETE FROM `" + t.name() + "` WHERE nr_sequence = ?", id);
        }
        functions.hooks(t.name(), "AFTER_DELETE", user, id, null);
    }

    /** Reordenação por arrasto: recebe a lista completa de ids na ordem final. */
    @Transactional
    public void reorder(String table, String visionKey, CurrentUser user, List<Long> ids) {
        MetaModel.Table t = tabela(table);
        MetaModel.Vision v = visao(t, visionKey, user, "UPDATE", null, null);
        if (!t.fields().containsKey("nr_order") && !schema.colunasDe(t.name()).contains("nr_order"))
            throw new IllegalArgumentException("tabela " + table + " não tem coluna nr_order");
        for (long id : ids) exigirVisivel(t, v, user, id);
        for (int i = 0; i < ids.size(); i++) {
            jdbc.update("UPDATE `" + t.name() + "` SET nr_order = ? WHERE nr_sequence = ?",
                    i + 1, ids.get(i));
        }
    }

    /* ============================ lookup (combos) ============================ */

    /** Opções id+rótulo de uma entidade para combos de FK — só o necessário, nada da linha. */
    public List<Map<String, Object>> lookup(String table, Map<String, String> params) {
        MetaModel.Table t = tabela(table);
        String rotulo = exprRotulo(t, "t");
        StringBuilder sql = new StringBuilder("SELECT t.nr_sequence AS id, " + rotulo + " AS label FROM `"
                + t.name() + "` t");
        List<Object> args = new ArrayList<>();
        List<String> where = new ArrayList<>();
        if (t.logicalDelete()) where.add("t.ie_active");
        for (Map.Entry<String, String> p : params.entrySet()) {
            if (p.getKey().startsWith("_") || p.getValue() == null || p.getValue().isBlank()) continue;
            if ("q".equals(p.getKey())) {
                where.add(rotulo + " LIKE ?");
                args.add("%" + p.getValue() + "%");
                continue;
            }
            MetaModel.Field f = t.fields().get(p.getKey());
            if (f == null || f.computed()) continue;
            where.add("t.`" + ident(p.getKey()) + "` = ?");
            args.add(coagir(f, p.getValue()));
        }
        if (!where.isEmpty()) sql.append(" WHERE ").append(String.join(" AND ", where));
        sql.append(" ORDER BY label LIMIT 500");
        return jdbc.queryForList(sql.toString(), args.toArray());
    }

    /* ============================== montagem SQL ============================= */

    private String selectBase(MetaModel.Table t) {
        List<String> cols = new ArrayList<>();
        cols.add("t.nr_sequence");
        List<String> joins = new ArrayList<>();
        int nJoin = 0;
        for (MetaModel.Field f : t.fields().values()) {
            if ("PASSWORD".equals(f.type())) continue; // hash nunca sai do banco
            if (f.computed()) {
                cols.add("(" + f.formula() + ") AS `" + ident(f.name()) + "`");
                continue;
            }
            cols.add("t.`" + ident(f.name()) + "`");
            if ("ENTITY".equals(f.type()) && f.refTable() != null) {
                MetaModel.Table ref = meta.get().tables.get(f.refTable());
                String alias = "r" + (++nJoin);
                joins.add("LEFT JOIN `" + ref.name() + "` " + alias
                        + " ON " + alias + ".nr_sequence = t.`" + ident(f.name()) + "`");
                cols.add(exprRotulo(ref, alias) + " AS `" + ident(f.name()) + "__label`");
            }
        }
        return "SELECT " + String.join(", ", cols) + " FROM `" + t.name() + "` t "
                + String.join(" ", joins);
    }

    /** Rótulo de um registro: CONCAT_WS dos labelFields; sem labelFields, o próprio id. */
    private String exprRotulo(MetaModel.Table t, String alias) {
        if (t.labelFields().isEmpty()) return "CAST(" + alias + ".nr_sequence AS CHAR)";
        List<String> partes = t.labelFields().stream()
                .map(lf -> alias + ".`" + ident(lf) + "`").toList();
        return partes.size() == 1 ? partes.get(0) : "CONCAT_WS(' · ', " + String.join(", ", partes) + ")";
    }

    private List<String> whereBase(MetaModel.Table t, MetaModel.Vision v, CurrentUser user,
                                   Long parentId, List<Object> args) {
        List<String> where = new ArrayList<>();
        if (t.logicalDelete()) where.add("t.ie_active");
        RestrictionEngine.Where filtros = restriction.filtros(v, user, parentId);
        if (!filtros.sql().isEmpty()) {
            where.add(filtros.sql());
            args.addAll(filtros.params());
        }
        return where;
    }

    private String orderBy(MetaModel.Table t) {
        return t.fields().containsKey("nr_order") || schema.colunasDe(t.name()).contains("nr_order")
                ? " ORDER BY t.nr_order, t.nr_sequence"
                : " ORDER BY t.nr_sequence";
    }

    /* ============================ visão/segurança ============================ */

    private MetaModel.Table tabela(String nome) {
        MetaModel.Table t = meta.get().tables.get(nome);
        if (t == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                "tabela '" + nome + "' não cadastrada no dicionário");
        return t;
    }

    private MetaModel.Vision visao(MetaModel.Table t, String visionKey, CurrentUser user,
                                   String operation, Long recordId, Map<String, Object> payload) {
        if (visionKey == null || visionKey.isBlank())
            throw new IllegalArgumentException("parâmetro _vision é obrigatório");
        MetaModel.Vision v = meta.get().visions.get(visionKey);
        if (v == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                "visão '" + visionKey + "' não cadastrada");
        if (!t.name().equals(v.table()))
            throw new IllegalArgumentException("visão '" + visionKey + "' não é da tabela " + t.name());

        if (!Permissions.pode(v, user, operation))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "sem permissão de " + operation + " em " + v.title());
        boolean escrita = switch (operation) {
            case "CREATE" -> !v.readOnly() && v.allowCreate();
            case "UPDATE" -> !v.readOnly() && v.allowUpdate();
            case "DELETE" -> !v.readOnly() && v.allowDelete();
            default -> true;
        };
        if (!escrita) throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "operação " + operation + " desabilitada na visão " + v.title());

        functions.autorizar(v, user, operation, recordId, payload);
        return v;
    }

    /** 404 se o registro não for alcançável pelos filtros da visão (não vaza existência). */
    private void exigirVisivel(MetaModel.Table t, MetaModel.Vision v, CurrentUser user, long id) {
        List<Object> args = new ArrayList<>();
        List<String> where = new ArrayList<>(whereBase(t, v, user, null, args));
        where.add("t.nr_sequence = ?");
        args.add(id);
        Integer n = jdbc.queryForObject("SELECT COUNT(*) FROM `" + t.name() + "` t WHERE "
                + String.join(" AND ", where), Integer.class, args.toArray());
        if (n == null || n == 0)
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "registro não encontrado");
    }

    private Long parentId(MetaModel.Vision v, Map<String, String> params) {
        if (v.parentFkField() == null) return null;
        String valor = params.get(v.parentFkField());
        return valor == null || valor.isBlank() ? null : Long.parseLong(valor);
    }

    /* ============================== coerção ================================= */

    /** Linha crua do banco (sem joins), para merge no update e para expressões. */
    private Map<String, Object> linhaCrua(MetaModel.Table t, long id) {
        Map<String, Object> row = jdbc.queryForMap(
                "SELECT * FROM `" + t.name() + "` WHERE nr_sequence = ?", id);
        Map<String, Object> soCampos = new LinkedHashMap<>();
        for (MetaModel.Field f : t.fields().values()) {
            if (!f.computed() && row.containsKey(f.name())) soCampos.put(f.name(), row.get(f.name()));
        }
        return soCampos;
    }

    private Map<String, Object> coagirPayload(MetaModel.Table t, Map<String, Object> payload,
                                              boolean criacao) {
        Map<String, Object> linha = new LinkedHashMap<>();
        for (Map.Entry<String, Object> e : payload.entrySet()) {
            MetaModel.Field f = t.fields().get(e.getKey());
            if (f == null || f.computed()) continue; // campo desconhecido é ignorado
            Object v = e.getValue();
            if ("PASSWORD".equals(f.type())) {
                // update com senha vazia mantém a atual
                if (v == null || String.valueOf(v).isBlank()) {
                    if (criacao && f.required()) linha.put(f.name(), null); // required acusa
                    continue;
                }
                linha.put(f.name(), auth.hash(String.valueOf(v)));
                continue;
            }
            linha.put(f.name(), v == null || "".equals(v) ? null : coagir(f, v));
        }
        return linha;
    }

    private void aplicarDefaults(MetaModel.Table t, Map<String, Object> linha) {
        for (MetaModel.Field f : t.fields().values()) {
            if (f.computed() || linha.containsKey(f.name()) || f.defaultValue() == null) continue;
            linha.put(f.name(), coagir(f, f.defaultValue()));
        }
    }

    private Object coagir(MetaModel.Field f, Object v) {
        try {
            String s = String.valueOf(v);
            return switch (f.type()) {
                case "INTEGER", "ENTITY" -> v instanceof Number n ? n.longValue() : Long.parseLong(s.trim());
                case "DECIMAL" -> v instanceof BigDecimal bd ? bd : new BigDecimal(s.trim());
                case "BOOLEAN" -> v instanceof Boolean b ? b
                        : (s.equalsIgnoreCase("true") || s.equals("1"));
                case "DATE" -> LocalDate.parse(s.trim());
                case "DATETIME" -> LocalDateTime.parse(s.trim().replace(' ', 'T'),
                        DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                case "TIME" -> LocalTime.parse(s.trim());
                default -> s; // STRING, TEXT, DOMAIN, JSON
            };
        } catch (RuntimeException e) {
            throw new ValidationException(List.of(new ValidationException.FieldError(
                    f.name(), "type", f.label() + " em formato inválido")));
        }
    }

    /** Tipos java.time viram SQL sem drama; o resto passa direto. */
    private Object paraBanco(MetaModel.Field f, Object v) {
        if (v instanceof LocalDate d) return java.sql.Date.valueOf(d);
        if (v instanceof LocalDateTime dt) return java.sql.Timestamp.valueOf(dt);
        if (v instanceof LocalTime t) return java.sql.Time.valueOf(t);
        return v;
    }

    private static String ident(String nome) {
        if (!IDENT.matcher(nome).matches())
            throw new IllegalArgumentException("identificador inválido: " + nome);
        return nome;
    }

    private static int intParam(String v, int padrao) {
        try { return v == null ? padrao : Math.max(0, Integer.parseInt(v)); }
        catch (NumberFormatException e) { return padrao; }
    }
}
