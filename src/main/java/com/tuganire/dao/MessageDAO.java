package com.tuganire.dao;

import com.tuganire.model.*;
import com.tuganire.util.HibernateUtil;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.query.Query;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Collections;

/**
 * Hibernate-based DAO for Message, MessageStatus, Reaction.
 */
public class MessageDAO {

    private final SessionFactory sessionFactory = HibernateUtil.getSessionFactory();

    public Optional<Message> findById(int id) {
        try (Session session = sessionFactory.openSession()) {
            Message msg = session.get(Message.class, id);
            return Optional.ofNullable(msg);
        }
    }

    /**
     * Paginated message history for a room, newest first.
     */
    public List<Message> findByRoomId(int roomId, int limit, int offset) {
        try (Session session = sessionFactory.openSession()) {
            Query<Message> q = session.createQuery(
                    "FROM Message m WHERE m.room.id = :roomId ORDER BY m.createdAt DESC",
                    Message.class);
            q.setParameter("roomId", roomId);
            q.setMaxResults(limit);
            q.setFirstResult(offset);
            List<Message> list = q.list();
            // Return in chronological order (oldest first) for display
            Collections.reverse(list);
            return list;
        }
    }

    public Message save(Message message) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            session.persist(message);
            session.getTransaction().commit();
            return message;
        }
    }

    /**
     * Mark message as READ for a user.
     */
    public void markAsRead(int messageId, int userId) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            Message msg = session.get(Message.class, messageId);
            User user = session.get(User.class, userId);
            if (msg != null && user != null) {
                Query<MessageStatus> q = session.createQuery(
                        "FROM MessageStatus ms WHERE ms.message.id = :msgId AND ms.user.id = :uId",
                        MessageStatus.class);
                q.setParameter("msgId", messageId);
                q.setParameter("uId", userId);
                MessageStatus ms = q.uniqueResult();
                if (ms != null) {
                    ms.setStatus(MessageStatusType.READ);
                    ms.setUpdatedAt(Instant.now());
                    session.merge(ms);
                } else {
                    MessageStatus newMs = new MessageStatus(msg, user, MessageStatusType.READ);
                    session.persist(newMs);
                }
            }
            session.getTransaction().commit();
        }
    }

    /**
     * Add or update reaction. One reaction per user per message.
     */
    public Reaction addOrUpdateReaction(int messageId, int userId, String emoji) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            Message msg = session.get(Message.class, messageId);
            User user = session.get(User.class, userId);
            if (msg == null || user == null) {
                session.getTransaction().rollback();
                return null;
            }
            Query<Reaction> q = session.createQuery(
                    "FROM Reaction r WHERE r.message.id = :msgId AND r.user.id = :uId",
                    Reaction.class);
            q.setParameter("msgId", messageId);
            q.setParameter("uId", userId);
            Reaction r = q.uniqueResult();
            if (r != null) {
                r.setEmoji(emoji);
                session.merge(r);
                session.getTransaction().commit();
                return r;
            }
            Reaction newR = new Reaction(msg, user, emoji);
            session.persist(newR);
            session.getTransaction().commit();
            return newR;
        }
    }

    /**
     * Get latest message in a room for preview.
     */
    public Optional<Message> getLastMessage(int roomId) {
        try (Session session = sessionFactory.openSession()) {
            Query<Message> q = session.createQuery(
                    "FROM Message m WHERE m.room.id = :roomId ORDER BY m.createdAt DESC",
                    Message.class);
            q.setParameter("roomId", roomId);
            q.setMaxResults(1);
            return q.uniqueResultOptional();
        }
    }

    /**
     * Count unread messages in a room for a user (messages after lastReadAt).
     */
    public long countUnread(int roomId, int userId, Instant lastReadAt) {
        try (Session session = sessionFactory.openSession()) {
            String hql = "SELECT COUNT(m) FROM Message m WHERE m.room.id = :roomId AND m.sender.id != :userId";
            if (lastReadAt != null) {
                hql += " AND m.createdAt > :lastRead";
            }
            Query<Long> q = session.createQuery(hql, Long.class);
            q.setParameter("roomId", roomId);
            q.setParameter("userId", userId);
            if (lastReadAt != null) {
                q.setParameter("lastRead", lastReadAt);
            }
            Long count = q.uniqueResult();
            return count != null ? count : 0;
        }
    }
}
