# Automated Attendance System - Code Explanation Guide

This guide breaks down exactly how the `attendance.sh` script works. It assumes you are new to Bash scripting and explains every component, command, and piece of logic used to fulfill the project requirements.

## 1. The Shebang and Setup (Lines 1-22)

```bash
#!/bin/bash
```
* **The Shebang (`#!/bin/bash`)**: This is always the first line in a Linux script. It tells the operating system which "interpreter" to use to run the file. Here, we are telling Linux to use the `bash` system shell.

```bash
WORK_DIR="${HOME}/attendance_system"
REPORT_DIR="${WORK_DIR}/reports"
ARCHIVE_DIR="${WORK_DIR}/archives"
```
* **Variables**: We store directory paths in variables so we don't have to type them out every time. `${HOME}` is a built-in variable pointing to your user's home directory (e.g., `/home/student`).

```bash
mkdir -p "$REPORT_DIR" "$ARCHIVE_DIR"
TODAY=$(date +"%Y-%m-%d")
```
* **`mkdir -p`**: The `mkdir` command makes directories. The `-p` flag means "create the parent directories if they don't exist, and don't throw an error if they already exist." This ensures our script doesn't crash on its first run!
* **`$(command)`**: This is called **command substitution**. It runs the command inside the parentheses and replaces it with the output. Here, `date +"%Y-%m-%d"` creates our date variable (like `2023-10-25`).

---

## 2. Helper Functions (Lines 24-34)

In scripting, a **function** allows us to bundle code together so we can reuse it easily.

```bash
print_header() {
    clear
    echo "======================================================"
...
}
```
* **`clear`**: Clears the terminal screen so the menu looks fresh and clean.
* **`echo`**: Prints text directly to the screen.

```bash
pause() {
    echo ""
    read -p "Press Enter to return to the menu..."
}
```
* **`read -p`**: The `read` command pauses the script and waits for the user to type something and hit Enter. The `-p` flag allows us to put a 'prompt' message on the same line.

---

## 3. Daily Attendance Generation (Lines 36-64)

This function pulls login sessions matching *today's* date.

```bash
last | grep "$date_filter" | grep -v 'reboot' | head -n -1 > "/tmp/last_temp.txt"
```
This single line uses **pipes** (`|`), which take the output of the command on the left and feed it directly as input to the command on the right.
* **`last`**: A built-in Linux tool that reads system logs (specifically `/var/log/wtmp`) and prints a list of everyone who has logged into the server.
* **`grep "$date_filter"`**: `grep` searches for text. It filters out only the lines that contain today's date.
* **`grep -v 'reboot'`**: The `-v` flag means *invert*. It REMOVES any lines that contain the word "reboot".
* **`head -n -1`**: The `last` command often prints "wtmp begins" at the very bottom. This removes that last line.
* **`>`**: The redirect operator. Instead of printing the result to the screen, we dump it into a temporary text file (`/tmp/last_temp.txt`).

**The While Loop:**
```bash
while read -r line; do
    user=$(echo "$line" | awk '{print $1}')
...
done < "/tmp/last_temp.txt"
```
* **`while read...`**: This loop reads our temporary text file line by line.
* **`awk '{print $1}'`**: `awk` is a powerful text processing tool. By default, it splits lines up by spaces. `$1` means "print the 1st word". `$2` is the second word, and `$NF` means "print the last word" (which happens to be where the duration like `(01:30)` sits).
* **`tr -d '()'`**: `tr` translates or deletes characters. Here we are deleting the parentheses from the duration.

---

## 4. Exporting to CSV (Lines 66-99)

A CSV (Comma-Separated Values) file is just a text file where columns are divided by commas. Excel can read these.

```bash
echo "Username,Terminal,Host,Day,Month,Date,Time,Duration" > "$full_csv_file"
```
* Using `>` creates (or overwrites) the file and pastes our column headers into it.

Inside the loop, we do the same `awk` splitting we learned above, but instead of formatted printing, we use commas and append (`>>`):
```bash
echo "$user,$term,$host,$day,$month,$date_num,$time_val,$duration" >> "$full_csv_file"
```
* **`>>` (Append)**: Unlike `>`, `>>` adds text to the *bottom* of an existing file without deleting what was already there. 

*(Note: We use an `if` statement to check if the user is logging in from a local server or remotely over the internet, because `last` shifts columns over if there is no IP address).*

---

## 5. Summary Analytics (Lines 101-107)

```bash
last | egrep -v "reboot|wtmp" | awk '{print $1}' | sort | uniq -c | sort -nr
```
This uses a classic Linux pipeline trick!
1. **`awk '{print $1}'`**: Gets just the usernames.
2. **`sort`**: Alphabetizes the list of usernames so that all identical usernames are grouped together.
3. **`uniq -c`**: Takes consecutive identical lines and collapses them into one line, placing a **count** (`-c`) next to them!
4. **`sort -nr`**: Sorts them numerically (`-n`) and in reverse order (`-r`). This puts the highest-logged-in user at the top (a leaderboard!).

---

## 6. Automation - Archiving using `tar` (Lines 111-120)

```bash
find "$REPORT_DIR" -type f -name "*.csv" -mtime +7 -exec tar -czvf "${ARCHIVE_DIR}/${archive_name}" {} + 
```
Instead of manually zipping files, we use automation:
* **`find ... -type f`**: Searches for **files**.
* **`-name "*.csv"`**: Looks specifically for CSV files.
* **`-mtime +7`**: Filters for files modified more than **7 days ago**.
* **`-exec ... {} +`**: For every old file found, run the `tar` command on it!
* **`tar -czvf`**: Archives files. `c` (create), `z` (compress with gzip), `v` (verbose/show progress), `f` (filename).

---

## 7. Automation - Rsync Over SSH (Lines 122-132)

```bash
rsync -avz -e ssh "$ARCHIVE_DIR/" "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DEST}"
```
* **`rsync`**: A tool designed to sync folders from your machine to another machine extremely efficiently.
* **`-avz`**: Archive mode (`a`), Verbose (`v`), and Compress data during the transfer (`z`).
* **`-e ssh`**: This tells `rsync` to use SSH (Secure Shell) to establish a secure, encrypted connection to the remote backup server. We are currently printing it as a "Dry Run" because actual servers need SSH Public Keys configured first.

---

## 8. Automation - Cron Scheduling (Lines 134-142)

`cron` is the Linux time-based job scheduler. It acts as a robot repeating tasks on a set schedule.
```bash
CRON_CMD="50 23 * * * ${WORK_DIR}/attendance.sh --auto >> ${WORK_DIR}/cron.log 2>&1"
```
* **`50 23 * * *`**: This is cron syntax meaning: Run at Minute 50, Hour 23 (11:50 PM), Every day, Every month, Every day-of-week.
* **`>> cron.log 2>&1`**: This silently collects all text output and error messages and puts them in `cron.log` out of sight.

```bash
(crontab -l 2>/dev/null | grep -v "attendance.sh"; echo "$CRON_CMD") | crontab -
```
* This grabs your current cron schedule (`crontab -l`), deletes any old versions of our script (`grep -v`), appends our new schedule (`echo "$CRON_CMD"`), and installs it back into the system (`crontab -`).

---

## 9. The Main Interactive Menu (Lines 155-195)

At the very bottom lies the central nervous system of the script.

```bash
while true; do
...
    read -p "Select an option [1-6]: " choice
    case $choice in
        1)
            generate_daily_attendance
            ;;
```
* **`while true`**: This is an infinite loop. It ensures the menu keeps showing up again after a command finishes, unless the user chooses to exit.
* **`case $choice in`**: Instead of a massive chain of `if/else`, Bash provides a `case` statement. If the user hits `1`, it runs the `generate_daily_attendance` block. If they press `6`, it runs `exit 0` which breaks out of the script cleanly. The `*)` is a wildcard that grabs any invalid input (like pressing '8' or 'X') and handles it nicely without crashing.
