from flask import Flask, jsonify, render_template, request
from pymodbus.client.sync import ModbusTcpClient
import threading
import time
import logging
import json
from datetime import datetime

app = Flask(__name__)

# Configure logging
log_file = 'request_logs.json'
logging.basicConfig(filename=log_file, level=logging.INFO, format='%(message)s')

# Global variables for SCADA data
scada_data = {
    'temperature': 0,
    'pressure': 0,
    'humidity': 0
}

# Function to log requests and responses
def log_request(response):
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "remote_ip": request.remote_addr,
        "user_agent": request.headers.get("User-Agent"),
        "method": request.method,
        "endpoint": request.path,
        "status_code": response.status_code,
        "referer": request.headers.get("Referer"),
        "headers": dict(request.headers),
        "cookies": request.cookies,
        "query_parameters": request.args.to_dict(),
        "request_payload": request.get_json() if request.is_json else request.form.to_dict(),
        "response_payload": response.get_json() if response.is_json else response.get_data(as_text=True),
        "response_time_ms": response.response_time_ms if hasattr(response, 'response_time_ms') else None,
        "request_size_bytes": request.content_length,
        "response_size_bytes": len(response.get_data()),
    }
    
    # Write the log entry as a JSON line
    with open(log_file, 'a') as f:
        json.dump(log_entry, f)
        f.write('\n')  # New line for each log entry

    return response

@app.before_request
def start_timer():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    # Calculate response time in milliseconds
    response.response_time_ms = int((time.time() - request.start_time) * 1000)
    log_request(response)
    return response

def run_scada():
    client = ModbusTcpClient('192.168.1.35', port=502)
    client.connect()

    while True:
        try:
            # Read holding registers from the Modbus server
            temperature = client.read_holding_registers(0, 1).registers[0] / 10
            pressure = client.read_holding_registers(1, 1).registers[0] / 10
            humidity = client.read_holding_registers(2, 1).registers[0] / 10

            # Update global SCADA data
            scada_data['temperature'] = temperature
            scada_data['pressure'] = pressure
            scada_data['humidity'] = humidity

            time.sleep(1)
        except Exception as e:
            print(f"Error reading Modbus registers: {e}")
            break

# Flask routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/scada-data')
def get_scada_data():
    return jsonify(scada_data)

if __name__ == "__main__":
    # Run SCADA in a separate thread
    scada_thread = threading.Thread(target=run_scada)
    scada_thread.start()

    # Start Flask server
    app.run(host="0.0.0.0", port=80, debug=True)