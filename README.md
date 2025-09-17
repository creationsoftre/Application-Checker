# Application Checker (PowerShell)

**Script:** `App_Checker.ps1`  
**Author:** TW  
**Original:** 2022‑04‑15  
**Purpose:** Quickly verify—at scale—whether a specific application is installed on a list of remote Windows machines.

---

## What this does (pitch for recruiters)

This script showcases **Windows fleet automation** and **PowerShell remoting** skills by:
- Prompting the user to select a text file containing computer names.
- Collecting credentials (pre-filled with the current user’s DOMAIN\username).
- Establishing **parallel remote sessions** to all machines via `New-PSSession`.
- Running a **remote inventory check** for a target application (default: `PowerShell 7-x64`) via `Invoke-Command`.
- Emitting concise, colorized status for each machine and **cleanly tearing down** remote sessions.

This demonstrates: secure credential handling, WinRM remoting, multi-host orchestration, and operational hygiene (session cleanup).

---

## High-level flow

1. **File picker UI** – Uses `.NET` `System.Windows.Forms.OpenFileDialog` so a non-technical user can click-select a `servers.txt`.
2. **Input parsing** – Reads servers into an array: `@(Get-Content servers.txt)`.
3. **Credential capture** – `Get-Credential` initialized with `DOMAIN\username` for least friction.
4. **Session fan‑out** – `New-PSSession -ComputerName $servers -Credential $creds`.
5. **Remote check** – `Invoke-Command` on each remote to determine if the application is installed.
6. **Results** – Colorized `Write-Host` lines (Green if found, Red if not).
7. **Cleanup** – `Get-PSSession | Remove-PSSession`.

---

## Key implementation details

- **UI/UX:** Lightweight Windows Forms dialog to select the server list file (no hardcoding paths).
- **Security:** Uses the user’s domain context to seed `Get-Credential`; actual password is **not stored**.
- **Remoting:** `New-PSSession` + `Invoke-Command` provide controlled, reusable remote contexts (more efficient than `Invoke-Command -ComputerName` for many targets).
- **Target app:** Currently set to `PowerShell 7-x64`. Easy to make configurable (see “Extending the script”).

> **Note on `Win32_Product`:** The script uses `Get-WmiObject -Class Win32_Product`. While functional, it can be **slow** and may trigger **MSI repair** operations on some systems. For production-scale use, consider registry-based queries or `Get-CimInstance` against `Win32Reg_AddRemovePrograms` (or package providers) instead. See “Production considerations.”

---

## Prerequisites

- **PowerShell 5.1+** on the operator machine.
- **WinRM/Remoting enabled** on target machines.
- Network reachability and firewall rules permitting WinRM (TCP 5985/5986).
- An account with rights to query installed software on the target hosts.
- A text file with one computer name per line, e.g.:
  ```text
  WS-101
  WS-102
  SRV-FILE01
  SRV-APPS02.domain.local
  ```

---

## Usage

1. **Open PowerShell** as a user with rights to the target machines.
2. **Run** the script:
   ```powershell
   .\App_Checker.ps1
   ```
3. **Select** the server list file when the picker appears.
4. **Enter credentials** if prompted (pre-filled with `DOMAIN\username`).
5. **Read results** in the console output:
   - `MACHINE-NAME – Application: PowerShell 7-x64 is installed.` (Green)
   - `MACHINE-NAME – Application: PowerShell 7-x64 is not installed.` (Red)

---

## Example output

```text
WS-101 – Application: PowerShell 7-x64 is installed.
WS-102 – Application: PowerShell 7-x64 is not installed.
SRV-APPS02 – Application: PowerShell 7-x64 is installed.
```

---

## Production considerations (what I’d improve for scale)

- **Avoid Win32_Product:** Replace with registry queries for better performance and no MSI side effects, e.g.:
  - Query `HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall` and the WOW6432Node equivalent.
  - Or use `Get-CimInstance` and filter by `Name`/`Version` properties exposed by ARP providers.
- **Parameterize inputs:** Add `param()` for `$ApplicationName`, `$ServerListPath`, `$ExportPath`.
- **Resiliency:** Add timeouts, per-host error handling, offline detection via `Test-Connection`/`Test-NetConnection`.
- **Reporting:** Export to CSV/JSON with `Export-Csv` for audit trails.
- **Parallelism:** Use PowerShell 7 + `ForEach-Object -Parallel` or background jobs where appropriate.
- **Logging:** Structured logs (e.g., ETW, JSON) for ingestion into Splunk/Log Analytics.

---

## Extending the script (quick wins)

- **Make the target app configurable:**
  ```powershell
  param(
    [string]$ApplicationName = "PowerShell 7-x64",
    [string]$ServerListPath
  )
  ```
- **Registry-based detection sample (remote):**
  ```powershell
  $paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
  )
  $found = Get-ChildItem $paths -ErrorAction SilentlyContinue |
           Get-ItemProperty |
           Where-Object { $_.DisplayName -eq $ApplicationName } |
           Select-Object DisplayName, DisplayVersion
  ```
- **Export results:**
  ```powershell
  $results | Export-Csv -NoTypeInformation -Path .\App_Checker_Results.csv
  ```

---

## Why this project is relevant (recruiter framing)

- **Demonstrates real-world IT automation**: file-driven inventory, remote fan-out, and secure credential use.
- **Scales across environments**: designed for multiple hosts and easily parameterized for different targets.
- **Operational maturity**: session lifecycle management, clear operator prompts, and actionable output.
- **Adaptable**: small refactors unlock reporting, dashboards, and compliance checks.

---

## Files

- `App_Checker.ps1` – Main script (UI for file pick, credentials, sessions, remote application check, cleanup).

---

## License

MIT (or specify your preferred license).
