package kr.co.computermate.scmrft.board.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.computermate.scmrft.board.api.AttachmentRefRequest;
import kr.co.computermate.scmrft.board.api.BoardPostDetailResponse;
import kr.co.computermate.scmrft.board.api.CreateBoardPostRequest;
import kr.co.computermate.scmrft.board.repository.BoardAttachmentRepository;
import kr.co.computermate.scmrft.board.repository.BoardPostEntity;
import kr.co.computermate.scmrft.board.repository.BoardPostRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class BoardServiceTests {
  @Mock
  private BoardPostRepository boardPostRepository;
  @Mock
  private BoardAttachmentRepository boardAttachmentRepository;
  @Mock
  private BoardFileClient boardFileClient;

  @Test
  void createPostReturnsDependencyErrorWhenAttachmentValidationFails() {
    BoardService service = new BoardService(boardPostRepository, boardAttachmentRepository, boardFileClient);
    UUID fileId = UUID.randomUUID();
    doThrow(BoardApiException.failedDependency("attachment validation failed."))
        .when(boardFileClient).validateAttachments(List.of(fileId));

    CreateBoardPostRequest request = new CreateBoardPostRequest(
        "GENERAL",
        "title",
        "content",
        "writer",
        List.of(new AttachmentRefRequest(fileId.toString()))
    );

    assertThatThrownBy(() -> service.createPost(request))
        .isInstanceOf(BoardApiException.class)
        .hasMessageContaining("attachment validation failed");
  }

  @Test
  void getPostByIdReturnsDetailEvenWhenFileMetadataLookupFails() {
    BoardService service = new BoardService(boardPostRepository, boardAttachmentRepository, boardFileClient);
    UUID postId = UUID.randomUUID();
    UUID fileId = UUID.randomUUID();
    when(boardPostRepository.findById(postId)).thenReturn(Optional.of(
        new BoardPostEntity(postId, "GENERAL", "title", "content", "ACTIVE", "writer", Instant.now())
    ));
    when(boardAttachmentRepository.findFileIdsByPostId(postId)).thenReturn(List.of(fileId));
    when(boardFileClient.tryResolveFileName(fileId)).thenReturn(null);

    BoardPostDetailResponse response = service.getPostById(postId.toString());

    assertThat(response.postId()).isEqualTo(postId.toString());
    assertThat(response.attachments()).hasSize(1);
    assertThat(response.attachments().get(0).fileName()).isNull();
  }
}
