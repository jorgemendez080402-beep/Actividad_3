import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import '../bluetooth_service_manager.dart'; 
import 'screen/historical_alerts_screen.dart'; // Asegúrate de que la ruta de importación sea correcta según tu proyecto

class BluetoothScannerScreen extends StatefulWidget {
  const BluetoothScannerScreen({super.key});

  @override
  _BluetoothScannerScreenState createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends State<BluetoothScannerScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isConnecting = false;
  final BluetoothServiceManager _btManager = BluetoothServiceManager();

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  // Obtener la lista de dispositivos ya vinculados (como tu HC-05)
  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print("Error al obtener dispositivos vinculados: $e");
    }

    setState(() {
      _devices = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar HC-05 (Bluetooth)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Asegúrate de haber emparejado el HC-05 previamente en los ajustes de Bluetooth de tu Android (PIN: 1234).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(
                    child: Text('No hay dispositivos Bluetooth vinculados.'),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = _devices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Colors.orangeAccent, size: 28),
                          title: Text(device.name ?? "Dispositivo desconocido", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(device.address),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Conectar'),
                            onPressed: _isConnecting
                                ? null
                                : () async {
                                    setState(() {
                                      _isConnecting = true;
                                    });
                                    
                                    // 1. Nos conectamos al HC-05 mediante el manager
                                    await _btManager.connectToDevice(device, context);
                                    
                                    setState(() {
                                      _isConnecting = false;
                                    });

                                    // 2. Si la conexión fue exitosa, saltamos automáticamente a la pantalla de historial de datos
                                    if (_btManager.connection != null && _btManager.connection!.isConnected) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              title: const Text('Monitoreo en Vivo (Bluetooth)'),
                                              centerTitle: true,
                                            ),
                                            body: const HistoricalAlertsScreen(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isConnecting)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}