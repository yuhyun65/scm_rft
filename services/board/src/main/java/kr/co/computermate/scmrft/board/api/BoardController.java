package kr.co.computermate.scmrft.board.api;

import jakarta.validation.Valid;
import kr.co.computermate.scmrft.board.service.BoardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/board/v1")
public class BoardController {
  private final BoardService boardService;

  public BoardController(BoardService boardService) {
    this.boardService = boardService;
  }

  @GetMapping("/posts")
  public SearchBoardPostsResponse searchPosts(
      @RequestParam(value = "boardType", required = false) String boardType,
      @RequestParam(value = "keyword", required = false) String keyword,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "20") int size
  ) {
    return boardService.searchPosts(boardType, keyword, page, size);
  }

  @GetMapping("/posts/{postId}")
  public BoardPostDetailResponse getPostById(@PathVariable("postId") String postId) {
    return boardService.getPostById(postId);
  }

  @PostMapping("/posts")
  public ResponseEntity<CreateBoardPostResponse> createPost(@Valid @RequestBody CreateBoardPostRequest request) {
    return ResponseEntity.status(201).body(boardService.createPost(request));
  }
}
