# Change breakdown (RBAC + employee view toggle + run fixes)

This document summarizes the changes made in this session, what the code looked like before (at a behavior/API level), why each change was made, and what the change does.

## High-level outcome

- **Employees** (non-`manager` role) no longer have access to the **Dashboard** tab in the Frontend shell.
- **Managers** still see **Dashboard** by default, and get a **Settings** toggle to switch into **Employee View** for the current session.
- The **Employee View override is in-memory only**, so it **resets on relaunch**.

No backend/API shape changes were required for RBAC; the Frontend uses the existing `user.role` from `/token`.

---

## Files added

- `Next.md`
  - A phase-based implementation plan + simulated output tree + parity risks.
- `ChangeBreakdown.md` (this file)
- `Frontend/lib/modules/settings/SettingsMenu.dart`
  - Minimal Settings bottom sheet UI with the manager-only “Employee View” toggle.

---

## Files modified (what changed vs before)

### 1) `Frontend/lib/modules/auth/SessionManager.dart`

**Before**
- Stored `_currentUser` and `_isAuthenticated`.
- `login()` set `_currentUser` from `/token` response and marked authenticated.
- `logout()` cleared user/auth.
- Role existed on the `User` object, but the session did not expose any role helpers and the UI didn’t act on role.

**After**
- Added an in-memory override: `String? _roleOverride`.
- Added role helpers:
  - `actualRole`: normalized role from `currentUser.role` (lowercased/trimmed) with safe default `employee`.
  - `effectiveRole`: becomes `employee` when the user is actually a manager and the override is enabled.
  - `isManager` and `isInEmployeeView` convenience getters.
- Added `setEmployeeView(bool enabled)`:
  - Only works for actual managers.
  - When enabled, sets override so `effectiveRole` becomes `employee`.
  - Not persisted anywhere → resets on relaunch.
- Clears override on `login()` and `logout()`.

**Why**
- This mirrors the v1 “state-based view mode” capability, but with the role source-of-truth coming from the backend user record.

**What it does**
- Gives the UI a single stable decision point (`effectiveRole`) to control what tabs/features are visible.

---

### 2) `Frontend/lib/modules/dashboard/OverviewScreens.dart`

**Before**
- Used a fixed `_pages` list of 3 widgets: Dashboard, Routes, Warehouse.
- Used a fixed `BottomNavigationBar.items` list of 3 tabs.
- Dashboard data loader (`BusinessMetrics()..loadData()`) was created at the top-level provider regardless of role.
- Result: all authenticated users saw Dashboard.

**After**
- Replaced fixed pages/items with a **single filtered tabs list** built from session state:
  - If `session.effectiveRole == 'manager'`: tabs include Dashboard + Routes + Warehouse.
  - Else: tabs include Routes + Warehouse only.
- Derived BOTH the page widgets and the bottom nav items from that tabs list, so indices always match.
- Added index safety:
  - If the tab set changes and `_selectedIndex` is out of range, it resets to `0`.
- Moved the dashboard metrics provider so it only exists when Dashboard exists:
  - `BusinessMetrics()..loadData()` is created inside the Dashboard tab spec.
- Added a manager-only Settings icon that opens `SettingsMenu` as a bottom sheet.

**Why**
- The most common failure mode with role-based tab hiding is index mismatch (`_pages[_selectedIndex]` throwing) or incorrect default page.
- Building pages + nav items from the same state-driven list is the smallest safe pattern and matches v1’s “state → pages” approach.

**What it does**
- Employees cannot see or navigate to Dashboard via tabs.
- Employees also do not trigger dashboard metrics loads (no background loading of sensitive metrics).
- Managers can toggle Employee View and immediately see the employee tab set.

---

### 3) `Frontend/lib/modules/settings/SettingsMenu.dart`

**Before**
- No Settings UI existed in the Frontend shell.

**After**
- Added a minimal Settings bottom sheet UI:
  - Shows a single `SwitchListTile` labeled “Employee View” for managers.
  - Toggle is wired to `session.setEmployeeView(...)`.
  - Includes a Close button.

**Why**
- Provides the manager-only switch requested while keeping scope minimal (no new routes/screens).

**What it does**
- Managers can switch between manager UI and employee UI without re-authentication.

---

## “Run in Chrome” fixes (required to successfully `flutter run -d chrome`)

These are build/runtime fixes encountered while attempting to run the Frontend on web. They are not RBAC logic, but were necessary to compile.

### 4) `Frontend/pubspec.yaml`

**Before**
- Declared assets under `src/data/*.json` (e.g., `src/data/history.json`), but that folder/files did not exist.

**After**
- Updated assets to the files that actually exist in `Frontend/assets/`:
  - `assets/routes_data.json`
  - `assets/users.json`
  - `assets/vendingicon.svg`

**Why / what it does**
- Fixes `flutter pub get` / build failures caused by missing assets.

---

### 5) `Frontend/lib/modules/dashboard/BusinessMetrics.dart`

**Before**
- Referenced `_isLoading` and `_employees` but they were not declared.
- UI referenced `metrics.isLoading` but there was no getter.

**After**
- Declared `_isLoading` and `_employees` fields.
- Added `bool get isLoading`.

**Why / what it does**
- Fixes compilation errors and restores the intended loading-state behavior.

---

### 6) `Frontend/lib/modules/dashboard/widgets/MachineStopCard.dart`

**Before**
- Used `Icons.vending_machine` which is not a valid Material icon constant.

**After**
- Switched to `Icons.storefront`.

**Why / what it does**
- Fixes a compilation error so the Dashboard widget can build.

---

### 7) `Frontend/lib/modules/warehouse/StockScreens.dart`

**Before**
- Returned `ChangeNotifierProvider(...)` with a `floatingActionButton:` parameter.
- `ChangeNotifierProvider` is not a `Scaffold`, so Flutter raised: `No named parameter with the name 'floatingActionButton'.`

**After**
- Wrapped the consumer UI in a `Scaffold` inside the provider.
- Moved `floatingActionButton` to that `Scaffold`.

**Why / what it does**
- Fixes compilation and preserves the intended FAB behavior for scanning.

---

## Documentation-only updates

### 8) `Frontend/README.md`

**Before**
- Empty.

**After**
- Added demo account credentials (manager + employee).

### 9) `Next.md`

**Before**
- Did not exist.

**After**
- Added implementation plan, simulated output tree, and parity risks/mitigation section.

---

## What did *not* change

- No new backend endpoints were added for RBAC.
- No `/token` response shape changes were required.
- No persistence for view mode: the manager override resets on app relaunch by design.
