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
    private int rateLimitRps;
    private WriteProtection writeProtection = new WriteProtection();

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
    if (trafficControl == null) {
      trafficControl = new TrafficControl();
    }
    if (routes == null) {
      routes = new ArrayList<>();
    }
    if (cutoverSwitches == null) {
      cutoverSwitches = new CutoverSwitches();
    }

    routes.removeIf(route -> route == null || Objects.isNull(route.getId()) || Objects.isNull(route.getPath()) || Objects.isNull(route.getTarget()));
  }
}
