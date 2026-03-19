package kr.co.computermate.scmrft.gateway.dashboard;

import java.util.Locale;
import kr.co.computermate.scmrft.gateway.auth.AuthVerificationClient;
import kr.co.computermate.scmrft.gateway.auth.TokenVerificationResult;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/dashboard/v1")
public class DashboardSummaryController {
  private final AuthVerificationClient authVerificationClient;
  private final DashboardSummaryService dashboardSummaryService;

  public DashboardSummaryController(
      AuthVerificationClient authVerificationClient,
      DashboardSummaryService dashboardSummaryService
  ) {
    this.authVerificationClient = authVerificationClient;
    this.dashboardSummaryService = dashboardSummaryService;
  }

  @GetMapping("/summary")
  public Mono<ResponseEntity<DashboardSummaryResponse>> getSummary(
      @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorizationHeader
  ) {
    String bearerToken = extractBearerToken(authorizationHeader);
    if (bearerToken == null) {
      return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
    }

    return authVerificationClient.verify(bearerToken)
        .flatMap(result -> {
          if (result.status() == TokenVerificationResult.VerificationStatus.ACTIVE) {
            return dashboardSummaryService.loadSummary().map(ResponseEntity::ok);
          }

          HttpStatus status = result.status() == TokenVerificationResult.VerificationStatus.UNAVAILABLE
              ? HttpStatus.SERVICE_UNAVAILABLE
              : HttpStatus.UNAUTHORIZED;
          return Mono.just(ResponseEntity.status(status).build());
        });
  }

  private String extractBearerToken(String authorizationHeader) {
    if (authorizationHeader == null || authorizationHeader.isBlank()) {
      return null;
    }
    if (!authorizationHeader.toLowerCase(Locale.ROOT).startsWith("bearer ")) {
      return null;
    }
    String token = authorizationHeader.substring(7).trim();
    return token.isEmpty() ? null : token;
  }
}
