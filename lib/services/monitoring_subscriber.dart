import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTSubscriber {
  final logger = Logger('MQTTSubscriber');
  late MqttServerClient client;

  // Callback untuk update data
  final Function(Map<String, dynamic>) onDataReceived;

  MQTTSubscriber({required this.onDataReceived});

  Future<void> initialize() async {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    // Update broker address sesuai dengan IP server Anda
    const broker = '192.168.113.189';
    const port = 1883;

    client = MqttServerClient(broker, '')
      ..port = port
      ..keepAlivePeriod = 20
      ..logging(on: true)
      ..onDisconnected = onDisconnected
      ..onConnected = onConnected
      ..onSubscribed = onSubscribed;

    // Set up message handler
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          onDataReceived(data);
        }
      } catch (e) {
        logger.severe('Error parsing message: $e');
      }
    });

    try {
      logger.info('Connecting to broker...');
      await client.connect('try', 'try');
    } catch (e) {
      logger.severe('Connection failed: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      logger.info('Connected to broker!');
      client.subscribe('sensor/data', MqttQos.atMostOnce);
    } else {
      logger.severe(
          'Connection failed with status: ${client.connectionStatus?.state}');
      client.disconnect();
    }
  }

  void onConnected() {
    logger.info('Connected to MQTT broker');
  }

  void onDisconnected() {
    logger.info('Disconnected from MQTT broker');
  }

  void onSubscribed(String topic) {
    logger.info('Subscribed to topic: $topic');
  }

  void disconnect() {
    client.disconnect();
  }
}

// Fungsi main() yang dibutuhkan untuk menjalankan subscriber
void main() {
  // Callback ketika data diterima
  void onDataReceived(Map<String, dynamic> data) {
    print('Data diterima: $data');
  }

  // Membuat instance dari MQTTSubscriber dan menjalankan
  final mqttSubscriber = MQTTSubscriber(onDataReceived: onDataReceived);
  mqttSubscriber.initialize();
}
