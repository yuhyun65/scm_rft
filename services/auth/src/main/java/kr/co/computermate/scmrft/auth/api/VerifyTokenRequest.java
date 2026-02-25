package kr.co.computermate.scmrft.auth.api;

import jakarta.validation.constraints.NotBlank;

public record VerifyTokenRequest(
    @NotBlank(message = "accessToken is required")
    String accessToken
) {}

