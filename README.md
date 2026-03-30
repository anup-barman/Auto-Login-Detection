# 📊 Linux Automated Attendance System

[![Bash Script](https://img.shields.io/badge/language-bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)

A robust, terminal-based attendance tracking solution for Linux systems. This system monitors user login/logout activity, generates daily reports, provides analytical summaries, and supports fully automated backups and archiving.

---

## ✨ Key Features

*   **🔍 Real-time Tracking**: Monitors all user sessions using system logs (`last`).
*   **📂 CSV Exporting**: Generate industry-standard CSV reports for easy import into Excel or Google Sheets.
*   **📈 Summary Analytics**: Instant "Leaderboard" view of user activity and login frequency.
*   **📦 Smart Archiving**: Automatically compresses old reports using `tar` to save disk space.
*   **🤖 Full Automation**: Built-in `cron` integration to schedule daily task execution.
*   **🌐 Remote Sync**: Supports `rsync` over SSH for secure off-site backups.
*   **💻 Interactive UI**: A clean, menu-driven terminal interface for manual management.

---

## 🚀 Quick Start

### 1. Installation
Clone the repository (or copy the script) and ensure it has execution permissions:

```bash
chmod +x attendance.sh
```

### 2. Manual Execution
Run the script to access the interactive dashboard:

```bash
./attendance.sh
```

### 3. Automated Setup
To enable daily automation (Reports @ 11:50 PM, Archiving, and Backups):
1.  Run the script: `./attendance.sh`
2.  Select Option **5** (**Setup Cron Automation & Rsync**).

---

## 🛠 Usage Modes

### 🖥 Interactive Mode
The script features a user-friendly menu:
1.  **Show Daily Attendance**: See who is logged in *today*.
2.  **Export All History to CSV**: Save all historical logs to a portable file.
3.  **View Summary Analytics**: Ranking of users by login count.
4.  **Archive Old Reports**: Compress logs older than 7 days.
5.  **Setup Automation**: Configure the system-wide 'Auto-Pilot'.

### ⚙️ Auto-Pilot Mode
For use in servers or scheduled tasks, use the `--auto` flag:
```bash
./attendance.sh --auto
```
This mode generates today's report, exports CSVs, archives old data, and attempts a remote sync without any user input.

---

## 📂 System Architecture

When executed, the system creates an `attendance_system` workspace in your home directory:

```text
~/attendance_system/
├── reports/     # Active CSV & TXT attendance records
├── archives/    # Compressed .tar.gz historical data
└── cron.log     # Internal logs for automated tasks
```

---

## 🔧 Configuration
Open `attendance.sh` in your favorite editor to customize:
*   **`WORK_DIR`**: Where the system stores data (Default: `~/attendance_system`).
*   **`BACKUP_DEST`**: The remote server path for `rsync` backups.
*   **`Cron Schedule`**: Modify the `setup_cron` function to change execution times.

---

## 📜 Documentation
For a deep dive into how the code works (perfect for beginners), refer to:
*   [Script-Explanation.md](./Script-Explanation.md) - Detailed line-by-line breakdown.
*   `Script-Explanation.pdf` - Printable version of the guide.

---

## ⚖️ License
This project is licensed under the MIT License - see the LICENSE file for details.

---
> Developed with ❤️ for Linux Administrators.
