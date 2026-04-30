# VendingBackpack Shape

Monorepo for the VendingBackpack system. Current active surfaces are:
- `Backend/` Rails API
- `Frontend/` Flutter client
- `Frontend-Next/` web client
- `VendingBackpack-CLI/` Python terminal client

## #SELF REMINDERS

### Main Goals
- Keep public Flutter/CLI traffic behind Rails API security, not direct database access.
- Preserve additive, non-destructive tenant migrations: backfill blank organization ownership only when unambiguous.
- Keep backend hardening focused on role escalation, tenant scoping, platform-admin org creation, generic admin verification, restricted CORS, and local token-file permissions.

### Next Sub-Goal
- Validate the backend hardening with Ruby 3.3.10/Bundler 4.0.3 or a running Docker daemon, then run the Rails security tests and migrations.
