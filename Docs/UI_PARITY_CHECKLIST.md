# UI Parity Checklist (Deprecated vs New Frontend)

This checklist tracks visible UI parity between `Frontend_Deprecated` and `Frontend`.

Legend: [=] parity, [~] partial, [ ] missing

## Global
- [~] Theme colors match deprecated black/white palette
- [~] Typography uses serif headers/body like deprecated
- [ ] Card/list styling matches deprecated spacing and borders
- [ ] Iconography and emphasis colors (green/blue) match

## Navigation & Layout
- [~] Desktop layout uses left sidebar + top banner
- [~] Mobile layout uses bottom bar with selected highlight
- [~] Tab selection styling matches deprecated (background + text)
- [~] Page title banner with adjustable height
- [ ] Manager vs Employee navigation flow parity

## Auth Experience
- [ ] Sign-in overlay (blurred background)
- [ ] Sign-up overlay
- [ ] Role selector (manager/employee)
- [ ] Match deprecated entry flow and styling

## Dashboard
- [ ] Metrics layout (cards + weekly chart)
- [ ] Machine status list with expandable inventory
- [ ] Manager vs employee dashboard split
- [ ] Refresh affordance (top-right in banner)

## Routes
- [ ] Interactive map with clusters and selection
- [ ] Manual route selection + road snapping
- [ ] Auto-routing for managers
- [ ] Employee route view parity

## Warehouse
- [ ] Manager inventory list with search
- [ ] Barcode scan flow + add item flow
- [ ] Employee scan/check-in/check-out parity

## Settings
- [ ] Settings overlay parity (modal styling)
- [ ] Employee view toggle for managers
