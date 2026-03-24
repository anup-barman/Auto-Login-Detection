from flask import Flask, jsonify, request
from flask_cors import CORS
import sqlite3
import os

app = Flask(__name__)
CORS(app)

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'attendance.db')

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/stats', methods=['GET'])
def get_stats():
    try:
        conn = get_db_connection()
        users = conn.execute("SELECT COUNT(*) as count FROM users WHERE is_active = 1").fetchone()
        hours = conn.execute("SELECT SUM(total_hours) as sum FROM user_stats").fetchone()
        sessions = conn.execute("SELECT COUNT(*) as count FROM sessions").fetchone()
        conn.close()
        
        return jsonify({
            "total_users": users['count'] if users else 0,
            "total_hours": round(hours['sum'] or 0, 2),
            "total_sessions": sessions['count'] if sessions else 0
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/users', methods=['GET'])
def get_users():
    try:
        conn = get_db_connection()
        users = conn.execute("SELECT * FROM user_stats ORDER BY total_hours DESC").fetchall()
        conn.close()
        return jsonify([dict(u) for u in users])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/alerts', methods=['GET'])
def get_alerts():
    try:
        conn = get_db_connection()
        alerts = conn.execute("SELECT * FROM alerts ORDER BY created_at DESC LIMIT 50").fetchall()
        conn.close()
        return jsonify([dict(a) for a in alerts])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

import csv
import io
from flask import Response

@app.route('/api/export', methods=['GET'])
def export_csv():
    try:
        conn = get_db_connection()
        users = conn.execute("SELECT * FROM user_stats ORDER BY total_hours DESC").fetchall()
        conn.close()

        si = io.StringIO()
        cw = csv.writer(si)
        cw.writerow(['username', 'total_sessions', 'total_hours', 'last_login'])
        for u in users:
            cw.writerow([u['username'], u['total_sessions'], round(u['total_hours'], 2), u['last_login']])
        
        output = si.getvalue()
        return Response(output, mimetype='text/csv', headers={'Content-Disposition': 'attachment; filename=attendance_stats.csv'})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Start on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
