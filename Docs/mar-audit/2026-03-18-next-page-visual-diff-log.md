# Next Page Visual Diff Log

Date: 2026-03-18

Goal:
- Make the Next frontend read as the same product family as the Flutter frontend before deeper API work.

This document logs the page-by-page visual and interaction differences that existed before the parity pass, the exact parity work applied in this pass, and the screenshot targets now used as the acceptance baseline.

## Shared token diff

Flutter token source:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/core/styles/AppStyle.dart`

Next token file changed in this pass:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css`

Pre-fix global mismatches:
- warm foundation and surface colors instead of `#F8FAFC` and `#FFFFFF`
- orange accent and brown warning instead of Flutter blue and pink-red
- serif typography instead of compact sans typography
- pill controls instead of `4px` rectangular fields and buttons
- `24px` to `34px` shell radii instead of the Flutter `4px` to `12px` range
- dark sidebar and editorial auth split-screen instead of the white rail and centered auth card
- glass/blur treatment instead of flat surfaces with clean borders

Global parity work applied:
- reset the palette to Flutter values
- switched body typography to a compact sans stack
- replaced shell, card, control, and modal radii with Flutter-sized values
- removed the auth gradient and dark shell identity
- added a shared internal parity component layer for cards, buttons, fields, overlays, and modal frames

## Login

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-login.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AccessScreens.dart`

Next pre-fix reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-login.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/auth-form.tsx`

Page-structure mismatches that existed:
- Next used a two-column split layout with a marketing aside
- the card width was materially wider than Flutter
- organization was a plain field instead of a search-and-select shell
- the mock role selector appeared on login even though Flutter login has no such control

Interaction mismatches that existed:
- no tenant chip state
- no compact auth action stack matching Flutter order
- login mode exposed mock-only controls in the main visible UI

Parity work applied:
- removed the auth aside entirely
- rebuilt login as a centered single-card auth surface
- added tenant search shell plus selected-tenant chip treatment
- removed the visible mock role selector from login
- matched the blue primary action, muted secondary action, and rectangular field treatment

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-login.png`

Remaining gap:
- tenant search is still mock-backed rather than Rails-backed

## Signup

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-signup.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AccessScreens.dart`

Next pre-fix reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-login.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/auth-form.tsx`

Page-structure mismatches that existed:
- signup inherited the same split-screen auth shell as login
- account type control was missing from the visible layout
- spacing and density were looser than Flutter

Interaction mismatches that existed:
- signup did not present the same compact field stack as Flutter
- org-registration and auth-mode links did not follow Flutter ordering

Parity work applied:
- reused the centered auth card for signup
- restored the account type selector to the visible signup flow
- matched the stacked field density and helper-link treatment

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-signup.png`

Remaining gap:
- signup is still mock-backed and not yet constrained by real whitelist or live org search

## Onboarding Step 1

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step1.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationOnboardingScreen.dart`

Next pre-fix reference:
- no dedicated page existed

Page-structure mismatches that existed:
- organization onboarding was not represented in the Next auth surface
- the progress indicator and centered `500px` onboarding shell were missing

Interaction mismatches that existed:
- no manager-validation step existed

Parity work applied:
- added `/auth/onboarding/step-1`
- reproduced the Flutter top bar, progress bars, manager-email field, and manager-password field

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-onboarding-step1.png`

Remaining gap:
- still mock only; no backend request is sent

## Onboarding Step 2

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step2.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationOnboardingScreen.dart`

Next pre-fix reference:
- no dedicated page existed

Page-structure mismatches that existed:
- org-details and admin-password step missing entirely

Interaction mismatches that existed:
- no step-driven onboarding navigation shell

Parity work applied:
- added `/auth/onboarding/step-2`
- matched the organization-details title, subtitle, and dense field stack

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-onboarding-step2.png`

Remaining gap:
- the step still routes locally instead of calling create-organization

## Onboarding Step 3

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step3.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationOnboardingScreen.dart`

Next pre-fix reference:
- no dedicated page existed

Page-structure mismatches that existed:
- whitelist step missing entirely

Interaction mismatches that existed:
- no add/remove whitelist shell
- no provisioning action aligned to the Flutter wizard

Parity work applied:
- added `/auth/onboarding/step-3`
- added whitelist add/remove controls and mock provisioning CTA

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-onboarding-step3.png`

Remaining gap:
- no final TOTP result step exists yet in Next

## Dashboard

Flutter reference:
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/DashboardHome.dart`
- Supporting widgets:
  - `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/DashboardMetrics.dart`
  - `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/MachineStopCard.dart`

Next pre-fix reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-dashboard.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/dashboard/components/dashboard-screen.tsx`

Page-structure mismatches that existed:
- oversized hero-stat layout
- editorial cards and status chips
- dark shell chrome around content

Interaction mismatches that existed:
- dashboard read as a redesign rather than an operational console

Parity work applied:
- removed the hero-story framing
- rebuilt the metric row as compact operational cards
- rewrote the machine list into flatter stop cards
- moved the shell to the white Flutter rail and quiet header

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-dashboard.png`

Remaining gap:
- dashboard content still uses mock data instead of live business metrics

## Routes

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-routes.png` if recaptured later
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/routes/MapInterface.dart`

Next pre-fix reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-routes.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/placeholders/components/placeholder-screen.tsx`

Page-structure mismatches that existed:
- generic placeholder cards instead of a map-first layout
- no filter pod
- no assignment surface

Interaction mismatches that existed:
- manager route assignment shell missing
- no employee-restricted route context

Parity work applied:
- replaced the generic placeholder with a React Leaflet map shell
- added the top-left filter pod
- added a manager assignment bottom sheet
- preserved a route-context sheet for employee mode

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-routes.png`

Remaining gap:
- route geometry, auto-generation, and backend assignment are still mock only

## Warehouse

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-warehouse.png` if recaptured later
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/warehouse/StockScreens.dart`

Next pre-fix reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-warehouse.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/placeholders/components/placeholder-screen.tsx`

Page-structure mismatches that existed:
- generic placeholder cards instead of a sparse inventory workspace
- no shipment entry point
- no scanner FAB

Interaction mismatches that existed:
- no shipment bottom sheet
- no stock/scanner modal shell

Parity work applied:
- replaced the placeholder with a warehouse scaffold matching the Flutter empty state
- added shipment button, shipment sheet, schedule dialog, and scanner modal shell
- restored the bottom-right dark scanner action

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-warehouse.png`

Remaining gap:
- inventory remains empty and mock-backed

## Admin Modal

Flutter reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-admin.png` if recaptured later
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationAdminModal.dart`

Next pre-fix reference:
- Screenshot: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-admin.png`
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/placeholders/components/placeholder-screen.tsx`

Page-structure mismatches that existed:
- standalone placeholder page instead of a modal shell
- no tabbed machine/whitelist treatment

Interaction mismatches that existed:
- no modal close behavior
- no whitelist add/remove shell

Parity work applied:
- converted `/admin` into a dimmed-backdrop modal surface
- added `Machines` and `Whitelist` tabs
- matched the dense form layout and primary actions

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-admin-modal.png`

Remaining gap:
- machine creation and whitelist persistence are still local mock actions

## Settings Overlay

Flutter reference:
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/settings/SettingsMenu.dart`
- Container shell: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart`

Next pre-fix reference:
- inline placeholder card inside page flow

Page-structure mismatches that existed:
- settings rendered inline in content instead of in an overlay panel
- admin verification state was absent

Interaction mismatches that existed:
- no employee simulation control in a dedicated settings surface
- no admin verification dialog entry

Parity work applied:
- moved settings into an overlay panel
- added session summary, employee simulation control, admin access status, and admin console link
- added a dedicated admin verification dialog shell

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-settings-overlay.png`

Remaining gap:
- verification state is local in-memory mock state only

## Mobile Nav State

Flutter reference:
- Source: `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart`

Next pre-fix reference:
- generic dark mobile bar with icon-only presentation

Page-structure mismatches that existed:
- dark mobile nav styling and oversized shell softness
- no Flutter-style white pill-bottom-nav appearance

Interaction mismatches that existed:
- mobile shell did not read as the same product family as Flutter

Parity work applied:
- rebuilt the mobile nav as a white rounded bottom control
- kept route icons and added settings entry
- aligned spacing and scale to the Flutter mobile shell

Acceptance / current parity capture:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-mobile-dashboard.png`

Remaining gap:
- mobile route/admin interactions are still parity shells, not live features

## Files changed in this parity pass

Core styling and shell:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/app-shell.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/providers/shell-provider.tsx`

Auth and onboarding:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/auth-form.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/onboarding-screen.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/admin-verification-dialog.tsx`

Feature shells:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/dashboard/components/dashboard-screen.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/routes/components/routes-screen.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/routes/components/route-map-canvas.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/warehouse/components/warehouse-screen.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/admin/components/admin-modal.tsx`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/settings/components/settings-panel.tsx`

Screenshot evidence:
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-login.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-signup.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-onboarding-step1.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-onboarding-step2.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-onboarding-step3.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-dashboard.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-routes.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-warehouse.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-admin-modal.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-settings-overlay.png`
- `/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-parity-mobile-dashboard.png`
