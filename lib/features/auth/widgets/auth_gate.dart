// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import 'auth_toggle.dart';
// import '../../home/screens/home_screen.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AuthService authService = AuthService();

//     return StreamBuilder<User?>(
//       stream: authService.authStateChanges,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (snapshot.hasError) {
//           debugPrint('AuthGate Stream Error: ${snapshot.error}');
//           return const Scaffold(
//             body: Center(child: Text('Authentication Error. Please restart the app.')),
//           );
//         }

//         if (snapshot.hasData) {
//           final user = snapshot.data!;

//           bool isEmailPasswordProvider = user.providerData.any((providerInfo) => providerInfo.providerId == 'password');

//           if (isEmailPasswordProvider && !user.emailVerified) {
//             debugPrint("AuthGate: User is Email/Password but NOT verified. Routing to AuthToggle.");
//             return const AuthToggle();
//           } else {
//             debugPrint("AuthGate: User logged in (Verified Email/Pass or Google). Routing to HomeScreen.");
//             return const HomeScreen();
//           }

//         } else {
//           debugPrint("AuthGate: User is logged out. Routing to AuthToggle.");
//           return const AuthToggle();
//         }
//       },
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_toggle.dart';
// import '../../home/screens/home_screen.dart'; // <<< REMOVED THIS OLD IMPORT
import '../../home/screens/home_gate.dart';   // <<< ADDED THIS NEW IMPORT

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('AuthGate Stream Error: ${snapshot.error}');
          return const Scaffold(
            body: Center(child: Text('Authentication Error. Please restart the app.')),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          bool isEmailPasswordProvider = user.providerData.any((providerInfo) => providerInfo.providerId == 'password');

          if (isEmailPasswordProvider && !user.emailVerified) {
            debugPrint("AuthGate: User is Email/Password but NOT verified. Routing to AuthToggle.");
            return const AuthToggle();
          } else {
            // <<< THIS IS THE ONLY CHANGE REQUIRED >>>
            // Instead of going directly to HomeScreen, we go to HomeGate.
            // HomeGate will then check if the user is an admin and show the correct screen.
            debugPrint("AuthGate: User logged in. Routing to HomeGate to check role.");
            return const HomeGate();
          }

        } else {
          debugPrint("AuthGate: User is logged out. Routing to AuthToggle.");
          return const AuthToggle();
        }
      },
    );
  }
}