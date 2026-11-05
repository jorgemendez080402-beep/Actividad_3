class SensorReading {
  final int? id;
  final String sensorType;
  final double value;
  final String timestamp;
  final int nodeId;

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.timestamp,
    required this.nodeId,
  });

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'],
      sensorType: map['sensorType'],
      value: map['value'],
      timestamp: map['timestamp'],
      nodeId: map['nodeId'],
    );
  }
}