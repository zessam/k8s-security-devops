# ---------- Stage 1: Build ----------
    FROM maven:3.9.5-eclipse-temurin-8-alpine AS builder

    # Set working directory inside builder image
    WORKDIR /app
    
    # Copy Maven files and source code
    COPY pom.xml .
    COPY src ./src
    
    # Build the application without running tests
    RUN mvn clean package -DskipTests=true
    
    
    # ---------- Stage 2: Runtime ----------
    FROM eclipse-temurin:8-jre-alpine AS runtime
    
    # Add metadata for traceability and security
    LABEL org.opencontainers.image.title="Secure Java App" \
          org.opencontainers.image.description="Hardened Java container using non-root user, multistage build, and healthcheck." \
          org.opencontainers.image.version="1.0.0" \
          org.opencontainers.image.source="https://github.com/zessam/k8s-security-devops" \
          org.opencontainers.image.licenses="Apache-2.0"
    
    # Add wget for HEALTHCHECK (small footprint)
    RUN apk add --no-cache wget
    
    # Create a non-root user and group
    RUN addgroup -S pipeline && adduser -S k8s-pipeline -G pipeline
    
    # Set working directory
    WORKDIR /home/k8s-pipeline
    
    # Copy the built JAR file from the build stage
    COPY --from=builder /app/target/numeric-0.0.1.jar ./app.jar
    
    # Set permissions: owned by root, not writable by app user
    RUN chown root:root app.jar && chmod 755 app.jar
    
    # Drop privileges
    USER k8s-pipeline
    
    # HEALTHCHECK to call your Spring Boot health endpoint
    HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
      CMD wget --spider -q http://localhost:8080/health || exit 1
    
    # Run the app
    ENTRYPOINT ["java", "-jar", "/home/k8s-pipeline/app.jar"]