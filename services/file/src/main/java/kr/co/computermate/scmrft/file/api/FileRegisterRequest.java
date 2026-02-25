package kr.co.computermate.scmrft.file.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record FileRegisterRequest(
    @NotBlank(message = "domainKey is required")
    @Size(max = 100, message = "domainKey length must be <= 100")
    String domainKey,
    @NotBlank(message = "originalName is required")
    @Size(max = 255, message = "originalName length must be <= 255")
    String originalName,
    @NotBlank(message = "storagePath is required")
    @Size(max = 500, message = "storagePath length must be <= 500")
    String storagePath
) {}
