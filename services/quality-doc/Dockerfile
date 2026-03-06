FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew && ./gradlew :services:quality-doc:bootJar --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /workspace/services/quality-doc/build/libs/*.jar /app/app.jar

EXPOSE 8084

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
