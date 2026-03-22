.
|-- Frontend
|   |-- assets
|   |   |-- routes_data.json
|   |   |-- users.json
|   |   `-- vendingicon.svg
|   |-- lib
|   |   |-- core
|   |   |   |-- models
|   |   |   |   |-- Employee.dart
|   |   |   |   `-- User.dart
|   |   |   |-- services
|   |   |   |   |-- ApiClient.dart
|   |   |   |   `-- Database.dart
|   |   |   |-- styles
|   |   |   |   `-- AppStyle.dart
|   |   |   `-- ui_kit
|   |   |       |-- AppButton.dart
|   |   |       `-- OverlayBlurWindow.dart
|   |   |-- modules
|   |   |   |-- auth
|   |   |   |   |-- AccessScreens.dart
|   |   |   |   |-- AdminVerificationDialog.dart
|   |   |   |   |-- Credentials.dart
|   |   |   |   |-- OrganizationAdminModal.dart
|   |   |   |   |-- OrganizationOnboardingScreen.dart
|   |   |   |   `-- SessionManager.dart
|   |   |   |-- dashboard
|   |   |   |   |-- widgets
|   |   |   |   |   |-- DashboardMetrics.dart
|   |   |   |   |   |-- MachineStopCard.dart
|   |   |   |   |   `-- MetricCard.dart
|   |   |   |   |-- BusinessMetrics.dart
|   |   |   |   |-- DashboardHome.dart
|   |   |   |   `-- OverviewScreens.dart
|   |   |   |-- layout
|   |   |   |   |-- MainContent.dart
|   |   |   |   |-- PagesLayout.dart
|   |   |   |   `-- Sidebar.dart
|   |   |   |-- routes
|   |   |   |   |-- MapInterface.dart
|   |   |   |   |-- RoutePlanner.dart
|   |   |   |   `-- RouteSegment.dart
|   |   |   |-- settings
|   |   |   |   `-- SettingsMenu.dart
|   |   |   `-- warehouse
|   |   |       |-- InventoryController.dart
|   |   |       |-- InventoryItem.dart
|   |   |       |-- ScanScreen.dart
|   |   |       |-- Shipment.dart
|   |   |       `-- StockScreens.dart
|   |   `-- main.dart
|   |-- nginx
|   |   `-- default.conf
|   |-- scripts
|   |   `-- build_web.sh
|   |-- test
|   |   |-- modules
|   |   |   `-- dashboard
|   |   |       `-- widgets
|   |   |           `-- machine_stop_card_test.dart
|   |   `-- widget_test.dart
|   |-- web
|   |   |-- icons
|   |   |   |-- Icon-192.png
|   |   |   |-- Icon-512.png
|   |   |   |-- Icon-maskable-192.png
|   |   |   `-- Icon-maskable-512.png
|   |   |-- favicon.png
|   |   |-- index.html
|   |   `-- manifest.json
|   |-- .dockerignore
|   |-- .gitignore
|   |-- analysis_options.yaml
|   |-- DESIGN.md
|   |-- Dockerfile
|   |-- package.json
|   |-- pubspec.yaml
|   `-- README.md
|-- Frontend-Next
|   |-- app
|   |   |-- (app)
|   |   |   |-- admin
|   |   |   |   `-- page.tsx
|   |   |   |-- corporate
|   |   |   |   `-- page.tsx
|   |   |   |-- dashboard
|   |   |   |   `-- page.tsx
|   |   |   |-- routes
|   |   |   |   `-- page.tsx
|   |   |   |-- warehouse
|   |   |   |   `-- page.tsx
|   |   |   `-- layout.tsx
|   |   |-- auth
|   |   |   |-- login
|   |   |   |   `-- page.tsx
|   |   |   |-- onboarding
|   |   |   |   |-- step-1
|   |   |   |   |   `-- page.tsx
|   |   |   |   |-- step-2
|   |   |   |   |   `-- page.tsx
|   |   |   |   |-- step-3
|   |   |   |   |   `-- page.tsx
|   |   |   |   `-- step-4
|   |   |   |       `-- page.tsx
|   |   |   `-- signup
|   |   |       `-- page.tsx
|   |   |-- globals.css
|   |   |-- layout.tsx
|   |   `-- page.tsx
|   |-- nginx
|   |   `-- default.conf
|   |-- public
|   |   `-- __frontend_health
|   |-- scripts
|   |   `-- dev-with-proxy.mjs
|   |-- src
|   |   |-- components
|   |   |   |-- parity
|   |   |   |   |-- parity-button.tsx
|   |   |   |   |-- parity-card.tsx
|   |   |   |   |-- parity-field.tsx
|   |   |   |   |-- parity-modal-frame.tsx
|   |   |   |   |-- parity-overlay.tsx
|   |   |   |   `-- parity-section-header.tsx
|   |   |   |-- primitives
|   |   |   |   |-- loading-screen.tsx
|   |   |   |   `-- status-pill.tsx
|   |   |   `-- shell
|   |   |       |-- app-shell.tsx
|   |   |       `-- nav-items.tsx
|   |   |-- features
|   |   |   |-- admin
|   |   |   |   `-- components
|   |   |   |       `-- admin-modal.tsx
|   |   |   |-- auth
|   |   |   |   `-- components
|   |   |   |       |-- admin-verification-dialog.tsx
|   |   |   |       |-- auth-form.tsx
|   |   |   |       `-- onboarding-screen.tsx
|   |   |   |-- corporate
|   |   |   |   |-- components
|   |   |   |   |   `-- corporate-screen.tsx
|   |   |   |   `-- lib
|   |   |   |       `-- corporate-preferences.ts
|   |   |   |-- dashboard
|   |   |   |   `-- components
|   |   |   |       `-- dashboard-screen.tsx
|   |   |   |-- placeholders
|   |   |   |   `-- components
|   |   |   |       `-- placeholder-screen.tsx
|   |   |   |-- routes
|   |   |   |   `-- components
|   |   |   |       |-- route-map-canvas.tsx
|   |   |   |       `-- routes-screen.tsx
|   |   |   |-- settings
|   |   |   |   `-- components
|   |   |   |       `-- settings-panel.tsx
|   |   |   `-- warehouse
|   |   |       `-- components
|   |   |           `-- warehouse-screen.tsx
|   |   |-- hooks
|   |   |   |-- use-auth-guard.ts
|   |   |   `-- use-onboarding-draft.ts
|   |   |-- lib
|   |   |   |-- api
|   |   |   |   |-- interfaces
|   |   |   |   |   |-- auth-repository.ts
|   |   |   |   |   |-- corporate-repository.ts
|   |   |   |   |   `-- dashboard-repository.ts
|   |   |   |   |-- mock
|   |   |   |   |   |-- mock-auth-repository.ts
|   |   |   |   |   `-- mock-dashboard-repository.ts
|   |   |   |   |-- repositories
|   |   |   |   |   |-- api-auth-repository.ts
|   |   |   |   |   `-- api-corporate-repository.ts
|   |   |   |   `-- api-client.ts
|   |   |   |-- constants.ts
|   |   |   |-- routes.ts
|   |   |   `-- storage.ts
|   |   |-- providers
|   |   |   |-- app-provider.tsx
|   |   |   |-- auth-provider.tsx
|   |   |   `-- shell-provider.tsx
|   |   `-- types
|   |       |-- auth.ts
|   |       |-- corporate.ts
|   |       `-- dashboard.ts
|   |-- .dockerignore
|   |-- .gitignore
|   |-- Dockerfile
|   |-- next.config.ts
|   |-- package.json
|   `-- tsconfig.json
`-- Frontend-Admin-Center
    |-- app
    |   |-- globals.css
    |   |-- layout.tsx
    |   `-- page.tsx
    |-- nginx
    |   `-- default.conf
    |-- public
    |   `-- __frontend_health
    |-- .dockerignore
    |-- Dockerfile
    |-- next.config.ts
    |-- package.json
    `-- tsconfig.json
