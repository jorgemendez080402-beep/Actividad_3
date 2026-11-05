import 'package:flutter/material.dart'; 
import '../sensor_reading.dart';
import '../database_helper.dart';

// 🌐 Notificador global para avisar cuando hay nuevos datos desde MQTT
final ValueNotifier<void> globalRefreshNotifier = ValueNotifier<void>(null);
 
class HistoricalAlertsScreen extends StatefulWidget { 
  const HistoricalAlertsScreen({super.key});

  @override 
  _HistoricalAlertsScreenState createState() => _HistoricalAlertsScreenState(); 
} 
 
class _HistoricalAlertsScreenState extends State<HistoricalAlertsScreen> { 
  late Future<List<SensorReading>> _readingsFuture; 

  @override 
  void initState() { 
    super.initState(); 
    _refreshData(); 
    // Escuchamos el notificador global para recargar la pantalla automáticamente
    globalRefreshNotifier.addListener(_refreshData);
  } 

  @override
  void dispose() {
    globalRefreshNotifier.removeListener(_refreshData);
    super.dispose();
  }
 
  void _refreshData() { 
    setState(() { 
      // Obtenemos las lecturas guardadas en SQLite
      _readingsFuture = DatabaseHelper.instance.getAllReadings(); 
    }); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(
        title: const Text('Histórico de Alertas (Local)'),
      ), 
      body: FutureBuilder<List<SensorReading>>( 
        future: _readingsFuture, 
        builder: (context, snapshot) { 
          if (snapshot.connectionState == ConnectionState.waiting) { 
            return const Center(child: CircularProgressIndicator()); 
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) { 
            return const Center(
              child: Text('No hay registros guardados todavía.\nEsperando datos del ESP32...', textAlign: TextAlign.center),
            ); 
          } 
 
          final readings = snapshot.data!; 
          return ListView.builder( 
            itemCount: readings.length, 
            itemBuilder: (context, index) { 
              final item = readings[index]; 
              return ListTile( 
                leading: Icon(
                  Icons.thermostat, 
                  color: item.value > 35.0 ? const Color.fromARGB(255, 54, 73, 244) : Colors.orange,
                ), 
                title: Text('${item.sensorType.toUpperCase()}: ${item.value} °C'), 
                subtitle: Text('Fecha: ${item.timestamp}'), 
              ); 
            }, 
          ); 
        }, 
      ), 
    ); 
  } 
}