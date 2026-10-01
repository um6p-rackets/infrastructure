# PostgreSQL Database Architecture

## Overview
PostgreSQL is a highly stable, secure, and strictly-typed open-source relational database. For this project, we are using the lightweight `postgres:18.6-alpine3.24` image.

Unlike simpler databases (like SQLite or MariaDB), PostgreSQL enforces strict user roles, schema ownership, and connection limits. It is designed to handle high-concurrency environments, making it the ideal choice for managing our NextJS/NestJS real-time application states (users, matches, chat history).

---

## Configuration Files

### 1. The `Dockerfile`
Our Dockerfile is kept minimal and secure. It relies on the official image's built-in initialization mechanics.

```dockerfile
FROM postgres:18.6-alpine3.24

# The "Magic Folder": Postgres automatically executes any .sql or .sh files 
# placed in /docker-entrypoint-initdb.d/ in alphabetical order, 
# ONLY during the very first time the database boots.
COPY init.sql /docker-entrypoint-initdb.d/init.sql

# Expose the default PostgreSQL port for internal network communication
EXPOSE 5432

```

### 2. The Schema Initialization (`init.sql`)

This script automatically generates our tables and seeds initial test data before the backend even connects.

```sql
-- Enable UUID generation function (essential for secure primary keys)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create the base accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    intra_id VARCHAR(50) UNIQUE NOT NULL,
    avatar_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed an initial admin user for development testing
INSERT INTO accounts (username, intra_id) 
VALUES ('abnsila', 'abnsila_42');

```

---

## The "First Boot" Setup Rule (CRITICAL)

PostgreSQL is highly protective of your data. The automated setup process (which runs `init.sql` and reads your password secret) **only triggers if the mapped storage volume is 100% empty.**

If you modify `init.sql` and rebuild the container, PostgreSQL will see existing data in the storage directory, skip the initialization folder, and your new tables will not be created.

**To apply changes to the schema:** You must completely wipe the host data directory/volume before rebuilding the image.

---

## Testing & Interaction Commands

Once the container is running and healthy, use these commands to interact with the database directly.

### 1. Enter the Container

Access the container's shell:

```bash
docker exec -it database sh

```

### 2. Connect to the Database

Connect using the PostgreSQL interactive terminal (`psql`). You must specify the user (`-U`) and the database name (`-d`) defined in your environment variables.

```bash
psql -U admin -d rackets_db

```

*(Your prompt will change to `rackets_db=#`)*

### 3. Essential `psql` Navigation Commands

PostgreSQL uses backslash commands for system navigation instead of standard SQL queries:

* `\l` : List all available databases.
* `\dt` : List all tables in the current database.
* `\d <tablename>` : Describe a specific table (shows columns, data types, and constraints).
* `\x` : Toggle expanded display (makes long rows easier to read).
* `\q` : Quit the database and return to the container shell.

### 4. Verify the Initialization

To confirm your `init.sql` worked correctly, run standard SQL queries inside the `psql` prompt:

```sql
-- Check if the table exists and structure is correct
\d accounts;

-- Check if the test user was seeded successfully
SELECT * FROM accounts;

```