package kr.co.computermate.scmrft.file.api;

import java.util.UUID;

public record FileMetadataResponse(
    UUID fileId,
    String domainKey,
    String originalName,
    String storagePath
) {}
