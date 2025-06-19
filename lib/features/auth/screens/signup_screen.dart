import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Ensure this path is correct

class SignUpScreen extends StatefulWidget {
  final VoidCallback showSignInScreen;

  const SignUpScreen({super.key, required this.showSignInScreen});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- NEW: FocusNodes ---
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  // --- END NEW ---

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // --- NEW: Dispose FocusNodes ---
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    // --- END NEW ---
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }
    if (!RegExp(r'[!@#\$%^&*()_+=\-[\]{};'':"\\|,.<>\/?~`]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  Future<void> _signUp() async {
    // FocusScope.of(context).unfocus(); // No longer needed here
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      // setState(() { _errorMessage = 'Please fix the errors above.'; }); // Optional, as fields show errors
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUpWithEmailPassword(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign up successful! Please check your email (including spam) to verify your account before signing in.',
              style: TextStyle(fontSize: 15),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
        widget.showSignInScreen();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget signUpFormContent = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Your Account',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode, // --- NEW ---
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next, // --- NEW ---
            onFieldSubmitted: (_) { // --- NEW ---
              FocusScope.of(context).requestFocus(_emailFocusNode);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                  return 'Please enter a valid name';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode, // --- NEW ---
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next, // --- NEW ---
            onFieldSubmitted: (_) { // --- NEW ---
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return 'Please enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode, // --- NEW ---
            obscureText: _obscurePassword,
            decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() { _obscurePassword = !_obscurePassword; });
                  },
                ),
                helperText: 'Min 8 chars, upper, lower, digit, symbol',
                helperMaxLines: 2,
                helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next, // --- NEW ---
            onFieldSubmitted: (_) { // --- NEW ---
              FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
            },
            validator: _validatePassword,
          ),
          const SizedBox(height: 15),

            TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode, // --- NEW ---
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() { _obscureConfirmPassword = !_obscureConfirmPassword; });
                  },
                ),
              ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done, // --- NEW ---
            onFieldSubmitted: (_) => _signUp(), // --- NEW ---
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                  return 'Passwords do not match';
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

          _isLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ))
              : ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
          const SizedBox(height: 20),

          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                TextButton(
                  onPressed: _isLoading ? null : widget.showSignInScreen,
                  child: const Text('Sign In'),
                ),
              ],
          ),
        ],
      ),
    );


    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
              ),
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
                  child: signUpFormContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // For PhoneAuthCredential, FirebaseAuthException
// import '../services/auth_service.dart'; // Ensure this path is correct

// // Enum to manage the different stages of the OTP and sign-up process
// enum OtpVerificationStep {
//   enterPhoneNumber, // User enters name, email, phone number
//   enterOtp,         // User enters OTP
//   phoneVerified,    // Phone is verified, user can set password and complete sign-up
// }

// class SignUpScreen extends StatefulWidget {
//   final VoidCallback showSignInScreen;

//   const SignUpScreen({super.key, required this.showSignInScreen});

//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   // --- NEW: Phone and OTP ---
//   final _phoneController = TextEditingController();
//   final _otpController = TextEditingController();
//   // --- END NEW ---

//   final AuthService _authService = AuthService();
//   bool _isLoading = false; // General loading for the whole screen action
//   String? _errorMessage;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   final FocusNode _nameFocusNode = FocusNode();
//   final FocusNode _emailFocusNode = FocusNode();
//   // --- NEW: Phone and OTP FocusNodes ---
//   final FocusNode _phoneFocusNode = FocusNode();
//   final FocusNode _otpFocusNode = FocusNode();
//   // --- END NEW ---
//   final FocusNode _passwordFocusNode = FocusNode();
//   final FocusNode _confirmPasswordFocusNode = FocusNode();

//   // --- NEW: State for OTP Flow ---
//   OtpVerificationStep _currentStep = OtpVerificationStep.enterPhoneNumber;
//   String? _verificationIdForSignUp; // Stores verification ID from AuthService
//   PhoneAuthCredential? _phoneAuthCredential; // Stores credential after OTP verification

//   bool _isSendingOtp = false;     // Specific loading state for sending OTP
//   bool _isVerifyingOtp = false;   // Specific loading state for verifying OTP
//   // --- END NEW ---

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _phoneController.dispose(); // --- NEW ---
//     _otpController.dispose();   // --- NEW ---

//     _nameFocusNode.dispose();
//     _emailFocusNode.dispose();
//     _phoneFocusNode.dispose(); // --- NEW ---
//     _otpFocusNode.dispose();   // --- NEW ---
//     _passwordFocusNode.dispose();
//     _confirmPasswordFocusNode.dispose();
//     super.dispose();
//   }

//   void _setLoading(bool loading) {
//     if (mounted) {
//       setState(() {
//         _isLoading = loading;
//       });
//     }
//   }

//   void _setErrorMessage(String? message) {
//      if (mounted) {
//       setState(() {
//         _errorMessage = message;
//       });
//     }
//   }

//   void _showSuccessSnackbar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message, style: const TextStyle(fontSize: 15)),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 5),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(10),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
//         ),
//       );
//     }
//   }

//   String? _validatePassword(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter a password';
//     }
//     if (value.length < 8) {
//       return 'Password must be at least 8 characters long';
//     }
//     if (!RegExp(r'[A-Z]').hasMatch(value)) {
//       return 'Password must contain at least one uppercase letter';
//     }
//     // ... (rest of your password validations from original code)
//     if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain at least one lowercase letter';
//     if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain at least one digit';
//     if (!RegExp(r'[!@#\$%^&*()_+=\-[\]{};'':"\\|,.<>\/?~`]').hasMatch(value)) return 'Password must contain at least one special character';
//     return null;
//   }

//   String? _validatePhoneNumber(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Please enter your phone number';
//     }
//     final pattern = r'^\+?[1-9]\d{1,14}$'; // Basic E.164-like pattern
//     final regExp = RegExp(pattern);
//     if (!regExp.hasMatch(value.trim())) {
//       return 'Enter a valid number with country code (e.g., +14155552671)';
//     }
//     return null;
//   }

//   // --- Action: Send OTP ---
//   Future<void> _handleSendOtp() async {
//     FocusScope.of(context).unfocus();
//     if (!_formKey.currentState!.validate()) { // Validates name, email, phone
//       _setErrorMessage("Please correct the errors above.");
//       return;
//     }
//     if (_isSendingOtp || _isLoading) return;

//     setState(() {
//       _isSendingOtp = true;
//       _isLoading = true; // Use general loader for now or a specific one for the button
//       _errorMessage = null;
//     });

//     try {
//       await _authService.sendOtpForSignUpProcess(
//         phoneNumber: _phoneController.text.trim(),
//         onVerificationCompleted: (PhoneAuthCredential credential) async {
//           // This callback is mainly for Android auto-retrieval.
//           if (mounted) {
//             _setErrorMessage(null); // Clear any previous error
//              _showSuccessSnackbar("Phone number auto-verified!");
//             setState(() {
//               _phoneAuthCredential = credential;
//               _otpController.text = credential.smsCode ?? ""; // Pre-fill OTP if available
//               _currentStep = OtpVerificationStep.phoneVerified; // Directly to verified
//               _isSendingOtp = false;
//               _isLoading = false;
//             });
//              _passwordFocusNode.requestFocus();
//           }
//         },
//         onVerificationFailed: (FirebaseAuthException e) {
//           if (mounted) {
//             setState(() {
//               _errorMessage = "OTP Send Failed: ${e.message}";
//               _isSendingOtp = false;
//               _isLoading = false;
//             });
//           }
//         },
//         onCodeSent: (String verificationId, int? resendToken) {
//           if (mounted) {
//              _showSuccessSnackbar("OTP sent to ${_phoneController.text.trim()}");
//             setState(() {
//               _verificationIdForSignUp = verificationId;
//               _currentStep = OtpVerificationStep.enterOtp;
//               _isSendingOtp = false;
//               _isLoading = false;
//             });
//             _otpFocusNode.requestFocus();
//           }
//         },
//         onCodeAutoRetrievalTimeout: (String verificationId) {
//           // You might want to update _verificationIdForSignUp here if it wasn't set by codeSent
//           // or inform the user. For now, we mainly rely on codeSent.
//           debugPrint("OTP auto-retrieval timed out. Verification ID: $verificationId");
//            if (mounted && _currentStep != OtpVerificationStep.enterOtp) { // If codeSent hasn't moved us already
//                _verificationIdForSignUp = verificationId;
//            }
//         },
//       );
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString().replaceFirst('Exception: ', '');
//           _isSendingOtp = false;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   // --- Action: Verify OTP ---
//   Future<void> _handleVerifyOtp() async {
//     FocusScope.of(context).unfocus();
//     if (_otpController.text.trim().isEmpty || _otpController.text.trim().length != 6) {
//       _setErrorMessage("Please enter the 6-digit OTP.");
//       _otpFocusNode.requestFocus();
//       return;
//     }
//     if (_verificationIdForSignUp == null) {
//       _setErrorMessage("Verification process error. Please try sending OTP again.");
//       setState(() => _currentStep = OtpVerificationStep.enterPhoneNumber);
//       return;
//     }
//     if (_isVerifyingOtp || _isLoading) return;

//     setState(() {
//       _isVerifyingOtp = true;
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final credential = await _authService.verifyOtpAndGetCredentialForSignUpProcess(
//         _otpController.text.trim(),
//       );
//       if (mounted) {
//         _showSuccessSnackbar("Phone number verified successfully!");
//         setState(() {
//           _phoneAuthCredential = credential;
//           _currentStep = OtpVerificationStep.phoneVerified;
//           _isVerifyingOtp = false;
//           _isLoading = false;
//         });
//         _passwordFocusNode.requestFocus();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString().replaceFirst('Exception: ', '');
//           _isVerifyingOtp = false;
//           _isLoading = false;
//         });
//         if (e.toString().contains("session-expired") || e.toString().contains("invalid-verification-id")){
//           setState(() {
//             _currentStep = OtpVerificationStep.enterPhoneNumber;
//              _verificationIdForSignUp = null; // Reset for resend
//           });
//         }
//       }
//     }
//   }


//   // --- Action: Complete Sign Up (after phone is verified) ---
//   Future<void> _completeSignUp() async {
//     FocusScope.of(context).unfocus();
//     if (_isLoading) return;

//     if (_currentStep != OtpVerificationStep.phoneVerified || _phoneAuthCredential == null) {
//       _setErrorMessage("Please verify your phone number first.");
//       // Guide user back if they somehow bypassed UI flow
//       if(_currentStep == OtpVerificationStep.enterPhoneNumber) _phoneFocusNode.requestFocus();
//       else if (_currentStep == OtpVerificationStep.enterOtp) _otpFocusNode.requestFocus();
//       return;
//     }

//     // Validate all fields now (name, email, phone should be valid, now password too)
//     if (!_formKey.currentState!.validate()) {
//       _setErrorMessage('Please fix the errors above.');
//       return;
//     }

//     _setLoading(true);
//     _setErrorMessage(null);

//     try {
//       // 1. Create email/password user
//       final newUser = await _authService.signUpWithEmailPassword(
//         _nameController.text.trim(),
//         _emailController.text.trim(),
//         _passwordController.text,
//         phoneNumberForRecord: _phoneController.text.trim(),
//       );

//       if (newUser == null) {
//         throw Exception("User account creation failed. Please try again.");
//       }

//       // 2. Link the verified phone credential to the newly created user
//       await _authService.linkOrUpdatePhoneForCurrentUser(_phoneAuthCredential!);

//       if (mounted) {
//          _showSuccessSnackbar('Sign up successful! Phone linked. Please check your email to verify your account.');
//         widget.showSignInScreen();
//       }

//     } catch (e) {
//       if (mounted) {
//         _setErrorMessage(e.toString().replaceFirst('Exception: ', ''));
//         // If email/password user was created but phone linking failed
//         if (_authService.getCurrentUser() != null && e.toString().contains("link")) {
//           debugPrint("SignUp Error: User created, but phone linking failed. Signing out user.");
//           await _authService.signOut(); // Sign out partially created user
//           _setErrorMessage("Account partly created, but phone linking failed. User signed out. Please try again. Error: ${e.toString().replaceFirst('Exception: ', '')}");
//           setState(() { // Reset phone verification state to allow retry
//             _phoneAuthCredential = null;
//             _currentStep = OtpVerificationStep.enterPhoneNumber; // Or keep them at phoneVerified to retry linking without re-entering details? For now, full reset.
//           });
//         }
//       }
//     } finally {
//       _setLoading(false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);

//     Widget formActionButton;
//     String actionButtonText = "";

//     if (_currentStep == OtpVerificationStep.enterPhoneNumber) {
//       actionButtonText = 'Send OTP';
//       formActionButton = ElevatedButton(
//         onPressed: _isLoading || _isSendingOtp ? null : _handleSendOtp,
//         style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
//         child: _isSendingOtp ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(actionButtonText, style: const TextStyle(fontSize: 16)),
//       );
//     } else if (_currentStep == OtpVerificationStep.enterOtp) {
//       actionButtonText = 'Verify OTP';
//       formActionButton = ElevatedButton(
//         onPressed: _isLoading || _isVerifyingOtp ? null : _handleVerifyOtp,
//         style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
//         child: _isVerifyingOtp ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(actionButtonText, style: const TextStyle(fontSize: 16)),
//       );
//     } else { // OtpVerificationStep.phoneVerified
//       actionButtonText = 'Sign Up';
//       formActionButton = ElevatedButton(
//         onPressed: _isLoading ? null : _completeSignUp,
//         style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
//         child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(actionButtonText, style: const TextStyle(fontSize: 16)),
//       );
//     }


//     Widget signUpFormContent = Form(
//       key: _formKey,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const Text(
//             'Create Your Account',
//             style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 30),

//           // --- Name Field ---
//           TextFormField(
//             controller: _nameController,
//             focusNode: _nameFocusNode,
//             decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
//             keyboardType: TextInputType.name,
//             textCapitalization: TextCapitalization.words,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             textInputAction: TextInputAction.next,
//             onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocusNode),
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) return 'Please enter your name';
//               if (value.trim().length < 2) return 'Please enter a valid name';
//               return null;
//             },
//             enabled: _currentStep == OtpVerificationStep.enterPhoneNumber, // Disable if past this step for now
//           ),
//           const SizedBox(height: 15),

//           // --- Email Field ---
//           TextFormField(
//             controller: _emailController,
//             focusNode: _emailFocusNode,
//             decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
//             keyboardType: TextInputType.emailAddress,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             textInputAction: TextInputAction.next,
//             onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) return 'Please enter your email';
//               if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return 'Please enter a valid email address';
//               return null;
//             },
//              enabled: _currentStep == OtpVerificationStep.enterPhoneNumber,
//           ),
//           const SizedBox(height: 15),

//           // --- Phone Number Field ---
//           TextFormField(
//             controller: _phoneController,
//             focusNode: _phoneFocusNode,
//             decoration: const InputDecoration(labelText: 'Phone Number (e.g. +1415... )', prefixIcon: Icon(Icons.phone_outlined)),
//             keyboardType: TextInputType.phone,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             textInputAction: _currentStep == OtpVerificationStep.enterPhoneNumber ? TextInputAction.done : TextInputAction.next,
//             onFieldSubmitted: (_) {
//                 if (_currentStep == OtpVerificationStep.enterPhoneNumber && !_isSendingOtp) {
//                    _handleSendOtp();
//                 } else if (_currentStep == OtpVerificationStep.phoneVerified) {
//                   FocusScope.of(context).requestFocus(_passwordFocusNode);
//                 }
//             },
//             validator: _validatePhoneNumber,
//             enabled: _currentStep == OtpVerificationStep.enterPhoneNumber, // Only editable at the start
//           ),
//           const SizedBox(height: 15),

//           // --- OTP Field (Conditional) ---
//           if (_currentStep == OtpVerificationStep.enterOtp) ...[
//             TextFormField(
//               controller: _otpController,
//               focusNode: _otpFocusNode,
//               decoration: const InputDecoration(labelText: 'OTP', prefixIcon: Icon(Icons.shield_outlined)),
//               keyboardType: TextInputType.number,
//               maxLength: 6,
//               autovalidateMode: AutovalidateMode.onUserInteraction,
//               textInputAction: TextInputAction.done,
//               onFieldSubmitted: (_) => _handleVerifyOtp(),
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) return 'Please enter OTP';
//                 if (value.trim().length != 6) return 'OTP must be 6 digits';
//                 return null;
//               },
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: (_isLoading || _isSendingOtp) ? null : (){
//                     // Resend OTP logic - basically go back to phone step if user wants to change, or directly call send if phone number is same
//                     _setErrorMessage(null); // Clear previous error
//                     setState(() => _currentStep = OtpVerificationStep.enterPhoneNumber);
//                     _phoneFocusNode.requestFocus(); // Let them re-confirm phone then send
//                   },
//                   child: const Text('Change Phone / Resend OTP?'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//           ],

//           // --- Phone Verified Indicator (Conditional) ---
//           if (_currentStep == OtpVerificationStep.phoneVerified) ...[
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.check_circle, color: Colors.green, size: 20),
//                   const SizedBox(width: 8),
//                   Text("Phone Verified: ${_phoneController.text}", style: const TextStyle(color: Colors.green)),
//                   TextButton(onPressed: (){
//                     setState(() {
//                       _currentStep = OtpVerificationStep.enterPhoneNumber;
//                       _phoneAuthCredential = null;
//                       _otpController.clear();
//                        _verificationIdForSignUp = null;
//                       _errorMessage = null;
//                       _passwordController.clear(); // Clear password if they go back
//                       _confirmPasswordController.clear();
//                     });
//                   }, child: const Text("(Change)"))
//                 ],
//               ),
//             ),
//              const SizedBox(height: 10),
//           ],


//           // --- Password Fields (Conditional - Show after phone verification) ---
//           if (_currentStep == OtpVerificationStep.phoneVerified) ...[
//             TextFormField(
//               controller: _passwordController,
//               focusNode: _passwordFocusNode,
//               obscureText: _obscurePassword,
//               decoration: InputDecoration(
//                   labelText: 'Password',
//                   prefixIcon: const Icon(Icons.lock_outline),
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
//                     onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                   ),
//                   helperText: 'Min 8 chars, upper, lower, digit, symbol',
//                   helperMaxLines: 2,
//                   helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
//               ),
//               autovalidateMode: AutovalidateMode.onUserInteraction,
//               textInputAction: TextInputAction.next,
//               onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
//               validator: _validatePassword,
//             ),
//             const SizedBox(height: 15),
//             TextFormField(
//               controller: _confirmPasswordController,
//               focusNode: _confirmPasswordFocusNode,
//               obscureText: _obscureConfirmPassword,
//               decoration: InputDecoration(
//                   labelText: 'Confirm Password',
//                   prefixIcon: const Icon(Icons.lock_reset_outlined),
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
//                     onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                   ),
//                 ),
//               autovalidateMode: AutovalidateMode.onUserInteraction,
//               textInputAction: TextInputAction.done,
//               onFieldSubmitted: (_) => _completeSignUp(),
//               validator: (value) {
//                 if (value == null || value.isEmpty) return 'Please confirm your password';
//                 if (value != _passwordController.text) return 'Passwords do not match';
//                 return null;
//               },
//             ),
//           ],
//           const SizedBox(height: 25),

//           // --- Error Message Display ---
//           if (_errorMessage != null && _errorMessage!.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 15.0),
//               child: Text(
//                 _errorMessage!,
//                 style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//           // --- Dynamic Action Button ---
//           formActionButton,
//           const SizedBox(height: 20),

//           // --- Switch to Sign In ---
//           Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text("Already have an account?"),
//                 TextButton(
//                   onPressed: _isLoading ? null : widget.showSignInScreen,
//                   child: const Text('Sign In'),
//                 ),
//               ],
//           ),
//         ],
//       ),
//     );

//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 400),
//               decoration: BoxDecoration(
//                 color: theme.cardColor,
//                 borderRadius: BorderRadius.circular(16.0),
//                 border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1.0),
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
//                   child: signUpFormContent,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }