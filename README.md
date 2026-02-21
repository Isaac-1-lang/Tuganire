# Tuganire — Real-Time Chat Application

**Tuganire** ("Let's Talk" in Kinyarwanda) is a full-stack real-time chat application built with pure Java EE — no Spring, no frameworks.

## Tech Stack

- **Frontend:** JSP + JSTL + HTML5 + CSS3 + Vanilla JavaScript
- **Backend:** Jakarta EE Servlets
- **Real-Time:** Java WebSocket API (`jakarta.websocket`) — `@ServerEndpoint`
- **Database:** PostgreSQL (local) / Neon (production)
- **ORM:** Hibernate with HQL/Criteria API
- **Connection Pool:** HikariCP
- **Auth:** JWT in httpOnly cookies, jBCrypt password hashing
- **Server:** Apache Tomcat 10+
- **Build:** Maven

## Prerequisites

- Java 17+
- Apache Tomcat 10+
- PostgreSQL (or Neon for production)
- Maven 3.6+

## Quick Start

### 1. Clone and configure

```bash
# Copy the env template and fill in your values
cp env.example .env
```

Edit `.env`:

```env
DB_URL=jdbc:postgresql://localhost:5432/tuganire
DB_USERNAME=postgres
DB_PASSWORD=yourpassword
JWT_SECRET=your_super_secret_key_min_32_chars
JWT_EXPIRY_HOURS=24
HIBERNATE_HBM2DDL_AUTO=update
```

### 2. Create the database

```sql
CREATE DATABASE tuganire;
```

Hibernate will create tables on first run (`hbm2ddl.auto=update`).

### 3. Build and deploy

```bash
mvn clean package
# Deploy target/tuganire.war to Tomcat
```

Or run with Tomcat Maven plugin:

```bash
mvn tomcat7:run
# Or configure Tomcat 10 in your IDE
```

### 4. Access the app

- **Login:** `http://localhost:8080/tuganire/views/login.jsp`
- **Register:** `http://localhost:8080/tuganire/views/register.jsp`
- **Chat:** `http://localhost:8080/tuganire/chat`

## Project Structure

```
tuganire/
├── src/main/java/com/tuganire/
│   ├── servlet/       # AuthServlet, ChatServlet, RoomServlet, UserServlet
│   ├── websocket/     # ChatEndpoint, HttpSessionConfigurator
│   ├── dao/           # UserDAO, MessageDAO, RoomDAO
│   ├── service/       # AuthService, ChatService, RoomService, UserService
│   ├── model/         # User, Room, Message, RoomMember, MessageStatus, Reaction
│   ├── filter/        # AuthFilter (JWT validation)
│   ├── util/          # EnvConfig, HibernateUtil, JwtUtil, PasswordUtil, CsrfUtil
│   └── listener/      # HibernateContextListener
└── src/main/webapp/
    ├── views/         # login.jsp, register.jsp, chat.jsp, error.jsp
    ├── css/style.css
    └── js/chat.js
```

## API Endpoints

| URL | Method | Action |
|-----|--------|--------|
| `/auth/login` | POST | Authenticate, issue JWT cookie |
| `/auth/register` | POST | Create account |
| `/auth/logout` | GET | Clear JWT cookie |
| `/rooms` | GET / POST | List joined rooms / create room |
| `/rooms/{id}/join` | POST | Join a room |
| `/messages` | GET | Load message history (paginated, JSON) |
| `/users/search` | GET | Search users |
| `/users/avatar` | POST | Update avatar |
| `/chat` | GET | Main chat page |

## WebSocket Protocol

Connect to `ws://host/tuganire/ws/chat`. Messages (JSON):

- `{"type":"MESSAGE","roomId":1,"content":"Hello!"}`
- `{"type":"TYPING","roomId":1,"isTyping":true}`
- `{"type":"SEEN","roomId":1,"messageId":42}`
- `{"type":"REACTION","messageId":42,"emoji":"👍"}`
- `{"type":"JOIN_ROOM","roomId":1}`

## Production (Neon)

Update `.env`:

```env
DB_URL=jdbc:postgresql://your-neon-host/tuganire?sslmode=require
HIBERNATE_HBM2DDL_AUTO=validate
```

## Security

- JWT verified on every request and WebSocket handshake
- Passwords hashed with jBCrypt
- CSRF tokens on POST forms
- Input sanitization to prevent XSS
- `.env` never committed — listed in `.gitignore`

## License

MIT
