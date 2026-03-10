# Multi-stage build for Tuganire
# Stage 1: Build the WAR file
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies (cached layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime with Tomcat
FROM tomcat:10.1-jdk17

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR from builder stage
COPY --from=builder /app/target/tuganire.war /usr/local/tomcat/webapps/ROOT.war

# Set working directory for .env file discovery
WORKDIR /usr/local/tomcat

# Copy environment file to working directory (from tuganire-docker subdirectory)
COPY tuganire-docker/tuganire.env .env

# Set environment variable to help app find .env
ENV TUGANIRE_PROJECT_DIR=/usr/local/tomcat

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
