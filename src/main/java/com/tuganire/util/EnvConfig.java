package com.tuganire.util;

import io.github.cdimascio.dotenv.Dotenv;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

/**
 * Loads configuration from .env file or system environment.
 * Never hardcode secrets - use EnvConfig.get("KEY") everywhere.
 *
 * <p>For Tomcat: set VM option -Dtuganire.project.dir=&lt;project-root&gt; if .env
 * is not found (working directory may differ when running from IDE).
 */
public final class EnvConfig {

    private static Dotenv dotenv;

    static {
        try {
            var builder = Dotenv.configure().ignoreIfMissing();
            Path projectDir = getProjectDirectory();
            if (projectDir != null) {
                builder = builder.directory(projectDir.toAbsolutePath().toString());
            }
            dotenv = builder.load();
        } catch (Exception e) {
            dotenv = null; // Fall back to system env only
        }
    }

    private static Path getProjectDirectory() {
        String dir = System.getProperty("tuganire.project.dir");
        if (dir != null && !dir.isBlank()) {
            return Paths.get(dir);
        }
        dir = System.getenv("TUGANIRE_PROJECT_DIR");
        if (dir != null && !dir.isBlank()) {
            return Paths.get(dir);
        }
        return null; // Use default (current working directory)
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
                new IllegalStateException("Missing required config: " + key + ". " +
                        "Create .env from env.example in the project root and set DB_URL, DB_USERNAME, DB_PASSWORD. " +
                        "If running from Tomcat/IDE, ensure Working directory is the project root, or add VM option: " +
                        "-Dtuganire.project.dir=<absolute-path-to-project>"));
    }

    /**
     * Get config with default fallback.
     */
    public static String get(String key, String defaultValue) {
        return get(key).orElse(defaultValue);
    }
}
