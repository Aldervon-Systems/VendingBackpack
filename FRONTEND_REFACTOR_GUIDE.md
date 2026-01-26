# VendingBackpack Frontend Refactor Guide

**Version:** 1.0  
**Last Updated:** 2026-01-22  
**Purpose:** Complete visual refactoring guide for Google AI Studio that preserves backend connections and container structure

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Constraints](#architecture-constraints)
3. [Backend API Contract](#backend-api-contract)
4. [Frontend Structure](#frontend-structure)
5. [Container & Deployment](#container--deployment)
6. [Refactoring Guidelines](#refactoring-guidelines)
7. [Testing & Validation](#testing--validation)

---

## Project Overview

### System Description
VendingBackpack is a comprehensive vending machine management system with:
- **Backend:** Ruby on Rails API (fixture-backed demo data)
- **Frontend:** Flutter web application
- **Deployment:** Docker Compose with nginx reverse proxy
- **Purpose:** Manage vending machine inventory, routes, transactions, and employee assignments

### Current Tech Stack
```yaml
Frontend:
  Framework: Flutter (Dart >= 3.8.1)
  Build Target: Web (deployed as static bundle)
  State Management: Provider pattern
  HTTP Client: dart:http
  
Backend:
  Framework: Ruby on Rails (API-only mode)
  Ruby Version: 3.3.10
  Data Source: JSON fixtures + in-memory stores
  Port: 9090

Deployment:
  Container Platform: Docker
  Reverse Proxy: nginx
  Frontend Port: 8082
  Backend Port: 9090
```

---

## Architecture Constraints

### ⚠️ CRITICAL: DO NOT MODIFY

#### 1. Backend API Endpoints
All backend routes are defined in `Backend/config/routes.rb`. **DO NOT change endpoint paths, HTTP methods, or request/response formats.**

#### 2. Container Structure
The Docker Compose setup (`docker-compose.yml`) defines:
- `backend_new` service (Rails API)
- `frontend_new` service (nginx serving Flutter web bundle)
- Port mappings and environment variables

**DO NOT modify:**
- Service names
- Port bindings
- Volume mounts
- Environment variable names
- nginx proxy configuration

#### 3. API Client Base URL Logic
The `ApiClient` class (`Frontend/lib/core/services/ApiClient.dart`) determines the base URL:
```dart
static String get baseUrl {
  if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
  if (kIsWeb) return '/api';  // Uses nginx proxy in production
  return _defaultNonWebBaseUrl;  // Direct connection for local dev
}
```

**DO NOT change:**
- The `/api` prefix for web builds
- The `API_BASE_URL` environment variable name
- The URL construction logic in `_buildUrl()`

#### 4. Authentication Flow
Authentication uses JWT tokens via `POST /api/token`:
```dart
Request: { "email": "user@example.com", "password": "password123" }
Response: { "token": "jwt_token_here", "user": {...} }
```

**DO NOT change:**
- Token endpoint path
- Request/response structure
- SessionManager token storage mechanism

---

## Backend API Contract

### Complete API Reference

#### Authentication
```http
POST /api/token
Content-Type: application/json

Request Body:
{
  "email": "string",
  "password": "string"
}

Response (200 OK):
{
  "token": "string (JWT)",
  "user": {
    "id": "integer",
    "name": "string",
    "email": "string",
    "role": "string (manager|employee)"
  }
}
```

#### Warehouse Inventory
```http
GET /api/warehouse
Authorization: Bearer {token}

Response (200 OK):
{
  "machine_id_1": [
    {
      "sku": "string",
      "name": "string",
      "qty": "integer",
      "price": "number (optional)"
    }
  ],
  "machine_id_2": [...]
}
```

```http
POST /api/warehouse/update
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "machine_id": "string",
  "sku": "string",
  "quantity": "integer"
}

Response (200 OK):
{
  "status": "success",
  "machine_id": "string",
  "sku": "string",
  "quantity": "integer"
}
```

```http
GET /api/items/{barcode}
Authorization: Bearer {token}

Response (200 OK):
{
  "sku": "string",
  "name": "string",
  "qty": "integer",
  "price": "number"
}
```

#### Daily Statistics
```http
GET /api/daily_stats
Authorization: Bearer {token}

Response (200 OK):
{
  "total_sales": "number",
  "total_transactions": "integer",
  "top_items": [
    {
      "name": "string",
      "quantity_sold": "integer"
    }
  ],
  "date": "string (ISO 8601)"
}
```

#### Items Management
```http
GET /api/items
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "id": "integer",
    "name": "string",
    "sku": "string",
    "price": "number",
    "slot_number": "integer (optional)"
  }
]
```

```http
POST /api/items
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "name": "string",
  "sku": "string",
  "price": "number",
  "slot_number": "integer (optional)"
}

Response (201 Created):
{
  "id": "integer",
  "name": "string",
  "sku": "string",
  "price": "number",
  "slot_number": "integer"
}
```

```http
PUT /api/items/{id}
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "name": "string (optional)",
  "price": "number (optional)",
  "slot_number": "integer (optional)"
}

Response (200 OK):
{
  "id": "integer",
  "name": "string",
  "sku": "string",
  "price": "number",
  "slot_number": "integer"
}
```

```http
DELETE /api/items/{id}
Authorization: Bearer {token}

Response (204 No Content)
```

#### Transactions
```http
GET /api/transactions
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "id": "integer",
    "item_id": "integer",
    "amount": "number",
    "timestamp": "string (ISO 8601)",
    "status": "string (completed|refunded)"
  }
]
```

```http
POST /api/transactions
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "item_id": "integer",
  "amount": "number"
}

Response (201 Created):
{
  "id": "integer",
  "item_id": "integer",
  "amount": "number",
  "timestamp": "string",
  "status": "completed"
}
```

```http
POST /api/transactions/{id}/refund
Authorization: Bearer {token}

Response (200 OK):
{
  "id": "integer",
  "status": "refunded",
  "refunded_at": "string (ISO 8601)"
}
```

#### Machines
```http
GET /api/machines
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "id": "integer",
    "name": "string",
    "location": "string",
    "status": "string (online|offline)"
  }
]
```

```http
GET /api/machines/{id}
Authorization: Bearer {token}

Response (200 OK):
{
  "id": "integer",
  "name": "string",
  "location": "string",
  "status": "string",
  "inventory": [
    {
      "sku": "string",
      "name": "string",
      "qty": "integer"
    }
  ]
}
```

#### Routes & Employees
```http
GET /api/routes
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "id": "integer",
    "name": "string",
    "stops": [
      {
        "machine_id": "integer",
        "order": "integer",
        "location": "string"
      }
    ]
  }
]
```

```http
GET /api/employees
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "id": "integer",
    "name": "string",
    "email": "string",
    "role": "string"
  }
]
```

```http
GET /api/employees/{id}/routes
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "id": "integer",
    "name": "string",
    "assigned_date": "string (ISO 8601)",
    "stops": [...]
  }
]
```

```http
POST /api/employees/{id}/routes/assign
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "route_id": "integer"
}

Response (200 OK):
{
  "status": "success",
  "employee_id": "integer",
  "route_id": "integer"
}
```

```http
PUT /api/employees/{id}/routes/stops
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "route_id": "integer",
  "stops": [
    {
      "machine_id": "integer",
      "order": "integer",
      "completed": "boolean"
    }
  ]
}

Response (200 OK):
{
  "status": "success",
  "updated_stops": "integer"
}
```

---

## Frontend Structure

### Directory Layout
```
Frontend/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── models/
│   │   │   ├── User.dart                  # User model
│   │   │   └── Employee.dart              # Employee model
│   │   ├── services/
│   │   │   ├── ApiClient.dart             # ⚠️ DO NOT MODIFY base URL logic
│   │   │   └── Database.dart              # Local storage (if used)
│   │   └── ui_kit/
│   │       ├── AppButton.dart             # Reusable button component
│   │       └── OverlayBlurWindow.dart     # Modal overlay component
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── AccessScreens.dart         # Login/signup screens
│   │   │   ├── Credentials.dart           # Credential input widgets
│   │   │   └── SessionManager.dart        # ⚠️ DO NOT MODIFY auth logic
│   │   ├── dashboard/
│   │   │   ├── DashboardHome.dart         # Main dashboard view
│   │   │   ├── OverviewScreens.dart       # Overview widgets
│   │   │   ├── BusinessMetrics.dart       # Metrics data models
│   │   │   └── widgets/
│   │   │       ├── DashboardMetrics.dart  # Metrics display widgets
│   │   │       ├── MachineStopCard.dart   # Machine status cards
│   │   │       └── MetricCard.dart        # Generic metric card
│   │   ├── warehouse/
│   │   │   ├── StockScreens.dart          # Inventory list view
│   │   │   ├── InventoryController.dart   # ⚠️ DO NOT MODIFY API calls
│   │   │   ├── InventoryItem.dart         # Inventory item model
│   │   │   └── ScanScreen.dart            # Barcode scanner UI
│   │   ├── routes/
│   │   │   ├── MapInterface.dart          # Route map view
│   │   │   ├── RoutePlanner.dart          # Route planning UI
│   │   │   └── RouteSegment.dart          # Route segment model
│   │   ├── settings/
│   │   │   └── SettingsMenu.dart          # Settings panel
│   │   └── layout/
│   │       ├── PagesLayout.dart           # Main app layout
│   │       ├── MainContent.dart           # Content area wrapper
│   │       └── Sidebar.dart               # Navigation sidebar
│   ├── assets/                            # Images, fonts, etc.
│   ├── pubspec.yaml                       # ⚠️ DO NOT REMOVE dependencies
│   └── web/
│       └── index.html                     # Web entry point
├── Dockerfile                             # ⚠️ DO NOT MODIFY
├── nginx/
│   └── default.conf                       # ⚠️ DO NOT MODIFY
└── scripts/
    └── build_web.sh                       # Build script
```

### Key Components

#### 1. ApiClient (`core/services/ApiClient.dart`)
**Purpose:** Centralized HTTP client for all API calls

**Methods:**
- `Future<dynamic> get(String endpoint)` - GET request
- `Future<dynamic> post(String endpoint, Map<String, dynamic> body)` - POST request
- `Future<dynamic> put(String endpoint, Map<String, dynamic> body)` - PUT request

**Usage Example:**
```dart
final client = ApiClient();
final data = await client.get('/warehouse');
```

**⚠️ CONSTRAINTS:**
- Do NOT modify `baseUrl` getter logic
- Do NOT change `_buildUrl()` method
- Do NOT alter error handling structure

#### 2. SessionManager (`modules/auth/SessionManager.dart`)
**Purpose:** Manages user authentication state

**Key Methods:**
- `Future<void> login(String email, String password)` - Authenticate user
- `void logout()` - Clear session
- `User? get currentUser` - Get current user

**⚠️ CONSTRAINTS:**
- Do NOT change token storage mechanism
- Do NOT modify login endpoint path
- Do NOT alter user model structure

#### 3. InventoryController (`modules/warehouse/InventoryController.dart`)
**Purpose:** Manages warehouse inventory state

**Key Properties:**
- `Map<String, List<InventoryItem>> inventory` - Machine-grouped inventory
- `bool isLoading` - Loading state

**Key Methods:**
- `Future<void> loadInventory()` - Fetch inventory from API

**⚠️ CONSTRAINTS:**
- Do NOT change API endpoint paths
- Do NOT modify data parsing logic
- Maintain the `Map<String, List<InventoryItem>>` structure

#### 4. PagesLayout (`modules/layout/PagesLayout.dart`)
**Purpose:** Main application layout with navigation

**Features:**
- Responsive sidebar (desktop) / bottom nav (mobile)
- Page routing
- Settings overlay
- User menu

**Refactorable Elements:**
- Visual styling (colors, fonts, spacing)
- Animation effects
- Layout dimensions
- Icon choices

---

## Container & Deployment

### Docker Compose Configuration

**File:** `docker-compose.yml`

```yaml
services:
  backend_new:
    build:
      context: ./Backend
      dockerfile: Dockerfile
    container_name: vending_backend
    restart: unless-stopped
    environment:
      RAILS_ENV: development
      PORT: 9090
      BINDING: 0.0.0.0
    ports:
      - "${BACKEND_NEW_PORT:-9090}:9090"

  frontend_new:
    build:
      context: ./Frontend
      dockerfile: Dockerfile
    container_name: vending_frontend_new
    restart: unless-stopped
    environment:
      API_SCHEME: ${API_SCHEME:-http}
      API_PRIMARY_HOST: ${API_PRIMARY_HOST:-backend_new:9090}
      API_FALLBACK_HOST: ${API_FALLBACK_HOST:-backend_new:9090}
    ports:
      - "${FRONTEND_NEW_PORT:-8082}:80"
    depends_on:
      - backend_new
```

### nginx Reverse Proxy

The frontend nginx configuration proxies API requests:
- Browser requests `/api/*` → nginx → `backend_new:9090/api/*`
- Browser requests `/health` → nginx → `backend_new:9090/health`

**⚠️ DO NOT MODIFY:**
- nginx configuration files
- Proxy pass rules
- Environment variable names
- Port mappings

### Build & Deployment Process

1. **Build Frontend:**
   ```bash
   cd Frontend
   flutter build web --release
   ```

2. **Start Stack:**
   ```bash
   docker compose up -d --build
   ```

3. **Access Application:**
   - Frontend: `http://localhost:8082`
   - Backend Health: `http://localhost:9090/health`

---

## Refactoring Guidelines

### ✅ SAFE TO MODIFY

#### Visual Design
- **Colors & Themes:** Change color schemes, gradients, shadows
- **Typography:** Update fonts, sizes, weights (via Google Fonts or custom)
- **Spacing & Layout:** Adjust padding, margins, grid systems
- **Animations:** Add/modify transitions, micro-interactions
- **Icons:** Replace icon sets (ensure Flutter compatibility)
- **Images & Assets:** Update logos, backgrounds, illustrations

#### UI Components
- **Widget Structure:** Reorganize widget trees for better composition
- **Component Library:** Create new reusable components
- **Styling Patterns:** Implement design systems, theme providers
- **Responsive Breakpoints:** Adjust mobile/tablet/desktop layouts

#### User Experience
- **Navigation Flow:** Redesign navigation patterns (keep route structure)
- **Form Layouts:** Improve input field designs, validation UI
- **Loading States:** Enhance loading indicators, skeleton screens
- **Error Handling UI:** Better error messages and recovery flows
- **Accessibility:** Add ARIA labels, keyboard navigation, screen reader support

#### State Management
- **Provider Patterns:** Refactor state management (keep API calls intact)
- **Local State:** Optimize component-level state
- **Derived State:** Add computed properties, memoization

### ⚠️ MODIFY WITH CAUTION

#### Data Models
- **Add Fields:** Safe if backend supports them
- **Rename Fields:** Update all references consistently
- **Remove Fields:** Ensure not used in API contracts

#### API Integration
- **Error Handling:** Improve error handling (keep endpoint paths)
- **Request Interceptors:** Add logging, retry logic
- **Response Parsing:** Enhance data transformation (keep structure)

### 🚫 DO NOT MODIFY

#### Backend Contracts
- API endpoint paths (defined in `Backend/config/routes.rb`)
- HTTP methods (GET, POST, PUT, DELETE)
- Request/response JSON structures
- Authentication token format

#### Infrastructure
- Docker Compose service definitions
- nginx configuration
- Environment variable names
- Port mappings
- Container networking

#### Core Services
- `ApiClient.baseUrl` logic
- `SessionManager` authentication flow
- API endpoint paths in controllers
- Data model core fields used in API responses

---

## Testing & Validation

### Pre-Refactor Checklist

1. **Document Current State:**
   ```bash
   # Capture current API responses
   curl http://localhost:9090/api/warehouse -H "Authorization: Bearer {token}" > warehouse_baseline.json
   curl http://localhost:9090/api/daily_stats -H "Authorization: Bearer {token}" > stats_baseline.json
   ```

2. **Test Authentication:**
   ```bash
   curl -X POST http://localhost:9090/api/token \
     -H "Content-Type: application/json" \
     -d '{"email":"Simon.swartout@gmail.com","password":"test123"}'
   ```

3. **Verify Container Health:**
   ```bash
   docker compose ps
   docker compose logs backend_new
   docker compose logs frontend_new
   ```

### Post-Refactor Validation

#### 1. API Contract Compliance
```dart
// Test all API endpoints return expected structure
void testApiContracts() async {
  final client = ApiClient();
  
  // Test warehouse endpoint
  final warehouse = await client.get('/warehouse');
  assert(warehouse is Map);
  assert(warehouse.values.first is List);
  
  // Test daily stats
  final stats = await client.get('/daily_stats');
  assert(stats.containsKey('total_sales'));
  assert(stats.containsKey('total_transactions'));
  
  // Test items endpoint
  final items = await client.get('/items');
  assert(items is List);
  assert(items.first.containsKey('sku'));
}
```

#### 2. Authentication Flow
```dart
void testAuthFlow() async {
  final session = SessionManager();
  
  // Test login
  await session.login('Simon.swartout@gmail.com', 'test123');
  assert(session.currentUser != null);
  assert(session.currentUser!.role == 'manager');
  
  // Test logout
  session.logout();
  assert(session.currentUser == null);
}
```

#### 3. Container Integration
```bash
# Verify frontend can reach backend through nginx proxy
docker exec vending_frontend_new curl http://backend_new:9090/health

# Test API proxy from frontend container
docker exec vending_frontend_new curl http://localhost/api/warehouse
```

#### 4. Visual Regression Testing
- Compare screenshots before/after refactor
- Test responsive breakpoints (mobile, tablet, desktop)
- Verify all navigation paths work
- Check form submissions and validations

#### 5. Performance Validation
```bash
# Measure build size
flutter build web --release
du -sh build/web

# Test load times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8082
```

### Demo Credentials

**Manager Account:**
- Email: `Simon.swartout@gmail.com`
- Password: `test123`
- Role: Full access to all features

**Employee Account:**
- Email: `amanda.jones@example.com`
- Password: `employee123`
- Role: Limited access (routes, inventory scanning)

---

## Common Refactoring Scenarios

### Scenario 1: Redesign Dashboard UI

**Goal:** Modernize dashboard with new metrics cards and layout

**Safe Changes:**
- Update `DashboardHome.dart` widget structure
- Redesign `MetricCard.dart` component styling
- Add new chart/graph widgets
- Change color scheme and typography

**Constraints:**
- Keep `BusinessMetrics.dart` data model intact
- Maintain API call to `/api/daily_stats`
- Preserve data parsing logic

**Example:**
```dart
// BEFORE: Simple metric card
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(title),
          Text(value, style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

// AFTER: Enhanced metric card with gradient and animation
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Scenario 2: Redesign Warehouse Inventory View

**Goal:** Create a more visual inventory management interface

**Safe Changes:**
- Redesign `StockScreens.dart` layout
- Add filtering/sorting UI
- Implement grid view option
- Add SKU images/thumbnails

**Constraints:**
- Keep `InventoryController.loadInventory()` API call
- Maintain `Map<String, List<InventoryItem>>` data structure
- Preserve barcode scanning functionality

**Example:**
```dart
// BEFORE: Simple list view
ListView.builder(
  itemCount: controller.inventory.length,
  itemBuilder: (context, index) {
    final machineId = controller.inventory.keys.elementAt(index);
    final items = controller.inventory[machineId]!;
    
    return ExpansionTile(
      title: Text('Machine $machineId'),
      children: items.map((item) => ListTile(
        title: Text(item.name),
        subtitle: Text('Qty: ${item.qty}'),
        trailing: Text(item.sku),
      )).toList(),
    );
  },
)

// AFTER: Enhanced grid view with filtering
Column(
  children: [
    // Filter bar
    Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search SKU or name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => controller.filterInventory(value),
            ),
          ),
          SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.grid_view),
            onPressed: () => setState(() => viewMode = ViewMode.grid),
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => setState(() => viewMode = ViewMode.list),
          ),
        ],
      ),
    ),
    
    // Grid view
    Expanded(
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: controller.flattenedInventory.length,
        itemBuilder: (context, index) {
          final item = controller.flattenedInventory[index];
          
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.inventory, size: 64),
                    ),
                  ),
                ),
                
                // Item details
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SKU: ${item.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.qty > 10 
                                ? Colors.green[100] 
                                : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${item.qty}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.qty > 10 
                                  ? Colors.green[800] 
                                  : Colors.orange[800],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 20),
                            onPressed: () => _editItem(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
)
```

### Scenario 3: Add Dark Mode Theme

**Goal:** Implement system-wide dark mode support

**Safe Changes:**
- Add `ThemeProvider` with light/dark themes
- Update all color references to use theme colors
- Add theme toggle in settings
- Persist theme preference locally

**Constraints:**
- Do NOT change API client behavior
- Maintain all existing functionality
- Ensure contrast ratios meet accessibility standards

**Example:**
```dart
// Create theme provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
      ? ThemeMode.dark 
      : ThemeMode.light;
    notifyListeners();
    // Persist to local storage
    _saveThemePreference();
  }
  
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF2196F3),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    // ... more theme properties
  );
  
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF1976D2),
    scaffoldBackgroundColor: Color(0xFF121212),
    cardColor: Color(0xFF1E1E1E),
    // ... more theme properties
  );
}

// Update main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AccessScreens(),
          );
        },
      ),
    );
  }
}
```

### Scenario 4: Implement Custom Design System

**Goal:** Create a comprehensive design system with tokens and components

**Safe Changes:**
- Create `design_system/` directory with tokens
- Build component library (buttons, cards, inputs)
- Implement spacing/typography scales
- Add animation/transition utilities

**Constraints:**
- Keep existing API integration intact
- Maintain data flow patterns
- Ensure backward compatibility during migration

**Example Structure:**
```
lib/
├── design_system/
│   ├── tokens/
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   ├── spacing.dart
│   │   └── shadows.dart
│   ├── components/
│   │   ├── buttons/
│   │   │   ├── primary_button.dart
│   │   │   ├── secondary_button.dart
│   │   │   └── icon_button.dart
│   │   ├── cards/
│   │   │   ├── base_card.dart
│   │   │   ├── metric_card.dart
│   │   │   └── info_card.dart
│   │   └── inputs/
│   │       ├── text_field.dart
│   │       ├── dropdown.dart
│   │       └── checkbox.dart
│   └── utils/
│       ├── responsive.dart
│       └── animations.dart
```

**Example Token Implementation:**
```dart
// design_system/tokens/colors.dart
class AppColors {
  // Primary palette
  static const primary50 = Color(0xFFE3F2FD);
  static const primary100 = Color(0xFFBBDEFB);
  static const primary500 = Color(0xFF2196F3);
  static const primary700 = Color(0xFF1976D2);
  static const primary900 = Color(0xFF0D47A1);
  
  // Semantic colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);
  
  // Neutral palette
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral500 = Color(0xFF9E9E9E);
  static const neutral900 = Color(0xFF212121);
}

// design_system/tokens/typography.dart
class AppTypography {
  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );
  
  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
  
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

// design_system/tokens/spacing.dart
class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

---

## Troubleshooting

### Issue: API Calls Failing After Refactor

**Symptoms:**
- Network errors in browser console
- Empty data in UI
- 404 or 500 errors

**Diagnosis:**
```bash
# Check backend is running
docker compose ps

# View backend logs
docker compose logs backend_new

# Test API directly
curl http://localhost:9090/api/warehouse
```

**Solutions:**
1. Verify `ApiClient.baseUrl` logic unchanged
2. Check endpoint paths match `Backend/config/routes.rb`
3. Ensure request headers include Authorization token
4. Validate request/response JSON structure

### Issue: Authentication Not Working

**Symptoms:**
- Login fails silently
- Token not persisted
- User redirected to login repeatedly

**Diagnosis:**
```dart
// Add logging to SessionManager
print('Login attempt: $email');
print('Token received: $token');
print('User data: ${user.toJson()}');
```

**Solutions:**
1. Verify `/api/token` endpoint path unchanged
2. Check request body format: `{"email": "...", "password": "..."}`
3. Ensure token storage mechanism intact
4. Validate `currentUser` getter logic

### Issue: Container Build Failures

**Symptoms:**
- Docker build errors
- Container exits immediately
- nginx 502 errors

**Diagnosis:**
```bash
# View build logs
docker compose build --no-cache

# Check container logs
docker compose logs -f frontend_new
docker compose logs -f backend_new

# Inspect container
docker exec -it vending_frontend_new sh
```

**Solutions:**
1. Ensure `Dockerfile` unchanged
2. Verify `pubspec.yaml` dependencies valid
3. Check nginx configuration intact
4. Rebuild Flutter web bundle: `flutter build web --release`

### Issue: Responsive Layout Broken

**Symptoms:**
- UI doesn't adapt to screen sizes
- Overflow errors on mobile
- Sidebar/navigation issues

**Diagnosis:**
```dart
// Add breakpoint debugging
print('Screen width: ${MediaQuery.of(context).size.width}');
print('Is mobile: $isMobile');
```

**Solutions:**
1. Test at multiple breakpoints (320px, 768px, 1024px, 1920px)
2. Use `LayoutBuilder` for dynamic sizing
3. Implement proper `MediaQuery` checks
4. Test on actual devices, not just browser resize

---

## Best Practices

### 1. Incremental Refactoring
- Refactor one module at a time
- Test thoroughly after each change
- Commit frequently with descriptive messages
- Keep a rollback plan

### 2. Preserve API Contracts
- Never change endpoint paths without backend coordination
- Maintain request/response structures
- Document any new API requirements
- Use TypeScript/Dart types to enforce contracts

### 3. Maintain Backward Compatibility
- Keep old components during migration
- Use feature flags for gradual rollout
- Provide fallbacks for new features
- Test with existing data

### 4. Performance Optimization
- Lazy load routes and heavy components
- Optimize images and assets
- Minimize bundle size
- Use code splitting where possible

### 5. Accessibility
- Maintain semantic HTML structure
- Ensure keyboard navigation works
- Provide ARIA labels
- Test with screen readers
- Maintain color contrast ratios (WCAG AA minimum)

### 6. Documentation
- Update component documentation
- Document new design patterns
- Maintain API integration examples
- Keep this guide updated with changes

---

## Quick Reference

### Environment Variables
```bash
# Frontend
API_BASE_URL=http://localhost:9090/api  # Local dev only

# Docker Compose
FRONTEND_NEW_PORT=8082
BACKEND_NEW_PORT=9090
API_SCHEME=http
API_PRIMARY_HOST=backend_new:9090
API_FALLBACK_HOST=backend_new:9090
```

### Common Commands
```bash
# Build frontend
cd Frontend && flutter build web --release

# Start stack
docker compose up -d --build

# View logs
docker compose logs -f

# Stop stack
docker compose down

# Rebuild specific service
docker compose up -d --build frontend_new

# Access container shell
docker exec -it vending_frontend_new sh

# Test API
curl -X POST http://localhost:9090/api/token \
  -H "Content-Type: application/json" \
  -d '{"email":"Simon.swartout@gmail.com","password":"test123"}'
```

### File Paths (Absolute)
```
Project Root: c:\GitHub\VendingBackpackv3

Frontend:
  Main: c:\GitHub\VendingBackpackv3\Frontend\lib\main.dart
  API Client: c:\GitHub\VendingBackpackv3\Frontend\lib\core\services\ApiClient.dart
  Session: c:\GitHub\VendingBackpackv3\Frontend\lib\modules\auth\SessionManager.dart
  Layout: c:\GitHub\VendingBackpackv3\Frontend\lib\modules\layout\PagesLayout.dart
  
Backend:
  Routes: c:\GitHub\VendingBackpackv3\Backend\config\routes.rb
  Warehouse Controller: c:\GitHub\VendingBackpackv3\Backend\app\controllers\api\warehouse_controller.rb
  
Docker:
  Compose: c:\GitHub\VendingBackpackv3\docker-compose.yml
```

---

## Appendix: Data Models

### User Model
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;  // "manager" | "employee"
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
```

### InventoryItem Model
```dart
class InventoryItem {
  final String sku;
  final String name;
  final int qty;
  final double? price;
  
  InventoryItem({
    required this.sku,
    required this.name,
    required this.qty,
    this.price,
  });
  
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      sku: json['sku'],
      name: json['name'],
      qty: json['qty'],
      price: json['price']?.toDouble(),
    );
  }
}
```

### Transaction Model
```dart
class Transaction {
  final int id;
  final int itemId;
  final double amount;
  final DateTime timestamp;
  final String status;  // "completed" | "refunded"
  
  Transaction({
    required this.id,
    required this.itemId,
    required this.amount,
    required this.timestamp,
    required this.status,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      itemId: json['item_id'],
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
    );
  }
}
```

---

## Support & Resources

### Documentation
- Flutter Web: https://docs.flutter.dev/platform-integration/web
- Provider State Management: https://pub.dev/packages/provider
- Docker Compose: https://docs.docker.com/compose/

### Project-Specific
- Main README: `c:\GitHub\VendingBackpackv3\README.md`
- Backend README: `c:\GitHub\VendingBackpackv3\Backend\README.md`
- Frontend README: `c:\GitHub\VendingBackpackv3\Frontend\README.md`

### Contact
For questions about backend API changes or infrastructure modifications, consult with the backend team before proceeding.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-22  
**Maintained By:** Development Team
