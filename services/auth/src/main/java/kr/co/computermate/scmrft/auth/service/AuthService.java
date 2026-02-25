package kr.co.computermate.scmrft.auth.service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import kr.co.computermate.scmrft.auth.api.LoginRequest;
import kr.co.computermate.scmrft.auth.api.LoginResponse;
import kr.co.computermate.scmrft.auth.api.VerifyTokenRequest;
import kr.co.computermate.scmrft.auth.api.VerifyTokenResponse;
import kr.co.computermate.scmrft.auth.repository.AuthCredentialEntity;
import kr.co.computermate.scmrft.auth.repository.AuthCredentialRepository;
import kr.co.computermate.scmrft.auth.token.IssuedAccessToken;
import kr.co.computermate.scmrft.auth.token.JwtAuthTokenProvider;
import kr.co.computermate.scmrft.auth.token.TokenVerification;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
  private final JwtAuthTokenProvider tokenProvider;
  private final AuthCredentialRepository authCredentialRepository;
  private final PasswordEncoder passwordEncoder;
  private final int maxFailedAttempts;
  private final long lockMinutes;

  public AuthService(
      JwtAuthTokenProvider tokenProvider,
      AuthCredentialRepository authCredentialRepository,
      PasswordEncoder passwordEncoder,
      @Value("${scm.auth.login.max-failed-attempts:5}") int maxFailedAttempts,
      @Value("${scm.auth.login.lock-minutes:15}") long lockMinutes
  ) {
    this.tokenProvider = tokenProvider;
    this.authCredentialRepository = authCredentialRepository;
    this.passwordEncoder = passwordEncoder;
    this.maxFailedAttempts = Math.max(1, maxFailedAttempts);
    this.lockMinutes = Math.max(1L, lockMinutes);
  }

  public LoginResponse login(LoginRequest request) {
    Instant now = Instant.now();
    String loginId = normalize(request.loginId());
    String password = normalize(request.password());
    if (loginId.isEmpty() || password.isEmpty()) {
      throw AuthApiException.badRequest("loginId and password are required.");
    }

    AuthCredentialEntity credential = authCredentialRepository.findByLoginId(loginId)
        .orElseThrow(() -> AuthApiException.unauthorized("Invalid credentials."));

    if (credential.lockedUntil() != null && credential.lockedUntil().isAfter(now)) {
      throw AuthApiException.locked("Account is temporarily locked.");
    }

    if (credential.passwordHash() == null || credential.passwordHash().isBlank()) {
      throw AuthApiException.unauthorized("Invalid credentials.");
    }

    if (!passwordEncoder.matches(password, credential.passwordHash())) {
      int failedCount = authCredentialRepository.incrementFailedCount(loginId);
      if (failedCount >= maxFailedAttempts) {
        authCredentialRepository.lockUntil(loginId, now.plus(lockMinutes, ChronoUnit.MINUTES));
      }
      throw AuthApiException.unauthorized("Invalid credentials.");
    }

    authCredentialRepository.resetFailureState(loginId);

    List<String> roles = resolveRoles(credential.memberId());
    IssuedAccessToken token = tokenProvider.issueToken(credential.memberId(), roles, now);
    return new LoginResponse(
        token.accessToken(),
        "Bearer",
        token.expiresInSeconds(),
        token.expiresAt(),
        credential.memberId(),
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
