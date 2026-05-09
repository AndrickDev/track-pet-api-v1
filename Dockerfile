FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copia apenas o pom.xml e baixa dependências (melhor cache)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia o restante do código-fonte
COPY src ./src

# Compila o projeto (gera o .jar)
RUN mvn clean package -DskipTests

# =========================
# Etapa 2: Execução da App
# =========================
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copia o jar da etapa anterior
ARG JAR_FILE=/app/target/*.jar
COPY --from=build ${JAR_FILE} app.jar

# Configura timezone e porta padrão
ENV TZ=America/Sao_Paulo
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]