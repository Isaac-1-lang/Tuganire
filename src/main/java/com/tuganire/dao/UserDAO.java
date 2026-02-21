package com.tuganire.dao;

import com.tuganire.model.User;
import com.tuganire.util.HibernateUtil;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.query.Query;

import java.util.List;
import java.util.Optional;

/**
 * Hibernate-based DAO for User entity.
 */
public class UserDAO {

    private final SessionFactory sessionFactory = HibernateUtil.getSessionFactory();

    public Optional<User> findById(int id) {
        try (Session session = sessionFactory.openSession()) {
            User user = session.get(User.class, id);
            return Optional.ofNullable(user);
        }
    }

    public Optional<User> findByUsername(String username) {
        try (Session session = sessionFactory.openSession()) {
            Query<User> q = session.createQuery("FROM User u WHERE u.username = :username", User.class);
            q.setParameter("username", username);
            return q.uniqueResultOptional();
        }
    }

    public Optional<User> findByEmail(String email) {
        try (Session session = sessionFactory.openSession()) {
            Query<User> q = session.createQuery("FROM User u WHERE u.email = :email", User.class);
            q.setParameter("email", email);
            return q.uniqueResultOptional();
        }
    }

    public List<User> searchByUsernameOrEmail(String query, int limit) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        String pattern = "%" + query.trim().toLowerCase() + "%";
        try (Session session = sessionFactory.openSession()) {
            Query<User> q = session.createQuery(
                    "FROM User u WHERE LOWER(u.username) LIKE :pat OR LOWER(u.email) LIKE :pat ORDER BY u.username",
                    User.class);
            q.setParameter("pat", pattern);
            q.setMaxResults(Math.min(limit, 50));
            return q.list();
        }
    }

    public User save(User user) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            session.persist(user);
            session.getTransaction().commit();
            return user;
        }
    }

    public void update(User user) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            session.merge(user);
            session.getTransaction().commit();
        }
    }

    public void setOnline(int userId, boolean online) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            User user = session.get(User.class, userId);
            if (user != null) {
                user.setOnline(online);
                user.setLastSeen(java.time.Instant.now());
                session.merge(user);
            }
            session.getTransaction().commit();
        }
    }
}
