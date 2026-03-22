# Login UI Rejects Valid Seeded Credentials

Date: 2026-03-18

Area: Flutter web frontend sign-in flow

Summary:
The visible Flutter sign-in form rejects valid seeded credentials with `INVALID CREDENTIALS`, while the backend token endpoint accepts the same credentials when the request is sent directly from the browser context.

Observed behavior:
- Opened the live Flutter web app at `http://localhost:9100/`
- Selected `Aldervon Systems`
- Entered seeded manager credentials:
  - `renee@aldervon.com`
  - `password123`
- Clicked `AUTHENTICATE`
- UI remained on the login screen and showed `INVALID CREDENTIALS`
- Network panel showed `POST /api/token -> 401 Unauthorized`

Backend validation:
- Replayed `POST /api/token` directly from the browser context with:
  - `email: renee@aldervon.com`
  - `password: password123`
- Backend returned `200 OK`
- Response included a valid access token and the expected manager user record

Impact:
- Seeded accounts cannot authenticate through the visible login form
- Live backend auth is functioning
- This blocks audit progress through normal UI login unless requests are replayed manually

Likely cause:
The login UI is sending incorrect or stale field values, or the Flutter web form wiring is not serializing the current email/password state correctly at submit time.

Relevant code:
- `Frontend/lib/modules/auth/AccessScreens.dart`
- `Frontend/lib/modules/auth/SessionManager.dart`

Recommended follow-up:
- Inspect how the login form populates `_emailController` and `_passwordController`
- Verify the active visible inputs map to the same controllers used by `_handleSubmit()`
- Confirm `SessionManager.login(...)` receives the typed values from the current screen state
- Compare the UI-submitted token payload against the successful direct request
