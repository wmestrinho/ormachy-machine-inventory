# Linux and Ormachy target-install decision record

Complete before formatting. Record secrets only in the approved secret manager,
never in this file.

## Target platform

- Linux distribution and release:
- Minimal/server installation:
- Filesystem and partition layout:
- LUKS encryption and unlock method:
- Boot mode and Secure Boot policy:
- Hostname convention (do not use a public hostname):
- Time zone and NTP source:
- Kernel update policy:

## Ormachy

- Ormachy version/source:
- Runtime and package manager:
- Service account name:
- Data directory:
- Listening interfaces and ports:
- Authentication method:
- Agent tools allowed:
- Agent tools explicitly denied:
- Upgrade/rollback method:

## Data migration

- Files/databases/configurations to migrate:
- Source validation and checksums:
- Destination ownership/permissions:
- Retention and deletion approval:
- Rollback point:

## Network and trust

- Management network/VLAN:
- Ormachy service network/VLAN:
- Egress allowlist:
- Ingress allowlist:
- DNS name policy:
- Firewall owner:

## Approval

- Technical owner:
- Data owner:
- Security reviewer:
- Planned install date:
- Go/no-go decision:

