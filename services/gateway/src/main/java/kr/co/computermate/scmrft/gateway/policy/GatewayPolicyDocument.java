package kr.co.computermate.scmrft.gateway.policy;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class GatewayPolicyDocument {
  private int policyVersion;
  private String name;
  private Defaults defaults = new Defaults();
  private TrafficControl trafficControl = new TrafficControl();
  private List<RouteRule> routes = new ArrayList<>();
  private CutoverSwitches cutoverSwitches = new CutoverSwitches();

  public int getPolicyVersion() {
    return policyVersion;
  }

  public void setPolicyVersion(int policyVersion) {
    this.policyVersion = policyVersion;
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public Defaults getDefaults() {
    return defaults;
  }

  public void setDefaults(Defaults defaults) {
    this.defaults = defaults;
  }

  public TrafficControl getTrafficControl() {
    return trafficControl;
  }

  public void setTrafficControl(TrafficControl trafficControl) {
    this.trafficControl = trafficControl;
  }

  public List<RouteRule> getRoutes() {
    return routes;
  }

  public void setRoutes(List<RouteRule> routes) {
    this.routes = routes;
  }

  public CutoverSwitches getCutoverSwitches() {
    return cutoverSwitches;
  }

  public void setCutoverSwitches(CutoverSwitches cutoverSwitches) {
    this.cutoverSwitches = cutoverSwitches;
  }

  public static class Defaults {
    private int requestTimeoutMs = 5000;
    private int connectTimeoutMs = 2000;
    private Retry retry = new Retry();
    private CircuitBreaker circuitBreaker = new CircuitBreaker();

    public int getRequestTimeoutMs() {
      return requestTimeoutMs;
    }

    public void setRequestTimeoutMs(int requestTimeoutMs) {
      this.requestTimeoutMs = requestTimeoutMs;
    }

    public int getConnectTimeoutMs() {
      return connectTimeoutMs;
    }

    public void setConnectTimeoutMs(int connectTimeoutMs) {
      this.connectTimeoutMs = connectTimeoutMs;
    }

    public Retry getRetry() {
      return retry;
    }

    public void setRetry(Retry retry) {
      this.retry = retry;
    }

    public CircuitBreaker getCircuitBreaker() {
      return circuitBreaker;
    }

    public void setCircuitBreaker(CircuitBreaker circuitBreaker) {
      this.circuitBreaker = circuitBreaker;
    }
  }

  public static class Retry {
    private boolean enabled = true;
    private int attempts = 2;
    private int backoffMs = 200;

    public boolean isEnabled() {
      return enabled;
    }

    public void setEnabled(boolean enabled) {
      this.enabled = enabled;
    }

    public int getAttempts() {
      return attempts;
    }

    public void setAttempts(int attempts) {
      this.attempts = attempts;
    }

    public int getBackoffMs() {
      return backoffMs;
    }

    public void setBackoffMs(int backoffMs) {
      this.backoffMs = backoffMs;
    }
  }

  public static class CircuitBreaker {
    private boolean enabled = true;
    private int failureRateThreshold = 50;
    private int slowCallRateThreshold = 50;
    private int waitDurationInOpenStateMs = 10000;

    public boolean isEnabled() {
      return enabled;
    }

    public void setEnabled(boolean enabled) {
      this.enabled = enabled;
    }

    public int getFailureRateThreshold() {
      return failureRateThreshold;
    }

    public void setFailureRateThreshold(int failureRateThreshold) {
      this.failureRateThreshold = failureRateThreshold;
    }

    public int getSlowCallRateThreshold() {
      return slowCallRateThreshold;
    }

    public void setSlowCallRateThreshold(int slowCallRateThreshold) {
      this.slowCallRateThreshold = slowCallRateThreshold;
    }

    public int getWaitDurationInOpenStateMs() {
      return waitDurationInOpenStateMs;
    }

    public void setWaitDurationInOpenStateMs(int waitDurationInOpenStateMs) {
      this.waitDurationInOpenStateMs = waitDurationInOpenStateMs;
    }
  }

  public static class TrafficControl {
    private GlobalRateLimit globalRateLimit = new GlobalRateLimit();

    public GlobalRateLimit getGlobalRateLimit() {
      return globalRateLimit;
    }

    public void setGlobalRateLimit(GlobalRateLimit globalRateLimit) {
      this.globalRateLimit = globalRateLimit;
    }
  }

  public static class GlobalRateLimit {
    private boolean enabled = true;
    private int requestsPerSecond = 300;
    private int burstCapacity = 600;

    public boolean isEnabled() {
      return enabled;
    }

    public void setEnabled(boolean enabled) {
      this.enabled = enabled;
    }

    public int getRequestsPerSecond() {
      return requestsPerSecond;
    }

    public void setRequestsPerSecond(int requestsPerSecond) {
      this.requestsPerSecond = requestsPerSecond;
    }

    public int getBurstCapacity() {
      return burstCapacity;
    }

    public void setBurstCapacity(int burstCapacity) {
      this.burstCapacity = burstCapacity;
    }
  }

  public static class RouteRule {
    private String id;
    private String path;
    private String target;
    private Boolean authRequired;
    private Integer requestTimeoutMs;
    private Integer connectTimeoutMs;
    private Retry retry;
    private CircuitBreaker circuitBreaker;
    private int rateLimitRps;
    private WriteProtection writeProtection = new WriteProtection();
    private List<MethodPolicy> methodPolicies = new ArrayList<>();

    public String getId() {
      return id;
    }

    public void setId(String id) {
      this.id = id;
    }

    public String getPath() {
      return path;
    }

    public void setPath(String path) {
      this.path = path;
    }

    public String getTarget() {
      return target;
    }

    public void setTarget(String target) {
      this.target = target;
    }

    public Boolean getAuthRequired() {
      return authRequired;
    }

    public void setAuthRequired(Boolean authRequired) {
      this.authRequired = authRequired;
    }

    public Integer getRequestTimeoutMs() {
      return requestTimeoutMs;
    }

    public void setRequestTimeoutMs(Integer requestTimeoutMs) {
      this.requestTimeoutMs = requestTimeoutMs;
    }

    public Integer getConnectTimeoutMs() {
      return connectTimeoutMs;
    }

    public void setConnectTimeoutMs(Integer connectTimeoutMs) {
      this.connectTimeoutMs = connectTimeoutMs;
    }

    public Retry getRetry() {
      return retry;
    }

    public void setRetry(Retry retry) {
      this.retry = retry;
    }

    public CircuitBreaker getCircuitBreaker() {
      return circuitBreaker;
    }

    public void setCircuitBreaker(CircuitBreaker circuitBreaker) {
      this.circuitBreaker = circuitBreaker;
    }

    public int getRateLimitRps() {
      return rateLimitRps;
    }

    public void setRateLimitRps(int rateLimitRps) {
      this.rateLimitRps = rateLimitRps;
    }

    public WriteProtection getWriteProtection() {
      return writeProtection;
    }

    public void setWriteProtection(WriteProtection writeProtection) {
      this.writeProtection = writeProtection;
    }

    public List<MethodPolicy> getMethodPolicies() {
      return methodPolicies;
    }

    public void setMethodPolicies(List<MethodPolicy> methodPolicies) {
      this.methodPolicies = methodPolicies;
    }
  }

  public static class MethodPolicy {
    private String id;
    private List<String> methods = new ArrayList<>();
    private Integer requestTimeoutMs;
    private Integer connectTimeoutMs;
    private Retry retry;
    private CircuitBreaker circuitBreaker;
    private Integer rateLimitRps;

    public String getId() {
      return id;
    }

    public void setId(String id) {
      this.id = id;
    }

    public List<String> getMethods() {
      return methods;
    }

    public void setMethods(List<String> methods) {
      this.methods = methods;
    }

    public Integer getRequestTimeoutMs() {
      return requestTimeoutMs;
    }

    public void setRequestTimeoutMs(Integer requestTimeoutMs) {
      this.requestTimeoutMs = requestTimeoutMs;
    }

    public Integer getConnectTimeoutMs() {
      return connectTimeoutMs;
    }

    public void setConnectTimeoutMs(Integer connectTimeoutMs) {
      this.connectTimeoutMs = connectTimeoutMs;
    }

    public Retry getRetry() {
      return retry;
    }

    public void setRetry(Retry retry) {
      this.retry = retry;
    }

    public CircuitBreaker getCircuitBreaker() {
      return circuitBreaker;
    }

    public void setCircuitBreaker(CircuitBreaker circuitBreaker) {
      this.circuitBreaker = circuitBreaker;
    }

    public Integer getRateLimitRps() {
      return rateLimitRps;
    }

    public void setRateLimitRps(Integer rateLimitRps) {
      this.rateLimitRps = rateLimitRps;
    }
  }

  public static class WriteProtection {
    private boolean enabledDuringCutover;
    private List<String> methods = new ArrayList<>();

    public boolean isEnabledDuringCutover() {
      return enabledDuringCutover;
    }

    public void setEnabledDuringCutover(boolean enabledDuringCutover) {
      this.enabledDuringCutover = enabledDuringCutover;
    }

    public List<String> getMethods() {
      return methods;
    }

    public void setMethods(List<String> methods) {
      this.methods = methods;
    }
  }

  public static class CutoverSwitches {
    private boolean blockLegacyWrites;
    private boolean allowReadOnlyFallback;
    private EmergencyStop emergencyStop = new EmergencyStop();

    public boolean isBlockLegacyWrites() {
      return blockLegacyWrites;
    }

    public void setBlockLegacyWrites(boolean blockLegacyWrites) {
      this.blockLegacyWrites = blockLegacyWrites;
    }

    public boolean isAllowReadOnlyFallback() {
      return allowReadOnlyFallback;
    }

    public void setAllowReadOnlyFallback(boolean allowReadOnlyFallback) {
      this.allowReadOnlyFallback = allowReadOnlyFallback;
    }

    public EmergencyStop getEmergencyStop() {
      return emergencyStop;
    }

    public void setEmergencyStop(EmergencyStop emergencyStop) {
      this.emergencyStop = emergencyStop;
    }
  }

  public static class EmergencyStop {
    private boolean enabled;
    private int httpStatus = 503;

    public boolean isEnabled() {
      return enabled;
    }

    public void setEnabled(boolean enabled) {
      this.enabled = enabled;
    }

    public int getHttpStatus() {
      return httpStatus;
    }

    public void setHttpStatus(int httpStatus) {
      this.httpStatus = httpStatus;
    }
  }

  public void normalize() {
    if (defaults == null) {
      defaults = new Defaults();
    }
    if (defaults.getRetry() == null) {
      defaults.setRetry(new Retry());
    }
    if (defaults.getCircuitBreaker() == null) {
      defaults.setCircuitBreaker(new CircuitBreaker());
    }
    if (trafficControl == null) {
      trafficControl = new TrafficControl();
    }
    if (trafficControl.getGlobalRateLimit() == null) {
      trafficControl.setGlobalRateLimit(new GlobalRateLimit());
    }
    if (routes == null) {
      routes = new ArrayList<>();
    }
    if (cutoverSwitches == null) {
      cutoverSwitches = new CutoverSwitches();
    }
    if (cutoverSwitches.getEmergencyStop() == null) {
      cutoverSwitches.setEmergencyStop(new EmergencyStop());
    }

    routes.removeIf(route -> route == null
        || Objects.isNull(route.getId())
        || Objects.isNull(route.getPath())
        || Objects.isNull(route.getTarget()));

    for (RouteRule route : routes) {
      if (route.getWriteProtection() == null) {
        route.setWriteProtection(new WriteProtection());
      }
      if (route.getMethodPolicies() == null) {
        route.setMethodPolicies(new ArrayList<>());
      }
      route.getMethodPolicies().removeIf(methodPolicy ->
          methodPolicy == null
              || methodPolicy.getMethods() == null
              || methodPolicy.getMethods().isEmpty()
      );
    }
  }
}
