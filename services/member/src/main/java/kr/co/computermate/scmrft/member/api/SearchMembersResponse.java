package kr.co.computermate.scmrft.member.api;

import java.util.List;

public record SearchMembersResponse(
    List<MemberResponse> items,
    long total,
    int page,
    int size
) {}

