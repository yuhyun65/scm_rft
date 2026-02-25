package kr.co.computermate.scmrft.file.repository;

import java.util.UUID;

public record FileMetadataEntity(
    UUID fileId,
    String domainKey,
    String originalName,
    String storagePath
) {}
