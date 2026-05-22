# ============================================
# STAGE 1: BUILD - Compila el proyecto Java
# ============================================
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder

WORKDIR /build

# Copiamos pom.xml primero para cachear dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiamos código fuente y compilamos
COPY src ./src
RUN mvn clean package -DskipTests -B

# ============================================
# STAGE 2: RUN - Imagen final minimalista
# ============================================
FROM eclipse-temurin:21-jre-alpine AS runner

LABEL maintainer="Antonio Vivar - Innovatech Chile"
LABEL description="Backend API REST Despachos - Innovatech Chile"

# Usuario no-root (mínimo privilegio - exigido por rúbrica IE1)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Solo copiamos el JAR final desde stage builder
COPY --from=builder /build/target/*.jar app.jar

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8081

ENV DB_ENDPOINT=db \
    DB_PORT=3306 \
    DB_NAME=despachos_db \
    DB_USERNAME=despacho_user \
    DB_PASSWORD=DespachoPass2025!

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]