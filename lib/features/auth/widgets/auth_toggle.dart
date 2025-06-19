import 'package:flutter/material.dart';
import '../screens/signin_screen.dart';
import '../screens/signup_screen.dart';

class AuthToggle extends StatefulWidget {
  const AuthToggle({super.key});

  @override
  _AuthToggleState createState() => _AuthToggleState();
}

class _AuthToggleState extends State<AuthToggle> {
  bool showSignIn = true;

  void toggleScreens() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: showSignIn
           ? SignInScreen(showSignUpScreen: toggleScreens)
           : SignUpScreen(showSignInScreen: toggleScreens),
    );
  }
}