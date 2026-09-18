# Ormachy agent capability matrix

Grant capabilities per agent and environment. Default to deny; require an
explicit owner, purpose, scope, approval, and expiry for every exception.

| Capability | Default | Allowed only when | Guardrails and evidence |
|---|---|---|---|
| Read sanitized inventory | Yes | Agent needs host planning | No serials, secrets, cookies, private keys, or file contents |
| Read application configuration | Review | Named config paths are approved | Redact secrets; read-only service account |
| Read/write Ormachy data | Review | Data owner approves exact paths | Least-privilege UID, backups, audit log |
| Execute local commands | No | Specific commands are allowlisted | Non-root, timeout, resource limits, audited output |
| Install packages | No | Maintenance window and owner approval | Signed repositories, review diff, rollback plan |
| Change firewall/network | No | Network owner approves a documented rule | Change ticket, staged rollout, rollback |
| Access Internet | No | Exact destination and purpose are approved | Egress allowlist, proxy/logging, no arbitrary URLs |
| Access management network | No | Operator workflow requires it | Separate identity, MFA, no lateral discovery |
| Handle credentials/secrets | No | Secret manager integration is approved | Never reveal values to prompts/logs; short-lived scoped access |
| Send external messages | No | Human-approved destination and content | No sensitive data; record recipient and approval |
| Reboot/shutdown | No | Maintenance window and operator approval | Console fallback and recovery verification |

## Review record

- Agent/service:
- Environment:
- Owner:
- Approved capabilities:
- Denied capabilities:
- Expiry/review date:
- Monitoring and log destination:
- Incident disable/revoke procedure:

