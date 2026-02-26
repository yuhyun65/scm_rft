package kr.co.computermate.scmrft.board.service;

import java.net.SocketTimeoutException;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Component
public class BoardFileClient {
  private final RestClient restClient;

  public BoardFileClient(@Value("${board.file-service.base-url:http://localhost:8087}") String baseUrl) {
    this.restClient = RestClient.builder()
        .baseUrl(baseUrl)
        .build();
  }

  public void validateAttachments(List<UUID> fileIds) {
    if (fileIds == null || fileIds.isEmpty()) {
      return;
    }

    for (UUID fileId : fileIds) {
      try {
        restClient.get()
            .uri("/api/file/v1/files/{fileId}", fileId)
            .retrieve()
            .toBodilessEntity();
      }
      catch (RestClientResponseException ex) {
        int status = ex.getStatusCode().value();
        if (status >= 500) {
          throw BoardApiException.badGateway("file service is unavailable.");
        }
        throw BoardApiException.failedDependency("attachment validation failed.");
      }
      catch (ResourceAccessException ex) {
        if (ex.getCause() instanceof SocketTimeoutException) {
          throw BoardApiException.upstreamTimeout("file service timeout.");
        }
        throw BoardApiException.badGateway("file service connection failed.");
      }
    }
  }

  public String tryResolveFileName(UUID fileId) {
    try {
      FileMetadataResponse response = restClient.get()
          .uri("/api/file/v1/files/{fileId}", fileId)
          .retrieve()
          .body(FileMetadataResponse.class);
      return response == null ? null : response.originalName();
    }
    catch (Exception ignored) {
      return null;
    }
  }

  private record FileMetadataResponse(
      String fileId,
      String domainKey,
      String originalName,
      String storagePath
  ) {
  }
}
