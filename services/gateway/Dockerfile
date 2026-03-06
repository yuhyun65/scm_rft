FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew && ./gradlew :services:gateway:bootJar --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /workspace/services/gateway/build/libs/*.jar /app/app.jar
COPY infra/gateway/policies /app/infra/gateway/policies

ENV GATEWAY_POLICY_PATH=/app/infra/gateway/policies/cutover-isolation.yaml
ENV GATEWAY_EMERGENCY_STOP_ENABLED=false
EXPOSE 18080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]

