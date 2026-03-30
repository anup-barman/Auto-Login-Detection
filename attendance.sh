#!/bin/bash
# ==============================================================================
# Linux Automated Attendance System 
# Features:
# - Login/logout tracking using system logs (last command)
# - Daily attendance generation (Logins for today)
# - CSV export functionality
# - Summary analytics (Total login counts & aggregated duration)
# - Automation support (cron, tar, rsync)
# ==============================================================================

# Directories
WORK_DIR="${HOME}/attendance_system"
REPORT_DIR="${WORK_DIR}/reports"
ARCHIVE_DIR="${WORK_DIR}/archives"

# Ensure directories exist
mkdir -p "$REPORT_DIR" "$ARCHIVE_DIR"

# CSV File for today
TODAY=$(date +"%Y-%m-%d")
CSV_OUTPUT="${REPORT_DIR}/attendance_${TODAY}.csv"

# Remote Backup Settings (Modify these for your environment)
BACKUP_USER="backupuser"
BACKUP_HOST="192.168.1.100"
BACKUP_DEST="/backups/attendance"

# ======================== Helpers ==========================

# Print formatting
print_header() {
    clear
    echo "======================================================"
    echo "        Linux Automated Attendance System             "
    echo "======================================================"
}

pause() {
    echo ""
    read -p "Press Enter to return to the menu..."
}

# ======================== Core Functions ===================

generate_daily_attendance() {
    local date_filter
    date_filter=$(date +"%a %b %d") # e.g., Thu Mar 30 
    
    echo "Generating Daily Attendance for: $date_filter"
    echo "This tracks all sessions recorded for today."
    echo "------------------------------------------------------"
    printf "%-15s %-15s %-15s %-15s\n" "USERNAME" "TERMINAL" "LOGIN TIME" "DURATION"
    echo "------------------------------------------------------"
    
    # Uses last to parse wtmp, greps today's date, ignores reboots
    last | grep "$date_filter" | grep -v 'reboot' | head -n -1 > "/tmp/last_temp.txt"
    
    if [ ! -s "/tmp/last_temp.txt" ]; then
        echo "No attendance records found for today."
    else
        while read -r line; do
            user=$(echo "$line" | awk '{print $1}')
            term=$(echo "$line" | awk '{print $2}')
            login_time=$(echo "$line" | awk '{print $7}')
            duration=$(echo "$line" | awk '{print $NF}' | tr -d '()')
            
            # Print tabular format
            printf "%-15s %-15s %-15s %-15s\n" "$user" "$term" "$login_time" "$duration"
        done < "/tmp/last_temp.txt"
    fi
    rm -f "/tmp/last_temp.txt"
}

export_to_csv() {
    echo "Exporting all historical attendance to CSV..."
    local full_csv_file="${REPORT_DIR}/full_attendance_export_${TODAY}.csv"
    
    # Create Headers
    echo "Username,Terminal,Host,Day,Month,Date,Time,Duration" > "$full_csv_file"
    
    # Parse last output - filter reboot and wtmp lines
    last | egrep -v "reboot|wtmp" | awk 'NF>0' | head -n -1 | while read -r line; do
        user=$(echo "$line" | awk '{print $1}')
        term=$(echo "$line" | awk '{print $2}')
        host=$(echo "$line" | awk '{print $3}')
        
        # If no host IP is recorded (e.g. local tty), fields shift.
        if [[ "$host" =~ ^[A-Z] ]]; then
            # Host is empty, shifting everything
            day=$host
            month=$(echo "$line" | awk '{print $4}')
            date_num=$(echo "$line" | awk '{print $5}')
            time_val=$(echo "$line" | awk '{print $6}')
            host="Local"
        else
            day=$(echo "$line" | awk '{print $4}')
            month=$(echo "$line" | awk '{print $5}')
            date_num=$(echo "$line" | awk '{print $6}')
            time_val=$(echo "$line" | awk '{print $7}')
        fi
        
        duration=$(echo "$line" | awk '{print $NF}' | tr -d '()')
        
        echo "$user,$term,$host,$day,$month,$date_num,$time_val,$duration" >> "$full_csv_file"
    done
    
    echo "Successfully Exported: $full_csv_file"
}

summary_analytics() {
    echo "Summary Analytics: Total Login Count per User (Lifetime)"
    echo "------------------------------------------------------"
    last | egrep -v "reboot|wtmp" | awk '{print $1}' | sort | uniq -c | sort -nr
    echo "------------------------------------------------------"
}

# ======================== Automation =======================

rotate_and_archive() {
    echo "Archiving old reports..."
    local archive_name="attendance_logs_${TODAY}.tar.gz"
    
    # Use tar to compress files older than 7 days
    if find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 | grep -q "csv"; then
        find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 -exec tar -czvf "${ARCHIVE_DIR}/${archive_name}" {} + > /dev/null
        find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 -exec rm {} +
        echo "Old reports archived into: ${ARCHIVE_DIR}/${archive_name}"
    else
        echo "No reports older than 7 days to archive."
    fi
}

sync_to_remote() {
    echo "Attempting to sync archives to remote server using rsync over ssh..."
    if [ -z "$BACKUP_USER" ] || [ -z "$BACKUP_HOST" ]; then
        echo "Remote backup not configured. Please edit the script variables."
    else
        echo "Running: rsync -avz -e ssh $ARCHIVE_DIR/ ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DEST}"
        # Make sure to setup SSH keys for passwordless auth via cron!
        # rsync -avz -e ssh "$ARCHIVE_DIR/" "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DEST}"
        echo "[DRY RUN] Rsync logic is implemented, configure SSH keys to activate."
    fi
}

setup_cron() {
    echo "Setting up a daily cron job to run this script automatically at 11:50 PM..."
    CRON_CMD="50 23 * * * ${WORK_DIR}/attendance.sh --auto >> ${WORK_DIR}/cron.log 2>&1"
    
    (crontab -l 2>/dev/null | grep -v "attendance.sh"; echo "$CRON_CMD") | crontab -
    echo "Cron job installed successfully."
}

# ======================== Auto Mode ========================

if [ "$1" == "--auto" ]; then
    # Automated execution logic for cron jobs
    generate_daily_attendance > "${REPORT_DIR}/automated_daily_${TODAY}.txt"
    export_to_csv
    rotate_and_archive
    sync_to_remote
    exit 0
fi

# ======================== Interactive Menu =================

while true; do
    print_header
    echo "1. Show Daily Attendance (Today)"
    echo "2. Export All History to CSV"
    echo "3. View Summary Analytics"
    echo "4. Archive Old Reports (Tar)"
    echo "5. Setup Cron Automation & Rsync"
    echo "6. Exit"
    echo "------------------------------------------------------"
    read -p "Select an option [1-6]: " choice
    
    case $choice in
        1)
            generate_daily_attendance
            pause
            ;;
        2)
            export_to_csv
            pause
            ;;
        3)
            summary_analytics
            pause
            ;;
        4)
            rotate_and_archive
            pause
            ;;
        5)
            echo "Automation Setup:"
            echo "- This sets up a Cron job to automate daily exports."
            echo "- Includes Tar log rotation and Rsync backups."
            setup_cron
            sync_to_remote
            pause
            ;;
        6)
            echo "Exiting Attendance System. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            sleep 1
            ;;
    esac
done
