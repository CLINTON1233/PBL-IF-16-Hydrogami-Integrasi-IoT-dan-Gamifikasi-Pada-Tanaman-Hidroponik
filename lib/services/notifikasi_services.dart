import 'package:mysql1/mysql1.dart';
import 'package:logging/logging.dart';

class NotificationService {
  static MySqlConnection? _connection;
  static final _logger = Logger('NotificationService');

  static Future<void> initializeDB() async {
    final settings = ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: 'root',
        password: '',
        db: 'db3_hydro');

    try {
      _connection = await MySqlConnection.connect(settings);
      _logger.info('Database connected successfully');
    } catch (e) {
      _logger.severe('Failed to connect to database: $e');
    }
  }

  static Future<void> closeConnection() async {
    await _connection?.close();
  }

  static String generateMessage(String sensorType, double value) {
    switch (sensorType) {
      case 'Suhu':
        if (value < 10) {
          return 'Suhu terlalu rendah ($value°C). Naikkan suhu untuk mencegah kerusakan tanaman.';
        }
        if (value > 40) {
          return 'Suhu terlalu tinggi ($value°C). Turunkan suhu untuk mencegah stress pada tanaman.';
        }
        if (value >= 15 && value <= 20 || value >= 30 && value <= 35) {
          return 'Suhu mendekati batas ideal ($value°C). Pertahankan suhu antara 19-25°C.';
        }
        break;

      case 'TDS':
        if (value < 300) {
          return 'Kadar nutrisi terlalu rendah ($value ppm). Tambahkan nutrisi segera.';
        }
        if (value > 2000) {
          return 'Kadar nutrisi terlalu tinggi ($value ppm). Encerkan larutan nutrisi.';
        }
        if (value >= 500 && value <= 700 || value >= 1500 && value <= 2000) {
          return 'Kadar nutrisi mendekati batas ($value ppm). Sesuaikan untuk mencapai 800-1500 ppm.';
        }
        break;

      case 'PH':
        if (value < 4.5) {
          return 'pH terlalu asam ($value). Tambahkan larutan pH up.';
        }
        if (value > 10.5) {
          return 'pH terlalu basa ($value). Tambahkan larutan pH down.';
        }
        if (value >= 5.0 && value <= 5.5 || value >= 6.5 && value <= 7.0) {
          return 'pH mendekati batas ideal ($value). Pertahankan pH antara 5.5-6.5.';
        }
        break;

      case 'Kelembaban Tanah':
        if (value == 0.0 || value < 0 || value > 1000) {
          return 'Sensor kelembaban tanah mendeteksi nilai tidak normal ($value%). Periksa sensor.';
        }
        if (value >= 300 && value <= 400 || value >= 70 && value <= 80) {
          return 'Kelembaban tanah mendekati batas ($value%). Sesuaikan irigasi.';
        }
        break;

      case 'Kelembaban Udara':
        if (value < 30) {
          return 'Kelembaban udara terlalu rendah ($value%). Tingkatkan kelembaban.';
        }
        if (value > 90) {
          return 'Kelembaban udara terlalu tinggi ($value%). Kurangi kelembaban.';
        }
        if (value >= 40 && value <= 50 || value >= 80 && value <= 90) {
          return 'Kelembaban udara mendekati batas ($value%). Pertahankan antara 60-75%.';
        }
        break;

      case 'Intensitas Cahaya':
        if (value < 1000) {
          return 'Intensitas cahaya terlalu rendah ($value Lux). Tambahkan pencahayaan.';
        }
        if (value > 50000) {
          return 'Intensitas cahaya terlalu tinggi ($value Lux). Kurangi pencahayaan.';
        }
        if (value >= 2000 && value <= 5000 ||
            value >= 30000 && value <= 40000) {
          return 'Intensitas cahaya mendekati batas ($value Lux). Sesuaikan ke 10000-25000 Lux.';
        }
        break;
    }
    return '';
  }

  static String determineStatus(String sensorType, double value) {
    switch (sensorType) {
      case 'Suhu':
        if (value < 10 || value > 40) {
          return 'Bahaya';
        }
        if ((value >= 15 && value <= 20) || (value >= 30 && value <= 35)) {
          return 'Perlu Penyesuaian';
        }
        if (value >= 19 && value <= 25) {
          return 'Optimal';
        }
        break;
      case 'TDS':
        if (value < 300 || value > 2000) {
          return 'Bahaya';
        }
        if ((value >= 500 && value <= 700) ||
            (value >= 1500 && value <= 2000)) {
          return 'Perlu Penyesuaian';
        }
        if (value >= 800 && value <= 1500) {
          return 'Optimal';
        }
        break;
      case 'PH':
        if (value < 4.5 || value > 10.5) {
          return 'Bahaya';
        }
        if ((value >= 5.0 && value <= 5.5) || (value >= 6.5 && value <= 7.0)) {
          return 'Perlu Penyesuaian';
        }
        if (value >= 5.5 && value <= 6.5) {
          return 'Optimal';
        }
        break;
      case 'Kelembaban Tanah':
        if (value == 0.0 || value < 0 || value > 1000) {
          return 'Bahaya';
        }
        if ((value >= 300 && value <= 400) || (value >= 70 && value <= 80)) {
          return 'Perlu Penyesuaian';
        }
        if (value >= 500 && value <= 900) {
          return 'Optimal';
        }
        break;
      case 'Kelembaban Udara':
        if (value < 30 || value > 90) {
          return 'Bahaya';
        }
        if ((value >= 40 && value <= 50) || (value >= 80 && value <= 90)) {
          return 'Perlu Penyesuaian';
        }
        if (value >= 60 && value <= 75) {
          return 'Optimal';
        }
        break;
      case 'Intensitas Cahaya':
        if (value < 1000 || value > 50000) {
          return 'Bahaya';
        }
        if ((value >= 2000 && value <= 5000) ||
            (value >= 30000 && value <= 40000)) {
          return 'Perlu Penyesuaian';
        }
        if (value >= 10000 && value <= 25000) {
          return 'Optimal';
        }
        break;
    }
    return 'Normal';
  }

  static Future<void> addNotification(String sensorType, double value) async {
    if (_connection == null) {
      await initializeDB();
    }

    String message = generateMessage(sensorType, value);
    String status = determineStatus(sensorType, value);

    if (message.isNotEmpty && status != 'Normal' && status != 'Optimal') {
      try {
        await _connection?.query(
            'INSERT INTO notifikasi (pesan, tipe_sensor, nilai_sensor, status) VALUES (?, ?, ?, ?)',
            [message, sensorType, value, status]);
      } catch (e) {
        _logger.severe('Failed to add notification: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_connection == null) {
      await initializeDB();
    }

    try {
      final results = await _connection
          ?.query('SELECT * FROM notifikasi ORDER BY waktu DESC');

      return results
              ?.map((row) => {
                    'message': row['pesan'],
                    'time': row['waktu'],
                    'status': row['status'],
                    'is_read': row['is_read'],
                  })
              .toList() ??
          [];
    } catch (e) {
      _logger.severe('Failed to get notifications: $e');
      return [];
    }
  }
}
