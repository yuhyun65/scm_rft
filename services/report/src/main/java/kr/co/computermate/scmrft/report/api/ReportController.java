package kr.co.computermate.scmrft.report.api;

import jakarta.validation.Valid;
import java.util.UUID;
import kr.co.computermate.scmrft.report.service.ReportService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/report/v1")
public class ReportController {
  private final ReportService reportService;

  public ReportController(ReportService reportService) {
    this.reportService = reportService;
  }

  @PostMapping("/jobs")
  public ResponseEntity<ReportJobResponse> createJob(@Valid @RequestBody ReportJobCreateRequest request) {
    ReportJobResponse response = reportService.createJob(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  @GetMapping("/jobs/{jobId}")
  public ReportJobResponse getJob(@PathVariable("jobId") UUID jobId) {
    return reportService.getJob(jobId);
  }
}
