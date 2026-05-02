# Build stage — compile the app with Gradle
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

# Grab gradle wrapper + config first so dependencies get cached
COPY gradlew gradlew
COPY gradle/ gradle/
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Now copy source and build (tests run in CI, skip them here)
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Runtime stage — slim image with just the JRE
FROM eclipse-temurin:17-jre

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Don't run as root
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser
WORKDIR /app
COPY --from=build /app/build/libs/*.jar sync-service.jar
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "sync-service.jar"]
