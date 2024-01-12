import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LoginState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _errorMsg = '';
  String _username = '';
  String _namaLengkap = '';

  bool get isLoggedIn => _isLoggedIn;
  String get errorMsg => _errorMsg;
  String get username => _username;
  String get namaLengkap => _namaLengkap;

  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  WebSocketChannel? _webSocketChannel;

  Future<void> login(String username, String password) async {
    final url = 'http://192.168.43.235/flutter_login/php/login.php';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('error')) {
          // Login failed
          _isLoggedIn = false;
          _errorMsg = data['error'];
          _username = ''; // Reset the username on failed login
          _namaLengkap = ''; // Reset the namaLengkap on failed login
        } else {
          // Login successful
          _isLoggedIn = true;
          _errorMsg = '';
          _username = data['username'];
          _namaLengkap = data['nama_lengkap'];
        }
      } catch (e) {
        // If decoding as map fails, try decoding as a list
        final List<dynamic> dataList = json.decode(response.body);

        if (dataList.isNotEmpty && dataList[0].containsKey('error')) {
          // Login failed
          _isLoggedIn = false;
          _errorMsg = dataList[0]['error'] ?? '';
          _username = ''; // Reset the username on failed login
          _namaLengkap = ''; // Reset the namaLengkap on failed login
        } else if (dataList.isNotEmpty) {
          // Login successful
          _isLoggedIn = true;
          _errorMsg = '';
          _username = dataList[0]['username'] ?? '';
          _namaLengkap = dataList[0]['nama_lengkap'] ?? '';
        }
      }
    } else {
      // Error occurred during the HTTP request
      _isLoggedIn = false;
      _errorMsg = 'HTTP Error: ${response.statusCode}';
      _username = ''; // Reset the username on failed login
      _namaLengkap = ''; // Reset the namaLengkap on failed login
    }

    Future<void> connectToWebSocket() async {
      try {
        _webSocketChannel = IOWebSocketChannel.connect('ws://localhost:3000');
        print('WebSocket connected');
      } catch (e) {
        print('Error connecting to WebSocket: $e');
      }
    }

    notifyListeners();
  }

  void logout() {
    // Clear the username and password fields
    idController.clear();
    passController.clear();

    // Add any necessary cleanup or additional logic for logout
    _isLoggedIn = false;
    _errorMsg = '';
    _username = '';
    _namaLengkap = '';
    notifyListeners();

    _webSocketChannel?.sink.close();
  }
}