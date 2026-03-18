package kr.co.computermate.scmrft.member.api;

import jakarta.validation.Valid;
import kr.co.computermate.scmrft.member.service.MemberService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/member/v1")
public class MemberController {
  private final MemberService memberService;

  public MemberController(MemberService memberService) {
    this.memberService = memberService;
  }

  @GetMapping("/members/{memberId}")
  public MemberResponse getMemberById(@PathVariable("memberId") String memberId) {
    return memberService.getMemberById(memberId);
  }

  @GetMapping("/members")
  public SearchMembersResponse searchMembers(
      @RequestParam(value = "keyword", required = false) String keyword,
      @RequestParam(value = "status", required = false) String status,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "20") int size
  ) {
    return memberService.searchMembers(keyword, status, page, size);
  }

  @PostMapping("/members")
  public ResponseEntity<MemberResponse> createMember(@Valid @RequestBody CreateMemberRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(memberService.createMember(request));
  }
}

