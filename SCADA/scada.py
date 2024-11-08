from flask import Flask, jsonify, render_template
#from pymodbus.client import ModbusTcpClient
from pymodbus.client.sync import ModbusTcpClient
import threading
import time

app = Flask(__name__)

# Variables globales para almacenar los datos del SCADA
scada_data = {
    'temperature': 0,
    'pressure': 0,
    'humidity': 0
}

def run_scada():
    client = ModbusTcpClient('192.168.1.35', port=502)
    client.connect()

    while True:
        try:
            # Leer los registros de holding (holding registers) desde el servidor
            temperature = client.read_holding_registers(0, 1).registers[0] / 10
            pressure = client.read_holding_registers(1, 1).registers[0] / 10
            humidity = client.read_holding_registers(2, 1).registers[0] / 10

            # Actualizar los valores globales
            scada_data['temperature'] = temperature
            scada_data['pressure'] = pressure
            scada_data['humidity'] = humidity

            time.sleep(1)
        except Exception as e:
            print(f"Error al leer registros Modbus: {e}")
            break

# Rutas de Flask
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/scada-data')
def get_scada_data():
    return jsonify(scada_data)

if __name__ == "__main__":
    # Correr SCADA en un hilo separado
    scada_thread = threading.Thread(target=run_scada)
    scada_thread.start()

    # Iniciar servidor Flask
#    app.run(debug=True)
    app.run(host="0.0.0.0", port=5000, debug=True)
