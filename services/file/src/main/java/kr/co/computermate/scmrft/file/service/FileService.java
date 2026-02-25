package kr.co.computermate.scmrft.file.service;

import java.util.UUID;
import java.util.regex.Pattern;
import kr.co.computermate.scmrft.file.api.FileMetadataResponse;
import kr.co.computermate.scmrft.file.api.FileRegisterRequest;
import kr.co.computermate.scmrft.file.repository.FileMetadataEntity;
import kr.co.computermate.scmrft.file.repository.FileRepository;
import org.springframework.stereotype.Service;

@Service
public class FileService {
  private static final Pattern DOMAIN_KEY_PATTERN = Pattern.compile("^[A-Za-z0-9][A-Za-z0-9._:/-]{0,99}$");
  private static final Pattern STORAGE_PATH_PATTERN = Pattern.compile("^[A-Za-z0-9][A-Za-z0-9/._-]{0,499}$");

  private final FileRepository fileRepository;

  public FileService(FileRepository fileRepository) {
    this.fileRepository = fileRepository;
  }

  public FileMetadataResponse registerFile(FileRegisterRequest request) {
    String domainKey = normalize(request.domainKey());
    String originalName = normalize(request.originalName());
    String storagePath = normalize(request.storagePath());

    validateDomainKey(domainKey);
    validateOriginalName(originalName);
    validateStoragePath(storagePath);

    FileMetadataEntity entity = new FileMetadataEntity(
        UUID.randomUUID(),
        domainKey,
        originalName,
        storagePath
    );
    fileRepository.insert(entity);
    return toResponse(entity);
  }

  public FileMetadataResponse getFile(UUID fileId) {
    if (fileId == null) {
      throw FileApiException.badRequest("fileId is required.");
    }

    FileMetadataEntity entity = fileRepository.findById(fileId)
        .orElseThrow(() -> FileApiException.notFound("File metadata not found."));
    return toResponse(entity);
  }

  private void validateDomainKey(String domainKey) {
    if (domainKey.isEmpty()) {
      throw FileApiException.badRequest("domainKey is required.");
    }
    if (!DOMAIN_KEY_PATTERN.matcher(domainKey).matches()) {
      throw FileApiException.badRequest("domainKey format is invalid.");
    }
  }

  private void validateOriginalName(String originalName) {
    if (originalName.isEmpty()) {
      throw FileApiException.badRequest("originalName is required.");
    }
    if (originalName.length() > 255) {
      throw FileApiException.badRequest("originalName length must be <= 255.");
    }
  }

  private void validateStoragePath(String storagePath) {
    if (storagePath.isEmpty()) {
      throw FileApiException.badRequest("storagePath is required.");
    }
    if (storagePath.startsWith("/") || storagePath.startsWith("\\")) {
      throw FileApiException.badRequest("storagePath must be a relative path.");
    }
    if (storagePath.contains("..")) {
      throw FileApiException.badRequest("storagePath must not contain parent path traversal.");
    }
    if (!STORAGE_PATH_PATTERN.matcher(storagePath).matches()) {
      throw FileApiException.badRequest("storagePath format is invalid.");
    }
  }

  private FileMetadataResponse toResponse(FileMetadataEntity entity) {
    return new FileMetadataResponse(
        entity.fileId(),
        entity.domainKey(),
        entity.originalName(),
        entity.storagePath()
    );
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim();
  }
}
