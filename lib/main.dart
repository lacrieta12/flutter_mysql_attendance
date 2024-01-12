import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:login_attendance_mysql/Dashboard.dart';
import 'package:login_attendance_mysql/LoginScreen.dart';
import 'package:login_attendance_mysql/LoginState.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LoginState(),
      child: KeyboardVisibilityProvider(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      home: Builder(
        builder: (context) {
          LoginState loginState = Provider.of<LoginState>(context, listen: false);

          return Navigator(
            pages: [
              // Always start with the LoginScreen
              MaterialPage(
                child: LoginScreen(),
              ),
              // If logged in, navigate to Dashboard
              if (loginState.isLoggedIn)
                MaterialPage(
                  child: Dashboard(),
                ),
            ],
            onPopPage: (route, result) {
              // Handle page popping if needed
              // Return true if the page is popped
              return false;
            },
          );
        },
      ),
    );
  }
}

