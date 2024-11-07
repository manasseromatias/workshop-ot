from pymodbus.server.sync import StartTcpServer
from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
import random
import threading
import time

def update_modbus_data(context):
    while True:
        # Simulate sensor data
        temperature = int(random.uniform(200, 300))  # Temperature in tenths of degrees
        pressure = int(random.uniform(0, 100))       # Pressure in tenths of bar
        humidity = int(random.uniform(0, 1000))      # Humidity in tenths of %

        # Update holding registers with sensor data
        slave_id = 0x00  # Slave ID, 0x00 is the single slave in this case
        context[slave_id].setValues(3, 0, [temperature])
        context[slave_id].setValues(3, 1, [pressure])
        context[slave_id].setValues(3, 2, [humidity])

        # Print values to verify they are updating
        print(f"Updating values: Temperature={temperature}, Pressure={pressure}, Humidity={humidity}")

        time.sleep(1)  # Update every second

def run_plc_server():
    # Create Modbus datastore with initial values
    store = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, [0]*100),
        co=ModbusSequentialDataBlock(0, [0]*100),
        hr=ModbusSequentialDataBlock(0, [0]*100),
        ir=ModbusSequentialDataBlock(0, [0]*100)
    )
    context = ModbusServerContext(slaves=store, single=True)

    # Define server identity
    identity = ModbusDeviceIdentification()
    identity.VendorName = 'pymodbus'
    identity.ProductCode = 'PM'
    identity.VendorUrl = 'http://github.com/bashwork/pymodbus/'
    identity.ProductName = 'pymodbus Server'
    identity.ModelName = 'pymodbus Server'
    identity.MajorMinorRevision = '1.0'

    # Start the Modbus server on all network interfaces (0.0.0.0) and port 502
    server = threading.Thread(target=StartTcpServer, args=(context, identity, ("0.0.0.0", 502)))
    server.start()
    return context

if __name__ == "__main__":
    # Run the Modbus server and start updating data
    context = run_plc_server()
    update_thread = threading.Thread(target=update_modbus_data, args=(context,))
    update_thread.start()