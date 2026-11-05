import 'dart:convert';
import 'package:http/http.dart' as http;

class ThingsboardService {
  Future<Map<String, dynamic>?> obtenerDatosThingsBoard(String tokenDispositivo) async {
try {
  final url = Uri.parse('https://thingsboard.cloud/api/plugins/telemetry/DEVICE/5c17c110-d349-11f1-9968-e99913795e0c/values/timeseries?keys=temperature,humidity');

      final respuesta = await http.get(url);
      // Agrega esto temporalmente justo cuando recibes la respuesta HTTP:
print("Respuesta cruda de ThingsBoard: ${respuesta.body}");
      
      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datos = json.decode(respuesta.body);
        
        // Validamos que 'temperature' y 'humidity' existan y no estén vacíos
        if (datos['temperature'] == null || (datos['temperature'] as List).isEmpty) {
          print('ThingsBoard respondió pero no hay datos de temperatura aún.');
          return null;
        }
        if (datos['humidity'] == null || (datos['humidity'] as List).isEmpty) {
          print('ThingsBoard respondió pero no hay datos de humedad aún.');
          return null;
        }

        double temp = double.parse(datos['temperature'][0]['value'].toString());
        double hum = double.parse(datos['humidity'][0]['value'].toString());
        int tiempo = datos['temperature'][0]['ts'];

        return {
          'temperature': temp,
          'humidity': hum,
          'timestamp': tiempo,
        };
      } else {
        print('Error en servidor ThingsBoard: ${respuesta.statusCode}');
      }
    } catch (e) {
      print('Excepción al conectar con ThingsBoard: $e');
    }
    return null;
  }
}