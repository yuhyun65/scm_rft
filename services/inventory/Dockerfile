FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew && ./gradlew :services:inventory:bootJar --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /workspace/services/inventory/build/libs/*.jar /app/app.jar

EXPOSE 8086

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
