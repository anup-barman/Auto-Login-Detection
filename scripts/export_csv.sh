#!/bin/bash
# export_csv.sh - Exports attendance statistics and session logs to CSV

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PATH="$PROJECT_DIR/data/attendance.db"
EXPORT_DIR="$PROJECT_DIR/data/exports"

# Create exports directory if it doesn't exist
mkdir -p "$EXPORT_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
STATS_CSV="$EXPORT_DIR/user_stats_$TIMESTAMP.csv"
SESSIONS_CSV="$EXPORT_DIR/sessions_$TIMESTAMP.csv"

echo "[export_csv] Exporting user statistics..."
sqlite3 -header -csv "$DB_PATH" "SELECT * FROM user_stats;" > "$STATS_CSV"

echo "[export_csv] Exporting complete session logs..."
sqlite3 -header -csv "$DB_PATH" "SELECT id, username, ip_address, login_time, logout_time, duration_minutes FROM sessions ORDER BY login_time DESC;" > "$SESSIONS_CSV"

echo "[export_csv] Data successfully exported to:"
echo "  - $STATS_CSV"
echo "  - $SESSIONS_CSV"
