# Next UX Parity Fix Plan

Date: 2026-03-18

Primary goal:
- Make the Next app visually and interactionally match the legacy Flutter frontend shell before prioritizing API integration.

Reference audit:
- [Full parity audit](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/2026-03-18-next-vs-legacy-full-parity-audit.md)

Reference screenshots:
- [Next screenshots](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots)
- [Legacy Flutter screenshots](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots)

## What parity means for this phase

This phase is not about making the Next app fully functional. It is about making it feel like the same product:
- same shell proportions
- same border radius system
- same spacing density
- same color language
- same typography feel
- same card and field treatment
- same overlay vs inline interaction patterns
- same route-level visual hierarchy

Anything related to live Rails integration is deferred unless it is necessary to render parity-accurate states.

## Current source of truth

Legacy styling and interaction references:
- [AppStyle.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/core/styles/AppStyle.dart)
- [AccessScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AccessScreens.dart)
- [PagesLayout.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart)
- [SettingsMenu.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/settings/SettingsMenu.dart)
- [DashboardHome.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/DashboardHome.dart)
- [MapInterface.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/routes/MapInterface.dart)
- [StockScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/warehouse/StockScreens.dart)
- [OrganizationAdminModal.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationAdminModal.dart)

Next implementation files to change:
- [globals.css](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css)
- [app-shell.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/app-shell.tsx)
- [nav-items.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/nav-items.tsx)
- [auth-form.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/auth-form.tsx)
- [dashboard-screen.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/dashboard/components/dashboard-screen.tsx)
- [placeholder-screen.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/placeholders/components/placeholder-screen.tsx)

Secondary Next files that should be reviewed during the same pass:
- [app-shell.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/app-shell.tsx)
- [auth-provider.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/providers/auth-provider.tsx)
- [mock-auth-repository.ts](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/lib/api/mock/mock-auth-repository.ts)
- [mock-dashboard-repository.ts](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/lib/api/mock/mock-dashboard-repository.ts)

## What the Next app still needs for parity

Auth and onboarding still needed:
- tenant search and tenant result list shell
- selected-tenant state chip
- compact register shell matching Flutter auth card density
- org onboarding wizard shell
- admin verification dialog shell

Shell still needed:
- white hover-expand sidebar treatment
- overlay settings panel instead of inline page card
- admin access status module
- quieter title bar and denser user metadata row

Dashboard still needed:
- metric cards closer to Flutter proportions
- machine stop card grammar
- dense section headers and operational subtitles
- less hero-story framing

Routes still needed:
- map-area shell
- manager filter/tool pod
- assignment sheet shell
- dispatch-style action affordances

Warehouse still needed:
- inventory list shell
- stock adjustment dialog shell
- scan entry shell
- shipment bottom sheet shell
- schedule shipment dialog shell

Admin still needed:
- modal-oriented admin console
- machine registration tab
- whitelist tab
- verification-aware admin state shell

## Styles that are currently wrong by default

Wrong or off-brand values currently in [globals.css](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css):
- `--bg: #f4f1e8`
- `--surface: rgba(255, 252, 246, 0.92)`
- `--surface-strong: #fffdf8`
- `--text: #1f2937`
- `--muted: #6b7280`
- `--accent: #b4491b`
- `--accent-soft: rgba(180, 73, 27, 0.12)`
- `--success: #0f766e`
- `--warning: #9a3412`
- `font-family: Georgia, Cambria, "Times New Roman", serif`
- `border-radius: 999px` on controls
- `border-radius: 30px` on sidebar
- `border-radius: 34px` on main panel
- `border-radius: 24px` on cards
- auth aside gradient `rgba(180, 73, 27, 0.92)` to `rgba(76, 29, 149, 0.72)`
- dark sidebar background `rgba(25, 28, 38, 0.94)`

Why these are inherently wrong:
- they push the product toward warm editorial SaaS styling
- the Flutter app is a cool lab-console tool
- even with perfect features, these values would still make the Next app feel non-parity

## Legacy token values to port first

Legacy colors from [AppStyle.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/core/styles/AppStyle.dart):
- foundation: `#F8FAFC`
- surface: `#FFFFFF`
- border: `#E2E8F0`
- dataPrimary: `#0F172A`
- dataSecondary: `#64748B`
- success: `#10B981`
- warning: `#F43F5E`
- actionAccent: `#3B82F6`

Legacy radius rules from source usage:
- primary surface cards: `8px`
- small interactive cards and input-like chips: `4px`
- overlay/admin dialog shell: `12px`
- row/select containers: `6px`
- mobile nav can remain pill-shaped where it already is in the Flutter shell

Legacy spacing and density signals:
- auth card max width around `380px`
- auth shell padding `32px` outer and `40px` inner
- labels are compact, uppercase, and dense
- controls use rectangular fields, not pill inputs
- dashboard sections use tighter spacing than current Next cards

## UX parity implementation plan

### 1. Replace the Next global design system

Target file:
- [globals.css](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css)

Changes:
- Replace the warm beige/orange/teal palette with the legacy Flutter palette.
- Remove serif typography and switch to a tighter product-safe sans stack that visually approximates Flutter web.
- Replace large expressive radii with the legacy radius system:
  - `--radius-card: 8px`
  - `--radius-control: 4px`
  - `--radius-overlay: 12px`
  - `--radius-row: 6px`
- Remove pill-shaped controls for `.input`, `.select`, `.button`, and `.ghost-button`.
- Reduce shell softness:
  - less blur
  - weaker shadow
  - clearer border lines
  - flatter surfaces
- Remove the editorial gradient-heavy auth treatment and move to a cleaner flat lab-console background.
- Replace dark sidebar styling with a light bordered sidebar modeled on Flutter.
- Replace brown-orange warning and teal success styling with Flutter semantic colors.

Acceptance criteria:
- Next login screen should read as the same product family as the Flutter login screen from a screenshot alone.
- No primary auth input or standard button should be fully pill-shaped.
- No primary app surface should depend on beige, orange, purple, or dark charcoal as its default shell identity.

### 2. Rebuild the auth shell to match Flutter structure

Target files:
- [auth-form.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/auth-form.tsx)
- [login/page.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/auth/login/page.tsx)
- [signup/page.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/auth/signup/page.tsx)

Changes:
- Collapse the current two-column auth composition into a centered single-card auth layout modeled on [AccessScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AccessScreens.dart).
- Keep the current Next mock wiring, but restyle the layout to match:
  - compact card width
  - bolt/logo tile
  - stacked field groups
  - rectangular tenant chip/search styling
  - understated helper text
- remove the current split-screen aside visual identity entirely
- Remove the high-level “Migration intent” aside from the main auth layout.
- Match heading hierarchy and spacing density to the Flutter auth card.
- Style signup mode to visually match Flutter’s “Register” state, including denser stacked fields and compact role selection.

Acceptance criteria:
- Login and signup screenshots should align closely with:
  - [flutter-login.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-login.png)
  - [flutter-signup.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-signup.png)

### 3. Rebuild the authenticated shell around Flutter proportions

Target files:
- [app-shell.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/app-shell.tsx)
- [nav-items.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/nav-items.tsx)
- [PagesLayout.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart)

Changes:
- Reduce the current highly rounded dark sidebar into a flatter, denser shell closer to the Flutter desktop layout.
- Match sidebar visual behavior to the legacy shell:
  - stronger information density
  - lower corner radii
  - less decorative copy
  - more operational labeling
- replace dark panel styling with white surface plus subtle right-border separation
- Rework the header so it resembles Flutter’s page-title/user bar instead of the current editorial topbar treatment.
- Make settings open as an overlay or side panel rather than inline placeholder content in the page flow.
- Preserve the manager-only admin nav rule and employee preview behavior, but style both to match Flutter controls.
- Ensure the mobile nav styling stays close to Flutter’s rounded bottom navigation pattern.

Acceptance criteria:
- Dashboard shell chrome should visually align with Flutter desktop shell proportions.
- Settings should no longer appear as a loose inline placeholder card inside page content.

### 4. Restyle dashboard content to match Flutter density

Target files:
- [dashboard-screen.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/dashboard/components/dashboard-screen.tsx)
- [DashboardHome.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/DashboardHome.dart)

Changes:
- Compress dashboard card spacing and typography.
- Replace the current hero-stat presentation with a flatter, denser section hierarchy closer to Flutter:
  - uppercase section label
  - tight subtitle
  - operational metrics cards
- Reduce the oversized decorative feel of KPI cards.
- remove warm accent emphasis from dashboard status surfaces
- Make list rows and machine summaries resemble Flutter machine cards more closely:
  - tighter radius
  - stronger border definition
  - less glassmorphism
  - less editorial whitespace
- Keep mock content for now, but reorganize the visual hierarchy to look operational instead of presentational.

Acceptance criteria:
- The Next dashboard should look like a web translation of [DashboardHome.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/DashboardHome.dart), not a redesign.

### 5. Replace placeholder route styling with parity-accurate shells

Target files:
- [placeholder-screen.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/placeholders/components/placeholder-screen.tsx)
- [MapInterface.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/routes/MapInterface.dart)
- [StockScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/warehouse/StockScreens.dart)
- [OrganizationAdminModal.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationAdminModal.dart)

Changes:
- Stop using one generic placeholder visual treatment for routes, warehouse, and admin.
- Give each route a parity-accurate shell, even if it is still mock-backed:
  - Routes: map-area frame, filter bar shell, manager action affordance, modal/bottom-sheet entry point styling
  - Warehouse: inventory table/list shell, shipment trigger shell, scanner-action shell
  - Admin: modal-oriented management shell with tab styling that mirrors Flutter admin tabs
- remove the current generic “placeholder shell” visual language from feature routes
- Keep these screens mock-backed if needed, but ensure their structure and component shapes resemble the legacy feature surfaces.

Acceptance criteria:
- Route screenshots should signal the same feature category as the Flutter pages, even before the real interactions are ported.
- Admin should stop reading as a full standalone placeholder page and instead reflect the Flutter modal workflow.

### 6. Build a reusable parity component layer in Next

Recommended new subsystem:
- `Frontend-Next/src/components/parity/`

Recommended components:
- `ParityCard`
- `ParityField`
- `ParityButton`
- `ParitySectionHeader`
- `ParityStatusRow`
- `ParityOverlayPanel`
- `ParityModalFrame`

Why:
- Prevent one-off CSS overrides across each page
- Keep the Next app from drifting again during later feature work
- Make future integration work inherit the Flutter visual system automatically

Implementation rule:
- Create the component layer only after the global tokens are reset, so the components encode the corrected radius, spacing, and color rules.

### 7. Keep integration intentionally secondary in this pass

Do not expand scope during the parity pass:
- do not port real auth yet
- do not wire real map interactions yet
- do not wire real inventory mutations yet
- do not wire real admin APIs yet

Allowed:
- minimal mock scaffolding additions only if they are needed to render parity-accurate UI states

## Execution order

1. Replace global tokens in [globals.css](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css)
2. Rebuild auth shell in [auth-form.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/features/auth/components/auth-form.tsx)
3. Rebuild shell chrome in [app-shell.tsx](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/src/components/shell/app-shell.tsx)
4. Restyle dashboard to match Flutter density
5. Split generic placeholders into route-specific parity shells
6. Add reusable parity components to stop further visual drift
7. Re-run Playwright screenshots and compare against the existing capture set

## Screenshot-driven acceptance criteria

Use these captures as the comparison baseline:
- [next-login.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-login.png)
- [next-dashboard.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-dashboard.png)
- [next-routes.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-routes.png)
- [next-warehouse.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-warehouse.png)
- [next-admin.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/next-admin.png)
- [flutter-login.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-login.png)
- [flutter-signup.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-signup.png)
- [flutter-org-onboarding-step1.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step1.png)
- [flutter-org-onboarding-step2.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step2.png)
- [flutter-org-onboarding-step3.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step3.png)

Definition of done for the UX pass:
- Next auth no longer looks like a redesign
- Next shell no longer uses oversized rounded editorial surfaces
- Next controls no longer use pill styling for standard fields/buttons
- Next route shells visually map to their Flutter equivalents
- Next settings/admin interaction patterns resemble Flutter overlays/modals instead of inline placeholders
- A fresh Playwright screenshot pass shows clear visual convergence with the legacy shell language

## Values that must change immediately

Current Next values in [globals.css](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend-Next/app/globals.css) that should be replaced:
- `--bg: #f4f1e8`
- `--surface: rgba(255, 252, 246, 0.92)`
- `--surface-strong: #fffdf8`
- `--text: #1f2937`
- `--muted: #6b7280`
- `--accent: #b4491b`
- `--accent-soft: rgba(180, 73, 27, 0.12)`
- `--success: #0f766e`
- `--warning: #9a3412`
- `--radius-xl: 28px`
- `--radius-lg: 20px`
- `--radius-md: 14px`
- `font-family: Georgia, Cambria, "Times New Roman", serif`
- `.input, .select, .button, .ghost-button { border-radius: 999px; }`
- `.sidebar { border-radius: 30px; }`
- `.sidebar { background: rgba(25, 28, 38, 0.94); }`
- `.main-panel { border-radius: 34px; }`
- `.main-panel { background: rgba(255, 251, 245, 0.7); }`
- `.card, .placeholder-card, .hero-stat { border-radius: 24px; }`
- `.auth-aside { background: linear-gradient(135deg, rgba(180, 73, 27, 0.92), rgba(76, 29, 149, 0.72)); }`
- `.status-pill { background: var(--accent-soft); color: var(--accent); }`
- `.spinner { border: 4px solid rgba(180, 73, 27, 0.16); border-top-color: var(--accent); }`

These are the fastest high-signal parity wins:
- change the palette to legacy values
- remove serif typography
- remove pill control styling
- collapse shell/card radii into legacy ranges
- remove warm gradients and dark shell surfaces
- correct semantic success/warning colors
- replace inline settings panel with overlay behavior

## Recommended follow-up after UX parity

Only after the screenshots converge:
- replace mock auth with Rails auth
- port settings/admin behavior against live APIs
- port routes and warehouse interactions
- reconcile old frontend bugs separately so the legacy app stays a reliable reference
