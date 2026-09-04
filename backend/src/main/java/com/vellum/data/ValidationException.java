package com.vellum.data;

import java.util.List;
import java.util.Map;

/** Erros de validação estruturados: o front distribui em .field-error por campo. */
public class ValidationException extends RuntimeException {

    public record FieldError(String field, String code, String message) {}

    private final List<FieldError> errors;

    public ValidationException(List<FieldError> errors) {
        super(errors.isEmpty() ? "validação falhou" : errors.get(0).message());
        this.errors = errors;
    }

    public List<Map<String, String>> asMaps() {
        return errors.stream().map(e -> Map.of(
                "field", e.field() == null ? "" : e.field(),
                "code", e.code(), "message", e.message())).toList();
    }
}
