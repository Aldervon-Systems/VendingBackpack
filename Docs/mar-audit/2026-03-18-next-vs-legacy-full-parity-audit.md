# Next App vs Legacy Frontend Full Parity Audit

Date: 2026-03-18

Compared surfaces:
- Next app: `http://localhost:3002`
- Legacy Flutter web frontend: `http://localhost:9100`

Method:
- Drove the live Next app with Playwright
- Drove the live legacy frontend with Playwright where possible
- Read implementation files from both codebases
- Cross-checked UI behavior against source-level integration depth
- Captured screenshot references for the reachable live states under `Docs/mar-audit/screenshots`

Route checklist walked:
- auth/login
- dashboard
- routes
- warehouse
- admin
- shell-level settings and role-switch behavior

## Executive summary

The Next app is currently a shell migration, not a feature-parity port. It successfully reproduces:
- auth shell structure
- protected app shell
- manager vs employee shell state
- navigation skeleton
- dashboard as a mocked representative screen

It does not yet reproduce the legacy frontend's:
- live Rails-backed authentication
- route planner and map workflows
- warehouse stock and shipment workflows
- admin modal functionality
- verification and whitelist controls
- operational data mutations

The visual language is also materially different. The Next app is using a warm editorial/glassmorphism treatment with large radii and serif typography, while the legacy Flutter UI uses a cooler lab-console style with tighter corners, denser spacing, and blue accenting.

## High-priority audit findings

1. Authentication parity is not present
- Next auth is fully mock-backed through `MockAuthRepository`
- Legacy auth is designed to hit real `/api` endpoints through `ApiClient`
- Result: the most critical integration boundary is not ported yet

2. Routes, warehouse, and admin are placeholders in Next
- Next `routes`, `warehouse`, and `admin` pages are intentionally placeholder-only
- Legacy frontend ships real modules for map routing, stock workflows, and organization admin
- Result: shell navigation exists, but feature parity does not

3. Visual parity is low
- Next uses `Georgia` and large rounded shapes (`28px`, `20px`, `24px`, `34px`, pill inputs)
- Legacy uses compact system UI styling, `8px` surface cards, `4px` interactive cards, and a blue-accent operational dashboard
- Result: the two products do not currently look like the same application family

4. Legacy live frontend has active auth/onboarding bugs
- Seeded login credentials are valid at the backend but rejected by the visible login UI
- Organization onboarding fails from the visible final submit button, but succeeds when the same payload is posted directly
- Result: the old frontend cannot currently be treated as a fully reliable reference implementation for pure click-path validation

5. Several Next style decisions are intrinsically off-brand for parity
- The Next app is not just “unfinished”; multiple baseline style choices are pointed in the wrong direction for this product
- The incorrect direction starts at the global token layer in `Frontend-Next/app/globals.css`
- Result: even fully implemented features would still feel wrong unless the token layer is corrected first

## Playwright walkthrough findings

### Auth / login

Next app:
- renders a two-column auth shell with large card, migration copy, and a static role selector
- visible copy explicitly frames the screen as a mock auth boundary
- login transitions into the mock shell successfully
- no backend dependency is required for the route to work

Legacy frontend:
- renders a compact single-card sign-in flow with tenant search, seeded-org lookup, and action links for org creation and account creation
- onboarding is modal/page-like and more operational than presentational
- visible login path fails with `INVALID CREDENTIALS` despite valid seeded backend credentials
- org onboarding advances through manager validation and org details, but fails at final visible provision submit

Key parity gap:
- Next reproduces auth framing, not auth behavior or visual language

### Dashboard

Next app:
- renders successfully after login
- includes shell header, manager view pill, and employee preview button
- dashboard body contains hero stat, KPI cards, machine pulse, and route note cards
- all dashboard content is mock-backed and stable

Legacy frontend:
- dashboard is data/controller-backed
- manager and employee behavior changes visible scope and metrics
- machine cards support operational interactions such as quantity update paths
- visual density is tighter and more tool-like

Key parity gap:
- Next matches the existence of a dashboard but not the interaction depth, data wiring, or compact operational styling

### Routes

Next app:
- route is navigable from the shell
- page is placeholder-only with explanatory copy about Phase 2
- no map canvas, no modal, no assignment interaction

Legacy frontend:
- route screen is a real map interface
- managers can filter, inspect, and assign
- route planning visuals include map markers and polylines
- assignment uses a bottom sheet/modal flow

Key parity gap:
- navigation parity exists, feature and overlay parity do not

### Warehouse

Next app:
- route is navigable from the shell
- page is placeholder-only with bullets about future inventory/shipment work
- no inventory rows, scanner, adjustment modal, or shipment sheet

Legacy frontend:
- warehouse includes inventory loading, scan-driven stock actions, dialogs, and shipments bottom sheet
- operational workflows are already modeled in the UI

Key parity gap:
- Next reserves the route only; legacy exposes actual stock and logistics workflows

### Admin

Next app:
- manager-only route exists and is reachable from the shell
- page is placeholder-only
- no whitelist management, machine creation, admin verification, or modal tabs

Legacy frontend:
- admin entry is modal-oriented rather than page-oriented
- machine registration and whitelist are separated into tabs
- admin flows are embedded in shell interactions, not isolated as a standalone placeholder page

Key parity gap:
- access restriction is mirrored, but the entire interaction model differs

### Settings and role-switch behavior

Next app:
- settings opens as an inline placeholder panel inside the shell
- manager can switch into employee preview mode from the header
- these interactions are visible and functional inside the mock shell

Legacy frontend:
- settings uses overlay behavior
- manager vs employee behavior is tied to session state and data restrictions
- the shell behavior is more modal/overlay-heavy than inline

Key parity gap:
- Next captures shell affordances conceptually, but not the same visual or interaction pattern

## Screenshot references

Next app captures:
- login: `Docs/mar-audit/screenshots/next-login.png`
- dashboard: `Docs/mar-audit/screenshots/next-dashboard.png`
- routes: `Docs/mar-audit/screenshots/next-routes.png`
- warehouse: `Docs/mar-audit/screenshots/next-warehouse.png`
- admin: `Docs/mar-audit/screenshots/next-admin.png`

Legacy Flutter captures:
- login: `Docs/mar-audit/screenshots/flutter-login.png`
- signup: `Docs/mar-audit/screenshots/flutter-signup.png`
- org onboarding step 1: `Docs/mar-audit/screenshots/flutter-org-onboarding-step1.png`
- org onboarding step 2: `Docs/mar-audit/screenshots/flutter-org-onboarding-step2.png`
- org onboarding step 3: `Docs/mar-audit/screenshots/flutter-org-onboarding-step3.png`

Screenshot limitations:
- Legacy authenticated dashboard/routes/warehouse/admin screenshots were not reliably reachable through the visible UI because the current login flow rejects valid seeded credentials
- The audit therefore uses live screenshots for all reachable auth/onboarding states and source-backed comparisons for the blocked authenticated legacy screens

## Next features still needed

### Auth and onboarding
- tenant search field and result list behavior comparable to Flutter auth
- selected-tenant chip state inside the auth card
- proper register-mode structure matching Flutter field order and density
- organization onboarding wizard shell equivalent to Flutter step flow
- admin verification surface equivalent to Flutter dual-key challenge
- backend auth integration later, but parity-accurate UI states now

### Shell and navigation
- hover-expand white sidebar behavior closer to Flutter
- quieter header bar with less hero emphasis
- overlay-based settings experience instead of inline content injection
- admin access status card comparable to Flutter settings
- manager/employee simulation controls styled like Flutter system controls

### Dashboard
- denser metric card row
- machine stop cards with expansion behavior
- operational list density instead of editorial card storytelling
- manager/employee content hierarchy closer to Flutter data panes

### Routes
- real route-shell composition instead of generic placeholder
- map canvas frame
- manager filter pod
- assignment sheet entry point
- visual affordance for route generation / dispatch actions

### Warehouse
- inventory list shell
- stock action dialog shell
- scanner entry affordance
- shipment bottom sheet shell
- shipment scheduling window shell

### Admin
- modal-style admin workflow, not full placeholder page
- machine registration tab shell
- whitelist management tab shell
- verification-aware admin status shell

### Mobile
- stronger parity for bottom navigation treatment
- route and warehouse mobile sheet patterns
- admin/settings modal behavior consistent with Flutter

## Inherently wrong or miscolored styles in Next

Primary source:
- [globals.css](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css)

### Wrong palette direction

Current Next values:
- `--bg: #f4f1e8`
- `--surface: rgba(255, 252, 246, 0.92)`
- `--surface-strong: #fffdf8`
- `--accent: #b4491b`
- `--accent-soft: rgba(180, 73, 27, 0.12)`
- `--success: #0f766e`
- `--warning: #9a3412`

Legacy target values:
- foundation `#F8FAFC`
- surface `#FFFFFF`
- border `#E2E8F0`
- primary text `#0F172A`
- secondary text `#64748B`
- accent `#3B82F6`
- success `#10B981`
- warning `#F43F5E`

Parity conclusion:
- the entire Next palette is shifted warm, earthy, and editorial
- the Flutter app is cool, clinical, and infrastructure-oriented

### Miscolored surfaces

Wrong now:
- warm beige page background
- cream-tinted panels
- dark charcoal sidebar
- purple/orange auth aside gradient
- warm accent pills and spinner

Should be:
- pale neutral foundation background
- white work surfaces
- light bordered sidebar shell
- blue-accent state cues
- no purple/orange storytelling gradients

### Miscolored semantic states

Wrong now:
- warning uses brown-orange (`#9a3412`) instead of alert pink-red
- success uses teal-green (`#0f766e`) instead of bright ops green
- accent-driven status styling inherits orange rather than blue

Why this matters:
- semantic colors in the Flutter UI communicate operational state
- changing them changes the app’s emotional tone and trust language

### Inherently wrong shape decisions

Wrong now:
- pill controls with `border-radius: 999px`
- auth card at `28px`
- sidebar at `30px`
- main panel at `34px`
- cards at `24px`

Flutter baseline:
- controls around `4px`
- rows around `6px`
- cards around `8px`
- admin modal shell around `12px`

Parity conclusion:
- these are not harmless style differences
- they make the Next app look like a different product family

### Inherently wrong typography and atmosphere

Wrong now:
- serif body stack `Georgia, Cambria, "Times New Roman", serif`
- decorative radial gradients in the page background
- glassmorphism blur on auth and shell surfaces
- stronger editorial whitespace and card softness

Flutter DNA:
- Inter-based sans
- flatter surfaces
- lower drama
- denser layout
- minimal atmospheric effects outside overlay blur

## Parity matrix

### 1. Auth

Legacy frontend:
- Multi-tenant org search
- login via `/api/token`
- signup via `/api/signup`
- org onboarding via `/api/organizations/create`
- session persistence through `SharedPreferences`
- admin verification flow exists in session manager

Next app:
- login and signup screens exist
- role selection is mock-only
- prefilled fake credentials are used
- auth does not call Rails
- session restore is local mock storage only

Parity verdict:
- Structural parity: partial
- Behavioral parity: low
- API parity: none

Notes:
- Next auth copy explicitly states "static auth boundary" and "without calling Rails yet"
- This is honest implementation status, but it is not parity

### 2. Shell and navigation

Legacy frontend:
- responsive shell with desktop sidebar and mobile nav
- settings overlay
- manager-only Admin entry
- sign out
- header with user context
- employee restriction and manager override behavior

Next app:
- desktop sidebar and mobile nav present
- settings rendered as a simple inline panel, not overlay
- manager-only admin route exists
- sign out works in the mock shell
- manager can preview employee state

Parity verdict:
- Structural parity: medium
- Behavioral parity: medium
- UX parity: low to medium

Gaps:
- settings interaction model does not match legacy overlay behavior
- admin in legacy is a modal flow, but Next uses a full placeholder page
- shell copy and brand tone differ substantially

### 3. Dashboard

Legacy frontend:
- loads business metrics via controllers/providers
- manager vs employee visibility is data-driven
- inventory and route scope are filtered by session role
- supports quantity updates through widget callbacks

Next app:
- dashboard is implemented, but uses `MockDashboardRepository`
- manager vs employee snapshots are mocked
- cards and KPI hierarchy are present
- no live data write paths

Parity verdict:
- Structural parity: medium
- Visual parity: medium-low
- Data parity: low

What matches:
- top-level dashboard route exists
- manager/employee switch exists
- KPI cards and machine summary sections exist

What does not match:
- no real repository integration
- no operational write interaction
- content shape is a simplified approximation of the Flutter version

### 4. Routes

Legacy frontend:
- real map screen via `flutter_map`
- route polylines
- employee filtering
- manager assignment modal
- auto-generate route control

Next app:
- placeholder only
- no map canvas
- no route list
- no assignment interaction
- no API or mock route planner behavior implemented

Parity verdict:
- Structural parity: low
- Behavioral parity: none
- API parity: none

### 5. Warehouse

Legacy frontend:
- inventory controller
- inventory loading
- barcode lookup
- add stock flow
- new SKU registration
- shipment bottom sheet
- add shipment dialog

Next app:
- placeholder only
- no inventory table
- no scanner
- no stock mutation flow
- no shipments UI

Parity verdict:
- Structural parity: low
- Behavioral parity: none
- API parity: none

### 6. Admin

Legacy frontend:
- manager-only admin modal
- machine registration
- whitelist management
- route and metrics refresh after mutation
- admin verification support exists in session manager and separate dialog

Next app:
- manager-only route guard exists
- admin page is placeholder only
- no whitelist UI
- no machine creation
- no admin verification

Parity verdict:
- Structural parity: low
- Behavioral parity: none
- API parity: none

### 7. Visual design system

Legacy frontend visual system:
- cool operational palette
- `AppColors.actionAccent = #3B82F6`
- foundation `#F8FAFC`
- surface `#FFFFFF`
- border `#E2E8F0`
- tight corners: `4px`, `6px`, `8px`, `12px`
- compact metrics and uppercase labels
- lab-console density and enterprise tool feel

Next visual system:
- warm beige/orange palette with teal secondary success
- accent `#b4491b`
- serif body typography
- strong gradient backgrounds
- glassmorphism panels
- much larger radii: `14px`, `20px`, `24px`, `28px`, `30px`, `34px`, pills

Parity verdict:
- Color parity: low
- Typography parity: low
- Radius parity: low
- Overall product identity parity: low

Specific differences:
- Next auth inputs are pill-shaped; legacy uses rectangular lab fields
- Next sidebar is rounded and editorial; legacy shell is flatter, denser, and more operational
- Next settings panel is lightweight inline content; legacy uses modals and overlays

### 8. Mobile behavior

Legacy frontend:
- mobile nav and overlay behavior are implemented in the main shell
- scanner and bottom sheets are part of actual feature thinking

Next app:
- mobile nav exists at shell level
- route and warehouse mobile interactions are not implemented because those features are placeholders

Parity verdict:
- Shell parity: partial
- Feature parity on mobile: none for routes/warehouse/admin

### 9. API and state management parity

Legacy frontend:
- `ApiClient` points web requests at `/api`
- auth, org creation, whitelist update, machine creation, inventory, and route flows are designed around real API interactions
- uses provider/change notifier patterns

Next app:
- auth and dashboard are mock repositories
- placeholder screens communicate future intent but do not integrate
- no equivalent live API-backed route, warehouse, or admin repositories are active

Parity verdict:
- Integration parity: very low
- Repository parity: low
- Persistence parity: low

## Live audit defects found during review

1. Legacy login UI rejects valid seeded credentials
- UI path returns `401`
- direct browser-context replay to `/api/token` with the same credentials returns `200`
- Logged separately in:
  - `Docs/mar-audit/2026-03-18-login-ui-rejects-seeded-creds.md`

2. Legacy org onboarding submit fails from the visible UI
- `PROVISION ORGANIZATION` returns `401`
- direct browser-context replay to `/api/organizations/create` with equivalent payload returns `200`
- Logged separately in:
  - `Docs/mar-audit/2026-03-18-org-onboarding-provision-401.md`

## Border radius and component-shape breakdown

Legacy frontend:
- cards mostly `8px`
- interactive surfaces often `4px`
- dialogs around `8px` to `12px`
- mobile nav `32px`
- overall feel: precise, technical, restrained

Next app:
- shell cards `24px`
- auth card `28px`
- sidebar `30px`
- main panel `34px`
- pills for inputs and buttons
- overall feel: soft, editorial, expressive

Parity conclusion:
- If the goal is migration fidelity, the Next component radius system should move much closer to the legacy shape language

## What is already good in the Next app

- clear shell decomposition
- role-aware navigation exists
- dashboard hierarchy is readable
- auth shell explains migration scope clearly
- manager-only admin guard is already respected
- mobile navigation baseline exists

## Recommended parity order

1. Fix legacy frontend login and org-onboarding UI bugs so the reference app is trustworthy during comparison
2. Replace Next mock auth with Rails-backed auth using the same contracts as the Flutter app
3. Align the Next design system to the legacy product language:
   - cooler palette
   - tighter radii
   - denser spacing
   - less editorial typography
4. Port warehouse from placeholder to functional inventory and shipment shell
5. Port routes from placeholder to map/list/assignment shell
6. Port admin from placeholder page to manager workflow matching whitelist and machine actions
7. Only after those are stable, refine visual polish and motion

## Final verdict

Current parity status:
- Auth: low
- Shell/navigation: medium
- Dashboard: medium-low
- Routes: none
- Warehouse: none
- Admin: none
- Visual design fidelity: low
- API integration fidelity: very low

The Next app is a valid migration scaffold, but it is not yet a parity implementation of the legacy frontend. Its strongest area is shell scaffolding. Its largest gaps are live API integration, routes, warehouse, admin, and visual fidelity to the existing operational UI.
