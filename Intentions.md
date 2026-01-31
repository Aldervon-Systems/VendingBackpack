# INTENTIONS

Purpose: Keep a short, always-updated record of (1) what we will do next and (2) what we changed recently.

## Personality & Skills (top)

- Tone: concise, practical, experienced.
- Skills: C#/.NET, Rust, Android, Audio DSP, Spatialization, XR, build & CI, testing.
- References: `README.md`, `docs/`.

## Rules (do not break)

- Always keep these sections: **Purpose**, **Current Intentions**, **Decisions & Out-of-Scope**, **Check-in Process**, **Journal**.
- Use short headings and one-line bullets only.
- Every bullet includes **Owner** and **Date**.

## Current Intentions (what to do next)

- [Antigravity] [2026-01-27] Apply "Clean Lab" visual overhaul to the entire application (DONE)
- [Antigravity] [2026-01-27] Implement Shipment Management menu and timeline in Warehouse (DONE)
- [Antigravity] [2026-01-27] Integrate barcode scanning for warehouse stock management (DONE)
- [Antigravity] [2026-01-27] Preseed machines and inventory data (DONE)
- [Antigravity] [2026-01-27] Refactor Warehouse view to show consolidated SKUs/quantities (DONE)
- [Antigravity] [2026-01-27] Allow users to register as a "manager" role (DONE)
- One line per item, highest priority first.
- Format: `- [Owner] [YYYY-MM-DD] Do X`

## Decisions & Out-of-Scope (record + who decided)

- Record decisions outside this doc’s scope.
- One line per decision: owner + date + rationale.
- Format: `- [Owner] [YYYY-MM-DD] Decision: X (Why: Y)`

## Check-in Process (before any change)

1. Confirm the change matches **Current Intentions**.
2. Make the change.
3. Add a one-line entry to **Journal**.

## Workflow (multi-step) 🔧

1. **Read:** Read `INTENTIONS.md` (confirm owner/date).
2. **Infer:** Add one line: **Inferred Goal** from the user prompt (owner/date).
3. **Prepare:** Create `docs/a_change/` with:
   - `CHANGE.md`
   - `CODE_REF.md`
   - `PLAN.md`
   - `ATOMIC_PLAN.md`
4. **Iterate:** Update those docs with the developer; log each update in **Journal** (owner/date).
5. **Execute:** Follow `ATOMIC_PLAN.md` (small testable steps) + `PLAN.md` (milestones). Use `CODE_REF.md`. Log progress in `CHANGE.md`.
6. **Close:** Add a final **Journal** entry summarizing the finished change + link to `CHANGE.md`.

## Journal (append-only)

- [Antigravity] [2026-01-27] Resolved web compilation errors by removing `dart:ui` FontFeatures and relaxing SDK constraints. "Clean Lab" theme active.
- [Antigravity] [2026-01-27] Completed "Clean Lab" visual overhaul: custom fonts, palette, and navigation (ref: AppStyle.dart)
- [Antigravity] [2026-01-27] Starting "Clean Lab" Visual Overhaul
- [Antigravity] [2026-01-27] Fixed build error in StockScreens.dart and finalized layout
- [Antigravity] [2026-01-27] Implemented Shipment Management & Timeline for Managers (ref: StockScreens.dart)
- [Antigravity] [2026-01-27] Starting Shipment Management Integration
- [Antigravity] [2026-01-27] Integrated Barcode Scanning with dynamic name/qty entry (ref: StockScreens.dart)
- [Antigravity] [2026-01-27] Starting Barcode Scanning Integration
- [Antigravity] [2026-01-27] Preseed machines and inventory data
- [Antigravity] [2026-01-27] Refactored Warehouse view to show consolidated central stock (ref: StockScreens.dart)
- [Antigravity] [2026-01-27] Started Warehouse Inventory Refactor
- [Antigravity] [2026-01-27] Implemented Manager registration in Frontend (AccessScreens and SessionManager)
- [Antigravity] [2026-01-27] Prepared Docs/a_change/ for Manager Registration
- [Owner] [YYYY-MM-DD] Did X (ref: path or PR)