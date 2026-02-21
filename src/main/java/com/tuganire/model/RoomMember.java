package com.tuganire.model;

import jakarta.persistence.*;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;

/**
 * Association between User and Room. Composite key: roomId + userId.
 */
@Entity
@Table(name = "room_members", indexes = {
        @Index(name = "idx_room_members_room", columnList = "room_id"),
        @Index(name = "idx_room_members_user", columnList = "user_id"),
        @Index(name = "idx_room_members_room_user", columnList = "room_id, user_id", unique = true)
})
public class RoomMember {

    @EmbeddedId
    private RoomMemberId id = new RoomMemberId();

    @ManyToOne(fetch = FetchType.LAZY,cascade  = CascadeType.ALL)
    @MapsId("roomId")
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY,cascade  = CascadeType.ALL)
    @MapsId("userId")
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt = Instant.now();

    @Column(name = "last_read_at")
    private Instant lastReadAt;

    // ---------- Constructors ----------
    public RoomMember() {
    }

    public RoomMember(Room room, User user) {
        this.room = room;
        this.user = user;
    }

    // ---------- Getters / Setters ----------
    public RoomMemberId getId() {
        return id;
    }

    public void setId(RoomMemberId id) {
        this.id = id;
    }

    public Room getRoom() {
        return room;
    }

    public void setRoom(Room room) {
        this.room = room;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Instant getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(Instant joinedAt) {
        this.joinedAt = joinedAt;
    }

    public Instant getLastReadAt() {
        return lastReadAt;
    }

    public void setLastReadAt(Instant lastReadAt) {
        this.lastReadAt = lastReadAt;
    }

    @Embeddable
    public static class RoomMemberId implements Serializable {
        @Column(name = "room_id")
        private Integer roomId;
        @Column(name = "user_id")
        private Integer userId;

        public RoomMemberId() {
        }

        public RoomMemberId(Integer roomId, Integer userId) {
            this.roomId = roomId;
            this.userId = userId;
        }

        public Integer getRoomId() {
            return roomId;
        }

        public void setRoomId(Integer roomId) {
            this.roomId = roomId;
        }

        public Integer getUserId() {
            return userId;
        }

        public void setUserId(Integer userId) {
            this.userId = userId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            RoomMemberId that = (RoomMemberId) o;
            return Objects.equals(roomId, that.roomId) && Objects.equals(userId, that.userId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(roomId, userId);
        }
    }
}
