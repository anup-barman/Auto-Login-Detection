#!/bin/bash
# alert_absentees.sh - Checks the SQLite db for users with low attendance

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PATH="$PROJECT_DIR/data/attendance.db"
MINIMUM_HOURS=10

echo "Checking for users with less than $MINIMUM_HOURS hours of total attendance..."

# Query SQLite for absent users
# We use the user_stats view created in db_init.sql
ABSENTEES=$(sqlite3 "$DB_PATH" "SELECT username, TRUNC(total_hours, 2) FROM user_stats WHERE total_hours < $MINIMUM_HOURS;")

if [ -z "$ABSENTEES" ]; then
    echo "All active users have met the attendance requirement (minimum $MINIMUM_HOURS hours)."
    exit 0
fi

echo "--- ABSENTEE ALERT ---"
echo "$ABSENTEES" | while IFS="|" read -r username hours_spent; do
    echo "WARNING: User '$username' has only $hours_spent hours!"
    
    # Insert an alert into the DB
    MSG="Low attendance warning: $hours_spent hours logged (Minimum is $MINIMUM_HOURS)"
    sqlite3 "$DB_PATH" "INSERT INTO alerts (username, alert_type, message) VALUES ('$username', 'LOW_ATTENDANCE', '$MSG');"
    
    # Optional integration: send a desktop notification to the current user 
    # to demonstrate automation in the presentation.
    # notify-send -u critical "Attendance Alert" "User $username needs to log $MINIMUM_HOURS hours!"
done

echo "System alerts fully updated in the database."
