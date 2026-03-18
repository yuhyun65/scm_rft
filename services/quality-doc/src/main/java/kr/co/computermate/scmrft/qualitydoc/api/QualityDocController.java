package kr.co.computermate.scmrft.qualitydoc.api;

import jakarta.validation.Valid;
import kr.co.computermate.scmrft.qualitydoc.service.QualityDocService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/quality-doc/v1")
public class QualityDocController {
  private final QualityDocService qualityDocService;

  public QualityDocController(QualityDocService qualityDocService) {
    this.qualityDocService = qualityDocService;
  }

  @GetMapping("/documents")
  public SearchQualityDocumentsResponse searchDocuments(
      @RequestParam(value = "status", required = false) String status,
      @RequestParam(value = "keyword", required = false) String keyword,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "20") int size
  ) {
    return qualityDocService.searchDocuments(status, keyword, page, size);
  }

  @GetMapping("/documents/{documentId}")
  public QualityDocumentDetailResponse getDocumentById(@PathVariable("documentId") String documentId) {
    return qualityDocService.getDocumentById(documentId);
  }

  @PostMapping("/documents")
  public ResponseEntity<QualityDocumentDetailResponse> registerDocument(
      @Valid @RequestBody RegisterQualityDocumentRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(qualityDocService.registerDocument(request));
  }

  @PutMapping("/documents/{documentId}/ack")
  public QualityDocumentAckResponse acknowledge(
      @PathVariable("documentId") String documentId,
      @Valid @RequestBody QualityDocumentAckRequest request
  ) {
    return qualityDocService.acknowledge(documentId, request);
  }
}
