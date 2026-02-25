package kr.co.computermate.scmrft.auth.token;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtAuthTokenProvider {
  private final SecretKey signingKey;
  private final String issuer;
  private final long accessTokenExpirationSeconds;

  public JwtAuthTokenProvider(
      @Value("${scm.auth.jwt.secret}") String secret,
      @Value("${scm.auth.jwt.issuer:scm-auth}") String issuer,
      @Value("${scm.auth.jwt.access-token-expiration-seconds:1800}") long accessTokenExpirationSeconds
  ) {
    if (secret == null || secret.isBlank()) {
      throw new IllegalArgumentException("JWT secret must not be blank.");
    }
    this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    this.issuer = issuer;
    this.accessTokenExpirationSeconds = Math.max(1, accessTokenExpirationSeconds);
  }

  public IssuedAccessToken issueToken(String subject, List<String> roles, Instant now) {
    Instant issuedAt = now == null ? Instant.now() : now;
    Instant expiresAt = issuedAt.plusSeconds(accessTokenExpirationSeconds);
    List<String> normalizedRoles = roles == null ? List.of() : roles.stream()
        .filter(Objects::nonNull)
        .map(String::trim)
        .filter(role -> !role.isEmpty())
        .toList();

    String token = Jwts.builder()
        .subject(subject)
        .issuer(issuer)
        .issuedAt(Date.from(issuedAt))
        .expiration(Date.from(expiresAt))
        .claim("roles", normalizedRoles)
        .signWith(signingKey)
        .compact();

    return new IssuedAccessToken(
        token,
        subject,
        normalizedRoles,
        issuedAt,
        expiresAt,
        accessTokenExpirationSeconds
    );
  }

  public TokenVerification verifyToken(String accessToken, Instant now) {
    if (accessToken == null || accessToken.isBlank()) {
      return TokenVerification.inactive();
    }

    Instant verifyTime = now == null ? Instant.now() : now;

    try {
      Claims claims = Jwts.parser()
          .verifyWith(signingKey)
          .build()
          .parseSignedClaims(accessToken)
          .getPayload();

      Date expiration = claims.getExpiration();
      if (expiration == null || !expiration.toInstant().isAfter(verifyTime)) {
        return TokenVerification.inactive();
      }

      List<String> roles = extractRoles(claims.get("roles"));
      Instant issuedAt = claims.getIssuedAt() == null ? null : claims.getIssuedAt().toInstant();
      return TokenVerification.active(
          claims.getSubject(),
          roles,
          issuedAt,
          expiration.toInstant()
      );
    }
    catch (JwtException | IllegalArgumentException ex) {
      return TokenVerification.inactive();
    }
  }

  private List<String> extractRoles(Object rolesClaim) {
    if (!(rolesClaim instanceof List<?> rawList)) {
      return List.of();
    }
    return rawList.stream()
        .filter(Objects::nonNull)
        .map(Object::toString)
        .map(String::trim)
        .filter(role -> !role.isEmpty())
        .toList();
  }
}
