import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_options.dart';
import 'features/auth/widgets/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Add these imports for Crashlytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher; // Needed for PlatformDispatcher

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint(".env file loaded");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // --- START Crashlytics Setup ---
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // Return true to indicate that the error has been handled.
      // This prevents it from being processed further by default error handlers
      // which might print to console or cause the app to exit depending on the error.
      return true;
    };
    // --- END Crashlytics Setup ---

    debugPrint("Firebase initialized successfully."); // Good to confirm initialization

  } catch (e) {
    // If Firebase initialization itself fails, Crashlytics might not be ready,
    // so we print the error and show a FirebaseErrorApp.
    // Crashlytics might still catch this if the native setup part was successful
    // and the error happens after the very initial native Firebase core setup.
    print('Failed to initialize Firebase: $e');
    FirebaseCrashlytics.instance.recordError(
        e, StackTrace.current,
        reason: 'Failed to initialize Firebase in main.dart',
        fatal: true
    );
    runApp(const FirebaseErrorApp());
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secrets Of Sports',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.indigo,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Failed to initialize Firebase.\nPlease ensure you have followed the setup instructions and placed the configuration files correctly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}