package kr.co.computermate.scmrft.board.repository;

import java.util.List;

public record BoardPostSearchResult(
    List<BoardPostEntity> items,
    long total
) {
}
