# Next: Frontend RBAC parity with v1 (auto-detected role + in-memory view toggle)

Goal: Make the **Frontend** app behave like **v1** for Manager vs Employee access:

- Employee: **Routes** (default) + **Warehouse**. **No Dashboard tab**.
- Manager: **Dashboard** (default) + Routes + Warehouse.
- Manager-only: a **Settings toggle** to switch into **Employee View** and back.
- The view override **resets on relaunch** (in-memory only; no persistence).

This plan is intentionally minimal and follows the existing pattern already used in both apps:
> state → build a list of visible pages → index into that list

---

## Phase 0 — Lock in current contract (no UX change)

**Why:** Avoid “architecture breakage” by agreeing on the source-of-truth.

- Source of truth for role: backend `/token` response (`user.role`) parsed into `User.role`.
  - File: `Frontend/lib/core/models/User.dart`
- Ensure role values are consistent: expected strings are `"manager"` and `"employee"`.

Acceptance:
- Logging in sets `SessionManager.currentUser.role` to the backend role.

---

## Phase 1 — Add “effective role” (in-memory view override)

**Why:** Lets managers temporarily see employee UI without changing auth or backend.

Edit: `Frontend/lib/modules/auth/SessionManager.dart`

Add:
- `String? _roleOverride;` // `null` (no override) OR `"employee"`
- `String get actualRole => _currentUser?.role ?? 'employee';`
- `String get effectiveRole => (actualRole == 'manager' && _roleOverride == 'employee') ? 'employee' : actualRole;`
- `bool get isManager => actualRole == 'manager';`
- `bool get isInEmployeeView => effectiveRole != 'manager';`

Add methods:
- `void setEmployeeView(bool enabled)`
  - If `!isManager`: no-op (or force disabled)
  - If `enabled`: set `_roleOverride = 'employee'`
  - If `!enabled`: set `_roleOverride = null`
  - `notifyListeners()`

Update logout:
- Clear `_roleOverride` on `logout()`.

Acceptance:
- Manager can toggle into employee view during a session.
- After app restart (relaunch), override is gone (because it’s not persisted).

---

## Phase 2 — Role-based tabs using the existing state-driven pattern

**Why:** Prevent index crashes and keep tabs/pages consistent.

Edit: `Frontend/lib/modules/dashboard/OverviewScreens.dart`

Refactor to:
- Build a single `tabs` list based on `SessionManager.effectiveRole`.
  - If `effectiveRole == 'manager'`: include Dashboard, Routes, Warehouse.
  - Else: include Routes, Warehouse.
- Derive BOTH:
  - the `_pages` list (widgets)
  - and `BottomNavigationBar.items`
  from the same `tabs` list.

Safety:
- Ensure `_selectedIndex` is always valid:
  - If the visible tab set changes and `_selectedIndex >= tabs.length`, reset to `0`.

Defaults:
- Employee: first tab must be **Routes**.
- Manager: first tab must be **Dashboard**.

Acceptance:
- Employee never sees the Dashboard tab.
- App never throws `RangeError` from `_pages[_selectedIndex]`.

---

## Phase 3 — Add a minimal Settings menu + manager-only toggle

**Why:** There is no Settings UI in Frontend today; add the smallest possible one.

Edits:
1) `Frontend/lib/modules/dashboard/OverviewScreens.dart`
   - Add a Settings icon (e.g., `Icons.settings`) in `AppBar.actions`.
   - Open a lightweight “settings menu” UI (recommended: `showModalBottomSheet` or `showDialog`).

2) New file: `Frontend/lib/modules/settings/SettingsMenu.dart`
   - Contains a single manager-only switch:
     - Label: “Employee View”
     - Visible only when `session.isManager == true`
     - Bound to `session.setEmployeeView(...)`

Behavior:
- When a manager flips “Employee View” ON:
  - `effectiveRole` becomes employee
  - Dashboard tab disappears
  - the app resets to the first available tab (Routes)

Acceptance:
- Managers can toggle Employee View on/off.
- Employees do not see the toggle.

---

## Phase 4 — Manual verification checklist

Manager login:
- `Simon.swartout@gmail.com / test123`
- Sees Dashboard/Routes/Warehouse.
- Settings → can enable Employee View.
- Enabling Employee View hides Dashboard and defaults to Routes.

Employee login:
- `amanda.jones@example.com / employee123`
- Sees Routes/Warehouse only.
- No Dashboard tab.
- Settings does not show Employee View toggle.

Relaunch behavior:
- If manager enabled Employee View, close the app and relaunch.
- After relaunch, manager is back to normal manager view (override reset).

---

## Simulated output (what the repo will look like after these phases)

This is a **simulated** tree showing the minimal file additions/changes expected after implementing Phases 1–3.

Legend:
- `[M]` modified file
- `[A]` added file
- `[=]` unchanged (shown for context)

```
VendingBackpack/
├─ Next.md                                        [M] (this plan + notes)
└─ Frontend/
  └─ lib/
    ├─ main.dart                                 [=]
    ├─ core/
    │  └─ models/
    │     └─ User.dart                            [=]
    └─ modules/
      ├─ auth/
      │  ├─ AccessScreens.dart                   [=]
      │  └─ SessionManager.dart                  [M] (add effectiveRole + setEmployeeView)
      ├─ dashboard/
      │  └─ OverviewScreens.dart                 [M] (role-based tabs + settings entrypoint)
      └─ settings/
        └─ SettingsMenu.dart                    [A] (manager-only “Employee View” toggle)
```

Optional (only if you also apply the v1 cleanup in Phase 3/4 of the earlier discussion):

```
VendingBackpack/
└─ v1/
  └─ lib/
    └─ widgets/
      └─ auth_widget.dart                        [M] (remove role dropdown; role comes from user data)
```

    ---

    ## Parity risks (what might accidentally change vs v1) + mitigation

    These are the most common “gotchas” when making the Frontend match v1 behavior.

    ### 1) Tab indices / selected page drift
    **Risk:** When Dashboard is hidden, old `_selectedIndex` values can point past the end of the filtered pages list (crash), or land on the “wrong” page (UX mismatch).

    Mitigation:
    - Build pages + nav items from a single filtered `tabs` list.
    - Clamp/reset index when tab set changes: if `_selectedIndex >= tabs.length`, set `_selectedIndex = 0`.
    - Verify defaults: manager → Dashboard first; employee → Routes first.

    ### 2) Dashboard data fetching still happens for employees
    **Risk:** Even if you hide the Dashboard tab, you might still be constructing `BusinessMetrics()` and calling `loadData()`, which can:
    - leak timing/traffic patterns
    - waste API calls
    - cause surprising loading spinners or errors in logs

    Mitigation:
    - Only create/load `BusinessMetrics` when `effectiveRole == 'manager'`.
    - Keep the provider scoped to the Dashboard tab (or lazily initialize it).

    ### 3) Role string mismatch / casing issues
    **Risk:** If backend returns `"Manager"`, `"MANAGER"`, or different role names, Frontend gating won’t match v1 expectations.

    Mitigation:
    - Normalize once in session: `actualRole = (currentUser?.role ?? 'employee').toLowerCase().trim()`.
    - Treat any non-`'manager'` as employee for safety.

    ### 4) “Employee view” toggle affects more than just tabs
    **Risk:** v1 changes behavior inside pages via capability flags (e.g., Routes auto-route). If Frontend only hides the Dashboard tab, managers in Employee View might still see manager-only behaviors inside Routes/Warehouse.

    Mitigation:
    - Define a single capability source: use `effectiveRole` (not `actualRole`) everywhere you branch UI.
    - Thread `effectiveRole` into Routes/Warehouse modules the same way v1 does (`allowAutoRoute`, manager/employee constructors).

    ### 5) Settings UX difference from v1
    **Risk:** v1 has a menu/settings overlay pattern; Frontend currently doesn’t. Adding a full Settings screen can accidentally introduce new navigation complexity.

    Mitigation:
    - Keep it minimal: a single bottom sheet/dialog with one switch.
    - Only show the Settings entrypoint to managers (optional) to avoid adding UI for employees.

    ### 6) Rebuilds that reset state
    **Risk:** If changing role/view mode rebuilds `OverviewScreens` aggressively, you can accidentally reset scroll positions, map state, or trigger repeated loads.

    Mitigation:
    - Keep tab widgets stable (use `const` where possible).
    - If any tab has expensive state (map), consider using `IndexedStack` for body rendering so switching tabs doesn’t dispose/recreate them.

    ### Mitigation strategy (practical)
    - Implement gating first (Phase 2), then add the toggle (Phase 3), then expand capability branching in Routes/Warehouse.
    - Add a quick manual parity checklist (Phase 4) and run it after each phase.
    - Treat “employee is safest default”: when in doubt, hide Dashboard and disable manager-only actions.
