#!/bin/bash

# Update system
yum update -y

# Install Python & tools
yum install -y python3 git

# Install MySQL client (to connect RDS)
sudo dnf install mariadb105 -y

# Install pip packages
pip3 install flask mysql-connector-python flask-cors werkzeug python-dotenv gunicorn

# Create app directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Create .env file
cat <<EOF > .env
DB_HOST=database-1.c6dcmey4anws.us-east-1.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=Password!654321
DB_NAME=testdb
EOF

# Create Flask app
cat <<EOF > app.py
from flask import Flask, request, jsonify
import mysql.connector
import os
from flask_cors import CORS
from werkzeug.security import generate_password_hash

app = Flask(__name__)
CORS(app)

db_config = {
    "host": "database-1.c6dcmey4anws.us-east-1.rds.amazonaws.com",
    "user": "admin",
    "password": "Password!654321",
    "database": "testdb"
}

def init_db():
    conn = mysql.connector.connect(
        host=db_config["host"],
        user=db_config["user"],
        password=db_config["password"]
    )
    cursor = conn.cursor()

    # Create DB if not exists
    cursor.execute("CREATE DATABASE IF NOT EXISTS testdb")
    conn.commit()

    # Use DB
    conn.database = "testdb"

    # Create table if not exists
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(255) UNIQUE,
            password VARCHAR(255)
        )
    """)

    conn.commit()
    cursor.close()
    conn.close()

# Run at startup
init_db()

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()

    username = data.get('username')
    password = data.get('password')

    hashed_password = generate_password_hash(password)

    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        query = "INSERT INTO users (username, password) VALUES (%s, %s)"
        cursor.execute(query, (username, hashed_password))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Signup successful!"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Change ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

# Run app with Gunicorn (background)
cd /home/ec2-user/app
nohup gunicorn -w 4 -b 0.0.0.0:5000 app:app > app.log 2>&1 &