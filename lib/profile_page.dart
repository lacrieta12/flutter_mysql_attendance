import 'package:flutter/material.dart';
import 'package:login_attendance_mysql/Dashboard.dart';
import 'package:login_attendance_mysql/LoginScreen.dart';
import 'package:login_attendance_mysql/LoginState.dart';
import 'package:login_attendance_mysql/last_location.dart';
import 'package:login_attendance_mysql/sidebar.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  LoginState? _loginState;

  @override
  void initState() {
    super.initState();
    // Get the LoginState using Provider
    _loginState = Provider.of<LoginState>(context, listen: false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      drawer: Sidebar(
        onTapDashboard: () {
          Navigator.pop(context); // Close the sidebar
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboard()));
        },
        onTapProfile: () {
          Navigator.pop(context); // Close the sidebar
        },
        onTapLocation: () {
          Navigator.pop(context); // Close the sidebar
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LastLocation()));
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
            Text('Profile Page Content'),
            _buildUserInfo(),
            // Add other profile-related content here
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (_loginState != null) {
      return Column(
        children: [
          Text('Name: ${_loginState!.namaLengkap}'),
          Text('ID: ${_loginState!.id}'),
          Text('Title: ${_loginState!.title}'),
        ],
      );
    } else {
      return Text('User information not available');
    }
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
}
