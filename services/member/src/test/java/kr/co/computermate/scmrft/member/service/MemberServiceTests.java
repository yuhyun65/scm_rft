package kr.co.computermate.scmrft.member.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import java.util.Optional;
import kr.co.computermate.scmrft.member.api.CreateMemberRequest;
import kr.co.computermate.scmrft.member.api.MemberResponse;
import kr.co.computermate.scmrft.member.repository.MemberEntity;
import kr.co.computermate.scmrft.member.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class MemberServiceTests {
  @Mock
  private MemberRepository memberRepository;

  @Test
  void getMemberByIdReturnsResponse() {
    MemberService memberService = new MemberService(memberRepository);
    when(memberRepository.findById("M001"))
        .thenReturn(Optional.of(new MemberEntity("M001", "Acme", "ACTIVE")));

    MemberResponse response = memberService.getMemberById("M001");

    assertThat(response.memberId()).isEqualTo("M001");
    assertThat(response.memberName()).isEqualTo("Acme");
    assertThat(response.status()).isEqualTo("ACTIVE");
  }

  @Test
  void searchMembersRejectsInvalidPageSize() {
    MemberService memberService = new MemberService(memberRepository);

    assertThatThrownBy(() -> memberService.searchMembers(null, null, 0, 0))
        .isInstanceOf(MemberApiException.class)
        .hasMessageContaining("size");
  }

  @Test
  void createMemberReturnsCreatedMember() {
    MemberService memberService = new MemberService(memberRepository);
    when(memberRepository.findById("SUP-NEW")).thenReturn(Optional.empty());

    MemberResponse response = memberService.createMember(
        new CreateMemberRequest("SUP-NEW", "New Supplier", "ACTIVE")
    );

    assertThat(response.memberId()).isEqualTo("SUP-NEW");
    assertThat(response.memberName()).isEqualTo("New Supplier");
    assertThat(response.status()).isEqualTo("ACTIVE");
  }
}

