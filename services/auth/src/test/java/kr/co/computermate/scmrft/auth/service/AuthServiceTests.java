package kr.co.computermate.scmrft.auth.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import kr.co.computermate.scmrft.auth.api.LoginRequest;
import kr.co.computermate.scmrft.auth.api.LoginResponse;
import kr.co.computermate.scmrft.auth.repository.AuthCredentialEntity;
import kr.co.computermate.scmrft.auth.repository.AuthCredentialRepository;
import kr.co.computermate.scmrft.auth.token.IssuedAccessToken;
import kr.co.computermate.scmrft.auth.token.JwtAuthTokenProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceTests {
  @Mock
  private JwtAuthTokenProvider tokenProvider;
  @Mock
  private AuthCredentialRepository credentialRepository;

  private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

  @Test
  void loginUsesCredentialFromDatabase() {
    AuthService authService = new AuthService(tokenProvider, credentialRepository, passwordEncoder, 5, 15);
    String encoded = passwordEncoder.encode("password-123");
    AuthCredentialEntity credential = new AuthCredentialEntity(
        "admin01",
        "admin01",
        encoded,
        "BCRYPT",
        0,
        null
    );

    when(credentialRepository.findByLoginId("admin01")).thenReturn(Optional.of(credential));
    when(tokenProvider.issueToken(eq("admin01"), anyList(), any())).thenReturn(
        new IssuedAccessToken(
            "token",
            "admin01",
            List.of("ADMIN", "USER"),
            Instant.now(),
            Instant.now().plusSeconds(1800),
            1800
        )
    );

    LoginResponse response = authService.login(new LoginRequest("admin01", "password-123"));

    assertThat(response.accessToken()).isEqualTo("token");
    assertThat(response.memberId()).isEqualTo("admin01");
    assertThat(response.roles()).contains("ADMIN");
    verify(credentialRepository).resetFailureState("admin01");
  }

  @Test
  void loginFailureIncrementsFailedCountAndLocksWhenThresholdReached() {
    AuthService authService = new AuthService(tokenProvider, credentialRepository, passwordEncoder, 5, 15);
    String encoded = passwordEncoder.encode("correct-password");
    AuthCredentialEntity credential = new AuthCredentialEntity(
        "user01",
        "user01",
        encoded,
        "BCRYPT",
        4,
        null
    );

    when(credentialRepository.findByLoginId("user01")).thenReturn(Optional.of(credential));
    when(credentialRepository.incrementFailedCount("user01")).thenReturn(5);

    assertThatThrownBy(() -> authService.login(new LoginRequest("user01", "wrong-password")))
        .isInstanceOf(AuthApiException.class)
        .hasMessageContaining("Invalid credentials");

    verify(credentialRepository).incrementFailedCount("user01");
    verify(credentialRepository).lockUntil(eq("user01"), any());
    verify(credentialRepository, never()).resetFailureState("user01");
  }

  @Test
  void lockedAccountIsRejected() {
    AuthService authService = new AuthService(tokenProvider, credentialRepository, passwordEncoder, 5, 15);
    AuthCredentialEntity credential = new AuthCredentialEntity(
        "user02",
        "user02",
        passwordEncoder.encode("password"),
        "BCRYPT",
        5,
        Instant.now().plusSeconds(60)
    );

    when(credentialRepository.findByLoginId("user02")).thenReturn(Optional.of(credential));

    assertThatThrownBy(() -> authService.login(new LoginRequest("user02", "password")))
        .isInstanceOf(AuthApiException.class)
        .hasMessageContaining("locked");
    verify(credentialRepository, never()).incrementFailedCount("user02");
  }
}

