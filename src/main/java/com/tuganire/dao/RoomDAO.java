package com.tuganire.dao;

import com.tuganire.model.Room;
import com.tuganire.model.RoomMember;
import com.tuganire.model.RoomType;
import com.tuganire.model.User;
import com.tuganire.util.HibernateUtil;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.query.Query;

import java.util.List;
import java.util.Optional;

/**
 * Hibernate-based DAO for Room and RoomMember.
 */
public class RoomDAO {

    private final SessionFactory sessionFactory = HibernateUtil.getSessionFactory();

    public Optional<Room> findById(int id) {
        try (Session session = sessionFactory.openSession()) {
            Room room = session.get(Room.class, id);
            return Optional.ofNullable(room);
        }
    }

    /**
     * Rooms where the user is a member, ordered by last activity (simplified: by room id for now).
     */
    public List<Room> findRoomsByUserId(int userId) {
        try (Session session = sessionFactory.openSession()) {
            Query<Room> q = session.createQuery(
                    "SELECT rm.room FROM RoomMember rm WHERE rm.user.id = :userId ORDER BY rm.joinedAt DESC",
                    Room.class);
            q.setParameter("userId", userId);
            return q.list();
        }
    }

    /**
     * Find existing DM room between two users, if any.
     */
    public Optional<Room> findDmBetweenUsers(int userId1, int userId2) {
        try (Session session = sessionFactory.openSession()) {
            // DM rooms have exactly 2 members - find room where both users are members
            Query<Room> q = session.createQuery(
                    "SELECT r FROM Room r WHERE r.type = :dm " +
                            "AND r IN (SELECT rm.room FROM RoomMember rm WHERE rm.user.id = :u1) " +
                            "AND r IN (SELECT rm.room FROM RoomMember rm WHERE rm.user.id = :u2)",
                    Room.class);
            q.setParameter("dm", RoomType.DM);
            q.setParameter("u1", userId1);
            q.setParameter("u2", userId2);
            return q.uniqueResultOptional();
        }
    }

    public Room save(Room room) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            session.persist(room);
            session.getTransaction().commit();
            return room;
        }
    }

    public void addMember(Room room, User user) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            RoomMember rm = new RoomMember(room, user);
            session.persist(rm);
            session.getTransaction().commit();
        }
    }

    public void removeMember(int roomId, int userId) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            Query<RoomMember> q = session.createQuery(
                    "FROM RoomMember rm WHERE rm.room.id = :roomId AND rm.user.id = :userId",
                    RoomMember.class);
            q.setParameter("roomId", roomId);
            q.setParameter("userId", userId);
            RoomMember rm = q.uniqueResult();
            if (rm != null) {
                session.remove(rm);
            }
            session.getTransaction().commit();
        }
    }

    public boolean isMember(int roomId, int userId) {
        try (Session session = sessionFactory.openSession()) {
            Query<Long> q = session.createQuery(
                    "SELECT COUNT(rm) FROM RoomMember rm WHERE rm.room.id = :roomId AND rm.user.id = :userId",
                    Long.class);
            q.setParameter("roomId", roomId);
            q.setParameter("userId", userId);
            Long count = q.uniqueResult();
            return count != null && count > 0;
        }
    }

    public List<User> getMembers(int roomId) {
        try (Session session = sessionFactory.openSession()) {
            Query<User> q = session.createQuery(
                    "SELECT rm.user FROM RoomMember rm WHERE rm.room.id = :roomId ORDER BY rm.joinedAt",
                    User.class);
            q.setParameter("roomId", roomId);
            return q.list();
        }
    }

    public java.time.Instant getLastReadAt(int roomId, int userId) {
        try (Session session = sessionFactory.openSession()) {
            Query<RoomMember> q = session.createQuery(
                    "FROM RoomMember rm WHERE rm.room.id = :roomId AND rm.user.id = :userId",
                    RoomMember.class);
            q.setParameter("roomId", roomId);
            q.setParameter("userId", userId);
            RoomMember rm = q.uniqueResult();
            return rm != null ? rm.getLastReadAt() : null;
        }
    }

    public void updateLastReadAt(int roomId, int userId, java.time.Instant when) {
        try (Session session = sessionFactory.openSession()) {
            session.beginTransaction();
            Query<RoomMember> q = session.createQuery(
                    "FROM RoomMember rm WHERE rm.room.id = :roomId AND rm.user.id = :userId",
                    RoomMember.class);
            q.setParameter("roomId", roomId);
            q.setParameter("userId", userId);
            RoomMember rm = q.uniqueResult();
            if (rm != null) {
                rm.setLastReadAt(when);
                session.merge(rm);
            }
            session.getTransaction().commit();
        }
    }
}
