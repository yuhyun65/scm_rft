package kr.co.computermate.scmrft.board.service;

import java.util.List;
import java.util.Locale;
import java.util.UUID;
import kr.co.computermate.scmrft.board.api.AttachmentRefRequest;
import kr.co.computermate.scmrft.board.api.AttachmentRefResponse;
import kr.co.computermate.scmrft.board.api.BoardPostDetailResponse;
import kr.co.computermate.scmrft.board.api.BoardPostSummaryResponse;
import kr.co.computermate.scmrft.board.api.CreateBoardPostRequest;
import kr.co.computermate.scmrft.board.api.CreateBoardPostResponse;
import kr.co.computermate.scmrft.board.api.PageMetaResponse;
import kr.co.computermate.scmrft.board.api.SearchBoardPostsResponse;
import kr.co.computermate.scmrft.board.repository.BoardAttachmentRepository;
import kr.co.computermate.scmrft.board.repository.BoardPostEntity;
import kr.co.computermate.scmrft.board.repository.BoardPostRepository;
import kr.co.computermate.scmrft.board.repository.BoardPostSearchResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BoardService {
  private static final int MAX_PAGE_SIZE = 200;

  private final BoardPostRepository boardPostRepository;
  private final BoardAttachmentRepository boardAttachmentRepository;
  private final BoardFileClient boardFileClient;

  public BoardService(
      BoardPostRepository boardPostRepository,
      BoardAttachmentRepository boardAttachmentRepository,
      BoardFileClient boardFileClient
  ) {
    this.boardPostRepository = boardPostRepository;
    this.boardAttachmentRepository = boardAttachmentRepository;
    this.boardFileClient = boardFileClient;
  }

  @Transactional(readOnly = true, timeout = 2)
  public SearchBoardPostsResponse searchPosts(String boardType, String keyword, int page, int size) {
    validatePaging(page, size);
    String normalizedBoardType = normalizeBoardType(boardType);
    String keywordPrefix = normalizeKeywordPrefix(keyword);

    BoardPostSearchResult result = boardPostRepository.search(normalizedBoardType, keywordPrefix, page * size, size);

    List<BoardPostSummaryResponse> items = result.items().stream()
        .map(this::toSummaryResponse)
        .toList();

    int totalPages = (int) Math.ceil(result.total() / (double) size);
    PageMetaResponse pageMeta = new PageMetaResponse(page, size, result.total(), totalPages, page + 1 < totalPages);

    return new SearchBoardPostsResponse(items, pageMeta);
  }

  @Transactional(readOnly = true, timeout = 2)
  public BoardPostDetailResponse getPostById(String postId) {
    UUID normalizedPostId = parseUuid(postId, "postId is invalid.");
    BoardPostEntity post = boardPostRepository.findById(normalizedPostId)
        .orElseThrow(() -> BoardApiException.notFound("Post not found."));

    List<AttachmentRefResponse> attachments = boardAttachmentRepository.findFileIdsByPostId(post.postId()).stream()
        .map(fileId -> new AttachmentRefResponse(fileId.toString(), boardFileClient.tryResolveFileName(fileId)))
        .toList();

    return new BoardPostDetailResponse(
        post.postId().toString(),
        post.boardType(),
        post.title(),
        toApiStatus(post.status()),
        post.createdBy(),
        post.createdAt(),
        post.content(),
        attachments
    );
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public CreateBoardPostResponse createPost(CreateBoardPostRequest request) {
    String boardType = normalizeBoardType(request.boardType());
    String createdBy = requireValue(request.createdBy(), "createdBy is required.");
    String title = requireValue(request.title(), "title is required.");
    String content = requireValue(request.content(), "content is required.");

    List<UUID> fileIds = parseFileIds(request.attachments());
    boardFileClient.validateAttachments(fileIds);

    BoardPostEntity created = boardPostRepository.create(
        boardType,
        title,
        content,
        createdBy,
        "NOTICE".equals(boardType)
    );
    boardAttachmentRepository.saveAttachments(created.postId(), fileIds);

    return new CreateBoardPostResponse(created.postId().toString(), created.createdAt());
  }

  private BoardPostSummaryResponse toSummaryResponse(BoardPostEntity entity) {
    return new BoardPostSummaryResponse(
        entity.postId().toString(),
        entity.boardType(),
        entity.title(),
        toApiStatus(entity.status()),
        entity.createdBy(),
        entity.createdAt()
    );
  }

  private String toApiStatus(String dbStatus) {
    if (dbStatus == null) {
      return "DRAFT";
    }
    return switch (dbStatus.toUpperCase(Locale.ROOT)) {
      case "ACTIVE" -> "PUBLISHED";
      case "DELETED" -> "CLOSED";
      case "HIDDEN" -> "DRAFT";
      default -> "DRAFT";
    };
  }

  private List<UUID> parseFileIds(List<AttachmentRefRequest> attachments) {
    if (attachments == null || attachments.isEmpty()) {
      return List.of();
    }

    return attachments.stream()
        .map(AttachmentRefRequest::fileId)
        .map(fileId -> parseUuid(fileId, "fileId is invalid."))
        .toList();
  }

  private UUID parseUuid(String value, String message) {
    try {
      return UUID.fromString(requireValue(value, message));
    }
    catch (IllegalArgumentException ex) {
      throw BoardApiException.badRequest(message);
    }
  }

  private void validatePaging(int page, int size) {
    if (page < 0) {
      throw BoardApiException.badRequest("page must be greater than or equal to 0.");
    }
    if (size < 1 || size > MAX_PAGE_SIZE) {
      throw BoardApiException.badRequest("size must be between 1 and 200.");
    }
  }

  private String normalizeBoardType(String boardType) {
    String normalized = normalizeToNull(boardType);
    if (normalized == null) {
      return null;
    }
    String upper = normalized.toUpperCase(Locale.ROOT);
    if (!"NOTICE".equals(upper) && !"GENERAL".equals(upper) && !"QUALITY".equals(upper)) {
      throw BoardApiException.badRequest("boardType must be NOTICE, GENERAL, or QUALITY.");
    }
    return upper;
  }

  private String normalizeKeywordPrefix(String keyword) {
    String normalized = normalizeToNull(keyword);
    return normalized == null ? null : normalized + "%";
  }

  private String normalizeToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private String requireValue(String value, String message) {
    String normalized = normalizeToNull(value);
    if (normalized == null) {
      throw BoardApiException.badRequest(message);
    }
    return normalized;
  }
}
