// import 'package:flutter/material.dart';
// import '../services/auth_service.dart'; // Ensure this path is correct
// import 'dart:async';

// // If your AuthService throws FirebaseAuthException, you'd uncomment this and use it
// // import 'package:firebase_auth/firebase_auth.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final AuthService _authService = AuthService();
//   bool _isLoading = false;
//   String? _errorMessage;
//   String? _successMessage;

//   // --- Static variable to store the cooldown end time ---
//   static DateTime? _cooldownEndTime;
//   // --- End static variable ---

//   bool _isButtonDisabled = false;
//   int _countdownSeconds = 60; // Default, will be overridden if cooldown active
//   Timer? _uiUpdateTimer; // Renamed from _timer for clarity

//   final FocusNode _emailFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _checkAndResumeCooldown();
//   }

//   void _checkAndResumeCooldown() {
//     if (_cooldownEndTime != null && _cooldownEndTime!.isAfter(DateTime.now())) {
//       final remainingDuration = _cooldownEndTime!.difference(DateTime.now());
//       if (remainingDuration.inSeconds > 0) {
//         if (!mounted) return;
//         setState(() {
//           _isButtonDisabled = true;
//           _countdownSeconds = remainingDuration.inSeconds;
//         });
//         _startUiUpdateTimer(initialSeconds: _countdownSeconds);
//       } else {
//         // Cooldown might have just expired between navigations
//         _cooldownEndTime = null;
//         _isButtonDisabled = false; // Ensure button is enabled
//       }
//     } else {
//       _cooldownEndTime = null; // Clear if expired or not set
//       _isButtonDisabled = false; // Ensure button is enabled initially if no cooldown
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _uiUpdateTimer?.cancel();
//     _emailFocusNode.dispose();
//     super.dispose();
//   }

//   void _startUiUpdateTimer({int initialSeconds = 60}) {
//     if (!mounted) return;
//     // Ensure _isButtonDisabled is true when timer starts
//     // and _countdownSeconds is set to the initial value for the display.
//     setState(() {
//       _isButtonDisabled = true;
//       _countdownSeconds = initialSeconds;
//     });

//     _uiUpdateTimer?.cancel(); // Cancel any existing timer
//     _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       setState(() {
//         if (_countdownSeconds > 0) {
//           _countdownSeconds--;
//         } else {
//           _uiUpdateTimer?.cancel();
//           _isButtonDisabled = false;
//           _cooldownEndTime = null; // Cooldown finished, clear the global state
//         }
//       });
//     });
//   }

//   Future<void> _sendResetLink() async {
//     // Check against the global cooldown first
//     if (_cooldownEndTime != null && _cooldownEndTime!.isAfter(DateTime.now())) {
//        // Optionally show a message: "Please wait for cooldown to finish"
//       return;
//     }
//     // Then check local state (isLoading, _isButtonDisabled should ideally reflect global)
//     if (_isButtonDisabled || !mounted || _isLoading) return;


//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//     _emailFocusNode.unfocus();

//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _successMessage = null;
//     });

//     final String email = _emailController.text.trim();

//     try {
//       await _authService.sendPasswordResetEmail(email);

//       if (mounted) {
//         // --- Set the global cooldown end time ---
//         _cooldownEndTime = DateTime.now().add(const Duration(seconds: 60));
//         // --- End set global ---

//         _startUiUpdateTimer(initialSeconds: 60); // Start local UI timer with full duration
//         _formKey.currentState?.reset();

//         setState(() {
//           _successMessage = 'Password reset link sent! Please check your email (including spam folder).';
//           _isLoading = false;
//         });

//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Password reset link sent!'),
//                 backgroundColor: Colors.green,
//                 behavior: SnackBarBehavior.floating,
//                 margin: EdgeInsets.all(10),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
//               ),
//             );
//           }
//         });
//       }
//     } catch (e, s) {
//       if (mounted) {
//         debugPrint("Error sending password reset link: $e\nStack trace: $s");
//         String displayMessage;
//         final errorString = e.toString().toLowerCase();

//         if (errorString.contains('user-not-found') || errorString.contains('no user record')) {
//             displayMessage = 'No account found with this email. Please check the email or sign up.';
//         } else if (errorString.contains('invalid-email') || errorString.contains('malformed')) {
//             displayMessage = 'The email address provided is not valid. Please enter a valid email.';
//         } else if (errorString.contains('network') || errorString.contains('socket') || errorString.contains('host lookup') || errorString.contains('timeout')) {
//             displayMessage = 'Could not connect. Please check your internet connection and try again.';
//         } else if (errorString.contains('too-many-requests')) {
//             displayMessage = 'Too many requests. Please wait a moment and try again.';
//              // If this error happens, we should respect it and start a cooldown
//             _cooldownEndTime = DateTime.now().add(const Duration(seconds: 60)); // Or based on API hint
//             _startUiUpdateTimer(initialSeconds: 60);
//         }
//         else {
//             displayMessage = 'An unexpected error occurred. Please try again later.';
//             debugPrint("Original error for unhandled case: $e");
//         }
//         setState(() {
//           _errorMessage = displayMessage;
//           _isLoading = false;
//           // Do not re-enable button if "too-many-requests" just triggered a cooldown
//           if (!errorString.contains('too-many-requests')) {
//              _isButtonDisabled = false; // Re-enable button on other errors
//              _cooldownEndTime = null; // Clear any previous cooldown if error wasn't 'too-many-requests'
//           }
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);

//     Widget forgotPasswordFormContent = Form(
//       key: _formKey,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const Icon(Icons.lock_reset_outlined, size: 60, color: Colors.orangeAccent),
//           const SizedBox(height: 20),
//           const Text(
//             'Forgot Your Password?',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 15),
//           Text(
//             'Enter your account email address below and we\'ll send you a link to reset your password.',
//             style: TextStyle(fontSize: 15, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 30),

//           TextFormField(
//             controller: _emailController,
//             focusNode: _emailFocusNode,
//             decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
//             keyboardType: TextInputType.emailAddress,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             textInputAction: TextInputAction.done,
//             onFieldSubmitted: (_) => _sendResetLink(),
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) return 'Please enter your email';
//               if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value.trim())) {
//                 return 'Please enter a valid email address';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 25),

//           if (_errorMessage != null && _errorMessage!.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 15.0),
//               child: Text(
//                 _errorMessage!,
//                 style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//           if (_successMessage != null && _successMessage!.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 15.0),
//               child: Text(
//                 _successMessage!,
//                 style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//           if (_isLoading)
//             const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: CircularProgressIndicator()))
//           else
//             ElevatedButton(
//               onPressed: _isButtonDisabled ? null : _sendResetLink, // The local _isButtonDisabled is key here
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 disabledBackgroundColor: Colors.orange.withOpacity(0.5),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//               ),
//               child: Text(
//                 _isButtonDisabled ? 'Resend in $_countdownSeconds s' : 'Send Reset Link',
//                 style: const TextStyle(fontSize: 16, color: Colors.white),
//               ),
//             ),
          
//           if (_successMessage != null && _successMessage!.isNotEmpty && !_isLoading)
//             Padding(
//               padding: const EdgeInsets.only(top: 12.0),
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (Navigator.canPop(context)) {
//                     Navigator.pop(context);
//                   } else {
//                     Navigator.pushReplacementNamed(context, '/login'); 
//                   }
//                 },
//                 style: ElevatedButton.styleFrom( 
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//                 child: const Text(
//                   'Back to Login',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),
//           const SizedBox(height: 20), 
//         ],
//       ),
//     );

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reset Password'),
//       ),
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 400),
//               decoration: BoxDecoration(
//                 color: theme.cardColor,
//                 borderRadius: BorderRadius.circular(16.0),
//                 border: Border.all(
//                   color: theme.dividerColor.withOpacity(0.5),
//                   width: 1.0,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 12.0,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(15.0),
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(24.0),
//                   child: forgotPasswordFormContent,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // It's good practice to import this for specific exceptions

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  static DateTime? _cooldownEndTime;

  bool _isButtonDisabled = false;
  int _countdownSeconds = 60;
  Timer? _uiUpdateTimer;

  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkAndResumeCooldown();
  }
  
  // UNCHANGED (Helper methods)
  void _checkAndResumeCooldown() {
    if (_cooldownEndTime != null && _cooldownEndTime!.isAfter(DateTime.now())) {
      final remainingDuration = _cooldownEndTime!.difference(DateTime.now());
      if (remainingDuration.inSeconds > 0) {
        if (!mounted) return;
        setState(() {
          _isButtonDisabled = true;
          _countdownSeconds = remainingDuration.inSeconds;
        });
        _startUiUpdateTimer(initialSeconds: _countdownSeconds);
      } else {
        _cooldownEndTime = null;
        _isButtonDisabled = false;
      }
    } else {
      _cooldownEndTime = null;
      _isButtonDisabled = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _uiUpdateTimer?.cancel();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _startUiUpdateTimer({int initialSeconds = 60}) {
    if (!mounted) return;
    setState(() {
      _isButtonDisabled = true;
      _countdownSeconds = initialSeconds;
    });

    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _uiUpdateTimer?.cancel();
          _isButtonDisabled = false;
          _cooldownEndTime = null;
        }
      });
    });
  }

  Future<void> _sendResetLink() async {
    // UNCHANGED (Validation and setup logic)
    if (_cooldownEndTime != null && _cooldownEndTime!.isAfter(DateTime.now())) {
      return;
    }
    if (_isButtonDisabled || !mounted || _isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }
    _emailFocusNode.unfocus();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final String email = _emailController.text.trim();
    
    // --- START OF MODIFIED SECTION ---
    try {
      await _authService.sendPasswordResetEmail(email);

      if (mounted) {
        _cooldownEndTime = DateTime.now().add(const Duration(seconds: 60));
        _startUiUpdateTimer(initialSeconds: 60);
        _formKey.currentState?.reset();

        setState(() {
          _successMessage = 'Password reset link sent! Please check your email (including spam folder).';
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset link sent!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            );
          }
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;

      debugPrint("Error sending password reset link: $e");
      String displayMessage;

      // This logic provides a cleaner mapping from the exception to a user-friendly message.
      if (e is FirebaseAuthException) {
        // Use the specific FirebaseAuthException codes for better messages
        switch (e.code) {
          case 'user-not-found':
            displayMessage = 'No account found with this email. Please check the email or sign up.';
            break;
          case 'invalid-email':
            displayMessage = 'The email address provided is not valid.';
            break;
          case 'too-many-requests':
            displayMessage = 'Too many requests. Please wait a moment and try again.';
            _cooldownEndTime = DateTime.now().add(const Duration(seconds: 60));
            _startUiUpdateTimer(initialSeconds: 60);
            break;
          default:
            displayMessage = 'An unexpected error occurred. Please try again.';
            break;
        }
      } else {
        // Fallback for generic exceptions from your service layer or elsewhere
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('network') || errorString.contains('socket') || errorString.contains('host lookup')) {
            displayMessage = 'Could not connect. Please check your internet connection.';
        } else {
            // A generic fallback that doesn't expose internal error strings.
            displayMessage = 'An unexpected error occurred. Please try again later.';
        }
      }
      
      setState(() {
        _errorMessage = displayMessage;
        _isLoading = false;
        if (!_isButtonDisabled) { // Only re-enable button if a cooldown wasn't just triggered
          _cooldownEndTime = null;
        }
      });
    }
    // --- END OF MODIFIED SECTION ---
  }
  
  // UNCHANGED (The entire build method remains the same)
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget forgotPasswordFormContent = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset_outlined, size: 60, color: Colors.orangeAccent),
          const SizedBox(height: 20),
          const Text(
            'Forgot Your Password?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Enter your account email address below and we\'ll send you a link to reset your password.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetLink(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your email';
              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 25),

          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          if (_successMessage != null && _successMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: CircularProgressIndicator()))
          else
            ElevatedButton(
              onPressed: _isButtonDisabled ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.orange.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _isButtonDisabled ? 'Resend in $_countdownSeconds s' : 'Send Reset Link',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          
          if (_successMessage != null && _successMessage!.isNotEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // This fallback may need adjustment based on your app's routing setup
                    // Navigator.pushReplacementNamed(context, '/login'); 
                  }
                },
                style: ElevatedButton.styleFrom( 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 20), 
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: forgotPasswordFormContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}