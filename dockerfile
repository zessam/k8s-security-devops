# ---------- Stage 1: Build ----------
    FROM maven:3.9.5-eclipse-temurin-8-alpine AS builder

    WORKDIR /app
    
    COPY pom.xml .
    COPY src ./src
    
    # Build without tests
    RUN mvn clean package -DskipTests=true
    
    
    # ---------- Stage 2: Runtime ----------
    FROM eclipse-temurin:8-jre-alpine
    
    LABEL org.opencontainers.image.title="Secure Java App" \
          org.opencontainers.image.description="Hardened Java container using non-root user, multistage build, and healthcheck." \
          org.opencontainers.image.version="1.0.0" \
          org.opencontainers.image.source="https://github.com/zessam/k8s-security-devops" \
          org.opencontainers.image.licenses="Apache-2.0"
    
    # Add healthcheck tool and create non-root user in one layer
    RUN apk add --no-cache wget && \
        addgroup -S pipeline && \
        adduser -S k8s-pipeline -G pipeline
    
    WORKDIR /home/k8s-pipeline
    
    # Copy the JAR file and set permissions in a single layer
    COPY --from=builder /app/target/numeric-0.0.1.jar ./app.jar
    RUN chown root:root app.jar && chmod 755 app.jar
    
    USER k8s-pipeline
    
    # HEALTHCHECK using Spring Boot actuator
    HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
      CMD wget --spider -q http://localhost:8080/health || exit 1
    
    ENTRYPOINT ["java", "-jar", "app.jar"]
    