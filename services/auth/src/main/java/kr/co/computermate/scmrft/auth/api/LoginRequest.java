package kr.co.computermate.scmrft.auth.api;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "loginId is required")
    String loginId,
    @NotBlank(message = "password is required")
    String password
) {}

