# Flutter Frontend Visual DNA

Date: 2026-03-18

Subject:
- Legacy Flutter web frontend at `http://localhost:9100`

Method:
- Live Playwright walkthrough of reachable screens
- Source review of shell, dashboard, routes, warehouse, auth, settings, and admin modules

Primary references:
- [main.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/main.dart)
- [AppStyle.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/core/styles/AppStyle.dart)
- [PagesLayout.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart)
- [Sidebar.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/Sidebar.dart)
- [AccessScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AccessScreens.dart)
- [SettingsMenu.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/settings/SettingsMenu.dart)
- [DashboardHome.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/DashboardHome.dart)
- [DashboardMetrics.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/DashboardMetrics.dart)
- [MachineStopCard.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/MachineStopCard.dart)
- [MapInterface.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/routes/MapInterface.dart)
- [StockScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/warehouse/StockScreens.dart)
- [OrganizationAdminModal.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationAdminModal.dart)
- [OrganizationOnboardingScreen.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationOnboardingScreen.dart)
- [AdminVerificationDialog.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AdminVerificationDialog.dart)

Screenshot references:
- [flutter-login.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-login.png)
- [flutter-signup.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-signup.png)
- [flutter-org-onboarding-step1.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step1.png)
- [flutter-org-onboarding-step2.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step2.png)
- [flutter-org-onboarding-step3.png](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/screenshots/flutter-org-onboarding-step3.png)

## 1. Core visual identity

The Flutter frontend reads like an internal operations console rather than a marketing product. The design language is:
- light-mode only
- cool and clinical
- rectangular before rounded
- dense before spacious
- labeled before decorative
- operational before expressive

The app is not minimal in the consumer-product sense. It is minimal in the enterprise-tool sense:
- low ornament
- small labels
- restrained shadows
- direct iconography
- uppercase system language

## 2. Design token DNA

Base token source:
- [AppStyle.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/core/styles/AppStyle.dart)

Color system:
- foundation: `#F8FAFC`
- surface: `#FFFFFF`
- border: `#E2E8F0`
- primary text: `#0F172A`
- secondary text: `#64748B`
- accent blue: `#3B82F6`
- success green: `#10B981`
- warning pink-red: `#F43F5E`

Typography:
- app-wide text theme uses Inter via Google Fonts in [main.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/main.dart)
- labels are compact, often uppercase, medium-weight to bold, with positive letter spacing
- metrics are larger but still restrained, not oversized or expressive
- titles are functional, not brand-heavy

Radius system:
- core cards: `8px`
- active nav rows and field frames: `4px` to `6px`
- admin modal shell: `12px`
- logo tile: `4px`
- mobile nav: `32px`

Shadow system:
- extremely restrained
- `surfaceCard` uses a soft blur of `10` with low-opacity shadow
- the visual weight comes from borders and spacing, not deep shadows

## 3. Overall shell architecture

Shell source:
- [PagesLayout.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart)

The app shell is split into:
- left navigation rail on desktop
- main content column
- mobile bottom nav on smaller screens
- optional overlay for settings

The shell uses white and near-white planes rather than tinted panels. It does not try to feel immersive or atmospheric. It feels like a clean lab workstation.

### Desktop shell

Desktop layout is a horizontal split:
- fixed or hover-expanding sidebar on the left
- full-height content region on the right
- top header bar inside the content region

The outer scaffold background is foundation gray. The sidebar and content region feel like flat white work surfaces laid on top of it.

### Mobile shell

Mobile keeps the content full-screen and floats a rounded bottom nav over the lower edge. This is one of the only deliberately soft shapes in the app.

## 4. Sidebar pane

Sidebar source:
- [Sidebar.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/Sidebar.dart)

The sidebar is a narrow white column with a right border. It is not a card and not a dark panel.

Visual anatomy:
- white background
- single vertical border on the right
- 64px collapsed width
- expands on hover to the configured width
- logo block at top
- nav items stacked down the column
- settings and sign out pinned near the bottom

### Logo block

The logo is a tiny lab-mark:
- dark navy square
- `4px` corner radius
- white bolt icon
- optional `LAB v3.0` wordmark when expanded

This sets the tone for the entire interface:
- compact
- technical
- sharp
- more utility-console than brand-platform

### Nav row styling

Each nav item is a 48px row with:
- tiny outer margin
- subtle selected background using foundation color
- `6px` radius
- icon-first layout
- text only when expanded

Selected state is expressed through:
- blue icon accent
- darker text
- lightly filled row

There is no dramatic glow, no large hover pill, and no oversized icon treatment.

## 5. Header pane

Header source:
- [PagesLayout.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/layout/PagesLayout.dart)

The desktop header is only 64px tall and visually quiet.

Structure:
- left: page title
- right: user name and small circular avatar

Visual behavior:
- transparent or near-transparent container
- no heavy card framing
- title uses medium-weight label styling, not a giant hero heading
- user identity is treated as metadata, not profile branding

This is an important DNA point: the shell does not glorify the page title. It treats it as navigation context.

## 6. Settings overlay window

Overlay source:
- [OverlayBlurWindow.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/core/ui_kit/OverlayBlurWindow.dart)
- [SettingsMenu.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/settings/SettingsMenu.dart)

The settings experience is not inline. It is overlay-based.

### Backdrop layer

The overlay backdrop applies:
- a `16px` blur
- transparent veil
- a soft top white gradient
- a secondary faint horizontal glow band

This is the only place where the app briefly becomes atmospheric. Even here, the atmosphere is restrained and clinical rather than glossy.

### Settings content pane

The settings menu itself is a stacked configuration column, not a decorative preferences center.

Sections:
- session/configuration title
- employee simulation card
- org admin access card
- provision new organization action
- dismiss button

#### Employee simulation card

Shape and behavior:
- filled foundation panel
- `6px` radius
- border line
- label and tiny explanatory text on the left
- switch on the right

This pane reads like a hardware toggle block.

#### Org admin access card

This card is status-aware:
- default state uses foundation background and border
- verified state shifts to green-tinted background/border
- content remains compact
- verify action is a tiny elevated button, not a broad CTA

The card feels like a security checkpoint rather than a feature module.

#### Provision new organization action

This is styled as a text button, not as a loud primary action. That makes it feel secondary and infrastructural.

## 7. Auth window

Auth source:
- [AccessScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AccessScreens.dart)

The auth experience is a centered single-card terminal-style access panel.

### Card frame

The auth card uses:
- max width `380px`
- inner padding `40px`
- `surfaceCard` treatment
- centered layout inside a large padded viewport

There is no left-right marketing split, no illustration panel, and no atmospheric aside. Everything is concentrated into one compact work card.

### Top block

Top block anatomy:
- square bolt tile
- `Sign In` or `Register` headline
- muted subtitle: `Access the VBP Lab Environment`

The headline is straightforward. The subtitle implies a controlled environment, not a consumer login.

### Tenant pane

Before credentials, the screen asks for organization context.

Unselected state:
- text field labeled `SELECT ORGANIZATION (TENANT)`
- search icon suffix
- narrow result list beneath with small rows

Selected state:
- inline tenant chip/panel
- pale blue-tinted background
- `4px` radius
- thin accent border
- business icon on the left
- close icon on the right

This pane is one of the clearest visual markers of the app’s multi-tenant DNA.

### Field system

All auth fields use the same lab-field pattern:
- tiny uppercase label
- `6px` gap
- filled field on foundation background
- dense vertical padding
- `4px` corners
- understated border

This field language repeats throughout the app.

### Action row

The primary auth button is full-width, 48px tall, and rectangular with softened corners. It feels like a serious system action, not a “friendly” button.

Secondary actions are text-driven:
- register new organization
- create new account
- back to sign in

This keeps the card’s hierarchy strongly operational.

## 8. Signup window

Signup is not a wholly different page. It is a mode switch inside the auth card.

Additional panes:
- full name field
- account type dropdown

The visual effect is:
- same card
- same skeleton
- slightly taller vertical stack
- same compact logic

This reuse is part of the app’s DNA. New states are usually added by stacking more controls into existing shells, not by creating brand-new visual systems.

## 9. Organization onboarding window

Source:
- [OrganizationOnboardingScreen.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationOnboardingScreen.dart)

This is a wizard-style full-page workflow with four steps.

### Overall frame

Layout:
- transparent app bar with back arrow
- centered container, max width `500px`
- top progress bar
- large gap before content
- single active step visible at a time

This is the app’s most “process-driven” screen. It feels like provisioning hardware or setting up lab infrastructure.

### Step 1 pane: Manager validation

Content:
- title
- explanatory sentence
- manager email field
- personal password field
- bottom-anchored continue button

Tone:
- authorization and trust
- understated but strict

### Step 2 pane: Organization details

Content:
- org name
- org admin password

The form language is corporate and security-oriented, not customer onboarding-oriented.

### Step 3 pane: Access control list

Content:
- email add field
- add-circle icon button
- whitelist list
- provision button

This pane feels like infrastructure configuration rather than account setup.

### Step 4 pane: Identity sync

Content:
- success icon
- TOTP seed container
- warning/help text
- complete setup button

The TOTP seed block is one of the few places where the UI foregrounds raw machine-readable data. That is core to the product DNA.

## 10. Dashboard pane family

Sources:
- [DashboardHome.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/DashboardHome.dart)
- [DashboardMetrics.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/DashboardMetrics.dart)
- [MetricCard.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/MetricCard.dart)
- [MachineStopCard.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/dashboard/widgets/MachineStopCard.dart)

Dashboard layout is a long vertical operational feed:
- section header
- metrics row
- section header
- machine cards

There is very little decorative separation. The screen relies on spacing and repeated card forms.

### Section headers

Headers use:
- uppercase primary title
- small subdued subtitle
- left alignment

They read like console section markers.

### Metrics pane row

The metrics row uses small standalone cards in a wrap layout.

Each metric card has:
- `180px` width
- `20px` padding
- small icon plus uppercase label row
- one large metric number

The card never tries to become a dramatic dashboard hero. It stays compact and legible.

### Machine stop cards

These cards are the most characteristic dashboard pane.

Frame:
- `surfaceCard`
- slight vertical margin
- expandable/collapsible behavior

Collapsed state:
- small circular status dot
- uppercase machine name
- machine subtitle containing unit id and payload count

Expanded state:
- inventory rows
- plus/minus quantity controls
- compact SKU metadata

The overall effect is:
- device-centric
- inventory-aware
- direct manipulation without ornament

#### Quantity control row

The plus/minus controls are tiny square-ish tap targets with `4px` radius. This is a recurring DNA trait: controls are almost toolhead-like.

## 11. Routes pane

Sources:
- [MapInterface.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/routes/MapInterface.dart)
- [RoutePlanner.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/routes/RoutePlanner.dart)

This pane is map-first.

### Main map window

Base layer:
- `flutter_map`
- light Carto basemap
- markers rendered as small circular beacons
- route polylines layered over the map

Marker styling:
- white fill
- blue border
- soft accent shadow
- sensor icon

This is one of the few places where the interface allows a little visual glow, but it is still functional and restrained.

### Manager filter chip pane

Managers see a floating top-left control bar:
- card-like container
- compact dropdown
- optional loading spinner
- auto-generate icon button

This bar is not a top app bar. It is a local map tool pod.

### Assignment bottom sheet

When a manager taps a machine marker, the app opens an assignment sheet.

Structure:
- bottom sheet
- padded content
- section title and subtitle
- employee list rows

Employee rows:
- foundation-colored rectangles
- `6px` radius
- bordered
- chevron on the right

The assignment sheet feels like dispatch tooling, not a pretty modal.

## 12. Warehouse pane

Sources:
- [StockScreens.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/warehouse/StockScreens.dart)
- [ScanScreen.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/warehouse/ScanScreen.dart)

Warehouse is a stacked operational screen with three window families:
- inventory list
- scan/add-stock dialog
- shipment bottom sheet and shipment dialog

### Inventory list window

The inventory pane is a scrolling list of stock cards.

Each inventory row uses:
- `surfaceCard`
- compact padding
- list-oriented information hierarchy

The screen is less about dramatic data visualization and more about actionable stock records.

### Scan/add-stock dialog

This dialog is used after a barcode scan or manual stock action.

Frame:
- white alert dialog
- `8px` radius
- compact action row

Content:
- barcode label
- either item identification or new SKU naming
- quantity field
- cancel and commit actions

The dialog reads like a transaction terminal.

### Shipment bottom sheet

This is a logistics window rather than a generic modal.

Structure:
- draggable bottom sheet
- large padded header row
- add icon button
- shipment list cards

Shipment card styling:
- `surfaceCard`
- transport icon in circular badge
- description/date on left
- quantity stack on right

The arrangement resembles a dispatch manifest.

### Add shipment dialog

The nested shipment dialog is very compact:
- description field
- unit count field
- cancel and schedule actions

This is another example of the app preferring small task windows over large scene changes.

### Scan screen

The scan screen itself is a simple full-screen camera surface:
- basic app bar
- full-body scanner view

It is utilitarian and intentionally plain, reinforcing that scanning is treated as a device function, not a designed showcase.

## 13. Admin modal window

Source:
- [OrganizationAdminModal.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/OrganizationAdminModal.dart)

This is a central part of the product’s operational identity.

### Modal shell

Frame:
- dialog
- foundation background
- `12px` radius
- max width `500px`
- max height `600px`

Header:
- title on left
- close icon on right

Tabbed body:
- `MACHINES`
- `WHITELIST`

This is not a generic settings modal. It is an organization control console.

### Machines tab pane

Content:
- machine registration title
- helper text
- machine name field
- VIN field
- latitude and longitude fields
- demo hub coordinates shortcut
- register button

This pane feels like network hardware registration.

### Whitelist tab pane

Content:
- explanatory heading
- email add row with plus icon
- bordered whitelist list container
- save whitelist button

This is a compact access-control pane. It feels administrative and procedural, not collaborative.

## 14. Admin verification dialog

Source:
- [AdminVerificationDialog.dart](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Frontend/lib/modules/auth/AdminVerificationDialog.dart)

This is the security checkpoint window.

Frame:
- dialog
- foundation background
- `8px` radius
- max width `400px`

Content:
- `DUAL-KEY CHALLENGE` title in accent blue
- short secondary description
- admin password field
- TOTP field
- optional uppercase error
- cancel and verify buttons

This window is pure product DNA:
- infrastructure-first language
- secondary credentials
- short labels
- no softness or reassurance language

## 15. Pane taxonomy

The app relies on a consistent set of pane types:

### Work surfaces
- sidebar
- page body
- map area
- inventory list

### Control pods
- metric cards
- filter bar
- tenant chip
- status cards in settings

### Task windows
- onboarding steps
- admin modal
- verification dialog
- stock mutation dialog
- shipment dialog
- assignment bottom sheet

### Data capsules
- machine stop cards
- shipment rows
- whitelist rows
- employee list rows

This taxonomy is important because the app feels coherent by reusing pane behaviors more than by reusing flashy decoration.

## 16. Motion and interaction character

Motion is present but secondary:
- sidebar expands on hover
- onboarding pages slide via page controller
- overlays blur the background
- bottom sheets rise from below
- expansion tiles reveal data vertically

The motion is utilitarian. It explains state changes. It does not dramatize them.

## 17. Emotional tone

The frontend projects:
- precision
- accountability
- infrastructure ownership
- machine oversight
- operator discipline

It does not project:
- consumer friendliness
- editorial storytelling
- brand theater
- premium lifestyle UI

This distinction matters for parity work. The app’s identity lives in:
- compact control density
- small radii
- blue-accent lab palette
- uppercase labels
- white surfaces
- card and dialog discipline

## 18. What must be preserved in any parity port

If another frontend is meant to match this Flutter app, it must preserve:
- the cool operational color system
- Inter-like compact sans typography
- the `4px` to `8px` radius baseline
- the centered single-card auth model
- the white sidebar with hover-expand behavior
- the quiet header bar
- overlay settings behavior
- the modal/tabbed admin console
- the map tool-pod pattern
- the logistics bottom-sheet pattern
- the machine-card and metric-card grammar

## 19. Limitations of live capture

Live Playwright capture covered:
- login
- signup
- org onboarding step 1
- org onboarding step 2
- org onboarding step 3

Authenticated legacy routes were source-reviewed rather than fully screenshot-captured because the current visible login flow rejects valid seeded credentials. That limitation is documented separately in:
- [login UI defect](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/2026-03-18-login-ui-rejects-seeded-creds.md)
- [org onboarding submit defect](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/mar-audit/2026-03-18-org-onboarding-provision-401.md)

## 20. Final DNA summary

The Flutter frontend is a clean lab console:
- pale foundation
- white instruments
- tight corners
- blue accents
- compact labels
- hardware and route language
- modals and sheets for focused tasks
- low visual ego

Its beauty comes from operational clarity, not stylistic flourish.
