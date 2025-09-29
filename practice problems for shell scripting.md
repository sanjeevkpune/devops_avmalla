

## 🟢 Beginner Level

These problems focus on basic syntax, file operations, and control structures.

### 1. **File Organizer**
- **Task:** Write a script that scans a directory and moves files into folders based on their extensions (e.g., `.jpg` → `Images`, `.pdf` → `Documents`).
- **Skills:** `for` loop, `mv`, `mkdir`, `basename`, `if`

### 2. **Disk Usage Reporter**
- **Task:** Display disk usage of each subdirectory in a given path and sort them by size.
- **Skills:** `du`, `sort`, `awk`

### 3. **Simple Backup Script**
- **Task:** Create a script that backs up a folder to a timestamped archive file.
- **Skills:** `tar`, `date`, `echo`

### 4. **User Login Tracker**
- **Task:** Monitor and log user login events using `who` or `last`.
- **Skills:** `grep`, `date`, `echo`, redirection

---

## 🟡 Intermediate Level

These problems involve more logic, scheduling, and interaction with system tools.

### 5. **Log File Analyzer**
- **Task:** Parse a web server log file and count the number of requests per IP address.
- **Skills:** `awk`, `sort`, `uniq`, `cut`

### 6. **Automated Cleanup**
- **Task:** Delete files older than 30 days from a directory and log the deleted files.
- **Skills:** `find`, `-mtime`, `-exec`, logging

### 7. **System Health Check**
- **Task:** Create a script that checks CPU load, memory usage, and disk space, then sends an alert if thresholds are exceeded.
- **Skills:** `top`, `free`, `df`, conditional logic

### 8. **Cron Job Manager**
- **Task:** Write a script that lists all cron jobs for all users and saves them to a file.
- **Skills:** `crontab`, `grep`, `awk`, `sudo`

---

## 🔴 Advanced Level

These problems require deeper system knowledge, error handling, and integration.

### 9. **Parallel File Downloader**
- **Task:** Read a list of URLs from a file and download them in parallel using background processes.
- **Skills:** `wget`, `&`, `wait`, `xargs`

### 10. **Dynamic Firewall Rules**
- **Task:** Monitor failed SSH login attempts and block offending IPs using `iptables`.
- **Skills:** `grep`, `awk`, `iptables`, `cron`, `fail2ban` logic

### 11. **Git Auto-Deployer**
- **Task:** Create a script that watches a Git repo and automatically pulls changes and restarts a service when updates are detected.
- **Skills:** `git`, `systemctl`, `inotifywait`, `trap`

### 12. **Interactive Menu System**
- **Task:** Build a CLI menu that lets users choose between system tasks (e.g., view logs, restart services, check uptime).
- **Skills:** `select`, `case`, `functions`, `trap`

---
