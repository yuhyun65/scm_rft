FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew && ./gradlew :services:order-lot:bootJar --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /workspace/services/order-lot/build/libs/*.jar /app/app.jar

EXPOSE 8085

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
