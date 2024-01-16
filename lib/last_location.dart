import 'package:flutter/material.dart';
import 'package:login_attendance_mysql/Dashboard.dart';
import 'package:login_attendance_mysql/Location_fetcher.dart';
import 'package:login_attendance_mysql/LoginScreen.dart';
import 'package:login_attendance_mysql/LoginState.dart';
import 'package:login_attendance_mysql/profile_page.dart';
import 'package:login_attendance_mysql/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';


class LastLocation extends StatefulWidget {
  const LastLocation({Key? key}) : super(key: key);

  @override
  _LastLocationState createState() => _LastLocationState();
}

class _LastLocationState extends State<LastLocation> {
  LoginState? _loginState;
  List<Map<String, dynamic>> _locationData = [];
  late WebSocketChannel channel;

  // List of names to filter
  final List<String> filteredNames = ["Bapak A", "Ibu B", "Bapak C", "Ibu D"];

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
      fetchLocationData();
    }

    // Listen to the locationDataStream and update the UI
    webSocketManager.locationDataStream.listen((locationData) {
      // Update UI with the new locationData
      setState(() {
        _locationData = locationData.where((item) => filteredNames.contains(item['nama_lengkap'])).toList();
        print('Received Location Data: $_locationData');
      });
    });
  }

  void updateLocationData(Map<String, dynamic> newData) {
    if (filteredNames.contains(newData['nama_lengkap'])) {
      String newDataDate = newData['scan_date'];
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (newDataDate == currentDate) {
        setState(() {
          int index = _locationData.indexWhere(
            (item) => item['nama_lengkap'] == newData['nama_lengkap']
          );

          if (index != -1) {
            _locationData[index] = newData;
          } else {
            _locationData.add(newData);
          }
        });

        print('Updated Location Data: $_locationData');
      }
    }
  }

  Future<void> fetchLocationData() async {
    try {
      List<Map<String, dynamic>> locationData =
          await LocationFetcher.fetchLocationData();
      
      // Get today's date in the 'yyyy-MM-dd' format
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      setState(() {
        // Filter location data based on the list of names and today's date
        _locationData = locationData
            .where((item) =>
                filteredNames.contains(item['nama_lengkap']) &&
                item['scan_date'] == todayDate)
            .toList();
      });

      print('Location Data: $_locationData');
    } catch (e) {
      print('Error fetching location data: $e');
      // Handle errors
    }
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
        title: const Text('Last location'),
      ),
      drawer: Sidebar(
        onTapDashboard: () {
          Navigator.pop(context); // Close the sidebar
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboard()));
        },
        onTapProfile: () {
          Navigator.pop(context); // Close the sidebar
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        },
        onTapLocation: () {
          Navigator.pop(context); // Close the sidebar
        },
        onTapLogout: () {
          Navigator.pop(context); // Close the sidebar
          _showLogoutConfirmation(context);
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Last location page'),
            // Add other profile-related content here
            _buildLocationTable()
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

  Widget _buildLocationTable() {
    // Get today's date in the 'yyyy-MM-dd' format
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    List<DataRow> dataRows = filteredNames.map<DataRow>((name) {
      // Find location data for the current name in the filtered list and today's date
      var location = _locationData.firstWhere(
        (item) =>
            item['nama_lengkap'] == name && item['scan_date'] == todayDate,
        orElse: () => <String, dynamic>{},
      );

      return DataRow(
        cells: [
          DataCell(Text(name)),
          DataCell(Text(location.isNotEmpty ? 'Present' : 'Absent')),
          DataCell(location.isNotEmpty
              ? Text('Floor ${location['rfid_location'] ?? '-'}')
              : const Text('-')),
          DataCell(location.isNotEmpty
              ? Text('${location['scan_date'] ?? '-'} ${location['scan_time'] ?? '-'}')
              : const Text('-')),
        ],
      );
    }).toList();

    return DataTable(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Last Seen')),
      ],
      rows: dataRows,
    );
  }
}