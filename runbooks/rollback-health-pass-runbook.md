# Rollback Health PASS Runbook (SCM-228)

## Goal
Enforce rollback completion with both:
- rollback time threshold pass (`<= 20 minutes`)
- post-restore service health pass (`auth/member/gateway = UP`)

## DoD
- `runbooks/evidence/<RunId>/rollback-time-summary.md` verdict is PASS.
- `runbooks/evidence/<RunId>/rollback-health-summary.md` verdict is PASS.
- `runbooks/go-nogo-signoff.md` rollback health metric is updated with evidence path.

## Command
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm228-enforce-rollback-health-pass.ps1 `
  -RunId "SCM-228-$(Get-Date -Format yyyyMMdd-HHmmss)" `
  -ThresholdMinutes 20 `
  -EnvFile ".env.staging" `
  -Database "MES_HI" `
  -SqlHost "localhost" `
  -SqlPort 11433 `
  -RedisHost "localhost" `
  -RedisPort 16379 `
  -GatewayPolicyPath "infra/gateway/policies/local-auth-member-e2e.yaml" `
  -StartupTimeoutSec 180 `
  -StopExistingPorts
```

## Expected Evidence
- `runbooks/evidence/<RunId>/rollback-time-summary.md`
- `runbooks/evidence/<RunId>/rollback-health-summary.md`
- `runbooks/evidence/<RunId>/rollback-health-summary.json`
- `runbooks/evidence/<RunId>/service-pids.json`
- `runbooks/evidence/<RunId>/service-auth.out.log`
- `runbooks/evidence/<RunId>/service-member.out.log`
- `runbooks/evidence/<RunId>/service-gateway.out.log`

## Failure Rule
- If rollback time exceeds threshold: FAIL.
- If any health endpoint is not UP within timeout: FAIL.
- On FAIL, mark signoff as NO-GO and keep evidence logs for investigation.
