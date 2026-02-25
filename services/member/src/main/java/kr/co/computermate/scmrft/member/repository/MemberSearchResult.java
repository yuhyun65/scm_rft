package kr.co.computermate.scmrft.member.repository;

import java.util.List;

public record MemberSearchResult(
    List<MemberEntity> items,
    long total
) {}

