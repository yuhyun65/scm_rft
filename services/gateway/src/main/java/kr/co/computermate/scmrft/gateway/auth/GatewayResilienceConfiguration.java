package kr.co.computermate.scmrft.gateway.auth;

import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import java.time.Duration;
import kr.co.computermate.scmrft.gateway.policy.GatewayPolicyDocument;
import kr.co.computermate.scmrft.gateway.policy.GatewayRoutePolicyResolver;
import kr.co.computermate.scmrft.gateway.policy.GatewayRoutePolicyResolver.ResolvedRoutePolicy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.circuitbreaker.resilience4j.ReactiveResilience4JCircuitBreakerFactory;
import org.springframework.cloud.circuitbreaker.resilience4j.Resilience4JConfigBuilder;
import org.springframework.cloud.client.circuitbreaker.Customizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayResilienceConfiguration {
  private static final Logger log = LoggerFactory.getLogger(GatewayResilienceConfiguration.class);

  @Bean
  public Customizer<ReactiveResilience4JCircuitBreakerFactory> gatewayCircuitBreakerCustomizer(
      @Value("${gateway.auth.verify-timeout-ms:1500}") long verifyTimeoutMs,
      @Value("${gateway.auth.circuit-breaker.sliding-window-size:20}") int slidingWindowSize,
      @Value("${gateway.auth.circuit-breaker.minimum-number-of-calls:10}") int minimumNumberOfCalls,
      @Value("${gateway.auth.circuit-breaker.failure-rate-threshold:50}") float failureRateThreshold,
      @Value("${gateway.auth.circuit-breaker.wait-duration-in-open-state-ms:10000}") long waitDurationInOpenStateMs,
      @Value("${gateway.auth.circuit-breaker.permitted-number-of-calls-in-half-open-state:3}") int permittedHalfOpenCalls,
      GatewayPolicyDocument policy,
      GatewayRoutePolicyResolver policyResolver
  ) {
    int windowSize = Math.max(2, slidingWindowSize);
    int minCalls = Math.max(1, minimumNumberOfCalls);
    long timeoutMs = Math.max(100L, verifyTimeoutMs);
    long waitMs = Math.max(100L, waitDurationInOpenStateMs);
    int halfOpenCalls = Math.max(1, permittedHalfOpenCalls);

    return factory -> {
      factory.configure(builder -> new Resilience4JConfigBuilder("authVerify")
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

      for (ResolvedRoutePolicy route : policyResolver.resolve(policy)) {
        if (!route.circuitBreaker().isEnabled()) {
          continue;
        }
        String breakerName = "cb-" + route.id();
        long routeTimeoutMs = Math.max(3000L, route.requestTimeoutMs());
        long routeWaitMs = Math.max(100L, route.circuitBreaker().getWaitDurationInOpenStateMs());
        float routeFailureThreshold = clampPercentage(route.circuitBreaker().getFailureRateThreshold());
        float routeSlowCallThreshold = clampPercentage(route.circuitBreaker().getSlowCallRateThreshold());

        factory.configure(builder -> new Resilience4JConfigBuilder(breakerName)
            .timeLimiterConfig(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofMillis(routeTimeoutMs))
                .build())
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
                .slidingWindowSize(20)
                .minimumNumberOfCalls(10)
                .failureRateThreshold(routeFailureThreshold)
                .slowCallRateThreshold(routeSlowCallThreshold)
                .waitDurationInOpenState(Duration.ofMillis(routeWaitMs))
                .permittedNumberOfCallsInHalfOpenState(3)
                .build())
            .build(), breakerName);

        log.info("Configured route circuit-breaker: name={} timeoutMs={} failureRate={} slowCallRate={} waitOpenMs={}",
            breakerName, routeTimeoutMs, routeFailureThreshold, routeSlowCallThreshold, routeWaitMs);
      }
    };
  }

  private float clampPercentage(int value) {
    if (value < 1) {
      return 1.0f;
    }
    if (value > 100) {
      return 100.0f;
    }
    return (float) value;
  }
}

