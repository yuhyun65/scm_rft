package kr.co.computermate.scmrft.auth.api;

import jakarta.validation.Valid;
import kr.co.computermate.scmrft.auth.service.AuthService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth/v1")
public class AuthController {
  private final AuthService authService;

  public AuthController(AuthService authService) {
    this.authService = authService;
  }

  @PostMapping("/login")
  public LoginResponse login(@Valid @RequestBody LoginRequest request) {
    return authService.login(request);
  }

  @PostMapping("/tokens/verify")
  public VerifyTokenResponse verifyToken(@Valid @RequestBody VerifyTokenRequest request) {
    return authService.verifyToken(request);
  }
}

