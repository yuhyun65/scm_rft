package kr.co.computermate.scmrft.gateway.policy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class GatewayPolicyLoader {
  private static final Logger log = LoggerFactory.getLogger(GatewayPolicyLoader.class);
  private static final String DEFAULT_REPO_POLICY_PATH = "infra/gateway/policies/cutover-isolation.yaml";
  private static final String DEFAULT_CLASSPATH_POLICY_PATH = "policy/cutover-isolation.yaml";

  private final ObjectMapper yamlMapper = new ObjectMapper(new YAMLFactory());
  private final String configuredPolicyPath;
  private final Path baseDirectory;

  @Autowired
  public GatewayPolicyLoader(@Value("${gateway.policy.path:}") String configuredPolicyPath) {
    this(configuredPolicyPath, Path.of("").toAbsolutePath().normalize());
  }

  GatewayPolicyLoader(String configuredPolicyPath, Path baseDirectory) {
    this.configuredPolicyPath = configuredPolicyPath;
    this.baseDirectory = baseDirectory == null ? Path.of("").toAbsolutePath().normalize() : baseDirectory.normalize();
  }

  public GatewayPolicyDocument load() {
    List<Path> candidates = new ArrayList<>();
    if (configuredPolicyPath != null && !configuredPolicyPath.isBlank()) {
      candidates.addAll(expandRelativeCandidates(Path.of(configuredPolicyPath)));
    }
    candidates.addAll(expandRelativeCandidates(Path.of(DEFAULT_REPO_POLICY_PATH)));

    for (Path candidate : candidates) {
      if (!candidate.isAbsolute()) {
        candidate = Path.of("").toAbsolutePath().resolve(candidate).normalize();
      }
      if (Files.exists(candidate)) {
        try (InputStream is = Files.newInputStream(candidate)) {
          GatewayPolicyDocument document = yamlMapper.readValue(is, GatewayPolicyDocument.class);
          document.normalize();
          log.info("Loaded gateway policy from file: {} (name={}, routes={})", candidate, document.getName(), document.getRoutes().size());
          return document;
        }
        catch (IOException e) {
          throw new IllegalStateException("failed to read gateway policy from file: " + candidate, e);
        }
      }
    }

    ClassPathResource resource = new ClassPathResource(DEFAULT_CLASSPATH_POLICY_PATH);
    if (!resource.exists()) {
      throw new IllegalStateException("gateway policy file not found in file system or classpath");
    }
    try (InputStream is = resource.getInputStream()) {
      GatewayPolicyDocument document = yamlMapper.readValue(is, GatewayPolicyDocument.class);
      document.normalize();
      log.info("Loaded gateway policy from classpath: {} (name={}, routes={})", DEFAULT_CLASSPATH_POLICY_PATH, document.getName(), document.getRoutes().size());
      return document;
    }
    catch (IOException e) {
      throw new IllegalStateException("failed to read gateway policy from classpath", e);
    }
  }

  private List<Path> expandRelativeCandidates(Path original) {
    if (original.isAbsolute()) {
      return List.of(original.normalize());
    }

    Set<Path> expanded = new LinkedHashSet<>();
    Path cursor = baseDirectory;
    while (cursor != null) {
      expanded.add(cursor.resolve(original).normalize());
      cursor = cursor.getParent();
    }
    return new ArrayList<>(expanded);
  }
}
