import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationFetcher {
  String _namaLengkap = '';
  int _rfidLocation = 0;
  String _scanDate = '';
  String _scanTime = '';

  String get namaLengkap => _namaLengkap;
  int get rfidLocation => _rfidLocation;
  String get scanDate => _scanDate;
  String get scanTime => _scanTime;

  static Future<List<Map<String, dynamic>>> fetchLocationData() async {
    const url = 'http://192.168.43.235/flutter_login/php/location.php';
    final response = await http.post(Uri.parse(url));

    if (response.statusCode == 200) {
      print('Response Body: ${response.body}');
      try {
        final dynamic data = json.decode(response.body);

        if (data is List<dynamic>) {
          // Handle the case where data is a List<dynamic>
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic> && data.containsKey('location_data')) {
          // Handle the case where data is a Map<String, dynamic> with 'location_data' key
          return (data['location_data'] as List<dynamic>).cast<Map<String, dynamic>>();
        } else {
          // Handle other cases or throw an error
          throw const FormatException('Invalid data format');
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
