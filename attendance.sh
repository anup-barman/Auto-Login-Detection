#!/bin/bash
# ==============================================================================
# Linux Automated Attendance System 
# Features:
# - Login/logout tracking using system logs (last command)
# - Daily attendance generation (Logins for today)
# - CSV export functionality
# - Summary analytics (Total login counts & aggregated duration)
# - Automation support (cron, tar, rsync)
# - AM/PM Time Formatting
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
SIMULATE_LOCAL_BACKUP="true" # Set to true to demonstrate rsync copying to a local folder
BACKUP_USER="backupuser"
BACKUP_HOST="192.168.1.100"
BACKUP_DEST="${HOME}/attendance_system/remote_backup_simulation"

# ======================== Helpers ==========================

# Print formatting
print_header() {
    clear
    echo "==========================================================================="
    echo "                 Linux Automated Attendance System                         "
    echo "==========================================================================="
}

pause() {
    echo ""
    read -p "Press Enter to return to the menu..."
}

# Core logic to parse a single line of the 'last' command
parse_log_line() {
    local line="$1"
    user=$(echo "$line" | awk '{print $1}')
    term=$(echo "$line" | awk '{print $2}')
    
    # Extract the exact date of the login (e.g., "Sat Apr 18")
    login_date=$(echo "$line" | grep -oE '[A-Z][a-z]{2} [A-Z][a-z]{2} +[0-9]+' | head -1)
    [ -z "$login_date" ] && login_date="N/A"
    
    # Strictly extract the first instance of HH:MM for login time
    local raw_login_time=$(echo "$line" | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
    
    # Convert login time to AM/PM format
    if [ -n "$raw_login_time" ]; then
        login_time=$(date -d "$raw_login_time" +"%I:%M %p" 2>/dev/null || echo "$raw_login_time")
    else
        login_time="N/A"
    fi
    
    # Determine logout time and duration based on session state
    if echo "$line" | grep -q "still logged in"; then
        logout_time="Active"
        duration="Active"
    elif echo "$line" | grep -q "\- crash"; then
        logout_time="Crash"
        duration=$(echo "$line" | grep -oE '\([0-9+:]+\)' | tr -d '()')
    elif echo "$line" | grep -q "\- down"; then
        logout_time="Sys Down"
        duration=$(echo "$line" | grep -oE '\([0-9+:]+\)' | tr -d '()')
    else
        # Standard logout time is the second HH:MM match on the line
        local raw_logout_time=$(echo "$line" | grep -oE '[0-9]{2}:[0-9]{2}' | sed -n '2p')
        
        # Convert logout time to AM/PM format safely
        if [ -n "$raw_logout_time" ]; then
            logout_time=$(date -d "$raw_logout_time" +"%I:%M %p" 2>/dev/null || echo "$raw_logout_time")
        else
            logout_time="N/A"
        fi
        duration=$(echo "$line" | grep -oE '\([0-9+:]+\)' | tr -d '()')
    fi

    # Fallbacks for empty variables
    [ -z "$duration" ] && duration="N/A"
}

# ======================== Core Functions ===================

generate_daily_attendance() {
    local date_filter
    date_filter=$(date +"%a %b %e")
    
    echo "Generating Daily Attendance for: $date_filter"
    echo "This tracks all sessions recorded for today."
    echo "---------------------------------------------------------------------------"
    printf "%-15s %-15s %-15s %-15s %-15s %-15s\n" "USERNAME" "TERMINAL" "DATE" "LOGIN TIME" "LOGOUT TIME" "DURATION"
    echo "---------------------------------------------------------------------------"
    
    # Exclude reboots, wtmp endings, redundant seat0, and gdm-greeter entries
    # last reads /var/log/wtmp and cheks the successful logins and logouts
    last | grep "$date_filter" | egrep -v 'reboot|wtmp|seat0|gdm-gree' > "/tmp/last_temp.txt"
    
    if [ ! -s "/tmp/last_temp.txt" ]; then
        echo "No attendance records found for today."
    else
        while read -r line; do
            parse_log_line "$line"
            # Print tabular format
            printf "%-15s %-15s %-15s %-15s %-15s %-15s\n" "$user" "$term" "$login_date" "$login_time" "$logout_time" "$duration"
        done < "/tmp/last_temp.txt"
    fi
    rm -f "/tmp/last_temp.txt"
}

export_to_csv() {
    echo "Exporting all historical attendance to CSV..."
    local full_csv_file="${REPORT_DIR}/full_attendance_export_${TODAY}.csv"
    
    # Create Headers
    echo "Username,Terminal,Date,Login_Time,Logout_Time,Duration" > "$full_csv_file"
    
    # Parse last output - filter reboot, wtmp, seat0, and pgdm-gree lines
    last | egrep -v "reboot|wtmp|seat0|gdm-gree" | awk 'NF>0' | while read -r line; do
        parse_log_line "$line"
        
        # Write to CSV
        echo "$user,$term,$login_date,$login_time,$logout_time,$duration" >> "$full_csv_file"
    done
    
    echo "Successfully Exported: $full_csv_file"
}

export_today_to_csv() {
    echo "Exporting today's attendance to CSV..."
    local today_csv_file="${REPORT_DIR}/today_attendance_export_${TODAY}.csv"
    
    local date_filter
    date_filter=$(date +"%a %b %e")
    
    # Create Headers
    echo "Username,Terminal,Date,Login_Time,Logout_Time,Duration" > "$today_csv_file"
    
    # Parse last output - filter for today and specific exclusions
    last | grep "$date_filter" | egrep -v "reboot|wtmp|seat0|gdm-gree" | awk 'NF>0' | while read -r line; do
        parse_log_line "$line"
        
        # Write to CSV
        echo "$user,$term,$login_date,$login_time,$logout_time,$duration" >> "$today_csv_file"
    done
    
    echo "Successfully Exported: $today_csv_file"
}

summary_analytics() {
    echo "Summary Analytics: Total Login Count per User (Lifetime)"
    echo "---------------------------------------------------------------------------"
    last | egrep -v "reboot|wtmp|seat0|gdm-gree" | awk '{print $1}' | sort | uniq -c | sort -nr
    echo "---------------------------------------------------------------------------"
}

# ======================== Automation =======================

rotate_and_archive() {
    echo "Archiving old reports..."
    local archive_name="attendance_logs_${TODAY}.tar.gz"
    
    if find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 | grep -q "csv"; then
        find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 -exec tar -czvf "${ARCHIVE_DIR}/${archive_name}" {} + > /dev/null
        find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 -exec rm {} +
        echo "Old reports archived into: ${ARCHIVE_DIR}/${archive_name}"
    else
        echo "No reports older than 7 days to archive."
    fi
}

sync_to_remote() {
    echo "Attempting to sync archives to remote backup destination..."
    
    # Create the simulated destination if it's a local backup test
    if [ "$SIMULATE_LOCAL_BACKUP" == "true" ]; then
        echo "Running in local simulation mode. Copying to $BACKUP_DEST"
        mkdir -p "$BACKUP_DEST"
        rsync -avz "$ARCHIVE_DIR/" "$BACKUP_DEST/"
        echo "Simulated sync complete! Check $BACKUP_DEST"
    elif [ -z "$BACKUP_USER" ] || [ -z "$BACKUP_HOST" ]; then
        echo "Remote backup not configured. Please edit the script variables."
    else
        echo "Running: rsync -avz -e ssh $ARCHIVE_DIR/ ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DEST}"
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
    echo "3. Export Today's History to CSV"
    echo "4. View Summary Analytics"
    echo "5. Archive Old Reports (Tar)"
    echo "6. Setup Cron Automation & Rsync"
    echo "7. Exit"
    echo "---------------------------------------------------------------------------"
    read -p "Select an option [1-7]: " choice
    
    if [ "$choice" == "1" ]; then
        generate_daily_attendance
        pause
    elif [ "$choice" == "2" ]; then
        export_to_csv
        pause
    elif [ "$choice" == "3" ]; then
        export_today_to_csv
        pause
    elif [ "$choice" == "4" ]; then
        summary_analytics
        pause
    elif [ "$choice" == "5" ]; then
        rotate_and_archive
        pause
    elif [ "$choice" == "6" ]; then
        echo "Automation Setup:"
        echo "- This sets up a Cron job to automate daily exports."
        echo "- Includes Tar log rotation and Rsync backups."
        setup_cron
        sync_to_remote
        pause
    elif [ "$choice" == "7" ]; then
        echo "Exiting Attendance System. Goodbye!"
        exit 0
    else
        echo "Invalid option. Please try again."
        sleep 1
    fi
done
