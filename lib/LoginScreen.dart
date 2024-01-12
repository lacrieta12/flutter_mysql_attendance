import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:login_attendance_mysql/Dashboard.dart';
import 'package:provider/provider.dart';
import 'LoginState.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color.fromARGB(255, 244, 112, 76);

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible =
        KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            isKeyboardVisible
                ? SizedBox(
                    height: screenHeight / 16,
                  )
                : Container(
                    height: screenHeight / 2.5,
                    width: screenWidth,
                    decoration: BoxDecoration(
                        color: primary,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(70),
                        )),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: screenWidth / 5,
                      ),
                    ),
                  ),
            Container(
              margin: EdgeInsets.only(
                top: screenHeight / 15,
                bottom: screenHeight / 20,
              ),
              child: Text(
                "Login",
                style: TextStyle(
                  fontSize: screenWidth / 18,
                  fontFamily: "NexaHeavy",
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Employee ID"),
                  customField("Enter your Employee ID", idController, false),
                  fieldTitle("Password"),
                  customField("Enter your Password", passController, true),
                  Container(
                    height: 60,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight / 40),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Get the LoginState using Provider
                          final loginState = Provider.of<LoginState>(context, listen: false);
                          
                          final username = idController.text;
                          final password = passController.text;
                          
                          await loginState.login(username, password);

                          if (loginState.isLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Dashboard()), // Pass loginState to Dashboard
                            );
                          } else {
                            // Display a custom dialog for invalid username/password
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Login Failed'),
                                  content: const Text('Invalid username or password. Please try again.'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        // Clear controllers and close the dialog
                                        loginState.logout();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "LOGIN",
                          style: TextStyle(
                            fontFamily: "NexaHeavy",
                            fontSize: screenWidth / 26,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth / 26,
          fontFamily: "NexaHeavy",
        ),
      ),
    );
  }

  Widget customField(
      String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth / 6,
            child: Icon(
              Icons.person,
              color: primary,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
