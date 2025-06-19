import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _usersCollection = 'mm_users';

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signUpWithEmailPassword(
      String name, String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        await _saveUserDataToFirestore(user, name: name, isNewUser: true);
        await _firebaseAuth.signOut();
      } else {
        throw Exception('User registration failed, user object is null.');
      }
    } on FirebaseAuthException catch (e) {
      String message = _handleAuthException(e, isSignUp: true);
      throw Exception(message);
    } catch (e) {
      debugPrint('General Exception (Sign Up): $e');
      throw Exception('An unknown error occurred during sign up.');
    }
  }

  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await _firebaseAuth.signOut();
        throw Exception(
            'Please verify your email address before signing in. Check your inbox (and spam folder).');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = _handleAuthException(e, isSignUp: false);
      throw Exception(message);
    } catch (e) {
      debugPrint('General Exception (Sign In): $e');
      if (e is Exception && e.toString().contains('verify your email')) {
        rethrow;
      }
      throw Exception('An unknown error occurred during sign in.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'Failed to send password reset email. Please try again.';
          debugPrint(
              'Firebase Auth Exception (Password Reset): ${e.code} - ${e.message}');
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('General Exception (Password Reset): $e');
      throw Exception('An unknown error occurred.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDocRef =
            _firestore.collection(_usersCollection).doc(user.uid);
        final userDoc = await userDocRef.get();
        if (!userDoc.exists) {
          await _saveUserDataToFirestore(user,
              name: googleUser.displayName, isNewUser: true);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = _handleAuthException(e, isSignUp: false);
      if (e.code == 'account-exists-with-different-credential') {
        message =
            'An account already exists with this email. Try signing in with your original method (e.g., Email/Password).';
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      if (e.toString().contains('network_error')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      if (e.toString().contains('sign_in_canceled')) {
        return null;
      }
      throw Exception(
          'An error occurred during Google Sign-In. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        debugPrint("Google user signed out.");
      }
      await _firebaseAuth.signOut();
      debugPrint("Firebase user signed out.");
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> _saveUserDataToFirestore(User user,
      {String? name, bool isNewUser = false}) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(user.uid);
      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'name': name?.trim() ??
            user.displayName?.trim() ??
            _extractNameFromEmail(user.email) ??
            'User',
        if (isNewUser) 'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
        if (isNewUser) 'favoriteVenueIds': [],
        if (isNewUser) 'profilePictureUrl': null,
        if (isNewUser) 'phoneNumber': null,
      };

      if (isNewUser) {
        await docRef.set(userData);
      } else {
        await docRef.set(userData, SetOptions(merge: !isNewUser));
      }
    } catch (e) {
      debugPrint('Error saving user data to Firestore for UID ${user.uid}: $e');
    }
  }

  Stream<Map<String, dynamic>?> getUserProfileStream() {
    final String? uid = getCurrentUser()?.uid;
    if (uid == null) {
      return Stream.value(null);
    }
    try {
      return _firestore
          .collection(_usersCollection)
          .doc(uid)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return snapshot.data();
        } else {
          return null;
        }
      }).handleError((error) {
        debugPrint('Error in user profile stream for UID $uid: $error');
        return null;
      });
    } catch (e) {
      debugPrint('Error creating user profile stream for UID $uid: $e');
      return Stream.value(null);
    }
  }

  Future<Map<String, dynamic>?> getUserProfileData() async {
    final String? uid = getCurrentUser()?.uid;
    if (uid == null) return null;
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile data for UID $uid: $e');
      throw Exception("Could not load profile data.");
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    if (uid.isEmpty) return null;
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data for UID $uid: $e');
      return null;
    }
  }

  Future<void> updateUserName(String name) async {
    final user = getCurrentUser();
    if (user == null) {
      throw Exception("User not logged in. Please sign in again.");
    }
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length < 2) {
      throw Exception("Please enter a valid name (at least 2 characters).");
    }
    try {
      final docRef = _firestore.collection(_usersCollection).doc(user.uid);
      await docRef.update(
          {'name': trimmedName, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error updating user name for UID ${user.uid}: $e');
      throw Exception(
          "Failed to update name. Please check your connection and try again.");
    }
  }

  String? _extractNameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    String namePart = email.split('@')[0];
    namePart = namePart.replaceAll(RegExp(r'[._-]'), ' ').trim();
    if (namePart.isEmpty) return null;
    return namePart
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ')
        .trim();
  }

  String _handleAuthException(FirebaseAuthException e,
      {required bool isSignUp}) {
    String message;
    debugPrint(
        'Firebase Auth Exception (${isSignUp ? "Sign Up" : "Sign In/Other"}): ${e.code} - ${e.message}');
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message =
            'An account already exists for that email. Please Sign In or use Forgot Password.';
        break;
      case 'invalid-email':
        message = 'The email address format is not valid.';
        break;
      case 'user-not-found':
        message =
            'No user found with this email. Please check the email or Sign Up.';
        break;
      case 'wrong-password':
        message =
            'Incorrect password. Please try again or use Forgot Password.';
        break;
      case 'user-disabled':
        message =
            'This user account has been disabled. Please contact support.';
        break;
      case 'account-exists-with-different-credential':
        message =
            'An account already exists with this email. Try signing in with your original method (e.g., Google or Email/Password).';
        break;
      case 'operation-not-allowed':
        message = 'Sign-in method not enabled. Please contact support.';
        break;
      case 'invalid-credential':
        message = 'The credentials provided are invalid.';
        break;
      case 'too-many-requests':
        message =
            'Too many attempts. Please wait a bit and try again or use Forgot Password.';
        break;
      case 'requires-recent-login':
        message =
            'This action requires you to recently sign in again for security.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection and try again.';
        break;
      default:
        message = 'An unexpected error occurred. Please try again.';
    }
    return message;
  }

  Future<bool> reauthenticateWithPassword(String password) async {
    final user = getCurrentUser();
    if (user == null || user.email == null) {
      throw Exception("User not logged in or email missing.");
    }
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true; // Re-authentication successful
    } on FirebaseAuthException catch (e) {
      debugPrint("Re-authentication error: ${e.code}");
      // Handle specific errors like wrong-password if needed
      throw Exception("Re-authentication failed. Please check your password.");
    } catch (e) {
      debugPrint("Generic Re-authentication error: $e");
      throw Exception("An error occurred during re-authentication.");
    }
  }

  Future<void> updateUserEmailAndSendVerification(String newEmail) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in.");

    try {
      await user.updateEmail(newEmail.trim());
      // If successful, send verification to the NEW email
      await user.sendEmailVerification();
      // IMPORTANT: Firestore update happens separately in UserService AFTER this succeeds
    } on FirebaseAuthException catch (e) {
      String message = "Failed to update email.";
      if (e.code == 'email-already-in-use') {
        message = 'This email address is already in use by another account.';
      } else if (e.code == 'invalid-email') {
        message = 'The new email address is not valid.';
      } else if (e.code == 'requires-recent-login') {
        message =
            'This action requires you to have signed in recently. Please try again.';
        // You might want to trigger the re-auth flow from the calling UI here
      }
      debugPrint("Update email error: ${e.code}");
      throw Exception(message);
    } catch (e) {
      debugPrint("Generic Update email error: $e");
      throw Exception("An unknown error occurred while updating email.");
    }
  }

  Future<void> verifyPhoneNumberStart({
    required String phoneNumber,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Duration timeout,
    int? forceResendingToken, // Pass this for resending OTP
  }) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in.");

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // Must be in E.164 format (e.g., +16505551234)
      verificationCompleted:
          onVerificationCompleted, // For Android instant verification
      verificationFailed: onVerificationFailed, // Handle errors
      codeSent: onCodeSent, // Store verificationId and prompt user
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out.
        // You might just ignore this or use the verificationId provided
        debugPrint(
            "Phone auth code auto retrieval timeout. Verification ID: $verificationId");
      },
      timeout: timeout,
      forceResendingToken: forceResendingToken, // Use for resending
    );
  }

  Future<PhoneAuthCredential> createPhoneCredential(
      String verificationId, String smsCode) async {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
  }

  // Use this after user enters OTP to link/verify the number with the logged-in user
  Future<void> confirmPhoneNumberUpdate(PhoneAuthCredential credential) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in.");
    try {
      await user.updatePhoneNumber(credential);
      // Firestore update happens separately in UserService after this succeeds
    } on FirebaseAuthException catch (e) {
      debugPrint("Confirm Phone Number Error: ${e.code}");
      String message = "Failed to verify phone number.";
      if (e.code == 'invalid-verification-code') {
        message = "The verification code is invalid.";
      } else if (e.code == 'session-expired') {
        message =
            "The verification session has expired. Please request a new code.";
      } else if (e.code == 'credential-already-in-use') {
        message = "This phone number is already linked to another account.";
      }
      throw Exception(message);
    } catch (e) {
      debugPrint("Generic Confirm Phone Number Error: $e");
      throw Exception("An unknown error occurred during phone verification.");
    }
  }
}


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart'; // For debugPrint, kept for consistency

// class AuthService {
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   static const String _usersCollection = 'mm_users';

//   // --- NEW: For OTP Sign-Up Flow ---
//   String? _signUpVerificationId; // To store verification ID for the sign-up OTP process
//   // --- END NEW ---

//   Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

//   User? getCurrentUser() {
//     return _firebaseAuth.currentUser;
//   }

//   // MODIFIED:
//   // 1. Returns User? to allow access to the created user for phone linking.
//   // 2. Removed `await _firebaseAuth.signOut();` to keep the user logged in for immediate phone linking.
//   // 3. Added optional `phoneNumberForRecord` to store phone number from input during Firestore save.
//   Future<User?> signUpWithEmailPassword(
//       String name, String email, String password, {String? phoneNumberForRecord}) async {
//     try {
//       UserCredential userCredential =
//           await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       User? user = userCredential.user;
//       if (user != null) {
//         await user.sendEmailVerification();
//         await _saveUserDataToFirestore(user, name: name, phoneNumberIfKnown: phoneNumberForRecord, isNewUser: true);
//         // User remains logged in for subsequent actions like phone linking.
//         // Sign out should be handled by the UI after all steps are complete or on error.
//         return user;
//       } else {
//         throw Exception('User registration failed, user object is null.');
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = _handleAuthException(e, isSignUp: true);
//       throw Exception(message);
//     } catch (e) {
//       debugPrint('General Exception (Sign Up): $e');
//       throw Exception('An unknown error occurred during sign up.');
//     }
//   }

//   Future<UserCredential?> signInWithEmailPassword(
//       String email, String password) async {
//     try {
//       UserCredential userCredential =
//           await _firebaseAuth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       User? user = userCredential.user;
//       if (user != null && !user.emailVerified) {
//         // Optionally, if you ALWAYS require email verification before ANY access after sign-in:
//         // await _firebaseAuth.signOut();
//         // throw Exception(
//         // 'Please verify your email address before signing in. Check your inbox (and spam folder). Resent verification.');
//         // await user.sendEmailVerification(); // Optionally resend if not verified

//         // If you allow them in but show a banner, then don't sign out.
//         // The current implementation is strict.
//         await _firebaseAuth.signOut(); // Kept original behavior
//         throw Exception(
//             'Please verify your email address before signing in. Check your inbox (and spam folder).');
//       }
//       // If user is email verified, proceed to update Firestore data if needed (e.g. lastLogin)
//       if (user != null) {
//         await _saveUserDataToFirestore(user, isNewUser: false); // Save last login or other updates
//       }
//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       String message = _handleAuthException(e, isSignUp: false);
//       throw Exception(message);
//     } catch (e) {
//       debugPrint('General Exception (Sign In): $e');
//       if (e is Exception && e.toString().contains('verify your email')) {
//         rethrow;
//       }
//       throw Exception('An unknown error occurred during sign in.');
//     }
//   }

//   Future<void> sendPasswordResetEmail(String email) async {
//     try {
//       await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
//     } on FirebaseAuthException catch (e) {
//       String message;
//       switch (e.code) {
//         case 'user-not-found':
//           message = 'No user found for that email.';
//           break;
//         case 'invalid-email':
//           message = 'The email address is not valid.';
//           break;
//         default:
//           message = 'Failed to send password reset email. Please try again.';
//           debugPrint(
//               'Firebase Auth Exception (Password Reset): ${e.code} - ${e.message}');
//       }
//       throw Exception(message);
//     } catch (e) {
//       debugPrint('General Exception (Password Reset): $e');
//       throw Exception('An unknown error occurred.');
//     }
//   }

//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         return null; // User cancelled Google Sign-In
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       UserCredential userCredential =
//           await _firebaseAuth.signInWithCredential(credential);
//       User? user = userCredential.user;

//       if (user != null) {
//         final userDocRef =
//             _firestore.collection(_usersCollection).doc(user.uid);
//         final userDoc = await userDocRef.get();
//         await _saveUserDataToFirestore(user,
//               name: googleUser.displayName, isNewUser: !userDoc.exists);
//       }

//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       String message = _handleAuthException(e, isSignUp: false);
//       if (e.code == 'account-exists-with-different-credential') {
//         message =
//             'An account already exists with this email. Try signing in with your original method (e.g., Email/Password).';
//       }
//       throw Exception(message);
//     } catch (e) {
//       debugPrint('Google Sign In Error: $e');
//       if (e.toString().contains('network_error')) {
//         throw Exception(
//             'Network error. Please check your connection and try again.');
//       }
//       if (e.toString().contains('sign_in_canceled') || e.toString().contains('popup_closed_by_user')) { // Common on web
//         return null;
//       }
//       throw Exception(
//           'An error occurred during Google Sign-In. Please try again.');
//     }
//   }

//   Future<void> signOut() async {
//     try {
//       if (await _googleSignIn.isSignedIn()) {
//         await _googleSignIn.signOut();
//         debugPrint("Google user signed out.");
//       }
//       await _firebaseAuth.signOut();
//       debugPrint("Firebase user signed out.");
//     } catch (e) {
//       debugPrint('Error signing out: $e');
//       // Potentially rethrow or handle differently
//     }
//   }

//   // MODIFIED:
//   // 1. Added `phoneNumberIfKnown` to store phone from input fields during initial save.
//   // 2. Ensures `user.phoneNumber` (from Firebase Auth after linking) takes precedence.
//   // 3. `profilePictureUrl` also tries to get `user.photoURL` (e.g. from Google).
//   // 4. Added `updatedAt` for non-new user updates.
//   Future<void> _saveUserDataToFirestore(User user,
//       {String? name, String? phoneNumberIfKnown, bool isNewUser = false}) async {
//     try {
//       final docRef = _firestore.collection(_usersCollection).doc(user.uid);
//       final Map<String, dynamic> userData = {
//         'uid': user.uid,
//         'email': user.email,
//         'name': name?.trim() ??
//             user.displayName?.trim() ??
//             _extractNameFromEmail(user.email) ??
//             'User',
//         'emailVerified': user.emailVerified,
//         // Prioritize actual linked phone number, fallback to provided one or null
//         'phoneNumber': user.phoneNumber ?? phoneNumberIfKnown,
//         'profilePictureUrl': user.photoURL, // Can be null if not available
//       };

//       if (isNewUser) {
//         userData['createdAt'] = FieldValue.serverTimestamp();
//         userData['favoriteVenueIds'] = []; // Default for new users
//         // If profilePictureUrl from user.photoURL is null, keep whatever was in Firestore or default
//         if(userData['profilePictureUrl'] == null && (await docRef.get()).exists) {
//             userData['profilePictureUrl'] = (await docRef.get()).data()?['profilePictureUrl'];
//         }
//         await docRef.set(userData);
//       } else {
//         // For updates, explicitly include updatedAt if merging other fields
//         userData['updatedAt'] = FieldValue.serverTimestamp();
//         await docRef.set(userData, SetOptions(merge: true)); // Use merge:true for updates
//       }
//     } catch (e) {
//       debugPrint('Error saving user data to Firestore for UID ${user.uid}: $e');
//       // Rethrow or handle error appropriately
//     }
//   }

//   Stream<Map<String, dynamic>?> getUserProfileStream() {
//     final String? uid = getCurrentUser()?.uid;
//     if (uid == null) {
//       return Stream.value(null);
//     }
//     try {
//       return _firestore
//           .collection(_usersCollection)
//           .doc(uid)
//           .snapshots()
//           .map((snapshot) {
//         if (snapshot.exists) {
//           return snapshot.data();
//         } else {
//           // If doc doesn't exist but user is authenticated, could create it here.
//           // For now, returning null if no doc.
//           return null;
//         }
//       }).handleError((error) {
//         debugPrint('Error in user profile stream for UID $uid: $error');
//         return null; // Emit null on error to keep stream alive if desired
//       });
//     } catch (e) {
//       debugPrint('Error creating user profile stream for UID $uid: $e');
//       return Stream.value(null);
//     }
//   }

//   Future<Map<String, dynamic>?> getUserProfileData() async {
//     final String? uid = getCurrentUser()?.uid;
//     if (uid == null) return null;
//     try {
//       DocumentSnapshot doc =
//           await _firestore.collection(_usersCollection).doc(uid).get();
//       if (doc.exists) {
//         return doc.data() as Map<String, dynamic>?;
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error fetching user profile data for UID $uid: $e');
//       throw Exception("Could not load profile data.");
//     }
//   }

//   Future<Map<String, dynamic>?> getUserData(String uid) async {
//     if (uid.isEmpty) return null;
//     try {
//       DocumentSnapshot doc =
//           await _firestore.collection(_usersCollection).doc(uid).get();
//       if (doc.exists) {
//         return doc.data() as Map<String, dynamic>?;
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error fetching user data for UID $uid: $e');
//       return null; // Or throw exception
//     }
//   }

//   Future<void> updateUserName(String name) async {
//     final user = getCurrentUser();
//     if (user == null) {
//       throw Exception("User not logged in. Please sign in again.");
//     }
//     final String trimmedName = name.trim();
//     if (trimmedName.isEmpty || trimmedName.length < 2) {
//       throw Exception("Please enter a valid name (at least 2 characters).");
//     }
//     try {
//       // Update Firebase Auth display name
//       await user.updateDisplayName(trimmedName);
//       // Update Firestore
//       final docRef = _firestore.collection(_usersCollection).doc(user.uid);
//       await docRef.update(
//           {'name': trimmedName, 'updatedAt': FieldValue.serverTimestamp()});
//     } catch (e) {
//       debugPrint('Error updating user name for UID ${user.uid}: $e');
//       throw Exception(
//           "Failed to update name. Please check your connection and try again.");
//     }
//   }

//   String? _extractNameFromEmail(String? email) {
//     if (email == null || !email.contains('@')) return null;
//     String namePart = email.split('@')[0];
//     namePart = namePart.replaceAll(RegExp(r'[._-]'), ' ').trim();
//     if (namePart.isEmpty) return null;
//     return namePart
//         .split(' ')
//         .map((word) {
//           if (word.isEmpty) return '';
//           return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
//         })
//         .join(' ')
//         .trim();
//   }

//   String _handleAuthException(FirebaseAuthException e,
//       {required bool isSignUp}) {
//     String message;
//     debugPrint(
//         'Firebase Auth Exception (${isSignUp ? "Sign Up" : "Sign In/Other"}): ${e.code} - ${e.message}');
//     switch (e.code) {
//       case 'weak-password':
//         message = 'The password provided is too weak.';
//         break;
//       case 'email-already-in-use':
//         message =
//             'An account already exists for that email. Please Sign In or use Forgot Password.';
//         break;
//       case 'invalid-email':
//         message = 'The email address format is not valid.';
//         break;
//       case 'user-not-found':
//         message =
//             'No user found with this email. Please check the email or Sign Up.';
//         break;
//       case 'wrong-password':
//         message =
//             'Incorrect password. Please try again or use Forgot Password.';
//         break;
//       case 'user-disabled':
//         message =
//             'This user account has been disabled. Please contact support.';
//         break;
//       case 'account-exists-with-different-credential':
//         message =
//             'An account already exists with this email. Try signing in with your original method (e.g., Google or Email/Password).';
//         break;
//       case 'operation-not-allowed':
//         message = 'Sign-in method not enabled. Please contact support.';
//         break;
//       case 'invalid-credential':
//       case 'invalid-verification-code': // Specific to phone auth
//         message = 'The credential or code provided is invalid.';
//         break;
//       case 'invalid-verification-id': // Specific to phone auth
//           message = 'The verification process timed out or was invalid. Please try sending OTP again.';
//           break;
//       case 'session-expired': // Specific to phone auth
//         message = 'The OTP has expired. Please request a new one.';
//         break;
//       case 'too-many-requests':
//         message =
//             'Too many attempts. Please wait a bit and try again or use Forgot Password.';
//         break;
//       case 'requires-recent-login':
//         message =
//             'This action requires you to recently sign in again for security.';
//         break;
//       case 'network-request-failed':
//         message = 'Network error. Please check your connection and try again.';
//         break;
//       default:
//         message = 'An unexpected error occurred: ${e.message ?? e.code}.'; // Provide more details if available
//     }
//     return message;
//   }

//   Future<bool> reauthenticateWithPassword(String password) async {
//     final user = getCurrentUser();
//     if (user == null || user.email == null) {
//       throw Exception("User not logged in or email missing.");
//     }
//     try {
//       final AuthCredential credential = EmailAuthProvider.credential(
//         email: user.email!,
//         password: password,
//       );
//       await user.reauthenticateWithCredential(credential);
//       return true; // Re-authentication successful
//     } on FirebaseAuthException catch (e) {
//       debugPrint("Re-authentication error: ${e.code}");
//       throw Exception(_handleAuthException(e, isSignUp: false)); // Use centralized handler
//     } catch (e) {
//       debugPrint("Generic Re-authentication error: $e");
//       throw Exception("An error occurred during re-authentication.");
//     }
//   }

//   Future<void> updateUserEmailAndSendVerification(String newEmail) async {
//     final user = getCurrentUser();
//     if (user == null) throw Exception("User not logged in.");

//     try {
//       await user.updateEmail(newEmail.trim());
//       await user.sendEmailVerification(); // Send verification to the NEW email
//       // Update Firestore with the new email. Also mark emailVerified as false until new email is verified.
//       await _firestore.collection(_usersCollection).doc(user.uid).update({
//         'email': newEmail.trim(),
//         'emailVerified': false, // User needs to verify the new email
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } on FirebaseAuthException catch (e) {
//       throw Exception(_handleAuthException(e, isSignUp: false)); // Use centralized handler
//     } catch (e) {
//       debugPrint("Generic Update email error: $e");
//       throw Exception("An unknown error occurred while updating email.");
//     }
//   }


//   // --- NEW: Phone Authentication Methods for SIGN-UP Flow ---

//   /// Initiates phone number verification for the sign-up process.
//   /// This can be called BEFORE a Firebase user is created.
//   Future<void> sendOtpForSignUpProcess({
//     required String phoneNumber, // E.164 format (e.g., +1XXXXXXXXXX)
//     required Function(PhoneAuthCredential) onVerificationCompleted, // For auto-retrieval (Android)
//     required Function(FirebaseAuthException) onVerificationFailed,
//     required Function(String verificationId, int? resendToken) onCodeSent,
//     required Function(String verificationId) onCodeAutoRetrievalTimeout,
//     Duration timeout = const Duration(seconds: 60),
//     int? forceResendingToken,
//   }) async {
//     try {
//       await _firebaseAuth.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: onVerificationCompleted,
//         verificationFailed: (FirebaseAuthException e) {
//           // Pass the original exception to the callback
//           onVerificationFailed(e);
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           _signUpVerificationId = verificationId; // Store for this sign-up attempt
//           onCodeSent(verificationId, resendToken);
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           // If codeSent hasn't fired yet for some reason and this fires first
//           if (_signUpVerificationId == null || _signUpVerificationId != verificationId) {
//              _signUpVerificationId = verificationId;
//           }
//           onCodeAutoRetrievalTimeout(verificationId);
//         },
//         timeout: timeout,
//         forceResendingToken: forceResendingToken,
//       );
//     } catch (e) {
//       // This catch might not be strictly necessary if all paths call onVerificationFailed
//       // but can catch setup issues with verifyPhoneNumber itself.
//       debugPrint("Error initiating OTP send: $e");
//       if (e is FirebaseAuthException) {
//         onVerificationFailed(e);
//       } else {
//          onVerificationFailed(FirebaseAuthException(code: 'otp-send-error', message: e.toString()));
//       }
//     }
//   }

//   /// Verifies the OTP entered by the user during the sign-up process
//   /// and returns a [PhoneAuthCredential].
//   Future<PhoneAuthCredential> verifyOtpAndGetCredentialForSignUpProcess(String otp) async {
//     if (_signUpVerificationId == null) {
//       throw Exception("Verification ID not found for sign-up. Please request OTP again.");
//     }
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _signUpVerificationId!,
//         smsCode: otp.trim(),
//       );
//       _signUpVerificationId = null; // Clear after use
//       return credential;
//     } on FirebaseAuthException catch (e) {
//       // Let the centralized handler format the message
//       throw Exception(_handleAuthException(e, isSignUp: false));
//     } catch (e) {
//       debugPrint("Generic OTP Verification Error (Sign Up): $e");
//       throw Exception("An unknown error occurred during OTP verification.");
//     }
//   }

//   // --- End NEW Phone Auth Methods for Sign-Up ---


//   // The existing methods below are for UPDATING phone for an ALREADY LOGGED-IN user.
//   // They are kept separate as their context is different (user is already authenticated).

//   /// Initiates phone number verification for an ALREADY LOGGED-IN user to update their phone.
//   Future<void> verifyPhoneNumberStartUpdate({ // Renamed for clarity
//     required String phoneNumber,
//     required Function(FirebaseAuthException) onVerificationFailed,
//     required Function(String verificationId, int? resendToken) onCodeSent,
//     required Function(PhoneAuthCredential credential) onVerificationCompleted,
//     required Duration timeout,
//     int? forceResendingToken,
//   }) async {
//     final user = getCurrentUser();
//     if (user == null) throw Exception("User not logged in for phone update.");

//     await _firebaseAuth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: onVerificationCompleted,
//       verificationFailed: onVerificationFailed,
//       codeSent: onCodeSent, // The calling UI will need to store this verificationId
//       codeAutoRetrievalTimeout: (String verificationId) {
//         debugPrint(
//             "Phone auth code auto retrieval timeout (update). Verification ID: $verificationId");
//       },
//       timeout: timeout,
//       forceResendingToken: forceResendingToken,
//     );
//   }

//   /// Creates a [PhoneAuthCredential] from verification ID and SMS code.
//   /// Used by the UI when updating phone number for an existing user.
//   PhoneAuthCredential createPhoneCredentialForUpdate( // Renamed for clarity
//       String verificationId, String smsCode) {
//     return PhoneAuthProvider.credential(
//       verificationId: verificationId,
//       smsCode: smsCode.trim(),
//     );
//   }

//   /// Links or updates the phone number for the CURRENTLY LOGGED-IN user using the provided credential.
//   /// This is used both after sign-up (linking new phone) and when user updates their phone.
//   Future<void> linkOrUpdatePhoneForCurrentUser(PhoneAuthCredential credential) async {
//     final user = getCurrentUser();
//     if (user == null) throw Exception("User not logged in to link/update phone number.");
//     try {
//       if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
//         // If user has no phone number, link this new one
//         await user.linkWithCredential(credential);
//       } else {
//         // If user already has a phone number, update it
//         await user.updatePhoneNumber(credential);
//       }
//       // Phone number is now updated in Firebase Auth.
//       // Update it in Firestore as well.
//       await _firestore.collection(_usersCollection).doc(user.uid).update({
//         'phoneNumber': user.phoneNumber, // This will be the newly verified number
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } on FirebaseAuthException catch (e) {
//       debugPrint("Link/Update Phone Number Error: ${e.code}");
//       String message = _handleAuthException(e, isSignUp: false); // Use centralized handler
//        if (e.code == 'credential-already-in-use') {
//         message = "This phone number is already linked to another account.";
//       } else if (e.code == 'provider-already-linked' && (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)) {
//         // This case should ideally not happen if logic is correct (means trying to link when already has a phone via link)
//         message = "The account is already linked with a phone provider.";
//       }
//       throw Exception(message);
//     } catch (e) {
//       debugPrint("Generic Link/Update Phone Number Error: $e");
//       throw Exception("An unknown error occurred during phone verification/linking.");
//     }
//   }

//   // Renamed the original 'confirmPhoneNumberUpdate' to 'linkOrUpdatePhoneForCurrentUser' for clarity and broader use.
//   // The original 'createPhoneCredential' is now 'createPhoneCredentialForUpdate'.
//   // The original 'verifyPhoneNumberStart' is now 'verifyPhoneNumberStartUpdate'.
// }