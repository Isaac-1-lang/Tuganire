package com.tuganire.model;

import jakarta.persistence.*;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;

/**
 * Tracks message status per user (SENT/DELIVERED/READ). Composite key: messageId + userId.
 */
@Entity
@Table(name = "message_status", indexes = {
        @Index(name = "idx_message_status_message", columnList = "message_id"),
        @Index(name = "idx_message_status_user", columnList = "user_id"),
        @Index(name = "idx_message_status_message_user", columnList = "message_id, user_id", unique = true)
})
public class MessageStatus {

    @EmbeddedId
    private MessageStatusId id = new MessageStatusId();

    @ManyToOne(fetch = FetchType.LAZY,cascade  = CascadeType.ALL)
    @MapsId("messageId")
    @JoinColumn(name = "message_id", nullable = false)
    private Message message;

    @ManyToOne(fetch = FetchType.LAZY,cascade  = CascadeType.ALL)
    @MapsId("userId")
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MessageStatusType status = MessageStatusType.SENT;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    // ---------- Constructors ----------
    public MessageStatus() {
    }

    public MessageStatus(Message message, User user, MessageStatusType status) {
        this.message = message;
        this.user = user;
        this.status = status;
    }

    // ---------- Getters / Setters ----------
    public MessageStatusId getId() {
        return id;
    }

    public void setId(MessageStatusId id) {
        this.id = id;
    }

    public Message getMessage() {
        return message;
    }

    public void setMessage(Message message) {
        this.message = message;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public MessageStatusType getStatus() {
        return status;
    }

    public void setStatus(MessageStatusType status) {
        this.status = status;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Embeddable
    public static class MessageStatusId implements Serializable {
        @Column(name = "message_id")
        private Integer messageId;
        @Column(name = "user_id")
        private Integer userId;

        public MessageStatusId() {
        }

        public MessageStatusId(Integer messageId, Integer userId) {
            this.messageId = messageId;
            this.userId = userId;
        }

        public Integer getMessageId() {
            return messageId;
        }

        public void setMessageId(Integer messageId) {
            this.messageId = messageId;
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
            MessageStatusId that = (MessageStatusId) o;
            return Objects.equals(messageId, that.messageId) && Objects.equals(userId, that.userId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(messageId, userId);
        }
    }
}
