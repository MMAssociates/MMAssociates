
import 'package:flutter/material.dart';
import 'package:mm_associates/features/home/screens/home_screen.dart';
import 'package:mm_associates/features/home/screens/venue_form.dart';
import 'package:mm_associates/features/user/services/user_service.dart';

class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  final UserService _userService = UserService();
  late Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState to prevent it from being called
    // on every rebuild.
    _isAdminFuture = _userService.isCurrentUserAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        // While waiting for the future to resolve, show a loading screen.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If there's an error, show the standard user screen for safety.
        if (snapshot.hasError) {
          debugPrint("Error in HomeGate FutureBuilder: ${snapshot.error}");
          // Show non-admin home screen, without the 'Add Venue' button.
          return const HomeScreen(showAddVenueButton: false);
        }

        final bool isAdmin = snapshot.data ?? false;

        if (isAdmin) {
          return const AddVenueFormScreen(isDirectAdminAccess: true);
        } else {
          return const HomeScreen(showAddVenueButton: false);
        }
      },
    );
  }
}