package kr.co.computermate.scmrft.report.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import kr.co.computermate.scmrft.report.api.ReportJobCreateRequest;
import kr.co.computermate.scmrft.report.api.ReportJobResponse;
import kr.co.computermate.scmrft.report.repository.ReportJobEntity;
import kr.co.computermate.scmrft.report.repository.ReportJobRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ReportServiceTests {
  @Mock
  private ReportJobRepository reportJobRepository;

  @Test
  void createJobStoresQueuedJob() {
    ReportService service = new ReportService(reportJobRepository);

    ReportJobResponse response = service.createJob(new ReportJobCreateRequest("LOT_LABEL", "admin01"));

    assertThat(response.jobId()).isNotNull();
    assertThat(response.status()).isEqualTo("QUEUED");
    assertThat(response.reportType()).isEqualTo("LOT_LABEL");
    assertThat(response.requestedByMemberId()).isEqualTo("admin01");

    ArgumentCaptor<ReportJobEntity> captor = ArgumentCaptor.forClass(ReportJobEntity.class);
    verify(reportJobRepository).insert(captor.capture());
    assertThat(captor.getValue().status()).isEqualTo("QUEUED");
  }

  @Test
  void createJobRejectsInvalidReportType() {
    ReportService service = new ReportService(reportJobRepository);

    assertThatThrownBy(() -> service.createJob(new ReportJobCreateRequest("bad type", "admin01")))
        .isInstanceOf(ReportApiException.class)
        .hasMessageContaining("reportType");
  }

  @Test
  void getJobReturnsStoredJob() {
    ReportService service = new ReportService(reportJobRepository);
    UUID jobId = UUID.randomUUID();
    when(reportJobRepository.findById(jobId)).thenReturn(Optional.of(new ReportJobEntity(
        jobId,
        "LOT_LABEL",
        "QUEUED",
        "admin01",
        Instant.now(),
        null,
        null,
        null
    )));

    ReportJobResponse response = service.getJob(jobId);

    assertThat(response.jobId()).isEqualTo(jobId);
    assertThat(response.reportType()).isEqualTo("LOT_LABEL");
  }

  @Test
  void getJobThrowsWhenNotFound() {
    ReportService service = new ReportService(reportJobRepository);
    UUID jobId = UUID.randomUUID();
    when(reportJobRepository.findById(jobId)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.getJob(jobId))
        .isInstanceOf(ReportApiException.class)
        .hasMessageContaining("not found");
  }
}
