package com.vellum.dashboard;

import com.vellum.auth.AuthTokenFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class DashboardController {

    private final DashboardService dashboard;

    public DashboardController(DashboardService dashboard) {
        this.dashboard = dashboard;
    }

    @GetMapping("/api/dashboard/{visionKey}")
    public Map<String, Object> dados(@PathVariable String visionKey,
                                     @RequestParam(required = false) String from,
                                     @RequestParam(required = false) String to,
                                     HttpServletRequest req) {
        return dashboard.dados(visionKey, AuthTokenFilter.usuarioAtual(req), from, to);
    }
}
