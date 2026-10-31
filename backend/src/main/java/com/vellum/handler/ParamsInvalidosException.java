package com.vellum.handler;

import com.vellum.data.ValidationException;

import java.util.List;

/** Parâmetros de ação que não passam nos `handler_param`: vira 400 (e não o 422 do CRUD). */
public class ParamsInvalidosException extends ValidationException {

    public ParamsInvalidosException(List<FieldError> errors) {
        super(errors);
    }
}
