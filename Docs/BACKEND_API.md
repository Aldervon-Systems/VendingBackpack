# Backend API Documentation

This document describes the current operational Rails API contract for VendingBackpack. The API is scoped under `/api` and the production operational client is `Frontend-Next`.

## Base URL
The API is scoped under `/api`.

## Current Operational Shape
- Runtime authority: Rails + SQL-backed ActiveRecord models
- Primary operational client: `Frontend-Next`
- External contract naming: `camelCase`
- Standard error envelope: `{ "detail": "..." }`
- Local seeded preview auth: standard SQL-backed users created by `db:seed`

## Local Seeded Stack

```bash
SEED_DEMO_DATA=true docker compose up -d --build backend frontend
```

Seeded preview accounts:
- Manager: `renee@aldervon.com`
- Employee: `amanda.jones@example.com`
- Organization search: `Aldervon Systems`
- Password: `password123`

## Authentication

### Generate Token
`POST /api/token`

Request body:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "organization_id": "org_aldervon"
}
```

### Signup
`POST /api/signup`

### Session Identity
`GET /api/me`

## Contract Rules
- Use `quantity`, never `qty`
- Use `machineId`, never `machine_id`
- Use `employeeId`, never `employee_id`
- Use `slotNumber`, never `slot_number`
- Manager and employee route payloads share the same base route DTO

## Warehouse And Inventory

### Warehouse Inventory
`GET /api/warehouse`

Response shape:
```json
[
  {
    "itemId": 1,
    "sku": "cold_brew",
    "name": "Cold Brew",
    "quantity": 18,
    "barcode": "111"
  }
]
```

### Machine Inventory
`GET /api/inventory`

Response shape:
```json
[
  {
    "machineId": "M-101",
    "machineName": "Union Station",
    "status": "online",
    "location": "Downtown Loop",
    "items": [
      {
        "itemId": 1,
        "quantity": 4,
        "slotNumber": "A1"
      }
    ]
  }
]
```

### Barcode Lookup
`GET /api/items/barcode/:barcode`

Response shape:
```json
{
  "id": 1,
  "sku": "cold_brew",
  "name": "Cold Brew",
  "description": "Chilled coffee can",
  "price": 4.25,
  "quantity": 18,
  "slotNumber": "A1",
  "isAvailable": true,
  "imageUrl": null,
  "barcode": "111",
  "createdAt": "2026-03-29T17:21:56Z",
  "updatedAt": "2026-03-29T17:21:56Z"
}
```

### Daily Stats
`GET /api/daily_stats`

Response shape:
```json
[
  {
    "date": "2026-03-29",
    "amount": 10.95,
    "transactionCount": 3
  }
]
```

### Machine Fill / Return
`POST /api/warehouse/update`

Request params:
```json
{
  "machineId": "M-101",
  "sku": "cold_brew",
  "quantity": 4
}
```

### Warehouse Add Stock
`POST /api/warehouse/add_stock`

Request params:
```json
{
  "barcode": "111",
  "name": "Cold Brew",
  "quantity": 6
}
```

### Shipments
`GET /api/warehouse/shipments`
`POST /api/warehouse/shipments`

Shipment response shape:
```json
{
  "id": 1,
  "description": "Cold brew resupply",
  "amount": 42.5,
  "scheduledFor": "2026-03-29T18:00:00Z",
  "status": "scheduled",
  "createdAt": "2026-03-29T17:21:56Z",
  "updatedAt": "2026-03-29T17:21:56Z"
}
```

## Items Management

### List All Items
`GET /api/items`

### Get Item by ID
`GET /api/items/:id`

### Get Item by Slot
`GET /api/items/slot/:slot_number`

### Create Item
`POST /api/items`

Request body:
```json
{
  "name": "Soda",
  "description": "Refreshing drink",
  "price": 1.5,
  "slotNumber": "A1",
  "quantity": 10,
  "isAvailable": true,
  "imageUrl": "http://example.com/image.png"
}
```

### Update Item
`PUT /api/items/:id`

### Delete Item
`DELETE /api/items/:id`

## Transactions

### List Transactions
`GET /api/transactions`

### Get Transaction Details
`GET /api/transactions/:id`

### Create Transaction
`POST /api/transactions`

Request body:
```json
{
  "itemId": 1,
  "machineId": "M-101",
  "slotNumber": "A1",
  "amount": 1.5,
  "paymentMethod": "card",
  "userId": "emp-07"
}
```

Response shape:
```json
{
  "id": 1,
  "itemId": 1,
  "itemName": "Cold Brew",
  "machineId": "M-101",
  "slotNumber": "A1",
  "amount": 4.25,
  "status": "completed",
  "paymentMethod": "card",
  "userId": "emp-07",
  "completedAt": "2026-03-29T17:30:00Z",
  "refundedAt": null,
  "createdAt": "2026-03-29T17:30:00Z",
  "updatedAt": "2026-03-29T17:30:00Z"
}
```

### Refund Transaction
`POST /api/transactions/:id/refund`

## Machines

### List Machines
`GET /api/machines`

Response shape:
```json
{
  "id": "M-101",
  "name": "Union Station",
  "vin": "VIN-101",
  "organizationId": "org_aldervon",
  "status": "online",
  "battery": 93,
  "lat": 42.3524,
  "lng": -71.0552,
  "location": "Downtown Loop",
  "createdAt": "2026-03-29T17:21:56Z",
  "updatedAt": "2026-03-29T17:21:56Z"
}
```

## Employees And Routes

### List Employees
`GET /api/employees`

### List All Employee Routes
`GET /api/employees/routes`

### Get Routes For Employee
`GET /api/employees/:id/routes`

Canonical route shape:
```json
{
  "id": 1,
  "employeeId": "emp-07",
  "employeeName": "Amanda Jones",
  "distanceMeters": 1234.56,
  "durationSeconds": 0,
  "stops": [
    {
      "machineId": "M-130",
      "name": "Harbor Point",
      "lat": 42.3473,
      "lng": -71.0386,
      "location": "Harbor District",
      "position": 0
    }
  ],
  "createdAt": "2026-03-29T17:21:56Z",
  "updatedAt": "2026-03-29T17:21:56Z"
}
```

### Assign Machine To Route
`POST /api/employees/:id/routes/assign`

Request params:
```json
{
  "machineId": "M-101"
}
```

### Update Route Stops
`PUT /api/employees/:id/routes/stops`

Request body:
```json
{
  "stopIds": ["M-130", "M-101"]
}
```

## Current Data Authority
- Operational inventory, routes, shipments, and transactions use SQL-backed models.
- Fixture helpers remain for seed and compatibility support, but they are no longer the live authority for the operational flows documented here.
