# VendingBackpack Backend API

FastAPI backend for the VendingBackpack vending machine system.

## Features

- ✅ RESTful API with automatic documentation (Swagger/OpenAPI)
- ✅ SQLite support for local development
- ✅ PostgreSQL support for production
- ✅ Environment variable configuration
- ✅ Database models for items and transactions
- ✅ CRUD operations for inventory management
- ✅ Transaction tracking and refunds

## Quick Start

### Local Development (SQLite)

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
   ```

3. **Access the API:**
   - API: http://localhost:8080
   - Swagger Docs: http://localhost:8080/docs
   - ReDoc: http://localhost:8080/redoc

### Production (PostgreSQL)

Set the `DATABASE_URL` or `DB_URI` environment variable:

```bash
export DATABASE_URL="postgresql://user:password@host:5432/database"
# OR
export DB_URI="postgresql://user:password@host:5432/database"
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Database connection string | `sqlite:///./vending_backpack.db` |
| `DB_URI` | Alternative to DATABASE_URL | - |
| `ENVIRONMENT` | Environment name (development/production) | `development` |
| `DEBUG` | Enable debug mode | `True` |
| `API_HOST` | API host address | `0.0.0.0` |
| `API_PORT` | API port | `8080` |

### Database URL Formats

**SQLite (Local):**
```
sqlite:///./vending_backpack.db
```

**PostgreSQL (Production):**
```
postgresql://username:password@hostname:5432/database_name
```

## API Endpoints

### Health Check
- `GET /` - Basic health check
- `GET /health` - Detailed health check

### Items
- `GET /api/items` - List all items
- `GET /api/items/{id}` - Get item by ID
- `GET /api/items/slot/{slot_number}` - Get item by slot
- `POST /api/items` - Create new item
- `PUT /api/items/{id}` - Update item
- `DELETE /api/items/{id}` - Delete item

### Transactions
- `GET /api/transactions` - List all transactions
- `GET /api/transactions/{id}` - Get transaction by ID
- `POST /api/transactions` - Create transaction (purchase)
- `POST /api/transactions/{id}/refund` - Refund transaction

## Docker Deployment

See [BACKEND_DEPLOYMENT.md](../BACKEND_DEPLOYMENT.md) for detailed Portainer deployment instructions.

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── config.py            # Configuration & env vars
│   ├── database.py          # Database connection
│   ├── models/              # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── item.py
│   │   └── transaction.py
│   ├── schemas/             # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── item.py
│   │   └── transaction.py
│   └── routers/             # API routes
│       ├── __init__.py
│       ├── items.py
│       └── transactions.py
├── Dockerfile
├── requirements.txt
└── README.md
```

## Development

### Adding New Endpoints

1. Create a new router in `app/routers/`
2. Add models in `app/models/`
3. Add schemas in `app/schemas/`
4. Include router in `app/main.py`

### Database Migrations

For production, consider using Alembic for database migrations:
```bash
pip install alembic
alembic init migrations
```

## License

Part of the VendingBackpack project.
