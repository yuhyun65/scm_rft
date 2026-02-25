package kr.co.computermate.scmrft.gateway.auth;

import java.time.Duration;
import java.util.List;
import java.util.Objects;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

@Component
public class AuthVerificationClient {
  private final WebClient webClient;
  private final String verifyUri;
  private final Duration timeout;

  public AuthVerificationClient(
      WebClient.Builder webClientBuilder,
      @Value("${gateway.auth.verify-uri}") String verifyUri,
      @Value("${gateway.auth.verify-timeout-ms:1500}") long verifyTimeoutMs
  ) {
    this.webClient = webClientBuilder.build();
    this.verifyUri = verifyUri;
    this.timeout = Duration.ofMillis(Math.max(100L, verifyTimeoutMs));
  }

  public Mono<TokenVerificationResult> verify(String accessToken) {
    return webClient.post()
        .uri(verifyUri)
        .contentType(MediaType.APPLICATION_JSON)
        .bodyValue(new VerifyTokenRequest(accessToken))
        .retrieve()
        .bodyToMono(VerifyTokenResponse.class)
        .timeout(timeout)
        .map(response -> {
          if (response.active()) {
            return TokenVerificationResult.active(response.subject(), response.roles());
          }
          return TokenVerificationResult.inactive();
        })
        .onErrorResume(WebClientResponseException.class, ex -> {
          if (ex.getStatusCode().is4xxClientError()) {
            return Mono.just(TokenVerificationResult.inactive());
          }
          return Mono.just(TokenVerificationResult.unavailable());
        })
        .onErrorResume(ex -> Mono.just(TokenVerificationResult.unavailable()));
  }

  private record VerifyTokenRequest(String accessToken) {}

  private record VerifyTokenResponse(
      boolean active,
      String subject,
      List<String> roles
  ) {
    private VerifyTokenResponse {
      roles = roles == null ? List.of() : roles.stream()
          .filter(Objects::nonNull)
          .map(String::trim)
          .filter(role -> !role.isEmpty())
          .toList();
    }
  }
}

