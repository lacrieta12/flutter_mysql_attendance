import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceFetcher {
  static Future<List<Map<String, dynamic>>> fetchAttendanceData(String namaLengkap) async {
    final url = 'http://192.168.43.235/flutter_login/php/attendance.php';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'nama_lengkap': namaLengkap,
        // Add any other necessary parameters
      },
    );

    if (response.statusCode == 200) {
      try {
        final dynamic data = json.decode(response.body);

        if (data is List<dynamic>) {
          // Handle the case where data is a List<dynamic>
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic> && data.containsKey('attendance_data')) {
          // Handle the case where data is a Map<String, dynamic> with 'attendance_data' key
          return (data['attendance_data'] as List<dynamic>).cast<Map<String, dynamic>>();
        } else {
          // Handle other cases or throw an error
          throw FormatException('Invalid data format');
        }
      } catch (e) {
        // Handle decoding errors
        throw FormatException('Error decoding response: $e');
      }
    } else {
      // Handle HTTP errors
      throw http.ClientException('HTTP Error: ${response.statusCode}');
    }
  }
}
