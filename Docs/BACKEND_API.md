# Backend API Documentation

This document describes the Backend API for the Vending Backpack system. The API is built using Ruby on Rails and provides endpoints for authentication, inventory management, transactions, and employee route tracking.

## Base URL
The API is scoped under `/api`.

---

## Container Architecture

The project currently uses the following containers defined in `docker-compose.yml`:

| Service | Container Name | Description | Registry | Port Mapping |
| :--- | :--- | :--- | :--- | :--- |
| **Backend** | `vending_backend` | Ruby on Rails API. | `ghcr.io/aldervon-systems/vendingbackpack/backend` | `9090:9090` |
| **Frontend** | `vending_frontend_new` | Flutter/Dart web client. | `ghcr.io/aldervon-systems/vendingbackpack/frontend` | `8082:80` |

### Legacy Infrastructure
The project also maintains a `docker-compose-deprecated.yml` for older components:
- **vending_db**: PostgreSQL 15 database.
- **vending_backpack_deprecated**: Previous Go-based backend.
- **vending_frontend**: Previous Flutter web client.

---

## Authentication

### Generate Token
`POST /api/token`

Authenticates a user and returns an access token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "mock_token_1",
  "token_type": "bearer",
  "user": {
    "name": "John Doe",
    "email": "user@example.com",
    "role": "admin",
    "id": 1
  }
}
```

### Signup
`POST /api/signup`

Creates a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123",
  "role": "employee"
}
```

**Response (201 Created):**
```json
{
  "access_token": "mock_token_user_123",
  "token_type": "bearer",
  "user": {
    "name": "John Doe",
    "email": "user@example.com",
    "role": "employee",
    "id": "user_123"
  }
}
```

---

## Warehouse & Inventory

### Get Warehouse Inventory
`GET /api/warehouse`

Returns the current consolidated inventory for the warehouse.

### Find Item by Barcode
`GET /api/items/:barcode`

Finds a specific item using its barcode.

### Get Daily Stats
`GET /api/daily_stats`

Returns sales and inventory statistics for the current day.

### Update Inventory
`POST /api/warehouse/update`

Updates the quantity of a specific SKU for a machine.

**Query Parameters:**
- `machine_id`: The ID of the machine.
- `sku`: The SKU of the item.
- `quantity`: The new quantity.

---

## Items Management

### List All Items
`GET /api/items`

### Get Item by ID
`GET /api/items/:id`

### Get Item by Slot
`GET /api/items/slot/:slot_number`

### Create Item
`POST /api/items`

**Request Body:**
```json
{
  "name": "Soda",
  "description": "Refreshing drink",
  "price": 1.50,
  "slot_number": "A1",
  "quantity": 10,
  "is_available": true,
  "image_url": "http://..."
}
```

### Update Item
`PUT /api/items/:id`

### Delete Item
`DELETE /api/items/:id`

---

## Transactions

### List Transactions
`GET /api/transactions`

### Get Transaction Details
`GET /api/transactions/:id`

### Create Transaction
`POST /api/transactions`

**Request Body:**
```json
{
  "item_id": 1,
  "amount": 1.50,
  "payment_method": "card",
  "user_id": 1
}
```

### Refund Transaction
`POST /api/transactions/:id/refund`

---

## Machines

### List Machines
`GET /api/machines`

### Get Machine Details
`GET /api/machines/:id`

---

## Employees & Routes

### List Employees
`GET /api/employees`

### Get Employee Details
`GET /api/employees/:id`

### List All Employee Routes
`GET /api/employees/routes`

### Get Routes for Employee
`GET /api/employees/:id/routes`

### Assign Machine to Route
`POST /api/employees/:id/routes/assign`

Adds a machine to the employee's route using a nearest-neighbor heuristic.

**Query Parameters:**
- `machine_id`: The ID of the machine to assign.

### Update Route Stops
`PUT /api/employees/:id/routes/stops`

Updates the entire ordered list of stops for an employee.

**Request Body:**
```json
{
  "stop_ids": ["machine_1", "machine_2", "machine_3"]
}
```

---

## Data Source
The API currently uses mock fixtures and an in-memory `MutableStore` for data persistence during development.
