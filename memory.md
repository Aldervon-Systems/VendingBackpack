# VendingBackpack Shape

Monorepo for the VendingBackpack system. Current active surfaces are:
- `Backend/` Rails API
- `Frontend/` Flutter client
- `Frontend-Next/` web client
- `VendingBackpack-CLI/` Python terminal client

## #SELF REMINDERS

### Main Goals
- Keep the Dart/Flutter client pointed at `https://app.aldervon.com/api` by default, with `API_BASE_URL` kept for local Rails overrides.
- Keep Flutter data contracts aligned to the Rails/Next route shapes through DTOs and repository layers.
- Keep the Python CLI as a sibling terminal surface; only bridge into Flutter through explicit surface-control flags.
- Treat the live database as Rails-owned; Flutter and CLI should connect through public/local Rails API endpoints, not directly to DB credentials.
- When launching Flutter for the user, report whether the macOS app process is actually running even if foregrounding fails.

### Next Sub-Goal
- Use the running macOS app to manually verify manager and employee login against the public Rails endpoint.
