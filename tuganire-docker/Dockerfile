# Use Tomcat 10 with Java 17
FROM tomcat:10.1.34-jdk17

# Copy your WAR to Tomcat webapps
COPY target/tuganire.war /usr/local/tomcat/webapps/

# Copy env if your app reads it
COPY tuganire.env /opt/tuganire/.env

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]