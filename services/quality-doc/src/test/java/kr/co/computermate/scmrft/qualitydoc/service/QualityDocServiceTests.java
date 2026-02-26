package kr.co.computermate.scmrft.qualitydoc.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import kr.co.computermate.scmrft.qualitydoc.api.QualityDocumentAckRequest;
import kr.co.computermate.scmrft.qualitydoc.api.QualityDocumentAckResponse;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentAckEntity;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentAckRepository;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentEntity;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class QualityDocServiceTests {
  @Mock
  private QualityDocumentRepository qualityDocumentRepository;
  @Mock
  private QualityDocumentAckRepository qualityDocumentAckRepository;

  @Test
  void acknowledgeReturnsDuplicateWhenSameRequestIsRepeated() {
    QualityDocService service = new QualityDocService(qualityDocumentRepository, qualityDocumentAckRepository);
    UUID documentId = UUID.randomUUID();
    when(qualityDocumentRepository.findById(documentId)).thenReturn(Optional.of(
        new QualityDocumentEntity(documentId, "doc", "NOTICE", "ISSUED", Instant.now())
    ));
    when(qualityDocumentAckRepository.findByDocumentIdAndMemberId(documentId, "user01"))
        .thenReturn(Optional.of(new QualityDocumentAckEntity(documentId, "user01", "READ", Instant.now())));

    QualityDocumentAckResponse response = service.acknowledge(
        documentId.toString(),
        new QualityDocumentAckRequest("user01", "READ", null)
    );

    assertThat(response.duplicateRequest()).isTrue();
    verify(qualityDocumentAckRepository, never()).insert(any(), any(), any(), any());
  }

  @Test
  void acknowledgeRejectsWhenExistingAckTypeDiffers() {
    QualityDocService service = new QualityDocService(qualityDocumentRepository, qualityDocumentAckRepository);
    UUID documentId = UUID.randomUUID();
    when(qualityDocumentRepository.findById(documentId)).thenReturn(Optional.of(
        new QualityDocumentEntity(documentId, "doc", "NOTICE", "ISSUED", Instant.now())
    ));
    when(qualityDocumentAckRepository.findByDocumentIdAndMemberId(documentId, "user01"))
        .thenReturn(Optional.of(new QualityDocumentAckEntity(documentId, "user01", "READ", Instant.now())));

    assertThatThrownBy(() -> service.acknowledge(
        documentId.toString(),
        new QualityDocumentAckRequest("user01", "CONFIRMED", null)
    ))
        .isInstanceOf(QualityDocApiException.class)
        .hasMessageContaining("different ackType");

    verify(qualityDocumentAckRepository, never()).insert(eq(documentId), eq("user01"), eq("CONFIRMED"), any());
  }
}
