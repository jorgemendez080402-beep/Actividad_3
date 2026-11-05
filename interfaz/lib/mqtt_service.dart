import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MqttService {
  late MqttServerClient client;

  Future<void> conectarYEscuchar(Function(double temp, double hum) onDataReceived) async {
    // Configura la IP de tu broker Mosquitto (ej. 'localhost' o la IP de tu servidor/PC)
    client = MqttServerClient('localhost', 'flutter_desktop_app');
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterWindowsClient')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      print('Conectando a Mosquitto MQTT...');
      await client.connect();
    } catch (e) {
      print('Error de conexión MQTT: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('¡Conectado exitosamente al broker MQTT!');
      
      // Suscríbete al mismo tópico que usa tu ESP32
      const topic = 'v1/devices/me/telemetry'; // O el tópico personalizado que maneje tu Mosquitto
      client.subscribe(topic, MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        
        print('Datos recibidos: $payload');

        try {
          // Parsear el JSON recibido del ESP32: {"temperature":22.7,"humidity":62.0}
          final data = jsonDecode(payload);
          double temp = double.parse(data['temperature'].toString());
          double hum = double.parse(data['humidity'].toString());

          // Llamar a la función para guardar en SQLite
          onDataReceived(temp, hum);
        } catch (e) {
          print('Error al parsear el JSON: $e');
        }
      });
    } else {
      print('Fallo en la conexión, estado: ${client.connectionStatus!.state}');
    }
  }

  void desconectar() {
    client.disconnect();
  }
}