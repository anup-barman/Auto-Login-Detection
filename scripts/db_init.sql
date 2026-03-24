CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    is_active INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    username TEXT,
    ip_address TEXT,
    login_time DATETIME,
    logout_time DATETIME,
    duration_minutes INTEGER,
    FOREIGN KEY(username) REFERENCES users(username)
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT,
    alert_type TEXT,
    message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(username) REFERENCES users(username)
);

CREATE VIEW IF NOT EXISTS user_stats AS
SELECT 
    username,
    COUNT(id) as total_sessions,
    SUM(duration_minutes) / 60.0 as total_hours,
    MAX(login_time) as last_login
FROM sessions
GROUP BY username;
