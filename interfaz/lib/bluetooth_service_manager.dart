import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'database_helper.dart'; 
import 'screen/historical_alerts_screen.dart'; 

class BluetoothServiceManager {
  BluetoothConnection? connection;
  String _buffer = ""; // 👈 Buffer para acumular los fragmentos que lleguen

  Future<void> connectToDevice(BluetoothDevice device, BuildContext context) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado exitosamente a ${device.name}')),
      );

      connection!.input!.listen(_onDataReceived).onDone(() {
        print('Conexión Bluetooth desconectada por el dispositivo');
      });
    } catch (exception) {
      print('No se pudo conectar al dispositivo: $exception');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el HC-05')),
      );
    }
  }

  void _onDataReceived(Uint8List data) async {
    String incomingMessage = ascii.decode(data);
    _buffer += incomingMessage; // Acumulamos el texto que va llegando

    // Buscamos si ya tenemos un objeto JSON completo (delimitado por llaves { ... })
    while (_buffer.contains('}') ) {
      int startIndex = _buffer.indexOf('{');
      int endIndex = _buffer.indexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        // Extraemos el JSON completo
        String jsonString = _buffer.substring(startIndex, endIndex + 1);
        
        // Limpiamos el buffer quitando lo que ya procesamos
        _buffer = _buffer.substring(endIndex + 1);

        try {
          Map<String, dynamic> jsonData = jsonDecode(jsonString);

          double temp = double.parse(jsonData['temperature'].toString());
          double hum = double.parse(jsonData['humidity'].toString());

          // 1. Guardar Temperatura en SQLite
          await DatabaseHelper.instance.insertReading({
            'sensorType': 'temperature',
            'value': temp,
            'timestamp': DateTime.now().toIso8601String(),
            'nodeID': 1,
          });

          // 2. Guardar Humedad en SQLite
          await DatabaseHelper.instance.insertReading({
            'sensorType': 'humidity',
            'value': hum,
            'timestamp': DateTime.now().toIso8601String(),
            'nodeID': 1,
          });

          // 3. Refrescar la interfaz
          globalRefreshNotifier.notifyListeners();
          print("¡JSON completo procesado, guardado en SQLite y UI actualizada!");

        } catch (e) {
          print("Error al parsear JSON fragmentado: $e");
        }
      } else {
        break;
      }
    }
  }

  void disconnect() {
    connection?.finish();
  }
}