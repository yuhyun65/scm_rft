package kr.co.computermate.scmrft.board.repository;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class BoardPostRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private BoardPostRepository boardPostRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.board_posts (
                post_id UUID PRIMARY KEY,
                category_code VARCHAR(30) NOT NULL,
                title VARCHAR(200) NOT NULL,
                content VARCHAR(4000),
                writer_member_id VARCHAR(50),
                is_notice BOOLEAN NOT NULL,
                status VARCHAR(20) NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.board_posts").update();
  }

  @Test
  void createAndSearchWorks() {
    boardPostRepository.create("GENERAL", "title", "content", "writer", false);

    BoardPostSearchResult result = boardPostRepository.search("GENERAL", "tit%", 0, 20);

    assertThat(result.total()).isEqualTo(1L);
    assertThat(result.items()).hasSize(1);
    assertThat(result.items().get(0).title()).isEqualTo("title");
  }
}
