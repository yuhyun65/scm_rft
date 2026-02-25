package kr.co.computermate.scmrft.member.service;

import java.util.List;
import java.util.Locale;
import kr.co.computermate.scmrft.member.api.MemberResponse;
import kr.co.computermate.scmrft.member.api.SearchMembersResponse;
import kr.co.computermate.scmrft.member.repository.MemberEntity;
import kr.co.computermate.scmrft.member.repository.MemberRepository;
import kr.co.computermate.scmrft.member.repository.MemberSearchResult;
import org.springframework.stereotype.Service;

@Service
public class MemberService {
  private static final int MAX_PAGE_SIZE = 100;

  private final MemberRepository memberRepository;

  public MemberService(MemberRepository memberRepository) {
    this.memberRepository = memberRepository;
  }

  public MemberResponse getMemberById(String memberId) {
    String normalizedMemberId = normalize(memberId);
    if (normalizedMemberId.isEmpty()) {
      throw MemberApiException.badRequest("memberId is required.");
    }

    MemberEntity member = memberRepository.findById(normalizedMemberId)
        .orElseThrow(() -> MemberApiException.notFound("Member not found."));

    return toResponse(member);
  }

  public SearchMembersResponse searchMembers(String keyword, String status, int page, int size) {
    if (page < 0) {
      throw MemberApiException.badRequest("page must be greater than or equal to 0.");
    }
    if (size < 1 || size > MAX_PAGE_SIZE) {
      throw MemberApiException.badRequest("size must be between 1 and 100.");
    }

    String normalizedKeyword = normalize(keyword);
    String normalizedStatus = normalizeStatus(status);
    MemberSearchResult result = memberRepository.search(
        normalizedKeyword.isEmpty() ? null : normalizedKeyword,
        normalizedStatus,
        page,
        size
    );

    List<MemberResponse> items = result.items().stream()
        .map(this::toResponse)
        .toList();

    return new SearchMembersResponse(items, result.total(), page, size);
  }

  private MemberResponse toResponse(MemberEntity entity) {
    return new MemberResponse(entity.memberId(), entity.memberName(), entity.status());
  }

  private String normalizeStatus(String status) {
    String normalized = normalize(status);
    if (normalized.isEmpty()) {
      return null;
    }

    String upper = normalized.toUpperCase(Locale.ROOT);
    if (!"ACTIVE".equals(upper) && !"INACTIVE".equals(upper)) {
      throw MemberApiException.badRequest("status must be ACTIVE or INACTIVE.");
    }
    return upper;
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim();
  }
}

