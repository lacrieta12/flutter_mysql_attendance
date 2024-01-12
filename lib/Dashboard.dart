import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_attendance_mysql/AttendanceFetcher.dart';
import 'package:login_attendance_mysql/LoginState.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:collection/collection.dart';


class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  LoginState? _loginState;
  List<Map<String, dynamic>> _attendanceData = [];
  late WebSocketChannel channel;
  bool isClosedManually = false;

  @override
void initState() {
  super.initState();
  _loginState = Provider.of<LoginState>(context, listen: false);

  // Initialize WebSocket channel
  channel = IOWebSocketChannel.connect('ws://localhost:3000');

  // Handle WebSocket events
  channel.stream.listen(
    (message) {
      final Map<String, dynamic> data = json.decode(message);
      if (data['type'] == 'attendanceUpdate') {
        setState(() {
          _attendanceData = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    },
    onDone: () {
      if (!isClosedManually) {
        // WebSocket closed (client disconnected), attempt reconnection
        print('WebSocket closed. Attempting to reconnect...');
        Future.delayed(Duration(seconds: 5), () {
          // Attempt reconnection after a delay (adjust as needed)
          channel = IOWebSocketChannel.connect('ws://localhost:3000');
          setupWebSocket();
        });
      }
    },
    onError: (error) {
      // Handle WebSocket errors
      print('WebSocket error: $error');
    },
    cancelOnError: true,
  );

  // Fetch initial attendance data
  if (_loginState?.isLoggedIn == true) {
    fetchAttendanceData(_loginState!);
  }
}

void setupWebSocket() {
  // Setup WebSocket events after reconnecting
  channel.stream.listen(
    (message) {
      final Map<String, dynamic> data = json.decode(message);
      if (data['type'] == 'attendanceUpdate') {
        setState(() {
          _attendanceData = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    },
    onDone: () {
      if (!isClosedManually) {
        // WebSocket closed (client disconnected), attempt reconnection
        print('WebSocket closed. Attempting to reconnect...');
        Future.delayed(Duration(seconds: 5), () {
          // Attempt reconnection after a delay (adjust as needed)
          channel = IOWebSocketChannel.connect('ws://localhost:3000');
          setupWebSocket();
        });
      }
    },
    onError: (error) {
      // Handle WebSocket errors
      print('WebSocket error: $error');
    },
    cancelOnError: true,
  );
}

  @override
  void dispose() {
    isClosedManually = true;
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
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
                _loginState?.logout();
                Navigator.pop(context);
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
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
        return Text('Today\'s Attendance: Absent');
      }
    } else {
      // No attendance data available
      return Text('No attendance data available. Absent.');
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
