package com.tuganire.model;

import jakarta.persistence.*;

/**
 * Emoji reaction on a message. One user can have one reaction per message.
 */
@Entity
@Table(name = "reactions", indexes = {
        @Index(name = "idx_reactions_message", columnList = "message_id"),
        @Index(name = "idx_reactions_user", columnList = "user_id"),
        @Index(name = "idx_reactions_message_user", columnList = "message_id, user_id", unique = true)
})
public class Reaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "message_id", nullable = false)
    private Message message;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 10)
    private String emoji;

    // ---------- Constructors ----------
    public Reaction() {
    }

    public Reaction(Message message, User user, String emoji) {
        this.message = message;
        this.user = user;
        this.emoji = emoji;
    }

    // ---------- Getters / Setters ----------
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
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

    public String getEmoji() {
        return emoji;
    }

    public void setEmoji(String emoji) {
        this.emoji = emoji;
    }
}
