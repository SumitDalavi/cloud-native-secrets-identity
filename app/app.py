from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def db_status():
    db_user = os.environ.get('DB_USERNAME', 'unknown')
    db_pass = os.environ.get('DB_PASSWORD', 'unknown')
    
    status = "Connected" if db_user != 'unknown' and db_pass != 'unknown' else "Disconnected"
    
    # Never log actual passwords in production! This is just for demonstration.
    return jsonify({
        "status": status,
        "database_user": db_user,
        "secrets_injected_successfully": db_user != 'unknown'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
