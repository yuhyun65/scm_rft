package kr.co.computermate.scmrft.member.api;

public record MemberResponse(
    String memberId,
    String memberName,
    String status
) {}

