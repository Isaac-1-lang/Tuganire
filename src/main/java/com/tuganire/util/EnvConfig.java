package com.tuganire.util;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Loads configuration from .env file or system environment.
 * Never hardcode secrets - use EnvConfig.get("KEY") everywhere.
 */
public final class EnvConfig {

    private static final Map<String, String> ENV_VARS = new HashMap<>();

    static {
        loadEnv();
    }

    private static void loadEnv() {
        try {
            Path[] candidates = {
                Paths.get(System.getProperty("tuganire.project.dir", "")),
                Paths.get(System.getenv("TUGANIRE_PROJECT_DIR") != null ? System.getenv("TUGANIRE_PROJECT_DIR") : ""),
                Paths.get("."),
                Paths.get("C:/Users/user/Documents/YEAR 2/Group projects/TERM I/Ecommerce/tuganire")
            };

            Path envFile = null;
            for (Path candidate : candidates) {
                if (candidate.toString().isEmpty()) continue;
                Path p = candidate.resolve(".env");
                if (Files.exists(p)) {
                    envFile = p;
                    break;
                }
            }

            if (envFile != null) {
                Files.readAllLines(envFile).forEach(line -> {
                    String trimmed = line.trim();
                    if (!trimmed.isEmpty() && !trimmed.startsWith("#") && trimmed.contains("=")) {
                        int idx = trimmed.indexOf('=');
                        String key = trimmed.substring(0, idx).trim();
                        String val = trimmed.substring(idx + 1).trim();
                        ENV_VARS.put(key, val);
                    }
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private EnvConfig() {}

    public static Optional<String> get(String key) {
        String sysVal = System.getenv(key);
        return sysVal != null && !sysVal.isBlank() ? Optional.of(sysVal.trim()) : Optional.empty();
        if (ENV_VARS.containsKey(key)) {
            return Optional.of(ENV_VARS.get(key));
        }
        return Optional.empty();
        
    }

    public static String getRequired(String key) {
        return get(key).orElseThrow(() ->
                new IllegalStateException("Missing required config key '" + key + "'. "
                        + "Make sure your .env file exists in the project root and contains this key. "
                        + "Alternatively, set -Dtuganire.project.dir=<project-root> as a VM option."));
    }

    public static String get(String key, String defaultValue) {
        return get(key).orElse(defaultValue);
    }
}

