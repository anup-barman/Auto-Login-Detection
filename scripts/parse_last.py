import sys
import hashlib
from datetime import datetime

def process_log():
    lines = sys.stdin.readlines()
    print("BEGIN TRANSACTION;")
    
    for line in lines:
        parts = line.split()
        if len(parts) < 14: continue
        if parts[0] in ['reboot', 'root', 'wtmp', 'shutdown']: continue
        if 'logged' in line and 'in' in line: continue
        if 'crash' in line or 'down' in line or 'gone' in line: continue
        
        days = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'}
        date_start_idx = -1
        for i, p in enumerate(parts):
            if p in days:
                date_start_idx = i
                break
                
        if date_start_idx == -1 or date_start_idx >= len(parts) - 6:
            continue
            
        username = parts[0]
        
        # Check if there is an IP or if it's local
        if date_start_idx > 2:
            ip_address = parts[2]
        else:
            ip_address = "local"
        
        login_str = " ".join(parts[date_start_idx:date_start_idx+5])
        try:
            login_time = datetime.strptime(login_str, "%a %b %d %H:%M:%S %Y")
        except ValueError:
            continue
        
        dash_idx = date_start_idx + 5
        if dash_idx >= len(parts) or parts[dash_idx] != '-': continue
        
        logout_str = " ".join(parts[dash_idx+1:dash_idx+6])
        try:
            logout_time = datetime.strptime(logout_str, "%a %b %d %H:%M:%S %Y")
        except ValueError:
            continue
            
        dur_str = parts[-1].strip("()")
        if '+' in dur_str:
            d, t = dur_str.split('+')
            try:
                h, m = t.split(':')
                duration_minutes = int(d) * 1440 + int(h) * 60 + int(m)
            except ValueError:
                continue
        else:
            s = dur_str.split(':')
            if len(s) == 2:
                duration_minutes = int(s[0]) * 60 + int(s[1])
            else:
                duration_minutes = 0

        # Basic fraud detection: ignore sessions < 1 min or > 24 hours (1440 min)
        if duration_minutes < 1 or duration_minutes > 1440:
            # We can log this to alerts table later
            pass

        session_id = hashlib.md5(f"{username}{login_time.isoformat()}".encode()).hexdigest()
        
        print(f"INSERT OR IGNORE INTO users (username) VALUES ('{username}');")
        print(f"INSERT OR IGNORE INTO sessions (id, username, ip_address, login_time, logout_time, duration_minutes) "
              f"VALUES ('{session_id}', '{username}', '{ip_address}', '{login_time.isoformat()}', '{logout_time.isoformat()}', {duration_minutes});")
              
    print("COMMIT;")

if __name__ == "__main__":
    process_log()
