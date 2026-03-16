package kr.co.computermate.scmrft.gateway;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.cloud.gateway.support.ConfigurationService;
import org.springframework.context.ApplicationContext;
import org.springframework.data.redis.core.ReactiveStringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;
import reactor.core.publisher.Flux;

class GatewayRouteConfigurationTests {

  @Test
  void buildRedisRateLimiterInitializesDslInstanceWithApplicationContext() {
    ReactiveStringRedisTemplate redisTemplate = mock(ReactiveStringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    RedisScript<List<Long>> redisScript = mock(RedisScript.class);
    ApplicationContext applicationContext = mock(ApplicationContext.class);

    when(applicationContext.getBean(ReactiveStringRedisTemplate.class)).thenReturn(redisTemplate);
    when(applicationContext.getBean(eq(RedisRateLimiter.REDIS_SCRIPT_NAME), eq(RedisScript.class))).thenReturn(redisScript);
    when(applicationContext.getBeanNamesForType(ConfigurationService.class)).thenReturn(new String[0]);
    doReturn(Flux.just(List.of(1L, 9L)))
        .when(redisTemplate)
        .execute(eq(redisScript), anyList(), anyList());

    RedisRateLimiter rateLimiter = GatewayRouteConfiguration.buildRedisRateLimiter(10, applicationContext);
    RedisRateLimiter.Response response = rateLimiter.isAllowed("auth", "client-1").block();

    assertThat(response).isNotNull();
    assertThat(response.isAllowed()).isTrue();
    assertThat(response.getHeaders())
        .containsEntry(RedisRateLimiter.REPLENISH_RATE_HEADER, "10")
        .containsEntry(RedisRateLimiter.BURST_CAPACITY_HEADER, "20")
        .containsEntry(RedisRateLimiter.REMAINING_HEADER, "9");
  }
}
