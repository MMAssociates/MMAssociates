// // // // import 'package:flutter/material.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:intl/intl.dart';
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // // // import 'package:flutter/foundation.dart'; // Import for debugPrint
// // // // import 'package:mm_associates/features/user/services/user_service.dart';
// // // // import 'package:mm_associates/features/profile/screens/edit_profile_screen.dart';

// // // // import 'my_favourites_screen.dart';
// // // // import 'my_bookings_screen.dart';
// // // // import 'my_reviews_screen.dart';
// // // // import 'help_support_screen.dart';
// // // // import 'privacy_policy_screen.dart';
// // // // import 'sign_out_button_tile.dart'; // Import the sign out tile

// // // // class ProfileScreen extends StatefulWidget {
// // // //   const ProfileScreen({Key? key}) : super(key: key);
// // // //   @override
// // // //   _ProfileScreenState createState() => _ProfileScreenState();
// // // // }

// // // // class _ProfileScreenState extends State<ProfileScreen> {
// // // //   final AuthService _authService = AuthService();
// // // //   final UserService _userService = UserService();
// // // //   User? _currentUser;
// // // //   Map<String, dynamic>? _userData;
// // // //   bool _isLoading = true;
// // // //   String? _errorMessage;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _loadUserProfile();
// // // //   }

// // // //   void setStateIfMounted(VoidCallback fn) {
// // // //     if (mounted) {
// // // //       setState(fn);
// // // //     }
// // // //   }

// // // //   Future<void> _loadUserProfile({bool forceRefresh = false}) async {
// // // //     debugPrint(
// // // //         '_loadUserProfile - Start: _isLoading: $_isLoading, _errorMessage: $_errorMessage, _currentUser: ${_currentUser?.uid}');
// // // //     if (!mounted) return;
// // // //     setStateIfMounted(() {
// // // //       _isLoading = true;
// // // //       _errorMessage = null;
// // // //     });

// // // //     _currentUser = _authService.getCurrentUser();
// // // //     if (_currentUser == null) {
// // // //       debugPrint('_loadUserProfile - User is null');
// // // //       setStateIfMounted(() {
// // // //         _isLoading = false;
// // // //         _errorMessage = "User not logged in.";
// // // //       });
// // // //       return;
// // // //     }

// // // //     try {
// // // //       // It's good practice to reload user to get fresh emailVerified status, etc.
// // // //       await _currentUser?.reload(); 
// // // //       _currentUser = _authService.getCurrentUser(); // Re-fetch after reload

// // // //       _userData =
// // // //           await _userService.getUserProfileData(forceRefresh: forceRefresh);
// // // //       if (!mounted) return;
// // // //       debugPrint('_loadUserProfile - User data loaded: ${_userData != null}');
// // // //       setStateIfMounted(() {
// // // //         _isLoading = false;
// // // //       });
// // // //     } catch (e) {
// // // //       debugPrint("Error loading profile: $e");
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() {
// // // //         _isLoading = false;
// // // //         _errorMessage = "Failed to load profile details.";
// // // //       });
// // // //     }
// // // //   }

// // // //   void _navigateToEditProfile() async {
// // // //     if (_currentUser == null || _userData == null) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Profile data not loaded yet.")),
// // // //       );
// // // //       return;
// // // //     }

// // // //     // Ensure 'name' from userData is prioritized, fallback to Firebase displayName
// // // //     final String currentName = _userData!['name'] as String? ?? _currentUser!.displayName ?? 'N/A';
// // // //     final String currentEmail = _currentUser!.email ?? 'N/A'; // Email is from Auth User
// // // //     final String? currentPhone = _userData!['phoneNumber'] as String?;
// // // //     final String? currentProfilePicUrl = _userData!['profilePictureUrl'] as String?;
// // // //     final String? currentBio = _userData!['bio'] as String?;
// // // //     final Timestamp? dobTimestamp = _userData!['dateOfBirth'] as Timestamp?;
// // // //     final DateTime? currentDateOfBirth = dobTimestamp?.toDate();
// // // //     final String? currentGender = _userData!['gender'] as String?;
// // // //     final String? currentAddressStreet = _userData!['addressStreet'] as String?;
// // // //     final String? currentAddressCity = _userData!['addressCity'] as String?;
// // // //     final String? currentAddressState = _userData!['addressState'] as String?;
// // // //     final String? currentAddressZipCode = _userData!['addressZipCode'] as String?;
// // // //     final String? currentAddressCountry = _userData!['addressCountry'] as String?;
// // // //     final String? currentSocialMediaLink = _userData!['socialMediaLink'] as String?;

// // // //     final result = await Navigator.push<bool>(
// // // //       context,
// // // //       MaterialPageRoute(
// // // //         builder: (context) => EditProfileScreen(
// // // //           currentName: currentName,
// // // //           currentEmail: currentEmail,
// // // //           currentPhone: currentPhone,
// // // //           currentProfilePicUrl: currentProfilePicUrl,
// // // //           currentBio: currentBio,
// // // //           currentDateOfBirth: currentDateOfBirth,
// // // //           currentGender: currentGender,
// // // //           currentAddressStreet: currentAddressStreet,
// // // //           currentAddressCity: currentAddressCity,
// // // //           currentAddressState: currentAddressState,
// // // //           currentAddressZipCode: currentAddressZipCode,
// // // //           currentAddressCountry: currentAddressCountry,
// // // //           currentSocialMediaLink: currentSocialMediaLink,
// // // //         ),
// // // //       ),
// // // //     );

// // // //     if (result == true && mounted) {
// // // //       _loadUserProfile(forceRefresh: true); // Force refresh if changes were saved
// // // //     }
// // // //   }


// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final ThemeData theme = Theme.of(context);
// // // //     return Scaffold(
// // // //       backgroundColor: theme.brightness == Brightness.light
// // // //           ? Colors.grey[100]!
// // // //           : theme.scaffoldBackgroundColor,
// // // //       appBar: AppBar(
// // // //         title: const Text('My Profile'),
// // // //         elevation: 0,
// // // //         backgroundColor: theme.scaffoldBackgroundColor,
// // // //         foregroundColor: theme.colorScheme.onSurface,
// // // //         actions: const [
// // // //           // Removed settings/edit icon from here as per typical UI patterns
// // // //           // where edit is invoked from within the profile details area.
// // // //         ],
// // // //       ),
// // // //       body: RefreshIndicator(
// // // //         onRefresh: () => _loadUserProfile(forceRefresh: true),
// // // //         child: _buildBody(theme),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildBody(ThemeData theme) {
// // // //     if (_isLoading) {
// // // //       return const Center(child: CircularProgressIndicator());
// // // //     }

// // // //     if (_errorMessage != null || _currentUser == null || _userData == null) {
// // // //       return Center(
// // // //         child: Padding(
// // // //           padding: const EdgeInsets.all(20.0),
// // // //           child: Column(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               Icon(Icons.error_outline, color: Colors.red[300], size: 60),
// // // //               const SizedBox(height: 15),
// // // //               Text(
// // // //                 _errorMessage ?? "Could not load profile.",
// // // //                 textAlign: TextAlign.center,
// // // //                 style: TextStyle(color: Colors.red[700], fontSize: 16),
// // // //               ),
// // // //               const SizedBox(height: 20),
// // // //               ElevatedButton.icon(
// // // //                 icon: const Icon(Icons.refresh),
// // // //                 label: const Text("Try Again"),
// // // //                 onPressed: () => _loadUserProfile(forceRefresh: true),
// // // //                 style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.onError, backgroundColor: theme.colorScheme.error,)
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }

// // // //     Widget profilePageContent = Column(
// // // //       mainAxisSize: MainAxisSize.min, // Allow column to take minimum necessary space
// // // //       crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //       children: [
// // // //         _buildHeaderCard(theme),
// // // //         // MODIFIED: Reduced SizedBox height
// // // //         const SizedBox(height: 16),
// // // //         _buildActionsCard(theme),
// // // //       ],
// // // //     );

// // // //     return Center(
// // // //       child: Padding(
// // // //         // MODIFIED: Reduced vertical padding
// // // //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
// // // //         child: Container(
// // // //           constraints: BoxConstraints(
// // // //             maxWidth: 550,
// // // //             // Keep maxHeight relatively high to accommodate content, rely on SingleChildScrollView
// // // //             maxHeight: MediaQuery.of(context).size.height * 0.9, 
// // // //           ),
// // // //           decoration: BoxDecoration(
// // // //             color: theme.cardColor,
// // // //             borderRadius: BorderRadius.circular(16.0),
// // // //             border: Border.all(
// // // //               color: theme.dividerColor.withOpacity(0.5),
// // // //               width: 1.0,
// // // //             ),
// // // //             boxShadow: [
// // // //               BoxShadow(
// // // //                 color: Colors.black.withOpacity(0.08),
// // // //                 blurRadius: 12.0,
// // // //                 offset: const Offset(0, 4),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           child: ClipRRect(
// // // //             borderRadius: BorderRadius.circular(15.0),
// // // //             child: SingleChildScrollView(
// // // //               // MODIFIED: Reduced vertical padding inside scroll view
// // // //               padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
// // // //               child: profilePageContent,
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildHeaderCard(ThemeData theme) {
// // // //     // Prioritize name from Firestore, then Auth, then fallback.
// // // //     final String displayName = _userData?['name'] as String? ?? _currentUser?.displayName ?? 'User';
// // // //     final String email = _currentUser?.email ?? 'No Email';
// // // //     final String profilePicUrl = _userData?['profilePictureUrl'] as String? ?? '';
// // // //     final bool isEmailVerified = _currentUser?.emailVerified ?? false;
// // // //     // Handle Firestore Timestamp for updatedAt
// // // //     final dynamic updatedAtRaw = _userData?['updatedAt'];
// // // //     DateTime? lastUpdated;
// // // //     if (updatedAtRaw is Timestamp) {
// // // //       lastUpdated = updatedAtRaw.toDate();
// // // //     } else if (updatedAtRaw is String) {
// // // //       lastUpdated = DateTime.tryParse(updatedAtRaw); // Or custom parsing if string format is known
// // // //     }


// // // //     String joinedDateString = "";
// // // //     final creationTime = _currentUser?.metadata.creationTime;
// // // //     if (creationTime != null) {
// // // //       joinedDateString = "Since ${DateFormat('MMM yyyy').format(creationTime)}";
// // // //     }

// // // //     // MODIFIED: Slightly reduced ribbon space
// // // //     const double ribbonSpace = 90.0;


// // // //     return Card(
// // // //       elevation: 2.0,
// // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
// // // //       clipBehavior: Clip.antiAlias,
// // // //       child: Stack(
// // // //         children: [
// // // //           // Main content of the card
// // // //           Padding(
// // // //             padding: const EdgeInsets.fromLTRB(16.0, 16.0, ribbonSpace, 16.0),
// // // //             child: Row(
// // // //               crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically in the row
// // // //               children: [
// // // //                 CircleAvatar(
// // // //                   // MODIFIED: Slightly smaller avatar
// // // //                   radius: 36,
// // // //                   backgroundColor: theme.colorScheme.surfaceContainerHighest,
// // // //                   foregroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
// // // //                   child: profilePicUrl.isEmpty ? Icon(Icons.person_outline, size: 38, color: theme.colorScheme.onSurfaceVariant) : null,
// // // //                 ),
// // // //                 // MODIFIED: Slightly smaller SizedBox
// // // //                 const SizedBox(width: 12),
// // // //                 Expanded(
// // // //                   child: Column(
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     mainAxisSize: MainAxisSize.min, // Crucial for Column inside Row to not over-expand
// // // //                     children: [
// // // //                       Text(
// // // //                         displayName,
// // // //                         style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), // Adjusted from headlineSmall
// // // //                         maxLines: 2, 
// // // //                         overflow: TextOverflow.ellipsis,
// // // //                       ),
// // // //                       const SizedBox(height: 2), // Reduced spacing
// // // //                       Text(
// // // //                         email, 
// // // //                         style: theme.textTheme.bodyMedium, // Adjusted from bodyLarge
// // // //                         maxLines: 2, // MODIFIED: Allow email to wrap to 2 lines
// // // //                         overflow: TextOverflow.ellipsis,
// // // //                       ),
// // // //                       if (!isEmailVerified)
// // // //                         Padding(
// // // //                           padding: const EdgeInsets.only(top: 5.0), // Adjusted padding
// // // //                           child: Container(
// // // //                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Adjusted padding
// // // //                             decoration: BoxDecoration(color: Colors.orange.withAlpha(38), borderRadius: BorderRadius.circular(4)),
// // // //                             child: Row(mainAxisSize: MainAxisSize.min, children: [
// // // //                               Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 13),
// // // //                               const SizedBox(width: 3),
// // // //                               Text("Email Not Verified", style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500))
// // // //                             ]),
// // // //                           ),
// // // //                         ),
// // // //                       if (lastUpdated != null) ...[
// // // //                         const SizedBox(height: 5), // Adjusted spacing
// // // //                         Text(
// // // //                           "Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastUpdated)}",
// // // //                           style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11), // Adjusted for conciseness
// // // //                            maxLines: 1,
// // // //                            overflow: TextOverflow.ellipsis,
// // // //                         )
// // // //                       ],
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),

// // // //           // Positioned Ribbon
// // // //           if (joinedDateString.isNotEmpty)
// // // //             Positioned(
// // // //               top: 16.0,
// // // //               right: 0, 
// // // //               child: Container(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
// // // //                 decoration: BoxDecoration(
// // // //                   color: theme.colorScheme.primary,
// // // //                   borderRadius: const BorderRadius.only(
// // // //                     topLeft: Radius.circular(6.0),
// // // //                     bottomLeft: Radius.circular(6.0),
// // // //                   ),
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: Colors.black.withOpacity(0.1),
// // // //                       blurRadius: 3,
// // // //                       offset: const Offset(-1,1)
// // // //                     )
// // // //                   ]
// // // //                 ),
// // // //                 child: Text(
// // // //                   joinedDateString,
// // // //                   style: theme.textTheme.bodySmall?.copyWith(
// // // //                     color: theme.colorScheme.onPrimary,
// // // //                     fontWeight: FontWeight.w500,
// // // //                     fontSize: 10, // Make ribbon text slightly smaller if needed
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildActionsCard(ThemeData theme) {
// // // //     return Card(
// // // //       elevation: 1.5,
// // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
// // // //       child: Column(
// // // //         children: [
// // // //           _buildActionTile(theme, icon: Icons.edit_note_outlined, title: "Personal Details", onTap: _navigateToEditProfile),
// // // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // // //           _buildActionTile(theme, icon: Icons.favorite_border_outlined, title: "My Favourites", onTap: () {
// // // //             if (!mounted) return;
// // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFavouritesScreen()));
// // // //           }),
// // // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // // //           _buildActionTile(theme, icon: Icons.event_note_outlined, title: "My Bookings", onTap: () {
// // // //             if (!mounted) return;
// // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
// // // //           }),
// // // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // // //           _buildActionTile(theme, icon: Icons.rate_review_outlined, title: "My Reviews", onTap: () {
// // // //             if (!mounted) return;
// // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
// // // //           }),
// // // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // // //           _buildActionTile(theme, icon: Icons.support_agent_outlined, title: "Help & Support", onTap: () {
// // // //             if (!mounted) return;
// // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
// // // //           }),
// // // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // // //           _buildActionTile(theme, icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {
// // // //             if (!mounted) return;
// // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
// // // //           }),
// // // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // // //           const SignOutButtonTile(), // Assuming this widget is styled appropriately
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildActionTile(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
// // // //     return ListTile(
// // // //       leading: Icon(icon, color: theme.colorScheme.secondary, size: 22), // Slightly smaller icon
// // // //       title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)), // titleSmall from titleMedium
// // // //       trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
// // // //       onTap: onTap,
// // // //       // MODIFIED: Reduced vertical padding in ListTile for compactness
// // // //       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0), 
// // // //       dense: true,
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:intl/intl.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // // import 'package:flutter/foundation.dart'; // Import for debugPrint
// // // import 'package:mm_associates/features/user/services/user_service.dart';
// // // import 'package:mm_associates/features/profile/screens/edit_profile_screen.dart';

// // // import 'my_favourites_screen.dart';
// // // import 'my_bookings_screen.dart';
// // // import 'my_reviews_screen.dart';
// // // import 'help_support_screen.dart';
// // // import 'privacy_policy_screen.dart';
// // // import 'sign_out_button_tile.dart'; // Import the sign out tile

// // // class ProfileScreen extends StatefulWidget {
// // //   const ProfileScreen({Key? key}) : super(key: key);
// // //   @override
// // //   _ProfileScreenState createState() => _ProfileScreenState();
// // // }

// // // class _ProfileScreenState extends State<ProfileScreen> {
// // //   final AuthService _authService = AuthService();
// // //   final UserService _userService = UserService();
// // //   User? _currentUser;
// // //   Map<String, dynamic>? _userData;
// // //   bool _isLoading = true;
// // //   String? _errorMessage;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadUserProfile();
// // //   }

// // //   void setStateIfMounted(VoidCallback fn) {
// // //     if (mounted) {
// // //       setState(fn);
// // //     }
// // //   }

// // //   Future<void> _loadUserProfile({bool forceRefresh = false}) async {
// // //     debugPrint(
// // //         '_loadUserProfile - Start: _isLoading: $_isLoading, _errorMessage: $_errorMessage, _currentUser: ${_currentUser?.uid}');
// // //     if (!mounted) return;
// // //     setStateIfMounted(() {
// // //       _isLoading = true;
// // //       _errorMessage = null;
// // //     });

// // //     _currentUser = _authService.getCurrentUser();
// // //     if (_currentUser == null) {
// // //       debugPrint('_loadUserProfile - User is null');
// // //       setStateIfMounted(() {
// // //         _isLoading = false;
// // //         _errorMessage = "User not logged in.";
// // //       });
// // //       return;
// // //     }

// // //     try {
// // //       // It's good practice to reload user to get fresh emailVerified status, etc.
// // //       await _currentUser?.reload();
// // //       _currentUser = _authService.getCurrentUser(); // Re-fetch after reload

// // //       _userData =
// // //           await _userService.getUserProfileData(forceRefresh: forceRefresh);
// // //       if (!mounted) return;
// // //       debugPrint('_loadUserProfile - User data loaded: ${_userData != null}');
// // //       setStateIfMounted(() {
// // //         _isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       debugPrint("Error loading profile: $e");
// // //       if (!mounted) return;
// // //       setStateIfMounted(() {
// // //         _isLoading = false;
// // //         _errorMessage = "Failed to load profile details.";
// // //       });
// // //     }
// // //   }

// // //   void _navigateToEditProfile() async {
// // //     if (_currentUser == null || _userData == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text("Profile data not loaded yet.")),
// // //       );
// // //       return;
// // //     }

// // //     // Ensure 'name' from userData is prioritized, fallback to Firebase displayName
// // //     final String currentName = _userData!['name'] as String? ?? _currentUser!.displayName ?? 'N/A';
// // //     final String currentEmail = _currentUser!.email ?? 'N/A'; // Email is from Auth User
// // //     final String? currentPhone = _userData!['phoneNumber'] as String?;
// // //     final String? currentProfilePicUrl = _userData!['profilePictureUrl'] as String?;
// // //     final String? currentBio = _userData!['bio'] as String?;
// // //     final Timestamp? dobTimestamp = _userData!['dateOfBirth'] as Timestamp?;
// // //     final DateTime? currentDateOfBirth = dobTimestamp?.toDate();
// // //     final String? currentGender = _userData!['gender'] as String?;
// // //     final String? currentAddressStreet = _userData!['addressStreet'] as String?;
// // //     final String? currentAddressCity = _userData!['addressCity'] as String?;
// // //     final String? currentAddressState = _userData!['addressState'] as String?;
// // //     final String? currentAddressZipCode = _userData!['addressZipCode'] as String?;
// // //     final String? currentAddressCountry = _userData!['addressCountry'] as String?;
// // //     final String? currentSocialMediaLink = _userData!['socialMediaLink'] as String?;

// // //     final result = await Navigator.push<bool>(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (context) => EditProfileScreen(
// // //           currentName: currentName,
// // //           currentEmail: currentEmail,
// // //           currentPhone: currentPhone,
// // //           currentProfilePicUrl: currentProfilePicUrl,
// // //           currentBio: currentBio,
// // //           currentDateOfBirth: currentDateOfBirth,
// // //           currentGender: currentGender,
// // //           currentAddressStreet: currentAddressStreet,
// // //           currentAddressCity: currentAddressCity,
// // //           currentAddressState: currentAddressState,
// // //           currentAddressZipCode: currentAddressZipCode,
// // //           currentAddressCountry: currentAddressCountry,
// // //           currentSocialMediaLink: currentSocialMediaLink,
// // //         ),
// // //       ),
// // //     );

// // //     if (result == true && mounted) {
// // //       _loadUserProfile(forceRefresh: true); // Force refresh if changes were saved
// // //     }
// // //   }


// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final ThemeData theme = Theme.of(context);
// // //     return Scaffold(
// // //       backgroundColor: theme.brightness == Brightness.light
// // //           ? Colors.grey[100]!
// // //           : theme.scaffoldBackgroundColor,
// // //       appBar: AppBar(
// // //         title: const Text('My Profile'),
// // //         elevation: 0,
// // //         backgroundColor: theme.brightness == Brightness.light ? Colors.grey[100]! : theme.scaffoldBackgroundColor,
// // //         foregroundColor: theme.colorScheme.onSurface,
// // //       ),
// // //       body: RefreshIndicator(
// // //         onRefresh: () => _loadUserProfile(forceRefresh: true),
// // //         child: _buildBody(theme),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildBody(ThemeData theme) {
// // //     if (_isLoading) {
// // //       return const Center(child: CircularProgressIndicator());
// // //     }

// // //     if (_errorMessage != null || _currentUser == null || _userData == null) {
// // //       return Center(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(20.0),
// // //           child: Column(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               Icon(Icons.error_outline, color: Colors.red[300], size: 60),
// // //               const SizedBox(height: 15),
// // //               Text(
// // //                 _errorMessage ?? "Could not load profile.",
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(color: Colors.red[700], fontSize: 16),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               ElevatedButton.icon(
// // //                 icon: const Icon(Icons.refresh),
// // //                 label: const Text("Try Again"),
// // //                 onPressed: () => _loadUserProfile(forceRefresh: true),
// // //                 style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.onError, backgroundColor: theme.colorScheme.error,)
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     // Determine if it's web or mobile like context (not strictly kIsWeb)
// // //     // For this example, we'll use a simple screen width check for layout
// // //     bool isTabletOrLarger = MediaQuery.of(context).size.width >= 720; // Threshold for web-like layout

// // //     if (isTabletOrLarger) { // Web-like or tablet layout - REVERTED TO ORIGINAL BOXED LAYOUT
// // //         return Center(
// // //           child: Padding(
// // //             // Original padding
// // //             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
// // //             child: Container(
// // //               constraints: BoxConstraints(
// // //                 maxWidth: 550, // Original max width
// // //                 maxHeight: MediaQuery.of(context).size.height * 0.9,
// // //               ),
// // //               decoration: BoxDecoration(
// // //                 color: theme.cardColor,
// // //                 borderRadius: BorderRadius.circular(16.0),
// // //                 border: Border.all(
// // //                   color: theme.dividerColor.withOpacity(0.5),
// // //                   width: 1.0,
// // //                 ),
// // //                 boxShadow: [
// // //                   BoxShadow(
// // //                     color: Colors.black.withOpacity(0.08),
// // //                     blurRadius: 12.0,
// // //                     offset: const Offset(0, 4),
// // //                   ),
// // //                 ],
// // //               ),
// // //               child: ClipRRect(
// // //                 borderRadius: BorderRadius.circular(15.0),
// // //                 child: SingleChildScrollView(
// // //                   // Original padding inside scroll view
// // //                   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
// // //                   child: Column( // Original Column for stacking header and actions
// // //                     mainAxisSize: MainAxisSize.min,
// // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // //                     children: [
// // //                        _buildHeaderSection(theme),
// // //                        const SizedBox(height: 16),
// // //                        _buildActionsSection(theme),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         );
// // //     } else { // Mobile layout (stacked) - without the outer box
// // //         return SingleChildScrollView(
// // //           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.stretch,
// // //             children: [
// // //               _buildHeaderSection(theme),
// // //               const SizedBox(height: 16), 
// // //               _buildActionsSection(theme),
// // //               const SizedBox(height: 24), 
// // //             ],
// // //           ),
// // //         );
// // //     }
// // //   }

// // //   Widget _buildHeaderSection(ThemeData theme) {
// // //     return _buildHeaderCard(theme);
// // //   }

// // //   Widget _buildActionsSection(ThemeData theme) {
// // //     return _buildActionsCard(theme);
// // //   }


// // //   Widget _buildHeaderCard(ThemeData theme) {
// // //     final String displayName = _userData?['name'] as String? ?? _currentUser?.displayName ?? 'User';
// // //     final String email = _currentUser?.email ?? 'No Email';
// // //     final String profilePicUrl = _userData?['profilePictureUrl'] as String? ?? '';
// // //     final bool isEmailVerified = _currentUser?.emailVerified ?? false;
// // //     final dynamic updatedAtRaw = _userData?['updatedAt'];
// // //     DateTime? lastUpdated;
// // //     if (updatedAtRaw is Timestamp) {
// // //       lastUpdated = updatedAtRaw.toDate();
// // //     } else if (updatedAtRaw is String) {
// // //       lastUpdated = DateTime.tryParse(updatedAtRaw);
// // //     }

// // //     String joinedDateString = "";
// // //     final creationTime = _currentUser?.metadata.creationTime;
// // //     if (creationTime != null) {
// // //       joinedDateString = "Since ${DateFormat('MMM yyyy').format(creationTime)}";
// // //     }

// // //     const double ribbonSpace = 90.0; // Space for the "Joined since" ribbon

// // //     return Card(
// // //       elevation: 2.0,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
// // //       clipBehavior: Clip.antiAlias,
// // //       margin: EdgeInsets.zero,
// // //       child: Stack(
// // //         children: [
// // //           Padding(
// // //             padding: const EdgeInsets.fromLTRB(16.0, 16.0, ribbonSpace, 16.0),
// // //             child: Row(
// // //               crossAxisAlignment: CrossAxisAlignment.center,
// // //               children: [
// // //                 CircleAvatar(
// // //                   radius: 36,
// // //                   backgroundColor: theme.colorScheme.surfaceContainerHighest,
// // //                   foregroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
// // //                   child: profilePicUrl.isEmpty ? Icon(Icons.person_outline, size: 38, color: theme.colorScheme.onSurfaceVariant) : null,
// // //                 ),
// // //                 const SizedBox(width: 12),
// // //                 Expanded(
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     mainAxisSize: MainAxisSize.min,
// // //                     children: [
// // //                       Text(
// // //                         displayName,
// // //                         style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
// // //                         maxLines: 2,
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                       const SizedBox(height: 2),
// // //                       Text(
// // //                         email,
// // //                         style: theme.textTheme.bodyMedium,
// // //                         maxLines: 2,
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                       if (!isEmailVerified)
// // //                         Padding(
// // //                           padding: const EdgeInsets.only(top: 5.0),
// // //                           child: Container(
// // //                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// // //                             decoration: BoxDecoration(color: Colors.orange.withAlpha(38), borderRadius: BorderRadius.circular(4)),
// // //                             child: Row(mainAxisSize: MainAxisSize.min, children: [
// // //                               Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 13),
// // //                               const SizedBox(width: 3),
// // //                               Text("Email Not Verified", style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500))
// // //                             ]),
// // //                           ),
// // //                         ),
// // //                       if (lastUpdated != null) ...[
// // //                         const SizedBox(height: 5),
// // //                         Text(
// // //                           "Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastUpdated)}",
// // //                           style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
// // //                           maxLines: 2, // MODIFIED: Allow wrapping to 2 lines
// // //                           overflow: TextOverflow.ellipsis, // Ellipsis if it still exceeds
// // //                         )
// // //                       ],
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           if (joinedDateString.isNotEmpty)
// // //             Positioned(
// // //               top: 16.0,
// // //               right: 0,
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
// // //                 decoration: BoxDecoration(
// // //                   color: theme.colorScheme.primary,
// // //                   borderRadius: const BorderRadius.only(
// // //                     topLeft: Radius.circular(6.0),
// // //                     bottomLeft: Radius.circular(6.0),
// // //                   ),
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: Colors.black.withOpacity(0.1),
// // //                       blurRadius: 3,
// // //                       offset: const Offset(-1,1)
// // //                     )
// // //                   ]
// // //                 ),
// // //                 child: Text(
// // //                   joinedDateString,
// // //                   style: theme.textTheme.bodySmall?.copyWith(
// // //                     color: theme.colorScheme.onPrimary,
// // //                     fontWeight: FontWeight.w500,
// // //                     fontSize: 10,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildActionsCard(ThemeData theme) {
// // //     return Card(
// // //       elevation: 1.5,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
// // //       margin: EdgeInsets.zero,
// // //       child: Column(
// // //         mainAxisAlignment: MainAxisAlignment.start,
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           _buildActionTile(theme, icon: Icons.edit_note_outlined, title: "Personal Details", onTap: _navigateToEditProfile),
// // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // //           _buildActionTile(theme, icon: Icons.favorite_border_outlined, title: "My Favourites", onTap: () {
// // //             if (!mounted) return;
// // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFavouritesScreen()));
// // //           }),
// // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // //           _buildActionTile(theme, icon: Icons.event_note_outlined, title: "My Bookings", onTap: () {
// // //             if (!mounted) return;
// // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
// // //           }),
// // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // //           _buildActionTile(theme, icon: Icons.rate_review_outlined, title: "My Reviews", onTap: () {
// // //             if (!mounted) return;
// // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
// // //           }),
// // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // //           _buildActionTile(theme, icon: Icons.support_agent_outlined, title: "Help & Support", onTap: () {
// // //             if (!mounted) return;
// // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
// // //           }),
// // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // //           _buildActionTile(theme, icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {
// // //             if (!mounted) return;
// // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
// // //           }),
// // //           const Divider(height: 0, indent: 16, endIndent: 16),
// // //           const SignOutButtonTile(),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildActionTile(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
// // //     return ListTile(
// // //       leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
// // //       title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
// // //       trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
// // //       onTap: onTap,
// // //       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
// // //       dense: true,
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:intl/intl.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // import 'package:flutter/foundation.dart'; // Import for debugPrint
// // import 'package:mm_associates/features/user/services/user_service.dart';
// // import 'package:mm_associates/features/profile/screens/edit_profile_screen.dart';

// // import 'my_favourites_screen.dart';
// // import 'my_bookings_screen.dart';
// // import 'my_reviews_screen.dart';
// // import 'help_support_screen.dart';
// // import 'privacy_policy_screen.dart';
// // import 'sign_out_button_tile.dart'; // Import the sign out tile

// // class ProfileScreen extends StatefulWidget {
// //   const ProfileScreen({Key? key}) : super(key: key);
// //   @override
// //   _ProfileScreenState createState() => _ProfileScreenState();
// // }

// // class _ProfileScreenState extends State<ProfileScreen> {
// //   final AuthService _authService = AuthService();
// //   final UserService _userService = UserService();
// //   User? _currentUser;
// //   Map<String, dynamic>? _userData;
// //   bool _isLoading = true;
// //   String? _errorMessage;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUserProfile();
// //   }

// //   void setStateIfMounted(VoidCallback fn) {
// //     if (mounted) {
// //       setState(fn);
// //     }
// //   }

// //   Future<void> _loadUserProfile({bool forceRefresh = false}) async {
// //     debugPrint(
// //         '_loadUserProfile - Start: _isLoading: $_isLoading, _errorMessage: $_errorMessage, _currentUser: ${_currentUser?.uid}');
// //     if (!mounted) return;
// //     setStateIfMounted(() {
// //       _isLoading = true;
// //       _errorMessage = null;
// //     });

// //     _currentUser = _authService.getCurrentUser();
// //     if (_currentUser == null) {
// //       debugPrint('_loadUserProfile - User is null');
// //       setStateIfMounted(() {
// //         _isLoading = false;
// //         _errorMessage = "User not logged in.";
// //       });
// //       return;
// //     }

// //     try {
// //       await _currentUser?.reload();
// //       _currentUser = _authService.getCurrentUser();

// //       _userData =
// //           await _userService.getUserProfileData(forceRefresh: forceRefresh);
// //       if (!mounted) return;
// //       debugPrint('_loadUserProfile - User data loaded: ${_userData != null}');
// //       setStateIfMounted(() {
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       debugPrint("Error loading profile: $e");
// //       if (!mounted) return;
// //       setStateIfMounted(() {
// //         _isLoading = false;
// //         _errorMessage = "Failed to load profile details.";
// //       });
// //     }
// //   }

// //   void _navigateToEditProfile() async {
// //     if (_currentUser == null || _userData == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Profile data not loaded yet.")),
// //       );
// //       return;
// //     }

// //     final String currentName = _userData!['name'] as String? ?? _currentUser!.displayName ?? 'N/A';
// //     final String currentEmail = _currentUser!.email ?? 'N/A';
// //     final String? currentPhone = _userData!['phoneNumber'] as String?;
// //     final String? currentProfilePicUrl = _userData!['profilePictureUrl'] as String?;
// //     final String? currentBio = _userData!['bio'] as String?;
// //     final Timestamp? dobTimestamp = _userData!['dateOfBirth'] as Timestamp?;
// //     final DateTime? currentDateOfBirth = dobTimestamp?.toDate();
// //     final String? currentGender = _userData!['gender'] as String?;
// //     final String? currentAddressStreet = _userData!['addressStreet'] as String?;
// //     final String? currentAddressCity = _userData!['addressCity'] as String?;
// //     final String? currentAddressState = _userData!['addressState'] as String?;
// //     final String? currentAddressZipCode = _userData!['addressZipCode'] as String?;
// //     final String? currentAddressCountry = _userData!['addressCountry'] as String?;
// //     final String? currentSocialMediaLink = _userData!['socialMediaLink'] as String?;

// //     final result = await Navigator.push<bool>(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => EditProfileScreen(
// //           currentName: currentName,
// //           currentEmail: currentEmail,
// //           currentPhone: currentPhone,
// //           currentProfilePicUrl: currentProfilePicUrl,
// //           currentBio: currentBio,
// //           currentDateOfBirth: currentDateOfBirth,
// //           currentGender: currentGender,
// //           currentAddressStreet: currentAddressStreet,
// //           currentAddressCity: currentAddressCity,
// //           currentAddressState: currentAddressState,
// //           currentAddressZipCode: currentAddressZipCode,
// //           currentAddressCountry: currentAddressCountry,
// //           currentSocialMediaLink: currentSocialMediaLink,
// //         ),
// //       ),
// //     );

// //     if (result == true && mounted) {
// //       _loadUserProfile(forceRefresh: true);
// //     }
// //   }


// //   @override
// //   Widget build(BuildContext context) {
// //     final ThemeData theme = Theme.of(context);
// //     return Scaffold(
// //       backgroundColor: theme.brightness == Brightness.light
// //           ? Colors.grey[100]!
// //           : theme.scaffoldBackgroundColor,
// //       appBar: AppBar(
// //         title: const Text('My Profile'),
// //         elevation: 0,
// //         backgroundColor: theme.brightness == Brightness.light ? Colors.grey[100]! : theme.scaffoldBackgroundColor,
// //         foregroundColor: theme.colorScheme.onSurface,
// //       ),
// //       body: RefreshIndicator(
// //         onRefresh: () => _loadUserProfile(forceRefresh: true),
// //         child: _buildBody(theme),
// //       ),
// //     );
// //   }

// //   Widget _buildBody(ThemeData theme) {
// //     if (_isLoading) {
// //       return const Center(child: CircularProgressIndicator());
// //     }

// //     if (_errorMessage != null || _currentUser == null || _userData == null) {
// //       return Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(20.0),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Icon(Icons.error_outline, color: Colors.red[300], size: 60),
// //               const SizedBox(height: 15),
// //               Text(
// //                 _errorMessage ?? "Could not load profile.",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(color: Colors.red[700], fontSize: 16),
// //               ),
// //               const SizedBox(height: 20),
// //               ElevatedButton.icon(
// //                 icon: const Icon(Icons.refresh),
// //                 label: const Text("Try Again"),
// //                 onPressed: () => _loadUserProfile(forceRefresh: true),
// //                 style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.onError, backgroundColor: theme.colorScheme.error,)
// //               ),
// //             ],
// //           ),
// //         ),
// //       );
// //     }

// //     bool isTabletOrLarger = MediaQuery.of(context).size.width >= 720; 

// //     if (isTabletOrLarger) { 
// //         return Center(
// //           child: Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
// //             child: Container(
// //               constraints: BoxConstraints(
// //                 maxWidth: 550, 
// //                 maxHeight: MediaQuery.of(context).size.height * 0.9,
// //               ),
// //               decoration: BoxDecoration(
// //                 color: theme.cardColor,
// //                 borderRadius: BorderRadius.circular(16.0),
// //                 border: Border.all(
// //                   color: theme.dividerColor.withOpacity(0.5),
// //                   width: 1.0,
// //                 ),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black.withOpacity(0.08),
// //                     blurRadius: 12.0,
// //                     offset: const Offset(0, 4),
// //                   ),
// //                 ],
// //               ),
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(15.0),
// //                 child: SingleChildScrollView(
// //                   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
// //                   child: Column( 
// //                     mainAxisSize: MainAxisSize.min,
// //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// //                     children: [
// //                        _buildHeaderSection(theme),
// //                        const SizedBox(height: 16),
// //                        _buildActionsSection(theme),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         );
// //     } else { 
// //         return SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               _buildHeaderSection(theme),
// //               const SizedBox(height: 16), 
// //               _buildActionsSection(theme),
// //               const SizedBox(height: 24), 
// //             ],
// //           ),
// //         );
// //     }
// //   }

// //   Widget _buildHeaderSection(ThemeData theme) {
// //     return _buildHeaderCard(theme);
// //   }

// //   Widget _buildActionsSection(ThemeData theme) {
// //     return _buildActionsCard(theme);
// //   }


// //   Widget _buildHeaderCard(ThemeData theme) {
// //     final String displayName = _userData?['name'] as String? ?? _currentUser?.displayName ?? 'User';
// //     final String email = _currentUser?.email ?? 'No Email';
// //     final String profilePicUrl = _userData?['profilePictureUrl'] as String? ?? '';
// //     final bool isEmailVerified = _currentUser?.emailVerified ?? false;
// //     final dynamic updatedAtRaw = _userData?['updatedAt'];
// //     DateTime? lastUpdated;
// //     if (updatedAtRaw is Timestamp) {
// //       lastUpdated = updatedAtRaw.toDate();
// //     } else if (updatedAtRaw is String) {
// //       lastUpdated = DateTime.tryParse(updatedAtRaw);
// //     }

// //     String joinedDateString = "";
// //     final creationTime = _currentUser?.metadata.creationTime;
// //     if (creationTime != null) {
// //       joinedDateString = "Since ${DateFormat('MMM yyyy').format(creationTime)}";
// //     }

// //     // MODIFIED: Reduced ribbonSpace to give more horizontal room to the text
// //     const double ribbonSpace = 80.0; 

// //     return Card(
// //       elevation: 2.0,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
// //       clipBehavior: Clip.antiAlias,
// //       margin: EdgeInsets.zero,
// //       child: Stack(
// //         children: [
// //           Padding(
// //             padding: EdgeInsets.fromLTRB(16.0, 16.0, ribbonSpace, 16.0),
// //             child: Row(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: [
// //                 CircleAvatar(
// //                   radius: 36,
// //                   backgroundColor: theme.colorScheme.surfaceContainerHighest,
// //                   foregroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
// //                   child: profilePicUrl.isEmpty ? Icon(Icons.person_outline, size: 38, color: theme.colorScheme.onSurfaceVariant) : null,
// //                 ),
// //                 const SizedBox(width: 12),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       Text(
// //                         displayName,
// //                         style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
// //                         maxLines: 2,
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                       const SizedBox(height: 2),
// //                       Text(
// //                         email,
// //                         style: theme.textTheme.bodyMedium,
// //                         maxLines: 2,
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                       if (!isEmailVerified)
// //                         Padding(
// //                           padding: const EdgeInsets.only(top: 5.0),
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //                             decoration: BoxDecoration(color: Colors.orange.withAlpha(38), borderRadius: BorderRadius.circular(4)),
// //                             child: Row(mainAxisSize: MainAxisSize.min, children: [
// //                               Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 13),
// //                               const SizedBox(width: 3),
// //                               Text("Email Not Verified", style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500))
// //                             ]),
// //                           ),
// //                         ),
// //                       if (lastUpdated != null) ...[
// //                         const SizedBox(height: 5),
// //                         Text(
// //                           "Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastUpdated)}",
// //                           style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
// //                           maxLines: 2, 
// //                           overflow: TextOverflow.ellipsis, 
// //                         )
// //                       ],
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           if (joinedDateString.isNotEmpty)
// //             Positioned(
// //               top: 16.0,
// //               right: 0,
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
// //                 decoration: BoxDecoration(
// //                   color: theme.colorScheme.primary,
// //                   borderRadius: const BorderRadius.only(
// //                     topLeft: Radius.circular(6.0),
// //                     bottomLeft: Radius.circular(6.0),
// //                   ),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black.withOpacity(0.1),
// //                       blurRadius: 3,
// //                       offset: const Offset(-1,1)
// //                     )
// //                   ]
// //                 ),
// //                 child: Text(
// //                   joinedDateString,
// //                   style: theme.textTheme.bodySmall?.copyWith(
// //                     color: theme.colorScheme.onPrimary,
// //                     fontWeight: FontWeight.w500,
// //                     fontSize: 10,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildActionsCard(ThemeData theme) {
// //     return Card(
// //       elevation: 1.5,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
// //       margin: EdgeInsets.zero,
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.start,
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           _buildActionTile(theme, icon: Icons.edit_note_outlined, title: "Personal Details", onTap: _navigateToEditProfile),
// //           const Divider(height: 0, indent: 16, endIndent: 16),
// //           _buildActionTile(theme, icon: Icons.favorite_border_outlined, title: "My Favourites", onTap: () {
// //             if (!mounted) return;
// //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFavouritesScreen()));
// //           }),
// //           const Divider(height: 0, indent: 16, endIndent: 16),
// //           _buildActionTile(theme, icon: Icons.event_note_outlined, title: "My Bookings", onTap: () {
// //             if (!mounted) return;
// //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
// //           }),
// //           const Divider(height: 0, indent: 16, endIndent: 16),
// //           _buildActionTile(theme, icon: Icons.rate_review_outlined, title: "My Reviews", onTap: () {
// //             if (!mounted) return;
// //             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
// //           }),
// //           const Divider(height: 0, indent: 16, endIndent: 16),
// //           _buildActionTile(theme, icon: Icons.support_agent_outlined, title: "Help & Support", onTap: () {
// //             if (!mounted) return;
// //             Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
// //           }),
// //           const Divider(height: 0, indent: 16, endIndent: 16),
// //           _buildActionTile(theme, icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {
// //             if (!mounted) return;
// //             Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
// //           }),
// //           const Divider(height: 0, indent: 16, endIndent: 16),
// //           const SignOutButtonTile(),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildActionTile(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
// //     return ListTile(
// //       leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
// //       title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
// //       trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
// //       onTap: onTap,
// //       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
// //       dense: true,
// //     );
// //   }
// // }


// //admin related changes----
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mm_associates/features/auth/services/auth_service.dart';
// import 'package:flutter/foundation.dart'; // Import for debugPrint
// import 'package:mm_associates/features/user/services/user_service.dart';
// import 'package:mm_associates/features/profile/screens/edit_profile_screen.dart';

// import 'my_venues_screen.dart'; // <<< ADDED IMPORT FOR ADMIN
// import 'my_favourites_screen.dart';
// import 'my_bookings_screen.dart';
// import 'my_reviews_screen.dart';
// import 'help_support_screen.dart';
// import 'privacy_policy_screen.dart';
// import 'sign_out_button_tile.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);
//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final AuthService _authService = AuthService();
//   final UserService _userService = UserService();
//   User? _currentUser;
//   Map<String, dynamic>? _userData;
//   bool _isLoading = true;
//   String? _errorMessage;
//   bool _isAdmin = false; // <<< ADDED STATE FOR ADMIN ROLE

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//   }

//   void setStateIfMounted(VoidCallback fn) {
//     if (mounted) {
//       setState(fn);
//     }
//   }

//   Future<void> _loadUserProfile({bool forceRefresh = false}) async {
//     if (!mounted) return;
//     setStateIfMounted(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     _currentUser = _authService.getCurrentUser();
//     if (_currentUser == null) {
//       setStateIfMounted(() {
//         _isLoading = false;
//         _errorMessage = "User not logged in.";
//       });
//       return;
//     }

//     try {
//       await _currentUser?.reload();
//       _currentUser = _authService.getCurrentUser();

//       // Fetch user data and admin status in parallel for efficiency
//       final results = await Future.wait([
//         _userService.getUserProfileData(forceRefresh: forceRefresh),
//         _userService.isCurrentUserAdmin(),
//       ]);

//       if (!mounted) return;
      
//       _userData = results[0] as Map<String, dynamic>?;
//       final bool isAdmin = results[1] as bool;

//       debugPrint('_loadUserProfile - User data loaded: ${_userData != null}, isAdmin: $isAdmin');
      
//       setStateIfMounted(() {
//         _isAdmin = isAdmin;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint("Error loading profile: $e");
//       if (!mounted) return;
//       setStateIfMounted(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load profile details.";
//       });
//     }
//   }

//   void _navigateToEditProfile() async {
//     if (_currentUser == null || _userData == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile data not loaded yet.")),
//       );
//       return;
//     }

//     final String currentName = _userData!['name'] as String? ?? _currentUser!.displayName ?? 'N/A';
//     final String currentEmail = _currentUser!.email ?? 'N/A';
//     final String? currentPhone = _userData!['phoneNumber'] as String?;
//     final String? currentProfilePicUrl = _userData!['profilePictureUrl'] as String?;
//     final String? currentBio = _userData!['bio'] as String?;
//     final Timestamp? dobTimestamp = _userData!['dateOfBirth'] as Timestamp?;
//     final DateTime? currentDateOfBirth = dobTimestamp?.toDate();
//     final String? currentGender = _userData!['gender'] as String?;
//     final String? currentAddressStreet = _userData!['addressStreet'] as String?;
//     final String? currentAddressCity = _userData!['addressCity'] as String?;
//     final String? currentAddressState = _userData!['addressState'] as String?;
//     final String? currentAddressZipCode = _userData!['addressZipCode'] as String?;
//     final String? currentAddressCountry = _userData!['addressCountry'] as String?;
//     final String? currentSocialMediaLink = _userData!['socialMediaLink'] as String?;

//     final result = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditProfileScreen(
//           currentName: currentName,
//           currentEmail: currentEmail,
//           currentPhone: currentPhone,
//           currentProfilePicUrl: currentProfilePicUrl,
//           currentBio: currentBio,
//           currentDateOfBirth: currentDateOfBirth,
//           currentGender: currentGender,
//           currentAddressStreet: currentAddressStreet,
//           currentAddressCity: currentAddressCity,
//           currentAddressState: currentAddressState,
//           currentAddressZipCode: currentAddressZipCode,
//           currentAddressCountry: currentAddressCountry,
//           currentSocialMediaLink: currentSocialMediaLink,
//         ),
//       ),
//     );

//     if (result == true && mounted) {
//       _loadUserProfile(forceRefresh: true);
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: theme.brightness == Brightness.light
//           ? Colors.grey[100]!
//           : theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text('My Profile'),
//         elevation: 0,
//         backgroundColor: theme.brightness == Brightness.light ? Colors.grey[100]! : theme.scaffoldBackgroundColor,
//         foregroundColor: theme.colorScheme.onSurface,
//       ),
//       body: RefreshIndicator(
//         onRefresh: () => _loadUserProfile(forceRefresh: true),
//         child: _buildBody(theme),
//       ),
//     );
//   }

//   Widget _buildBody(ThemeData theme) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_errorMessage != null || _currentUser == null || _userData == null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, color: Colors.red[300], size: 60),
//               const SizedBox(height: 15),
//               Text(
//                 _errorMessage ?? "Could not load profile.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.red[700], fontSize: 16),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.refresh),
//                 label: const Text("Try Again"),
//                 onPressed: () => _loadUserProfile(forceRefresh: true),
//                 style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.onError, backgroundColor: theme.colorScheme.error,)
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     bool isTabletOrLarger = MediaQuery.of(context).size.width >= 720; 

//     if (isTabletOrLarger) { 
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: 550, 
//                 maxHeight: MediaQuery.of(context).size.height * 0.9,
//               ),
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
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
//                   child: Column( 
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                        _buildHeaderSection(theme),
//                        const SizedBox(height: 16),
//                        _buildActionsSection(theme),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//     } else { 
//         return SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildHeaderSection(theme),
//               const SizedBox(height: 16), 
//               _buildActionsSection(theme),
//               const SizedBox(height: 24), 
//             ],
//           ),
//         );
//     }
//   }

//   Widget _buildHeaderSection(ThemeData theme) {
//     return _buildHeaderCard(theme);
//   }

//   Widget _buildActionsSection(ThemeData theme) {
//     return _buildActionsCard(theme);
//   }

//   Widget _buildHeaderCard(ThemeData theme) {
//     final String displayName = _userData?['name'] as String? ?? _currentUser?.displayName ?? 'User';
//     final String email = _currentUser?.email ?? 'No Email';
//     final String profilePicUrl = _userData?['profilePictureUrl'] as String? ?? '';
//     final bool isEmailVerified = _currentUser?.emailVerified ?? false;
//     final dynamic updatedAtRaw = _userData?['updatedAt'];
//     DateTime? lastUpdated;
//     if (updatedAtRaw is Timestamp) {
//       lastUpdated = updatedAtRaw.toDate();
//     } else if (updatedAtRaw is String) {
//       lastUpdated = DateTime.tryParse(updatedAtRaw);
//     }

//     String joinedDateString = "";
//     final creationTime = _currentUser?.metadata.creationTime;
//     if (creationTime != null) {
//       joinedDateString = "Since ${DateFormat('MMM yyyy').format(creationTime)}";
//     }
    
//     const double ribbonSpace = 80.0; 

//     return Card(
//       elevation: 2.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       clipBehavior: Clip.antiAlias,
//       margin: EdgeInsets.zero,
//       child: Stack(
//         children: [
//           Padding(
//             padding: EdgeInsets.fromLTRB(16.0, 16.0, ribbonSpace, 16.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 36,
//                   backgroundColor: theme.colorScheme.surfaceContainerHighest,
//                   foregroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
//                   child: profilePicUrl.isEmpty ? Icon(Icons.person_outline, size: 38, color: theme.colorScheme.onSurfaceVariant) : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         displayName,
//                         style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         email,
//                         style: theme.textTheme.bodyMedium,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if (!isEmailVerified)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 5.0),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(color: Colors.orange.withAlpha(38), borderRadius: BorderRadius.circular(4)),
//                             child: Row(mainAxisSize: MainAxisSize.min, children: [
//                               Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 13),
//                               const SizedBox(width: 3),
//                               Text("Email Not Verified", style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500))
//                             ]),
//                           ),
//                         ),
//                       if (lastUpdated != null) ...[
//                         const SizedBox(height: 5),
//                         Text(
//                           "Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastUpdated)}",
//                           style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
//                           maxLines: 2, 
//                           overflow: TextOverflow.ellipsis, 
//                         )
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (joinedDateString.isNotEmpty)
//             Positioned(
//               top: 16.0,
//               right: 0,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.primary,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(6.0),
//                     bottomLeft: Radius.circular(6.0),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 3,
//                       offset: const Offset(-1,1)
//                     )
//                   ]
//                 ),
//                 child: Text(
//                   joinedDateString,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onPrimary,
//                     fontWeight: FontWeight.w500,
//                     fontSize: 10,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // <<< MODIFIED WIDGET TO BE ROLE-AWARE >>>
//   Widget _buildActionsCard(ThemeData theme) {
//     // A list to hold the action tiles which we will build dynamically.
//     List<Widget> actionTiles = [];

//     // Personal Details - Common for all users
//     actionTiles.add(_buildActionTile(theme, icon: Icons.edit_note_outlined, title: "Personal Details", onTap: _navigateToEditProfile));
//     actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
    
//     // Role-specific tiles
//     if (_isAdmin) {
//       // Tiles for Admin users
//       actionTiles.add(_buildActionTile(
//         theme, 
//         icon: Icons.store_mall_directory_outlined, 
//         title: "My Venues", 
//         onTap: () {
//           if (!mounted) return;
//           Navigator.push(context, MaterialPageRoute(builder: (context) => const MyVenuesScreen()));
//         }
//       ));
//     } else {
//       // Tiles for regular users
//       actionTiles.add(_buildActionTile(theme, icon: Icons.favorite_border_outlined, title: "My Favourites", onTap: () {
//         if (!mounted) return;
//         Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFavouritesScreen()));
//       }));
//       actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
//       actionTiles.add(_buildActionTile(theme, icon: Icons.event_note_outlined, title: "My Bookings", onTap: () {
//         if (!mounted) return;
//         Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
//       }));
//       actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
//       actionTiles.add(_buildActionTile(theme, icon: Icons.rate_review_outlined, title: "My Reviews", onTap: () {
//         if (!mounted) return;
//         Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
//       }));
//     }
    
//     // Common tiles for all users
//     actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
//     actionTiles.add(_buildActionTile(theme, icon: Icons.support_agent_outlined, title: "Help & Support", onTap: () {
//       if (!mounted) return;
//       Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
//     }));
//     actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
//     actionTiles.add(_buildActionTile(theme, icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {
//       if (!mounted) return;
//       Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
//     }));
//     actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
//     actionTiles.add(const SignOutButtonTile());

//     return Card(
//       elevation: 1.5,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       margin: EdgeInsets.zero,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: actionTiles,
//       ),
//     );
//   }

//   Widget _buildActionTile(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
//     return ListTile(
//       leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
//       title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
//       trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
//       onTap: onTap,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
//       dense: true,
//     );
//   }
// }


//---my bookings for admins---
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:mm_associates/features/user/services/user_service.dart';
import 'package:mm_associates/features/profile/screens/edit_profile_screen.dart';

// MODIFICATION: Import the new screen for admin bookings
import 'package:mm_associates/features/admin/screens/admin_bookings_screen.dart';

import 'my_venues_screen.dart'; 
import 'my_favourites_screen.dart';
import 'my_bookings_screen.dart';
import 'my_reviews_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'sign_out_button_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    if (!mounted) return;
    setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _currentUser = _authService.getCurrentUser();
    if (_currentUser == null) {
      setStateIfMounted(() {
        _isLoading = false;
        _errorMessage = "User not logged in.";
      });
      return;
    }

    try {
      await _currentUser?.reload();
      _currentUser = _authService.getCurrentUser();

      final results = await Future.wait([
        _userService.getUserProfileData(forceRefresh: forceRefresh),
        _userService.isCurrentUserAdmin(),
      ]);

      if (!mounted) return;
      
      _userData = results[0] as Map<String, dynamic>?;
      final bool isAdmin = results[1] as bool;

      debugPrint('_loadUserProfile - User data loaded: ${_userData != null}, isAdmin: $isAdmin');
      
      setStateIfMounted(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (!mounted) return;
      setStateIfMounted(() {
        _isLoading = false;
        _errorMessage = "Failed to load profile details.";
      });
    }
  }

  void _navigateToEditProfile() async {
    if (_currentUser == null || _userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile data not loaded yet.")),
      );
      return;
    }

    final String currentName = _userData!['name'] as String? ?? _currentUser!.displayName ?? 'N/A';
    final String currentEmail = _currentUser!.email ?? 'N/A';
    final String? currentPhone = _userData!['phoneNumber'] as String?;
    final String? currentProfilePicUrl = _userData!['profilePictureUrl'] as String?;
    final String? currentBio = _userData!['bio'] as String?;
    final Timestamp? dobTimestamp = _userData!['dateOfBirth'] as Timestamp?;
    final DateTime? currentDateOfBirth = dobTimestamp?.toDate();
    final String? currentGender = _userData!['gender'] as String?;
    final String? currentAddressStreet = _userData!['addressStreet'] as String?;
    final String? currentAddressCity = _userData!['addressCity'] as String?;
    final String? currentAddressState = _userData!['addressState'] as String?;
    final String? currentAddressZipCode = _userData!['addressZipCode'] as String?;
    final String? currentAddressCountry = _userData!['addressCountry'] as String?;
    final String? currentSocialMediaLink = _userData!['socialMediaLink'] as String?;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: currentName,
          currentEmail: currentEmail,
          currentPhone: currentPhone,
          currentProfilePicUrl: currentProfilePicUrl,
          currentBio: currentBio,
          currentDateOfBirth: currentDateOfBirth,
          currentGender: currentGender,
          currentAddressStreet: currentAddressStreet,
          currentAddressCity: currentAddressCity,
          currentAddressState: currentAddressState,
          currentAddressZipCode: currentAddressZipCode,
          currentAddressCountry: currentAddressCountry,
          currentSocialMediaLink: currentSocialMediaLink,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadUserProfile(forceRefresh: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.grey[100]!
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: theme.brightness == Brightness.light ? Colors.grey[100]! : theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadUserProfile(forceRefresh: true),
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _currentUser == null || _userData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 60),
              const SizedBox(height: 15),
              Text(
                _errorMessage ?? "Could not load profile.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                onPressed: () => _loadUserProfile(forceRefresh: true),
                style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.onError, backgroundColor: theme.colorScheme.error,)
              ),
            ],
          ),
        ),
      );
    }

    bool isTabletOrLarger = MediaQuery.of(context).size.width >= 720; 

    if (isTabletOrLarger) { 
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 550, 
                maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column( 
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       _buildHeaderSection(theme),
                       const SizedBox(height: 16),
                       _buildActionsSection(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    } else { 
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(theme),
              const SizedBox(height: 16), 
              _buildActionsSection(theme),
              const SizedBox(height: 24), 
            ],
          ),
        );
    }
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return _buildHeaderCard(theme);
  }

  Widget _buildActionsSection(ThemeData theme) {
    return _buildActionsCard(theme);
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final String displayName = _userData?['name'] as String? ?? _currentUser?.displayName ?? 'User';
    final String email = _currentUser?.email ?? 'No Email';
    final String profilePicUrl = _userData?['profilePictureUrl'] as String? ?? '';
    final bool isEmailVerified = _currentUser?.emailVerified ?? false;
    final dynamic updatedAtRaw = _userData?['updatedAt'];
    DateTime? lastUpdated;
    if (updatedAtRaw is Timestamp) {
      lastUpdated = updatedAtRaw.toDate();
    } else if (updatedAtRaw is String) {
      lastUpdated = DateTime.tryParse(updatedAtRaw);
    }

    String joinedDateString = "";
    final creationTime = _currentUser?.metadata.creationTime;
    if (creationTime != null) {
      joinedDateString = "Since ${DateFormat('MMM yyyy').format(creationTime)}";
    }
    
    const double ribbonSpace = 80.0; 

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, ribbonSpace, 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                  child: profilePicUrl.isEmpty ? Icon(Icons.person_outline, size: 38, color: theme.colorScheme.onSurfaceVariant) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isEmailVerified)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.withAlpha(38), borderRadius: BorderRadius.circular(4)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 13),
                              const SizedBox(width: 3),
                              Text("Email Not Verified", style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500))
                            ]),
                          ),
                        ),
                      if (lastUpdated != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          "Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastUpdated)}",
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                        )
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (joinedDateString.isNotEmpty)
            Positioned(
              top: 16.0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6.0),
                    bottomLeft: Radius.circular(6.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(-1,1)
                    )
                  ]
                ),
                child: Text(
                  joinedDateString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // MODIFIED: Added Venue Bookings for admin.
  Widget _buildActionsCard(ThemeData theme) {
    List<Widget> actionTiles = [];

    // Personal Details - Common for all users
    actionTiles.add(_buildActionTile(theme, icon: Icons.edit_note_outlined, title: "Personal Details", onTap: _navigateToEditProfile));
    actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
    
    // Role-specific tiles
    if (_isAdmin) {
      // Tiles for Admin users
      actionTiles.add(_buildActionTile(
        theme, 
        icon: Icons.store_mall_directory_outlined, 
        title: "My Venues", 
        onTap: () {
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MyVenuesScreen()));
        }
      ));
      
      // <<< THIS IS THE NEWLY ADDED TILE FOR ADMINS >>>
      actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
      actionTiles.add(_buildActionTile(
        theme, 
        icon: Icons.event_available_outlined, 
        title: "Venue Bookings", 
        onTap: () {
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingsScreen()));
        }
      ));
      // <<< END OF NEWLY ADDED TILE >>>

    } else {
      // Tiles for regular users
      actionTiles.add(_buildActionTile(theme, icon: Icons.favorite_border_outlined, title: "My Favourites", onTap: () {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFavouritesScreen()));
      }));
      actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
      actionTiles.add(_buildActionTile(theme, icon: Icons.event_note_outlined, title: "My Bookings", onTap: () {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
      }));
      actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
      actionTiles.add(_buildActionTile(theme, icon: Icons.rate_review_outlined, title: "My Reviews", onTap: () {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
      }));
    }
    
    // Common tiles for all users
    actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
    actionTiles.add(_buildActionTile(theme, icon: Icons.support_agent_outlined, title: "Help & Support", onTap: () {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
    }));
    actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
    actionTiles.add(_buildActionTile(theme, icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
    }));
    actionTiles.add(const Divider(height: 0, indent: 16, endIndent: 16));
    actionTiles.add(const SignOutButtonTile());

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: actionTiles,
      ),
    );
  }

  Widget _buildActionTile(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      dense: true,
    );
  }
}