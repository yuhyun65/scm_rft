package kr.co.computermate.scmrft.file.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;
import java.util.UUID;
import kr.co.computermate.scmrft.file.api.FileMetadataResponse;
import kr.co.computermate.scmrft.file.api.FileRegisterRequest;
import kr.co.computermate.scmrft.file.repository.FileMetadataEntity;
import kr.co.computermate.scmrft.file.repository.FileRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class FileServiceTests {
  @Mock
  private FileRepository fileRepository;

  @Test
  void registerFileReturnsCreatedMetadata() {
    FileService fileService = new FileService(fileRepository);

    FileMetadataResponse response = fileService.registerFile(
        new FileRegisterRequest("ORDER-LOT:LOT-001", "lot-label.pdf", "uploadData/2026/02/lot-label.pdf")
    );

    assertThat(response.fileId()).isNotNull();
    assertThat(response.domainKey()).isEqualTo("ORDER-LOT:LOT-001");
    assertThat(response.originalName()).isEqualTo("lot-label.pdf");
    assertThat(response.storagePath()).isEqualTo("uploadData/2026/02/lot-label.pdf");
    verify(fileRepository).insert(new FileMetadataEntity(
        response.fileId(),
        response.domainKey(),
        response.originalName(),
        response.storagePath()
    ));
  }

  @Test
  void registerFileRejectsInvalidDomainKey() {
    FileService fileService = new FileService(fileRepository);

    assertThatThrownBy(() -> fileService.registerFile(
        new FileRegisterRequest("bad key", "name.txt", "uploadData/ok/name.txt")
    ))
        .isInstanceOf(FileApiException.class)
        .hasMessageContaining("domainKey");
  }

  @Test
  void registerFileRejectsPathTraversal() {
    FileService fileService = new FileService(fileRepository);

    assertThatThrownBy(() -> fileService.registerFile(
        new FileRegisterRequest("BOARD:POST-1", "note.txt", "../secrets/note.txt")
    ))
        .isInstanceOf(FileApiException.class)
        .hasMessageContaining("traversal");
  }

  @Test
  void getFileReturnsMetadata() {
    FileService fileService = new FileService(fileRepository);
    UUID fileId = UUID.randomUUID();
    when(fileRepository.findById(fileId))
        .thenReturn(Optional.of(new FileMetadataEntity(fileId, "BOARD:POST-2", "notice.txt", "uploadData/notice.txt")));

    FileMetadataResponse response = fileService.getFile(fileId);

    assertThat(response.fileId()).isEqualTo(fileId);
    assertThat(response.domainKey()).isEqualTo("BOARD:POST-2");
  }

  @Test
  void getFileThrowsNotFoundWhenMissing() {
    FileService fileService = new FileService(fileRepository);
    UUID fileId = UUID.randomUUID();
    when(fileRepository.findById(fileId)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> fileService.getFile(fileId))
        .isInstanceOf(FileApiException.class)
        .hasMessageContaining("not found");
  }
}
