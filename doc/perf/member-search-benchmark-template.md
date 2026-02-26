# Member Search Benchmark Report

## 1. Test Scope
- Date:
- Operator:
- Branch/Commit:
- DB Size:
- Service Version:

## 2. Environment
- DB: SQL Server (container name / version)
- App runtime:
- Host spec:
- Data source: synthetic members dataset

## 3. Dataset Profile
| Rows | ACTIVE ratio | INACTIVE ratio | Name keyword distribution |
|---:|---:|---:|---|
| 100,000 |  |  |  |
| 500,000 |  |  |  |
| 1,000,000 |  |  |  |

## 4. Scenario Matrix
| Scenario | Query/API | Page | Expected index path |
|---|---|---:|---|
| status-only | `status=ACTIVE` | 0 | `ix_members_status_member_id` |
| keyword-prefix | `keyword=M0001` | 0 | PK/prefix seek |
| status+keyword | `status=ACTIVE&keyword=ALPHA` | 0 | composite + name index |
| page variance | `status=ACTIVE` | 1000 | pagination scan/seek |

## 5. SQL Execution Plan and STATISTICS IO/TIME
### 5.1 Estimated/Actual plan summary
- Key operators:
- Seek/Scan ratio:
- Warnings (spill, missing index):

### 5.2 IO/TIME summary
| Scenario | logical reads | cpu time(ms) | elapsed time(ms) |
|---|---:|---:|---:|
| status-only |  |  |  |
| keyword-prefix |  |  |  |
| status+keyword |  |  |  |
| page variance |  |  |  |

## 6. API Benchmark (p50/p95/p99, TPS, error rate)
| Scenario | p50(ms) | p95(ms) | p99(ms) | TPS | Error Rate(%) |
|---|---:|---:|---:|---:|---:|
| status-only |  |  |  |  |  |
| keyword-prefix |  |  |  |  |  |
| status+keyword |  |  |  |  |  |
| page variance |  |  |  |  |  |

## 7. Before/After Comparison
| Scenario | Before p95(ms) | After p95(ms) | Delta(%) | Notes |
|---|---:|---:|---:|---|
| status-only |  |  |  |  |
| keyword-prefix |  |  |  |  |
| status+keyword |  |  |  |  |
| page variance |  |  |  |  |

## 8. Bottlenecks and Next Actions
- Bottleneck 1:
- Bottleneck 2:
- Additional tuning proposal:

