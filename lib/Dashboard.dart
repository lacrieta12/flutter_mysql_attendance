import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_attendance_mysql/AttendanceFetcher.dart';
import 'package:login_attendance_mysql/LoginScreen.dart';
import 'package:login_attendance_mysql/LoginState.dart';
import 'package:login_attendance_mysql/last_location.dart';
import 'package:login_attendance_mysql/profile_page.dart';
import 'package:login_attendance_mysql/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:collection/collection.dart';

class WebSocketManager {
  late WebSocketChannel _channel;
  StreamController<String>? _streamController;
  List<Map<String, dynamic>> _attendanceData = [];
  List<Map<String, dynamic>> _locationData = [];
  bool isClosedManually = false;
  LoginState? _loginState;

  WebSocketManager(String url) {
    _channel = IOWebSocketChannel.connect(url);
    _setupWebSocket();
  }

  WebSocketChannel get channel => _channel;

  StreamController<String> get streamController {
    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<String>();
    }
    return _streamController!;
  }

  List<Map<String, dynamic>> get attendanceData => _attendanceData;
  List<Map<String, dynamic>> get locationData => _locationData;

  // New method to expose location data
  List<Map<String, dynamic>> getLocationData() {
    return _locationData;
  }

  List<Map<String, dynamic>> getAttendanceData() {
    return _attendanceData;
  }

  // Use StreamController to manage location data updates
  StreamController<List<Map<String, dynamic>>> _locationDataController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get locationDataStream => _locationDataController.stream;

  StreamController<List<Map<String, dynamic>>> _attendanceDataController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get attendanceDataStream => _attendanceDataController.stream;

  void _setupWebSocket() {
    _channel.stream.listen(
      (message) {
        final Map<String, dynamic> data = json.decode(message);
        if (data['type'] == 'attendanceUpdate') {
          _attendanceData = List<Map<String, dynamic>>.from(data['data']);
          _attendanceDataController.add(_attendanceData);
          streamController.add(message);
        } else if (data['type'] == 'locationUpdate') {
          _locationData = List<Map<String, dynamic>>.from(data['data']);
          // Add this line to update the location data stream
          _locationDataController.add(_locationData);
          streamController.add(message);
        }
      },
      onDone: () {
        if (_loginState?.isLoggedIn == true) {
          if(!isClosedManually) {
            // WebSocket closed (client disconnected), attempt reconnection
            print('WebSocket closed. Attempting to reconnect...');
            Future.delayed(const Duration(seconds: 1), () {
              // _channel = IOWebSocketChannel.connect('ws://localhost:3000');
              _setupWebSocket();
            });
          }
        else {
          _channel.sink.close();
        }
        }
      },
      onError: (error) {
        // Handle WebSocket errors
        print('WebSocket error: $error');
      },
      cancelOnError: true,
    );
    _streamController?.close();
  }

  void close() {
    isClosedManually = true;
    _channel.sink.close();
    _streamController?.close();
  }
}


class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  LoginState? _loginState;
  List<Map<String, dynamic>> _attendanceData = [];
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    _loginState = Provider.of<LoginState>(context, listen: false);
    // Use the WebSocketManager from the provider
    WebSocketManager webSocketManager = Provider.of<WebSocketManager>(context, listen: false);

    // Use the WebSocketManager passed from the main.dart file
    channel = webSocketManager.channel;

    // Fetch initial attendance data
    if (_loginState?.isLoggedIn == true) {
      fetchAttendanceData(_loginState!);
    }

    // Listen to the locationDataStream and update the UI
    webSocketManager.attendanceDataStream.listen((attendanceData) {
      // Update UI with the new locationData
      setState(() {
        _attendanceData = attendanceData;
        print('Received Attendance Data: $_attendanceData');
      });
    });
  }

  @override
  void dispose() {
    // If the user is logged out, close the WebSocket connection
    if (_loginState?.isLoggedIn == false) {
      channel.sink.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Sidebar(
        onTapDashboard: () {
          Navigator.pop(context); // Close the sidebar
        },
        onTapProfile: () {
          Navigator.pop(context); // Close the sidebar
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        },
        onTapLocation: () {
          Navigator.pop(context); // Close the sidebar
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LastLocation()));
        },
        onTapLogout: () {
          Navigator.pop(context); // Close the sidebar
          _showLogoutConfirmation(context);
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Welcome, ${_loginState?.username}!'),
            Text('Nama Lengkap: ${_loginState?.namaLengkap}'),
            _buildAttendanceInfo(),
            ElevatedButton(
              onPressed: () {
                _showLogoutConfirmation(context);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button for close popup
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the popup
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Perform logout and close the popup
                _loginState?.logout();
                Navigator.of(context).pop();
                // Navigate to the login screen
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceInfo() {
    if (_attendanceData.isNotEmpty) {
      // Check if there is attendance data for today
      bool isPresentToday = _attendanceData.any((attendance) => isToday(attendance['attendance_date']));

      if (isPresentToday) {
        // User is present today
        // Separate attendance data into in and out times based on time ranges
        var inAttendance = _attendanceData.firstWhereOrNull((attendance) {
          bool isTodayData = isToday(attendance['attendance_date']);
          int hour = parseHour(attendance['attendance_time']);

          print('Checking inAttendance condition: isTodayData=$isTodayData, hour=$hour');
          return isTodayData && hour >= 5 && hour < 12;
        });

        var outAttendance = _attendanceData.firstWhereOrNull((attendance) {
          bool isTodayData = isToday(attendance['attendance_date']);
          int hour = parseHour(attendance['attendance_time']);

          print('Checking outAttendance condition: isTodayData=$isTodayData, hour=$hour');
          return isTodayData && hour >= 15 && hour < 21;
        });

        // Display in and out attendance times along with the date
        String inDate = inAttendance != null ? formatDate(inAttendance['attendance_date']) : 'Not available';
        String inTime = inAttendance != null ? formatTime(inAttendance['attendance_time']) : 'Not available';

        String outDate = outAttendance != null ? formatDate(outAttendance['attendance_date']) : 'Not available';
        String outTime = outAttendance != null ? formatTime(outAttendance['attendance_time']) : 'Not available';

        print('In Attendance: $inDate $inTime');
        print('Out Attendance: $outDate $outTime');

        return Column(
          children: [
            Text('Today\'s In Attendance: $inDate $inTime'),
            Text('Today\'s Out Attendance: $outDate $outTime'),
          ],
        );
      } else {
        // User is absent today
        return const Text('Today\'s Attendance: Absent');
      }
    } else {
      // No attendance data available
      return const Text('No attendance data available. Absent.');
    }
  }

  int parseHour(String time) {
    try {
      return int.parse(time.split(':')[0]);
    } catch (e) {
      return 0;
    }
  }

  bool isToday(String? date) {
    final now = DateTime.now();
    final parsedDate = DateTime.tryParse(date ?? '');
    return parsedDate != null &&
        parsedDate.year == now.year &&
        parsedDate.month == now.month &&
        parsedDate.day == now.day;
  }

  String formatDate(String? date) {
    final parsedDate = DateTime.tryParse(date ?? '');
    return parsedDate != null ? DateFormat('MMMM dd, yyyy').format(parsedDate) : 'Not available';
  }

  String formatTime(String? time) {
    return time ?? 'Not available';
  }

  Future<void> fetchAttendanceData(LoginState loginState) async {
    try {
      List<Map<String, dynamic>> attendanceData =
          await AttendanceFetcher.fetchAttendanceData(loginState.namaLengkap);
      setState(() {
        _attendanceData = attendanceData;
      });
      print('Attendance Data: $_attendanceData');
    } catch (e) {
      print('Error fetching attendance data: $e');
      // Handle errors
    }
  }
}
