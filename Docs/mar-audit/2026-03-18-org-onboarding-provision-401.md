# Org Onboarding Provision Returns 401 From UI

Date: 2026-03-18

Area: Flutter web frontend organization onboarding

Summary:
Creating a new organization from the live Flutter web onboarding flow fails at the final `PROVISION ORGANIZATION` step with `401 Unauthorized`, even though the backend accepts the same request payload when it is sent directly from the browser context.

Observed behavior:
- Opened the live app at `http://localhost:9100/`
- Entered the org onboarding flow from `REGISTER NEW ORGANIZATION`
- Passed manager validation with seeded manager credentials
- Reached the final whitelist/provision screen
- Clicking `PROVISION ORGANIZATION` triggered `POST /api/organizations/create`
- The request returned `401 Unauthorized`

Backend validation:
- Replayed the same request from the browser context with explicit JSON:
  - `manager_email: admin@vbp.com`
  - `manager_password: password123`
  - `name: Codex Test Org 20260318-1816b`
  - `admin_password: admin-pass-123`
  - `whitelist: []`
- The backend returned `200 OK`
- The org was created successfully as `org_5dba19ac`
- The new org was then confirmed via `GET /api/organizations/search?q=Codex Test Org 20260318-1816b`

Impact:
- Users cannot complete organization provisioning through the visible onboarding UI
- Backend organization creation is functional
- The defect appears to be in frontend state binding, form wiring, or request construction during the final onboarding submit

Likely cause:
The onboarding UI is not sending the validated manager credentials correctly on the final submit, or it is submitting stale/empty state when `PROVISION ORGANIZATION` is pressed.

Recommended follow-up:
- Inspect `Frontend/lib/modules/auth/OrganizationOnboardingScreen.dart`
- Trace `SessionManager.createOrganization(...)`
- Confirm the final button sends the same manager credentials captured in step 1
- Verify Flutter field state survives page-step transitions and is serialized correctly into `/api/organizations/create`
