import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screen/historical_alerts_screen.dart'; // Tu pantalla de historial/datos
import 'bluetooth_scanner_screen.dart';       // Tu pantalla de Bluetooth (asegúrate de que esté en la misma carpeta o ruta correcta)
import 'mqtt_service.dart';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitoreo IoT Híbrido',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 183, 58, 58),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 183, 58, 58),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainMenuScreen(), // Ahora inicia en el menú principal interactivo
    );
  }
}

// ==========================================
// 1. MENÚ PRINCIPAL INTERACTIVO
// ==========================================
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.4),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.hub, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Panel Sensor DHT11',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Selecciona tu modo de conexión',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Tarjetas de Opciones
                Expanded(
                  child: ListView(
                    children: [
                      // Opción MQTT / Red Local
                      _buildMenuCard(
                        context,
                        title: 'Monitoreo por MQTT (Wi-Fi)',
                        subtitle: 'Conexión local en tiempo real con Mosquitto y base de datos SQLite.',
                        icon: Icons.wifi,
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MqttDashboardContainer(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Opción Bluetooth HC-05
                      _buildMenuCard(
                        context,
                        title: 'Conexión Bluetooth (HC-05)',
                        subtitle: 'Enlace inalámbrico directo por puerto serial con tu ESP32.',
                        icon: Icons.bluetooth,
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BluetoothScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Center(
                  child: Text(
                    'Sistema de Adquisición de Datos IoT v2.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. CONTENEDOR PARA MQTT (Mantiene tu lógica previa)
// ==========================================
class MqttDashboardContainer extends StatefulWidget {
  const MqttDashboardContainer({super.key});

  @override
  State<MqttDashboardContainer> createState() => _MqttDashboardContainerState();
}

class _MqttDashboardContainerState extends State<MqttDashboardContainer> {
  final MqttService _mqttService = MqttService();

  @override
  void initState() {
    super.initState();
    _mqttService.conectarYEscuchar((temp, hum) async {
      print("Guardando en SQLite (MQTT) -> Temp: $temp°C, Hum: $hum%");

      await DatabaseHelper.instance.insertReading({
        'sensorType': 'temperature',
        'value': temp,
        'timestamp': DateTime.now().toIso8601String(),
        'nodeID': 1,
      });

      await DatabaseHelper.instance.insertReading({
        'sensorType': 'humidity',
        'value': hum,
        'timestamp': DateTime.now().toIso8601String(),
        'nodeID': 1,
      });

      globalRefreshNotifier.notifyListeners();
    });
  }

  @override
  void dispose() {
    _mqttService.desconectar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo MQTT (Wi-Fi)'),
        centerTitle: true,
      ),
      body: const HistoricalAlertsScreen(),
    );
  }
}