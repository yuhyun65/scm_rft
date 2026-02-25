package kr.co.computermate.scmrft.report.service;

import java.time.Instant;
import java.util.UUID;
import java.util.regex.Pattern;
import kr.co.computermate.scmrft.report.api.ReportJobCreateRequest;
import kr.co.computermate.scmrft.report.api.ReportJobResponse;
import kr.co.computermate.scmrft.report.repository.ReportJobEntity;
import kr.co.computermate.scmrft.report.repository.ReportJobRepository;
import org.springframework.stereotype.Service;

@Service
public class ReportService {
  private static final Pattern REPORT_TYPE_PATTERN = Pattern.compile("^[A-Za-z0-9][A-Za-z0-9_-]{0,49}$");

  private final ReportJobRepository reportJobRepository;

  public ReportService(ReportJobRepository reportJobRepository) {
    this.reportJobRepository = reportJobRepository;
  }

  public ReportJobResponse createJob(ReportJobCreateRequest request) {
    String reportType = normalize(request.reportType());
    String requestedByMemberId = normalize(request.requestedByMemberId());

    validateReportType(reportType);
    if (requestedByMemberId != null && requestedByMemberId.length() > 50) {
      throw ReportApiException.badRequest("requestedByMemberId length must be <= 50.");
    }

    ReportJobEntity entity = new ReportJobEntity(
        UUID.randomUUID(),
        reportType,
        "QUEUED",
        requestedByMemberId,
        Instant.now(),
        null,
        null,
        null
    );
    reportJobRepository.insert(entity);
    return toResponse(entity);
  }

  public ReportJobResponse getJob(UUID jobId) {
    if (jobId == null) {
      throw ReportApiException.badRequest("jobId is required.");
    }

    ReportJobEntity entity = reportJobRepository.findById(jobId)
        .orElseThrow(() -> ReportApiException.notFound("Report job not found."));
    return toResponse(entity);
  }

  private void validateReportType(String reportType) {
    if (reportType == null) {
      throw ReportApiException.badRequest("reportType is required.");
    }
    if (!REPORT_TYPE_PATTERN.matcher(reportType).matches()) {
      throw ReportApiException.badRequest("reportType format is invalid.");
    }
  }

  private ReportJobResponse toResponse(ReportJobEntity entity) {
    return new ReportJobResponse(
        entity.jobId(),
        entity.reportType(),
        entity.status(),
        entity.requestedByMemberId(),
        entity.requestedAt(),
        entity.completedAt(),
        entity.outputFileId(),
        entity.errorMessage()
    );
  }

  private String normalize(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }
}
