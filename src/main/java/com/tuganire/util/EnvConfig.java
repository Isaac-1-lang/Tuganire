package com.tuganire.util;

import io.github.cdimascio.dotenv.Dotenv;

import java.util.Optional;

/**
 * Loads configuration from .env file or system environment.
 * Never hardcode secrets - use EnvConfig.get("KEY") everywhere.
 */
public final class EnvConfig {

    private static Dotenv dotenv;

    static {
        try {
            dotenv = Dotenv.configure()
                    .ignoreIfMissing()
                    .load();
        } catch (Exception e) {
            dotenv = null; // Fall back to system env only
        }
    }

    private EnvConfig() {
    }

    /**
     * Get config value: first from .env, then from system environment.
     *
     * @param key The configuration key (e.g. "DB_URL", "JWT_SECRET")
     * @return Optional containing the value, or empty if not found
     */
    public static Optional<String> get(String key) {
        if (dotenv != null) {
            String val = dotenv.get(key);
            if (val != null && !val.isBlank()) {
                return Optional.of(val.trim());
            }
        }
        String sysVal = System.getenv(key);
        return sysVal != null && !sysVal.isBlank() ? Optional.of(sysVal.trim()) : Optional.empty();
    }

    /**
     * Get required config value. Throws if missing.
     */
    public static String getRequired(String key) {
        return get(key).orElseThrow(() ->
                new IllegalStateException("Missing required config: " + key + ". Check .env file."));
    }

    /**
     * Get config with default fallback.
     */
    public static String get(String key, String defaultValue) {
        return get(key).orElse(defaultValue);
    }
}
