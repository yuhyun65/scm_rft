package kr.co.computermate.scmrft.auth.service;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import kr.co.computermate.scmrft.auth.api.LoginRequest;
import kr.co.computermate.scmrft.auth.api.LoginResponse;
import kr.co.computermate.scmrft.auth.api.VerifyTokenRequest;
import kr.co.computermate.scmrft.auth.api.VerifyTokenResponse;
import kr.co.computermate.scmrft.auth.token.IssuedAccessToken;
import kr.co.computermate.scmrft.auth.token.JwtAuthTokenProvider;
import kr.co.computermate.scmrft.auth.token.TokenVerification;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
  private static final String ACCEPTED_PASSWORD = "password";

  private final JwtAuthTokenProvider tokenProvider;

  public AuthService(JwtAuthTokenProvider tokenProvider) {
    this.tokenProvider = tokenProvider;
  }

  public LoginResponse login(LoginRequest request) {
    String loginId = normalize(request.loginId());
    String password = normalize(request.password());
    if (loginId.isEmpty() || password.isEmpty()) {
      throw AuthApiException.badRequest("loginId and password are required.");
    }
    if (!ACCEPTED_PASSWORD.equals(password)) {
      throw AuthApiException.unauthorized("Invalid credentials.");
    }

    List<String> roles = resolveRoles(loginId);
    IssuedAccessToken token = tokenProvider.issueToken(loginId, roles, Instant.now());
    return new LoginResponse(
        token.accessToken(),
        "Bearer",
        token.expiresInSeconds(),
        token.expiresAt(),
        token.subject(),
        token.roles()
    );
  }

  public VerifyTokenResponse verifyToken(VerifyTokenRequest request) {
    String accessToken = normalize(request.accessToken());
    if (accessToken.isEmpty()) {
      throw AuthApiException.badRequest("accessToken is required.");
    }

    TokenVerification verification = tokenProvider.verifyToken(accessToken, Instant.now());
    return new VerifyTokenResponse(
        verification.active(),
        verification.subject(),
        verification.roles(),
        verification.issuedAt(),
        verification.expiresAt()
    );
  }

  private List<String> resolveRoles(String loginId) {
    if (loginId.toLowerCase(Locale.ROOT).startsWith("admin")) {
      return List.of("ADMIN", "USER");
    }
    return List.of("USER");
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim();
  }
}

