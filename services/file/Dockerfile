FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew && ./gradlew :services:file:bootJar --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /workspace/services/file/build/libs/*.jar /app/app.jar

EXPOSE 8087

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
