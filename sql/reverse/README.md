# Reverse Engineering SQL Templates

This folder contains SQL Server metadata queries for reverse engineering:

- `01_tables_columns.sql`
- `02_pk_uk_fk.sql`
- `03_indexes.sql`
- `04_constraints.sql`
- `05_sp_dependencies.sql`
- `06_rowcount.sql`

## Export Command
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\reverse-export-schema.ps1 `
  -RunId "DB-RE-$(Get-Date -Format yyyyMMdd-HHmmss)" `
  -Server "localhost,11433" `
  -Database "MES_HI" `
  -EnvFile ".env.staging"
```

## Generate Mermaid ERD
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\reverse-generate-erd.ps1 `
  -InputDir "migration/reverse/<RunId>"
```

Output:
- `migration/reverse/<RunId>/erd.mmd`
