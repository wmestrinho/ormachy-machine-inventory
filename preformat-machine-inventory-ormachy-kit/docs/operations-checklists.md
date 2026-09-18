# Operations checklists

## Backup and preservation

- [ ] Identify all required user data, application data, licenses, and exports.
- [ ] Create two independent backups on separate media.
- [ ] Verify backup contents by restoring representative files.
- [ ] Record backup dates, sizes, checksums, and custodians offline.
- [ ] Export required Windows/Ormachy configuration without exporting secrets.
- [ ] Confirm BitLocker recovery key and Windows license handling.
- [ ] Obtain explicit approval before deleting the Windows installation.

## Recovery media

- [ ] Create and test Linux installer media from a trusted source.
- [ ] Create vendor diagnostics/firmware media if available.
- [ ] Keep a known-good network installer and offline package fallback.
- [ ] Record BIOS/UEFI boot-menu steps and reset procedure.
- [ ] Keep a second machine or console path for recovery.
- [ ] Test restore of the backup and document the result.

## Post-install hardening

- [ ] Apply firmware updates from the vendor and enable UEFI-only boot.
- [ ] Use LUKS/full-disk encryption; store recovery material in the approved vault.
- [ ] Create a non-root administrator; disable direct root and password SSH.
- [ ] Use SSH keys from the approved device; do not copy private keys into the node.
- [ ] Enable a host firewall with default-deny inbound policy.
- [ ] Permit Ormachy ports only from the management/service network.
- [ ] Enable unattended security updates with a tested reboot policy.
- [ ] Minimize packages and services; remove unused Windows-era software/data.
- [ ] Set time synchronization and a stable hostname.
- [ ] Verify audit logs, log rotation, disk-space alerts, and clock accuracy.
- [ ] Run a vulnerability/configuration scan and record exceptions.

## Network segmentation

- [ ] Put management access on a dedicated management VLAN or subnet.
- [ ] Put Ormachy workloads on a separate service VLAN/subnet.
- [ ] Deny lateral access to user, backup, and IoT networks by default.
- [ ] Restrict egress to required update, DNS, NTP, registry, and API endpoints.
- [ ] Permit inbound connections only from documented operators/services.
- [ ] Use split DNS or internal names; never expose administration to the public Internet.
- [ ] Document firewall rules with owner, purpose, source, destination, and expiry.

## Logging and backups

- [ ] Send security/system/service logs to a separate protected log destination.
- [ ] Do not log credentials, tokens, cookies, private keys, or full prompts containing secrets.
- [ ] Alert on authentication failures, privilege changes, service changes, disk health,
      low free space, backup failures, and unexpected network exposure.
- [ ] Back up Ormachy configuration and data using encryption and least privilege.
- [ ] Test restore quarterly and after major changes.
- [ ] Define retention, access reviewers, and deletion/incident procedures.

## Credential and secret migration rules

- [ ] Never migrate passwords, browser cookies, tokens, private keys, SSH agent sockets,
      credential-manager exports, or environment files by copying the old profile.
- [ ] Inventory secret *names and owners*, not secret values.
- [ ] Rotate every credential that touched the old Windows host before/after migration.
- [ ] Reissue service credentials in the approved secret manager with least privilege.
- [ ] Use short-lived credentials and scoped API access where supported.
- [ ] Inject secrets at runtime; keep them out of Git, logs, backups, and agent context.
- [ ] Revoke old credentials after a verified cutover and record revocation dates.

## Sign-off

- [ ] Inventory reviewed and sanitized.
- [ ] Backups restored successfully.
- [ ] Recovery media tested.
- [ ] Install decisions approved.
- [ ] Network rules reviewed.
- [ ] Hardening checks completed.
- [ ] Logging and backups verified.
- [ ] Credential rotation/revocation completed.
- [ ] Data owner sign-off:
- [ ] Technical owner sign-off:
- [ ] Security owner sign-off:
- [ ] Date and change reference:

