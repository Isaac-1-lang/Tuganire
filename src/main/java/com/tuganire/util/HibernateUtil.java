package com.tuganire.util;

import org.hibernate.SessionFactory;
import org.hibernate.boot.Metadata;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistry;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.hibernate.cfg.Environment;

import java.util.HashMap;
import java.util.Map;

/**
 * Hibernate SessionFactory singleton. Uses HikariCP and reads config from EnvConfig.
 */
public final class HibernateUtil {

    private static volatile SessionFactory sessionFactory;

    private HibernateUtil() {
    }

    public static SessionFactory getSessionFactory() {
        if (sessionFactory == null) {
            synchronized (HibernateUtil.class) {
                if (sessionFactory == null) {
                    sessionFactory = buildSessionFactory();
                }
            }
        }
        return sessionFactory;
    }

    private static SessionFactory buildSessionFactory() {
        Map<String, Object> settings = new HashMap<>();

        // Connection - from .env
        settings.put(Environment.DATASOURCE, createHikariDataSource());
        settings.put(Environment.DIALECT, "org.hibernate.dialect.PostgreSQLDialect");
        settings.put(Environment.SHOW_SQL, EnvConfig.get("HIBERNATE_SHOW_SQL", "false").equalsIgnoreCase("true"));
        settings.put(Environment.HBM2DDL_AUTO, EnvConfig.get("HIBERNATE_HBM2DDL_AUTO", "update"));
        settings.put(Environment.FORMAT_SQL, true);

        StandardServiceRegistry registry = new StandardServiceRegistryBuilder()
                .applySettings(settings)
                .build();

        MetadataSources sources = new MetadataSources(registry);
        sources.addAnnotatedClass(com.tuganire.model.User.class);
        sources.addAnnotatedClass(com.tuganire.model.Room.class);
        sources.addAnnotatedClass(com.tuganire.model.RoomMember.class);
        sources.addAnnotatedClass(com.tuganire.model.Message.class);
        sources.addAnnotatedClass(com.tuganire.model.MessageStatus.class);
        sources.addAnnotatedClass(com.tuganire.model.Reaction.class);

        try {
            Metadata metadata = sources.getMetadataBuilder().build();
            return metadata.getSessionFactoryBuilder().build();
        } catch (Exception e) {
            StandardServiceRegistryBuilder.destroy(registry);
            throw new RuntimeException("Failed to build Hibernate SessionFactory", e);
        }
    }

    private static com.zaxxer.hikari.HikariDataSource createHikariDataSource() {
        com.zaxxer.hikari.HikariDataSource ds = new com.zaxxer.hikari.HikariDataSource();
        ds.setJdbcUrl(EnvConfig.getRequired("DB_URL"));
        ds.setUsername(EnvConfig.getRequired("DB_USERNAME"));
        ds.setPassword(EnvConfig.getRequired("DB_PASSWORD"));
        ds.setDriverClassName("org.postgresql.Driver");
        ds.setMaximumPoolSize(10);
        ds.setMinimumIdle(2);
        return ds;
    }

    public static void shutdown() {
        if (sessionFactory != null) {
            sessionFactory.close();
            sessionFactory = null;
        }
    }
}
