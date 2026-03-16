# Topology Alignment Execution Plan

## Purpose
Close the remaining gap between the production-approved gateway policy topology and the current host-process pre-deploy execution model.

## Current Gap
- Production-approved policy: `infra/gateway/policies/cutover-isolation.yaml`
- Production route targets:
  - `http://auth:8081`
  - `http://member:8082`
  - `http://board:8083`
  - `http://quality-doc:8084`
  - `http://order-lot:8085`
  - `http://inventory:8086`
  - `http://file:8087`
  - `http://report:8088`
- Current pre-deploy runtime:
  - gateway/service JVMs run as host processes on `localhost`
- Result:
  - direct service login succeeds
  - gateway login fails because gateway cannot resolve service names such as `auth`, `member`

## Recommended Order
1. Immediate unblock: use `infra/gateway/policies/cutover-isolation-localhost.yaml` for host-process pre-deploy only.
2. Structural alignment: standardize one runtime model for pre-deploy and cutover.

## Option A. Hosts-Based Name Alignment

### Goal
Make the host-process runtime resolve production-style route targets without changing the gateway policy targets.

### Required Change
- Add local host aliases:
  - `127.0.0.1 auth`
  - `127.0.0.1 member`
  - `127.0.0.1 board`
  - `127.0.0.1 quality-doc`
  - `127.0.0.1 order-lot`
  - `127.0.0.1 inventory`
  - `127.0.0.1 file`
  - `127.0.0.1 report`

### Execution Steps
1. Backup current hosts file.
2. Append the 8 aliases.
3. Flush DNS cache.
4. Re-run `prod-up` with the original `cutover-isolation.yaml`.
5. Re-run `smoke-test`.

### Verification
- `Resolve-DnsName auth` or `ping auth` resolves to `127.0.0.1`
- gateway login via `http://localhost:18080/api/auth/v1/login` returns `200`
- `smoke-test` PASS under `cutover-isolation.yaml`

### Risks
- Requires administrator privileges.
- Can pollute the local machine outside this repo.
- Must be removed after validation if not used permanently.

### Use When
- Fastest way to validate the production policy unchanged.
- Dedicated validation machine is available.

## Option B. Container/Network Topology Alignment

### Goal
Run gateway and upstream services inside one Docker network so production-style DNS names work natively.

### Required Change
- Add service containers or compose profiles for:
  - gateway
  - auth
  - member
  - board
  - quality-doc
  - order-lot
  - inventory
  - file
  - report
- Ensure route targets use container DNS names identical to policy targets.

### Execution Steps
1. Add compose service definitions for all 9 JVM services.
2. Mount `.env.production` into container startup or inject env at compose runtime.
3. Expose only gateway externally; keep upstream services on internal network.
4. Start stack with `docker compose up`.
5. Re-run full pre-deploy gates with smoke against containerized gateway.

### Verification
- `docker exec <gateway-container> ping auth` succeeds
- gateway route calls to `http://auth:8081` succeed inside network
- `smoke-test` PASS with original `cutover-isolation.yaml`

### Risks
- Larger implementation scope.
- Need image build/publish strategy and service container runbooks.
- More moving parts for local debugging.

### Use When
- Pre-deploy and actual cutover should share one runtime model.
- Team wants long-term reduction of localhost-only exceptions.

## Recommended Decision
- Short term: use `cutover-isolation-localhost.yaml` for host-process pre-deploy.
- Mid term: implement Option B and retire the localhost-only variant.

## Definition of Done
1. `smoke-test` PASS under a policy whose control values match `cutover-isolation.yaml`
2. gateway login returns `200`
3. direct auth login and gateway login both succeed with the same seeded credentials
4. no manual target editing required on cutover day
