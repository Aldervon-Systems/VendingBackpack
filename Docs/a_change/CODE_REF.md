# CODE_REF: Barcode Integration

## Backend
- `Backend/app/services/fixtures/mock_api.rb`: `find_item_by_barcode` needs to search `central_stock`.
- `Backend/app/services/fixtures/mutable_store.rb`: Add `add_to_central_stock(barcode, name, qty)`.
- `Backend/app/controllers/api/warehouse_controller.rb`: Add `add_stock` action.

## Frontend
- `Frontend/lib/modules/warehouse/InventoryController.dart`: Add `lookupBarcode(barcode)` and `addStock(barcode, name, qty)`.
- `Frontend/lib/modules/warehouse/StockScreens.dart`: Implement flow in `FloatingActionButton.onPressed`.
- `Frontend/lib/modules/warehouse/ScanScreen.dart`: Returns barcode string.
