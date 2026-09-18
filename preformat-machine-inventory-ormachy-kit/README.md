# Pre-format machine inventory and Ormachy onboarding kit

This kit is for the old HP Windows 10 machine that will become the Linux
brain node. Run the collector before formatting while Windows is still
available. It is read-only: it queries Windows inventory APIs and writes
reports; it does not change configuration, install software, or upload data.

## Quick start

1. Copy this directory to the machine, or clone the repository.
2. Open **Windows PowerShell** (Run as administrator only if you want the
   optional health/security queries to return more fields).
3. Run:

   ```powershell
   Set-Location .\preformat-machine-inventory-ormachy-kit
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\collect-machine-inventory.ps1
   ```

4. Review the generated files under `capture\<timestamp>\`. The default report
   redacts serial numbers, MAC addresses, IP addresses, DNS suffixes, and
   other host-specific identifiers. Do not copy raw output into Git.
5. Complete `templates\preformat-inventory-summary.md`, the decision record,
   and the checklists before formatting.

To collect a local hardware serial for an offline handoff, use
`-IncludeHardwareIdentifiers`. That flag still writes only to the ignored
capture directory; manually remove or redact the value before sharing.

## Files

- `collect-machine-inventory.ps1` — portable, read-only collector.
- `templates/preformat-inventory-summary.md` — sanitized, Git-suitable
  inventory worksheet.
- `templates/target-install-decision-record.md` — decisions required before
  installing Linux and Ormachy.
- `docs/operations-checklists.md` — backup, recovery, hardening, networking,
  logging, and sign-off checklists.
- `docs/agent-capability-matrix.md` — capability boundaries for agents on the
  brain node.

## Safety boundary

The collector intentionally does **not** read passwords, tokens, browser
cookies, private keys, credential stores, or full user files. It does not
export file contents. It may expose software names and versions in the local
capture, so treat the capture as operationally sensitive and delete it after
the handoff is complete.

