#!/bin/bash
# install.sh - Sets up the environment for the project

echo "=== Automated Attendance System Setup ==="

# 1. Ensure sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    echo "ERROR: sqlite3 is required. Please install it (e.g., sudo apt install sqlite3)."
    exit 1
fi

# 2. Setup Python Virtual Environment
echo "Setting up Python Virtual Environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r backend/requirements.txt
pip install gunicorn

# 3. Setup permissions
echo "Setting execution permissions on scripts..."
chmod +x scripts/*.sh

# 4. Setup Cronjob (Optional, for full automation)
echo "Do you want to setup a cronjob to extract logs daily? (y/n)"
# read -r response # Disabled for automated installation
# if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
#    CRON_CMD="0 0 * * * cd $(pwd) && ./scripts/extract_logs.sh > /dev/null 2>&1"
#    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
#    echo "Cronjob installed to run daily at midnight."
# fi

echo "Setup Complete!"
echo "To initialize data, run: make extract"
echo "To start the system, run: make run"
