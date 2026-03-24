# Automated Attendance System using Login Logs

A comprehensive semester final project for an Operating Systems lab. Built by a 5-person team, this system extracts user login data from Linux machine logs (`last` / `wtmp`), stores them in a relational database (SQLite), and displays actionable analytics dynamically on a high-end web dashboard. 

## Features
- **Bash Mandatory Component**: A suite of robust Bash scripts orchestrates data extraction, sanitization, and DB insertion seamlessly without third-party ingestion tools.
- **Automated Fraud Detection**: Filters out impossibly short sessions (<1 min) and excessively long hanging sessions (>24 hours).
- **SQLite Database Integration**: Keeps track of students' net hours logged across multiple logins.
- **Alert System**: Detects "absentee" users who fail to meet the required lab hours threshold and triggers notifications.
- **RESTful API**: Python Flask backend to serve data scalably.
- **CSV Data Export**: One-click download of attendance statistics through the UI or `make export` via terminal.
- **Premium Dashboard UI**: Built with Tailwind CSS and Chart.js featuring glassmorphism design.
- **Fully Packaged Setup**: Includes an `install.sh` and `Makefile` for one-click deployment.

## Team Roles & Division of Labor

This project is perfectly modular for a 5-person team:
1. **Core Data Architect (Bash)**: Wrote `scripts/extract_logs.sh`, ensuring logs are read, cleaned, and piped effectively.
2. **Database Architect (SQL)**: Created `scripts/db_init.sql` and the ingestion schema to handle UPSERTs and View aggregation.
3. **Alerts & Automation (Bash)**: Authored `scripts/alert_absentees.sh`, tracking low attendance and triggering automated system alerts.
4. **Backend Developer (Python)**: Developed `backend/app.py` to bridge the SQLite files into a robust REST JSON API using Flask.
5. **Frontend Developer (HTML/JS)**: Built `frontend/index.html` combining Tailwind CSS and Chart.js to make statistical metrics interactive and visually pleasing.

## Installation & Setup

1. **Install dependencies**:
   ```bash
   make install
   ```
2. **Extract System Logs & Initialize Database**:
   ```bash
   make extract
   ```
   *This reads `/var/log/wtmp` using the `last` command, compiles the durations, and saves to `data/attendance.db`.*
3. **Run the Alert System** (Optional):
   ```bash
   make alert
   ```
4. **Start the Web Dashboard**:
   ```bash
   make run
   ```
   *Once started, simply open the `frontend/index.html` file in any web browser. The API will respond on `http://127.0.0.1:5000`.*
5. **Export to CSV**:
   ```bash
   make export
   ```
   *This outputs timestamped CSVs directly into `data/exports/`.*
