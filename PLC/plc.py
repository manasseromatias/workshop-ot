from pymodbus.server.sync import StartTcpServer
from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
import random
import threading
import time

def update_modbus_data(context):
    while True:
        # Simulando datos de sensores
        temperature = int(random.uniform(200, 300))  # Temperatura en décimas de grado
        pressure = int(random.uniform(0, 100))       # Presión en décimas de bar
        humidity = int(random.uniform(0, 1000))      # Humedad en décimas de %

        # Obtener el contexto esclavo (slave) y actualizar los registros de retención
        slave_id = 0x00  # Identificador del esclavo, 0x00 es el esclavo único en este caso
        context[slave_id].setValues(3, 0, [temperature])
        context[slave_id].setValues(3, 1, [pressure])
        context[slave_id].setValues(3, 2, [humidity])

        # Imprimir los valores para verificar que se están actualizando
        print(f"Actualizando valores: Temperatura={temperature}, Presión={pressure}, Humedad={humidity}")

        time.sleep(1)  # Actualizar cada segundo

def run_plc_server():
    store = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, [0]*100),
        co=ModbusSequentialDataBlock(0, [0]*100),
        hr=ModbusSequentialDataBlock(0, [0]*100),
        ir=ModbusSequentialDataBlock(0, [0]*100)
    )
    context = ModbusServerContext(slaves=store, single=True)

    identity = ModbusDeviceIdentification()
    identity.VendorName = 'pymodbus'
    identity.ProductCode = 'PM'
    identity.VendorUrl = 'http://github.com/bashwork/pymodbus/'
    identity.ProductName = 'pymodbus Server'
    identity.ModelName = 'pymodbus Server'
    identity.MajorMinorRevision = '1.0'

    # Iniciar el servidor Modbus en la IP 192.168.1.35 y puerto 502
    server = threading.Thread(target=StartTcpServer, args=(context, identity, ("192.168.1.35", 502)))
    server.start()
    return context

if __name__ == "__main__":
    context = run_plc_server()
    update_thread = threading.Thread(target=update_modbus_data, args=(context,))
    update_thread.start()