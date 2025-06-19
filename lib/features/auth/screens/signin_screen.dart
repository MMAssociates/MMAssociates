import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Ensure this path is correct
import 'forgot_password_screen.dart';    // Ensure this path is correct
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback showSignUpScreen;

  const SignInScreen({super.key, required this.showSignUpScreen});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // --- NEW: FocusNodes ---
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  // --- END NEW ---

  static const String _rememberMeKey = 'remember_me_preference';
  static const String _emailKey = 'remembered_email';

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  Future<void> _loadRememberMePreference() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool remembered = prefs.getBool(_rememberMeKey) ?? false;

      if (mounted) {
        setState(() {
          _rememberMe = remembered;
        });

        if (_rememberMe) {
          final String? savedEmail = prefs.getString(_emailKey);
          if (savedEmail != null) {
            _emailController.text = savedEmail;
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
      if (mounted) {
        setState(() {
          _rememberMe = false;
        });
      }
    }
  }


  Future<void> _updateRememberMePreference(bool value, String? email) async {
     try {
       final SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setBool(_rememberMeKey, value);
       if (value && email != null && email.isNotEmpty) {
         await prefs.setString(_emailKey, email);
       } else {
         await prefs.remove(_emailKey);
       }
     } catch (e) {
        debugPrint("Error saving SharedPreferences: $e");
     }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // --- NEW: Dispose FocusNodes ---
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    // --- END NEW ---
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    // FocusScope.of(context).unfocus(); // No longer needed here as onFieldSubmitted handles it
    if (_isLoading) return; // Prevent multiple submissions

    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      final String currentEmail = _emailController.text.trim();
      try {
        await _authService.signInWithEmailPassword(
          currentEmail,
          _passwordController.text,
        );

        await _updateRememberMePreference(_rememberMe, currentEmail);

        // if (mounted) _passwordController.clear(); // Let AuthWrapper handle navigation/clearing

      } catch (e) {
        if (mounted) {
          setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); });
          _passwordController.clear();
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    } else {
       _passwordController.clear();
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _authService.signInWithGoogle();
       if (mounted) {
         setState(() { _errorMessage = null; });
       }
    } catch (e) {
       if (mounted) {
         setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); });
       }
    } finally {
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }

  void _goToForgotPassword() {
     if (_isLoading) return;
     Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
     );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget signInFormContent = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Sign in to continue',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode, // --- NEW ---
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next, // --- NEW ---
            onFieldSubmitted: (_) { // --- NEW ---
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
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
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            autovalidateMode: AutovalidateMode.disabled,
            textInputAction: TextInputAction.done, // --- NEW ---
            onFieldSubmitted: (_) => _signInWithEmail(), // --- NEW ---
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: 'Remember my email address',
                  child: CheckboxListTile(
                    title: const Text("Remember Me", style: TextStyle(fontSize: 14)),
                    value: _rememberMe,
                    onChanged: _isLoading ? null : (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _rememberMe = newValue;
                        });
                        String? emailToSave = newValue ? _emailController.text.trim() : null;
                        _updateRememberMePreference(newValue, emailToSave);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextButton(
                  onPressed: _isLoading ? null : _goToForgotPassword,
                  child: const Text('Forgot Password?'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ))
          else ...[
            ElevatedButton(
              onPressed: _signInWithEmail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),

            Row(
              children: <Widget>[
                Expanded(child: Divider(color: Colors.grey[400])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR", style: TextStyle(color: Colors.grey[600])),
                ),
                Expanded(child: Divider(color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 20),

            SignInButton(
              Buttons.Google,
              text: "Sign in with Google",
              onPressed: _signInWithGoogle,
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: _isLoading ? null : widget.showSignUpScreen,
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ]
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
                  child: signInFormContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}