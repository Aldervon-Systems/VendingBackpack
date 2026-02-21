# Security Audit (MVP Snapshot)

Scope: current repo code paths as of this audit, focused on auth, CORS, tenancy boundaries, and obvious abuse paths. This document describes risks and where they exist; it does not apply fixes.

## Highest Risk Issues

### 1) Privilege Escalation via Signup Role Trust

Problem: the client can choose `role` during signup and the backend trusts it. An attacker can sign up as `"manager"` and gain access to manager-only endpoints.

Locations:
- `Frontend/lib/modules/auth/SessionManager.dart:52` sends `role` in `/signup`.
- `Backend/app/controllers/api/auth_controller.rb:44` (signup) reads `role` from request and stores it.
- `Backend/app/controllers/application_controller.rb:10` `require_manager!` only checks `current_user["role"] == "manager"`.

Impact: full manager-level authorization bypass.

### 2) Plaintext Credentials and Shared Secrets Stored in Repo Fixtures

Problem: user passwords and organization secrets are stored in JSON fixtures in plaintext.

Locations:
- `Backend/data/fixtures/users.json:1` includes plaintext `password`.
- `Backend/data/fixtures/organizations.json:1` includes `admin_password` and `totp_seed`.
- `Backend/data/fixtures/whitelists.json:1` includes email allowlists.

Impact: any repo leak / container filesystem leak / backup leak yields direct access and org admin secrets.

### 3) Host Authorization Disabled in Production

Problem: production environment disables host-header protections.

Location:
- `Backend/config/environments/production.rb:79` clears `config.hosts` and excludes host authorization for all requests.

Impact: enables classes of Host-header / DNS-rebinding attacks and weakens assumptions for security middleware.

### 4) CORS is Fully Open

Problem: wildcard origins and permissive resource policy.

Location:
- `Backend/config/initializers/cors.rb:8` uses `origins "*"` and `resource "*", headers: :any`.

Impact: increases cross-origin abuse surface. Becomes more dangerous if access tokens are persisted in browser storage or if cookies are introduced later without tightening CORS.

## High Risk / Likely Abuse Paths

### 5) Manager-Only Endpoints Are Global (No Org/Tenant Scoping)

Problem: manager authorization exists, but there is no tenant boundary enforcement for most domain data. A manager can see/modify all data.

Examples:
- `Backend/app/controllers/api/employees_controller.rb:19` returns `Route.all`.
- `Backend/app/controllers/api/employees_controller.rb:111` `Route.destroy_all` clears routes globally.
- `Backend/app/controllers/api/warehouse_controller.rb:24` updates inventory without org scope.

Impact: cross-tenant data access and destructive global actions.

### 6) Sensitive Reads Available to Any Authenticated User (No Org Scope)

Problem: several endpoints return full datasets to any authenticated user.

Examples:
- `Backend/app/controllers/api/machines_controller.rb:5` returns all machines from JSON store.
- `Backend/app/controllers/api/transactions_controller.rb:9` returns all transactions.
- `Backend/app/controllers/api/warehouse_controller.rb:11` returns entire inventory to any authenticated user.

Impact: information disclosure; in multi-tenant reality this becomes a serious breach.

### 7) Public Org/Admin Endpoints Accept Secrets and Are Brute-Forceable

Problem: organization creation and admin verification accept high-value secrets without being authenticated and without rate limiting/lockout.

Locations:
- `Backend/config/routes.rb:10` `/api/organizations/create`
- `Backend/config/routes.rb:11` `/api/organizations/verify_admin`
- `Backend/app/controllers/api/auth_controller.rb:112` `create_organization`
- `Backend/app/controllers/api/auth_controller.rb:158` `verify_admin`

Note: `verify_admin` uses `totp.verify(totp_code, drift_behind: 30)` at `Backend/app/controllers/api/auth_controller.rb:173`. Depending on library semantics, that may accept a large range of valid codes.

Impact: brute-force/credential-stuffing surface; secret validation endpoints should be protected and rate-limited.

## Medium Risk / Correctness Concerns That Affect Security

### 8) No Rails-Layer TLS Enforcement

Problem: `config.force_ssl` is disabled in production.

Location:
- `Backend/config/environments/production.rb:37` sets `config.force_ssl = false`.

Impact: relies entirely on proxy correctness for HTTPS, HSTS, and secure cookie behavior (if added later).

### 9) Access Tokens Are Signed and Expiring, but Not Revocable

Problem: access tokens are long-lived (12h) and cannot be revoked server-side without rotating verifier secrets.

Locations:
- `Backend/app/controllers/api/auth_controller.rb:228` issues tokens with `exp` set to 12 hours.
- `Backend/app/controllers/application_controller.rb:46` verifies token signature and expiry only.

Impact: leaked tokens remain usable until expiry.

### 10) Web Frontend Boot Clears Storage on Every Load (Persistence Conflicts)

Problem: the web entrypoint unregisters service workers and clears caches/IndexedDB on every load.

Location:
- `Frontend/web/index.html:36` nukes SW + caches + IndexedDB.

Impact: breaks/complicates any auth persistence and may hide auth/session bugs in testing.

## Minimal First Fix Recommendation (No Architecture Change)

Fix first: stop trusting `role` from the client during signup, and have the server decide the role (default to `"employee"`). This closes the single biggest privilege escalation vector before tightening CORS/cookies.

