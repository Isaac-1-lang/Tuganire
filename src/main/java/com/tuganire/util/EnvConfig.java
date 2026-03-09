package com.tuganire.util;

import io.github.cdimascio.dotenv.Dotenv;

import java.io.File;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Loads configuration from .env file or system environment.
 * Never hardcode secrets - use EnvConfig.get("KEY") everywhere.
 *
 * <p>Searches for .env in multiple locations:
 * 1. -Dtuganire.project.dir system property
 * 2. TUGANIRE_PROJECT_DIR environment variable
 * 3. Classpath root (and parent directories up to the project root)
 * 4. Current working directory (default)
 */
public final class EnvConfig {

    private static Dotenv dotenv;

    static {
        try {
            Path envDir = findEnvDirectory();
            var builder = Dotenv.configure().ignoreIfMissing();
            if (envDir != null) {
                builder = builder.directory(envDir.toAbsolutePath().toString());
            }
            dotenv = builder.load();
        } catch (Exception e) {
            dotenv = null; // Fall back to system env only
        }
    }

    /**
     * Searches multiple candidate directories for a .env file.
     */
    private static Path findEnvDirectory() {
        List<Path> candidates = new ArrayList<>();

        // 1. Explicit system property
        String dir = System.getProperty("tuganire.project.dir");
        if (dir != null && !dir.isBlank()) {
            candidates.add(Paths.get(dir));
        }

        // 2. Explicit environment variable
        dir = System.getenv("TUGANIRE_PROJECT_DIR");
        if (dir != null && !dir.isBlank()) {
            candidates.add(Paths.get(dir));
        }

        // 3. Classpath-based discovery (works inside Tomcat)
        try {
            URL resource = EnvConfig.class.getClassLoader().getResource("");
            if (resource != null) {
                Path classesDir = Paths.get(resource.toURI());
                // classesDir is typically WEB-INF/classes - walk up to find .env
                for (Path p = classesDir; p != null; p = p.getParent()) {
                    candidates.add(p);
                }
            }
        } catch (Exception ignored) {
        }

        // 4. Current working directory (last resort)
        candidates.add(Paths.get("."));

        // Return first directory that actually contains a .env file
        for (Path candidate : candidates) {
            if (Files.exists(candidate.resolve(".env"))) {
                return candidate;
            }
        }

        return null; // Will use cwd as default via dotenv
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
                new IllegalStateException("Missing required config key '" + key + "'. "
                        + "Make sure your .env file exists in the project root and contains this key. "
                        + "Alternatively, set -Dtuganire.project.dir=<project-root> as a VM option."));
    }

    /**
     * Get config with default fallback.
     */
    public static String get(String key, String defaultValue) {
        return get(key).orElse(defaultValue);
    }
}

