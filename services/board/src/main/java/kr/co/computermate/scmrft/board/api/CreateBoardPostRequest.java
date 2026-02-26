package kr.co.computermate.scmrft.board.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public record CreateBoardPostRequest(
    @NotBlank(message = "boardType is required.")
    String boardType,
    @NotBlank(message = "title is required.")
    @Size(max = 200, message = "title must be less than or equal to 200 characters.")
    String title,
    @NotBlank(message = "content is required.")
    @Size(max = 10000, message = "content must be less than or equal to 10000 characters.")
    String content,
    @NotBlank(message = "createdBy is required.")
    @Size(max = 40, message = "createdBy must be less than or equal to 40 characters.")
    String createdBy,
    @Valid
    List<AttachmentRefRequest> attachments
) {
}
