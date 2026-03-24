#!/bin/bash
# extract_logs.sh - Core data extraction script
# This script orchestrates reading system logs and updating the SQLite db.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PATH="$PROJECT_DIR/data/attendance.db"
SQL_INIT="$PROJECT_DIR/scripts/db_init.sql"
PARSER="$PROJECT_DIR/scripts/parse_last.py"

mkdir -p "$PROJECT_DIR/data"

echo "[extract_logs] Initializing database..."
sqlite3 "$DB_PATH" < "$SQL_INIT"

echo "[extract_logs] Reading login logs and inserting into database..."
# Run 'last' command and pipe to python parser, then pipe to sqlite3
last -F -w | python3 "$PARSER" | sqlite3 "$DB_PATH"

echo "[extract_logs] Process complete!"
