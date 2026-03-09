# Striim Demo - PostgreSQL to Azure SQL Edge CDC

This project demonstrates **Striim's Initial Load (IL)** and **Change Data Capture (CDC)** capabilities by replicating data from PostgreSQL to Azure SQL Edge using Docker containers running locally.

## 📋 Overview

This demo showcases:
- Running **PostgreSQL** and **Azure SQL Edge** as Docker containers locally
- Loading sample retail data into PostgreSQL (source database)
- Using **Striim** to perform:
  - **Initial Load (IL)**: Bulk data migration from source to target
  - **Change Data Capture (CDC)**: Real-time replication of INSERT, UPDATE, and DELETE operations
- PostgreSQL with **wal2json** plugin for logical replication
- Azure SQL Edge as the target database

## 🏗️ Architecture

```
┌─────────────────┐         ┌──────────────┐         ┌─────────────────┐
│   PostgreSQL    │         │    Striim    │         │  Azure SQL Edge │
│   (Source)      │ ──CDC──>│  (Local App) │ ──────> │    (Target)     │
│   Port: 5432    │         │              │         │   Port: 1433    │
└─────────────────┘         └──────────────┘         └─────────────────┘
```

## 🗂️ Project Structure

```
striim-demo/
├── docker-compose.yml          # Docker services configuration
├── dockerfile                  # Custom PostgreSQL image with wal2json
├── .env                        # Environment variables for databases
├── README.md                   # This file
└── script/
    ├── postgres_IL_data_load.sql  # Initial data load script (PostgreSQL)
    ├── postres_CDC.sql            # CDC test queries (INSERT/DELETE)
    └── azuresql.sql               # Query scripts for Azure SQL Edge
```

## 🚀 Prerequisites

- **Docker Desktop** installed and running
- **Striim** application installed locally (for CDC replication)
- SQL client (e.g., DBeaver, Azure Data Studio, pgAdmin) for database connections

## 📦 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd striim-demo
```

### 2. Start Docker Containers

Run the following command to start PostgreSQL and Azure SQL Edge containers:

```bash
docker-compose up -d
```

This will start:
- **PostgreSQL** on `localhost:5432`
  - Username: `****` (from `.env` file)
  - Password: `****` (from `.env` file)
  - Database: `demo`
  - Configured with `wal_level=logical` for CDC
  
- **Azure SQL Edge** on `localhost:1433`
  - Username: `sa`
  - Password: `****` (from `.env` file)

> **Note:** All credentials are stored in the `.env` file. See [Configuration Details](#-configuration-details) section below.

### 3. Verify Containers are Running

```bash
docker ps
```

You should see both `postgres` and `azuresqledge` containers running.

### 4. Load Initial Data into PostgreSQL

Connect to PostgreSQL and execute the initial load script:

```bash
# Using psql (if installed) - credentials from .env file
psql -h localhost -U <POSTGRES_USER> -d demo -f script/postgres_IL_data_load.sql

# Or connect via your SQL client and run the script
# Use credentials from .env file
```

This script will:
- Create the `retail` schema
- Create 5 tables: `customers`, `products`, `stores`, `orders`, `order_items`
- Load sample data:
  - 2,000 customers
  - 1,000 products
  - 100 stores
  - 5,000 orders
  - 5,000 order items

### 5. Configure Striim for Replication

1. **Start Striim** application locally
2. **Create a new application** in Striim
3. **Configure Source (PostgreSQL)**:
   - Connection Type: PostgreSQL Reader
   - Host: `localhost`
   - Port: `5432`
   - Database: `demo`
   - Username: `****` (from `.env` file: `POSTGRES_USER`)
   - Password: `****` (from `.env` file: `POSTGRES_PASSWORD`)
   - Schema: `retail`
   - Tables: All (`customers`, `products`, `stores`, `orders`, `order_items`)
   - Enable CDC: Yes (uses wal2json)

4. **Configure Target (Azure SQL Edge)**:
   - Connection Type: MS SQL Server Writer
   - Host: `localhost`
   - Port: `1433`
   - Database: Create or specify target database
   - Username: `sa`
   - Password: `****` (from `.env` file: `MSSQL_SA_PASSWORD`)
   - Schema: `retail`

5. **Run Initial Load** to migrate existing data
6. **Start CDC** to capture real-time changes

## 🧪 Testing CDC Functionality

### Test INSERT Operations

Connect to PostgreSQL and run:

```sql
-- Insert a single customer
INSERT INTO retail.customers (full_name, email, city)
VALUES ('John Demo','john.demo@retaildemo.com','New York');

-- Insert 100 customers
INSERT INTO retail.customers (full_name, email, city)
SELECT
    'Customer_' || g,
    'customer_' || g || '@retaildemo.com',
    (ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix'])[floor(random()*5)+1]
FROM generate_series(1,100) g;
```

### Test DELETE Operations

```sql
-- Delete customers with ID > 2000
DELETE FROM retail.customers WHERE customer_id > 2000;
```

### Verify on Target (Azure SQL Edge)

Check the Azure SQL Edge database to confirm the changes were replicated:

```sql
-- Check record counts
WITH counts AS (
    SELECT
        (SELECT count(*) FROM retail.customers) AS customers,
        (SELECT count(*) FROM retail.products) AS products,
        (SELECT count(*) FROM retail.stores) AS stores,
        (SELECT count(*) FROM retail.orders) AS orders,
        (SELECT count(*) FROM retail.order_items) AS order_items
)
SELECT
    customers,
    products,
    stores,
    orders,
    order_items,
    customers + products + stores + orders + order_items AS total_records
FROM counts;
```

## 🔍 Monitoring

Monitor Striim's dashboard to observe:
- **Events processed**: Number of CDC events captured
- **Latency**: Time between source change and target replication
- **Throughput**: Events per second
- **Error handling**: Any replication errors or warnings

## 🗄️ Database Schema

The retail schema includes the following tables:

- **customers**: Customer information (2,000 records)
- **products**: Product catalog (1,000 records)
- **stores**: Store locations (100 records)
- **orders**: Customer orders with foreign keys to customers and stores
- **order_items**: Line items for each order with product references

## 🧹 Cleanup

### Stop and Remove Containers

```bash
docker-compose down
```

### Remove Volumes (Delete all data)

```bash
docker-compose down -v
```

### Truncate Tables (PostgreSQL)

```sql
TRUNCATE TABLE
    retail.order_items,
    retail.orders,
    retail.customers,
    retail.products,
    retail.stores
RESTART IDENTITY CASCADE;
```

### Drop Tables (Azure SQL Edge)

```sql
DELETE FROM retail.order_items;
DELETE FROM retail.orders;
DELETE FROM retail.customers;
DELETE FROM retail.products;
DELETE FROM retail.stores;

DROP TABLE retail.order_items;
DROP TABLE retail.orders;
DROP TABLE retail.customers;
DROP TABLE retail.products;
DROP TABLE retail.stores;

DROP SCHEMA retail;
```

## 🔧 Configuration Details

### PostgreSQL Configuration

The PostgreSQL container is configured with:
- `wal_level=logical`: Enables logical replication for CDC
- `max_replication_slots=5`: Allows up to 5 replication slots
- `max_wal_senders=5`: Supports up to 5 concurrent WAL senders
- **wal2json plugin**: Installed for JSON-based change data capture

### Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# PostgreSQL
POSTGRES_USER=##
POSTGRES_PASSWORD=##
POSTGRES_DB=demo

# Azure SQL Edge
MSSQL_SA_PASSWORD=##
```

## 📝 Notes

- Azure SQL Edge is used instead of full SQL Server for local development (lightweight, ARM64 compatible)
- PostgreSQL uses the **wal2json** logical decoding plugin for CDC
- Striim must be configured to use the PostgreSQL replication slot
- Ensure Docker has sufficient resources allocated (at least 4GB RAM recommended)

## 🐛 Troubleshooting

### Cannot connect to PostgreSQL
- Verify container is running: `docker ps`
- Check port 5432 is not in use by another service
- Verify credentials in `.env` file

### Cannot connect to Azure SQL Edge
- Verify container is running: `docker ps`
- Check port 1433 is not in use by another service
- Ensure password meets SQL Server complexity requirements

### CDC not capturing changes
- Verify PostgreSQL `wal_level` is set to `logical`
- Check replication slot exists in PostgreSQL
- Verify Striim source is configured correctly
- Check Striim logs for connection or replication errors

## 📚 References

- [Striim Documentation](https://www.striim.com/docs/)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html)
- [wal2json Plugin](https://github.com/eulerto/wal2json)
- [Azure SQL Edge Documentation](https://learn.microsoft.com/en-us/azure/azure-sql-edge/)

## 📄 License

This project is for demonstration purposes.

---

**Happy Streaming with Striim! 🚀**

