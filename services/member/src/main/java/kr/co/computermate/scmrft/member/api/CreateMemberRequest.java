package kr.co.computermate.scmrft.member.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateMemberRequest(
    @NotBlank(message = "memberId is required.")
    @Size(max = 50, message = "memberId must be less than or equal to 50 characters.")
    String memberId,
    @NotBlank(message = "memberName is required.")
    @Size(max = 200, message = "memberName must be less than or equal to 200 characters.")
    String memberName,
    @Size(max = 20, message = "status must be less than or equal to 20 characters.")
    String status
) {
}
