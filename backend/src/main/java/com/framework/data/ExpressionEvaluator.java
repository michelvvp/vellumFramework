package com.framework.data;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Avaliador das expressões declarativas de VALIDATION (ds_expression), ex.:
 * "reps_max >= reps_min", "qt_min_token > 0 or qt_min_token == null".
 *
 * Gramática (recursive descent):
 *   or    := and ("or" and)*
 *   and   := not ("and" not)*
 *   not   := "not" not | cmp
 *   cmp   := sum (("=="|"="|"!="|"<>"|">="|"<="|">"|"<") sum)?
 *   sum   := term (("+"|"-") term)*
 *   term  := unary (("*"|"/") unary)*
 *   unary := "-" unary | atom
 *   atom  := número | 'string' | "null" | "true" | "false" | campo | "(" or ")"
 *
 * Campos vêm do payload da linha; campo ausente vale null. Comparação com null
 * segue o intuitivo (== null / != null funcionam; <, > com null dão false).
 */
public final class ExpressionEvaluator {

    private final String src;
    private final Map<String, Object> row;
    private int pos;

    private ExpressionEvaluator(String src, Map<String, Object> row) {
        this.src = src;
        this.row = row;
    }

    /** true = expressão satisfeita (validação passa). */
    public static boolean eval(String expression, Map<String, Object> row) {
        ExpressionEvaluator e = new ExpressionEvaluator(expression, row);
        Object r = e.or();
        e.skipWs();
        if (e.pos < e.src.length())
            throw new IllegalArgumentException("expressão inválida perto de '" + e.src.substring(e.pos) + "'");
        return Boolean.TRUE.equals(r);
    }

    /* ---------- parser/avaliador ---------- */

    private Object or() {
        Object a = and();
        while (matchWord("or") || matchOp("||")) {
            Object b = and();
            a = Boolean.TRUE.equals(a) || Boolean.TRUE.equals(b);
        }
        return a;
    }

    private Object and() {
        Object a = not();
        while (matchWord("and") || matchOp("&&")) {
            Object b = not();
            a = Boolean.TRUE.equals(a) && Boolean.TRUE.equals(b);
        }
        return a;
    }

    private Object not() {
        if (matchWord("not") || matchOp("!")) return !Boolean.TRUE.equals(not());
        return cmp();
    }

    private Object cmp() {
        Object a = sum();
        String op = null;
        for (String candidato : new String[]{"==", "!=", "<>", ">=", "<=", "=", ">", "<"}) {
            if (matchOp(candidato)) { op = candidato; break; }
        }
        if (op == null) return a;
        Object b = sum();
        return switch (op) {
            case "==", "=" -> iguais(a, b);
            case "!=", "<>" -> !iguais(a, b);
            case ">" -> comparar(a, b) > 0;
            case ">=" -> comparar(a, b) >= 0;
            case "<" -> comparar(a, b) < 0;
            case "<=" -> comparar(a, b) <= 0;
            default -> throw new IllegalStateException();
        };
    }

    private Object sum() {
        Object a = term();
        while (true) {
            if (matchOp("+")) a = aritmetica(a, term(), '+');
            else if (matchOp("-")) a = aritmetica(a, term(), '-');
            else return a;
        }
    }

    private Object term() {
        Object a = unary();
        while (true) {
            if (matchOp("*")) a = aritmetica(a, unary(), '*');
            else if (matchOp("/")) a = aritmetica(a, unary(), '/');
            else return a;
        }
    }

    private Object unary() {
        if (matchOp("-")) {
            Object v = unary();
            return v == null ? null : numero(v).negate();
        }
        return atom();
    }

    private Object atom() {
        skipWs();
        if (pos >= src.length()) throw new IllegalArgumentException("expressão terminou cedo demais");
        char c = src.charAt(pos);
        if (c == '(') {
            pos++;
            Object v = or();
            skipWs();
            if (pos >= src.length() || src.charAt(pos) != ')')
                throw new IllegalArgumentException("falta fechar parêntese");
            pos++;
            return v;
        }
        if (c == '\'') {
            int fim = src.indexOf('\'', pos + 1);
            if (fim < 0) throw new IllegalArgumentException("string sem fechar");
            String s = src.substring(pos + 1, fim);
            pos = fim + 1;
            return s;
        }
        if (Character.isDigit(c)) {
            int inicio = pos;
            while (pos < src.length() && (Character.isDigit(src.charAt(pos)) || src.charAt(pos) == '.')) pos++;
            return new BigDecimal(src.substring(inicio, pos));
        }
        if (Character.isLetter(c) || c == '_') {
            int inicio = pos;
            while (pos < src.length() && (Character.isLetterOrDigit(src.charAt(pos)) || src.charAt(pos) == '_')) pos++;
            String palavra = src.substring(inicio, pos);
            return switch (palavra.toLowerCase()) {
                case "null" -> null;
                case "true" -> true;
                case "false" -> false;
                default -> row.get(palavra);
            };
        }
        throw new IllegalArgumentException("caractere inesperado '" + c + "'");
    }

    /* ---------- semântica ---------- */

    private static boolean iguais(Object a, Object b) {
        if (a == null || b == null) return a == b;
        if (ehNumero(a) && ehNumero(b)) return numero(a).compareTo(numero(b)) == 0;
        if (a instanceof Boolean || b instanceof Boolean)
            return String.valueOf(a).equalsIgnoreCase(String.valueOf(b));
        return String.valueOf(a).equals(String.valueOf(b));
    }

    /** null em <,>,<=,>= nunca satisfaz (retorna "incomparável" = 2). */
    private static int comparar(Object a, Object b) {
        if (a == null || b == null) return 2;
        if (ehNumero(a) && ehNumero(b)) return numero(a).compareTo(numero(b));
        return String.valueOf(a).compareTo(String.valueOf(b));
    }

    private static Object aritmetica(Object a, Object b, char op) {
        if (a == null || b == null) return null;
        BigDecimal x = numero(a), y = numero(b);
        return switch (op) {
            case '+' -> x.add(y);
            case '-' -> x.subtract(y);
            case '*' -> x.multiply(y);
            case '/' -> y.signum() == 0 ? null : x.divide(y, 10, java.math.RoundingMode.HALF_UP);
            default -> throw new IllegalStateException();
        };
    }

    private static boolean ehNumero(Object o) {
        if (o instanceof Number) return true;
        if (o instanceof String s) {
            try { new BigDecimal(s); return true; } catch (NumberFormatException e) { return false; }
        }
        return false;
    }

    private static BigDecimal numero(Object o) {
        if (o instanceof BigDecimal bd) return bd;
        if (o instanceof Number n) return new BigDecimal(n.toString());
        return new BigDecimal(String.valueOf(o));
    }

    /* ---------- léxico ---------- */

    private void skipWs() {
        while (pos < src.length() && Character.isWhitespace(src.charAt(pos))) pos++;
    }

    private boolean matchOp(String op) {
        skipWs();
        if (src.regionMatches(pos, op, 0, op.length())) {
            // não confundir ">" com ">=" nem "=" com "=="
            if ((op.equals(">") || op.equals("<") || op.equals("=")) && pos + 1 < src.length()
                    && (src.charAt(pos + 1) == '=' || (op.equals("<") && src.charAt(pos + 1) == '>'))) return false;
            pos += op.length();
            return true;
        }
        return false;
    }

    private boolean matchWord(String palavra) {
        skipWs();
        int fim = pos + palavra.length();
        if (fim <= src.length() && src.substring(pos, fim).equalsIgnoreCase(palavra)
                && (fim == src.length() || !Character.isLetterOrDigit(src.charAt(fim)))) {
            pos = fim;
            return true;
        }
        return false;
    }
}
