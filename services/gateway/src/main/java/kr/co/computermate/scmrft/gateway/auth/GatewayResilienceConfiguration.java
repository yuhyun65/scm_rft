package kr.co.computermate.scmrft.gateway.auth;

import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.circuitbreaker.resilience4j.ReactiveResilience4JCircuitBreakerFactory;
import org.springframework.cloud.circuitbreaker.resilience4j.Resilience4JConfigBuilder;
import org.springframework.cloud.client.circuitbreaker.Customizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayResilienceConfiguration {
  @Bean
  public Customizer<ReactiveResilience4JCircuitBreakerFactory> authVerifyCircuitBreakerCustomizer(
      @Value("${gateway.auth.verify-timeout-ms:1500}") long verifyTimeoutMs,
      @Value("${gateway.auth.circuit-breaker.sliding-window-size:20}") int slidingWindowSize,
      @Value("${gateway.auth.circuit-breaker.minimum-number-of-calls:10}") int minimumNumberOfCalls,
      @Value("${gateway.auth.circuit-breaker.failure-rate-threshold:50}") float failureRateThreshold,
      @Value("${gateway.auth.circuit-breaker.wait-duration-in-open-state-ms:10000}") long waitDurationInOpenStateMs,
      @Value("${gateway.auth.circuit-breaker.permitted-number-of-calls-in-half-open-state:3}") int permittedHalfOpenCalls
  ) {
    int windowSize = Math.max(2, slidingWindowSize);
    int minCalls = Math.max(1, minimumNumberOfCalls);
    long timeoutMs = Math.max(100L, verifyTimeoutMs);
    long waitMs = Math.max(100L, waitDurationInOpenStateMs);
    int halfOpenCalls = Math.max(1, permittedHalfOpenCalls);

    return factory -> factory.configure(builder -> new Resilience4JConfigBuilder("authVerify")
        .timeLimiterConfig(TimeLimiterConfig.custom()
            .timeoutDuration(Duration.ofMillis(timeoutMs))
            .build())
        .circuitBreakerConfig(CircuitBreakerConfig.custom()
            .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
            .slidingWindowSize(windowSize)
            .minimumNumberOfCalls(minCalls)
            .failureRateThreshold(failureRateThreshold)
            .waitDurationInOpenState(Duration.ofMillis(waitMs))
            .permittedNumberOfCallsInHalfOpenState(halfOpenCalls)
            .build())
        .build(), "authVerify");
  }
}

