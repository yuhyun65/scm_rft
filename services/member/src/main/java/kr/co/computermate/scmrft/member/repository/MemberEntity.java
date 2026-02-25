package kr.co.computermate.scmrft.member.repository;

public record MemberEntity(
    String memberId,
    String memberName,
    String status
) {}

