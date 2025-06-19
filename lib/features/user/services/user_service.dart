import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mm_associates/features/data/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mm_associates/core/services/image_upload_service.dart'; // <--- IMPORT NEW SERVICE

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ImageUploadService _imageUploadService = ImageUploadService(); // <--- INSTANTIATE

  static const String _usersCollection = 'mm_users';
  static const String _favoritesField = 'favoriteVenueIds';
  static const String _profilePictureUploadPreset = 'mm_associates_profile_pics';

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  Future<String?> uploadProfilePicture(XFile imageXFile) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");

    try {
      debugPrint("UserService: Calling ImageUploadService to upload to Cloudinary...");
      final String? cloudinaryUrl = await _imageUploadService.uploadImageToCloudinary(
        imageXFile,
        uploadPreset: _profilePictureUploadPreset,
        folder: 'profile_pictures/$userId' // Optional: organize in Cloudinary by user ID
      );

      if (cloudinaryUrl != null) {
        debugPrint("UserService: Cloudinary URL received: $cloudinaryUrl. Updating Firestore.");
        await updateProfilePictureUrl(cloudinaryUrl);
        return cloudinaryUrl; // Return the URL for immediate UI update if needed
      } else {
        throw Exception("Failed to get URL from Cloudinary.");
      }
    } catch (e) {
      debugPrint('UserService: Error in uploadProfilePicture orchestrator: $e');
      throw Exception("Profile picture upload failed overall: $e");
    }
  }

  Future<void> updateProfilePictureUrl(String? url) async {
     final userId = _currentUserId;
     if (userId == null) throw Exception("User not logged in");
     await _updateUserData(userId, {'profilePictureUrl': url}); // Send null to remove
   }


  Future<void> addFavorite(String venueId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");
    if (venueId.isEmpty) return;
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      await userDocRef.update({_favoritesField: FieldValue.arrayUnion([venueId])});
    } catch (e) { debugPrint("Error adding favorite: $e"); throw Exception("Could not add favorite."); }
  }

  Future<void> removeFavorite(String venueId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");
    if (venueId.isEmpty) return;
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      await userDocRef.update({_favoritesField: FieldValue.arrayRemove([venueId])});
    } catch (e) { debugPrint("Error removing favorite: $e"); throw Exception("Could not remove favorite.");}
  }

  Future<bool> isVenueFavorite(String venueId) async {
    final userId = _currentUserId;
    if (userId == null || venueId.isEmpty) return false;
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final favorites = data?[_favoritesField] as List<dynamic>? ?? [];
        return favorites.contains(venueId);
      } return false;
    } catch (e) { debugPrint("Error checking if favorite: $e"); return false; }
  }

  Stream<List<String>> getFavoriteVenueIdsStream() {
     final userId = _currentUserId;
     if (userId == null) return Stream.value([]);
     return _firestore.collection(_usersCollection).doc(userId).snapshots().map((snapshot) {
        if (!snapshot.exists) return <String>[];
        final data = snapshot.data();
        final favorites = data?[_favoritesField] as List<dynamic>? ?? [];
        return favorites.cast<String>().toList();
     }).handleError((error) { debugPrint("Error getting favorite venue IDs stream: $error"); return <String>[]; });
  }

  Future<List<String>> getFavoriteVenueIds() async {
    final userId = _currentUserId;
    if (userId == null) return [];
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final favorites = data?[_favoritesField] as List<dynamic>? ?? [];
        return favorites.cast<String>().toList();
      } return [];
    } catch (e) { debugPrint("Error getting favorite venue IDs: $e"); return []; }
  }

  Future<List<Map<String, dynamic>>> getFavoriteVenues() async {
    final List<String> favoriteIds = await getFavoriteVenueIds();
    if (favoriteIds.isEmpty) return [];
    List<Map<String, dynamic>> favoriteVenuesData = [];
    try {
      for (String venueId in favoriteIds) {
        final venueData = await _firestoreService.getVenueDetails(venueId);
        if (venueData != null) { favoriteVenuesData.add(venueData); }
        else { debugPrint("Favorite venue $venueId not found or error fetching details.");}
      }
      favoriteVenuesData.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
      return favoriteVenuesData;
    } catch (e) { debugPrint("Error fetching details for favorite venues: $e"); throw Exception("Failed to load favorite venues.");}
  }

  Future<Map<String, dynamic>?> getUserProfileData({bool forceRefresh = false}) async {
    final userId = _currentUserId;
    if (userId == null) { debugPrint("User not logged in, cannot fetch profile data."); return null; }
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      return userDoc.data();
    } catch (e) { debugPrint("Error fetching user profile data for UID $userId: $e"); return null;}
  }

  Future<void> _updateUserData(String userId, Map<String, dynamic> dataToUpdate) async {
    if (userId.isEmpty) throw Exception("User ID invalid");
    try {
      Map<String, dynamic> finalUpdateData = Map.from(dataToUpdate);
      finalUpdateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_usersCollection).doc(userId).update(finalUpdateData);
    } catch (e) { debugPrint('Error updating user data for UID $userId: $e'); throw Exception("Failed to update profile data in Firestore.");}
  }

  Future<void> updateUserProfileData(Map<String, dynamic> dataToUpdate) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");
    await _updateUserData(userId, dataToUpdate);
  }

  Future<void> updateUserName(String name) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");
    if (name.trim().isEmpty || name.trim().length < 2) throw Exception("Invalid name");
    await _updateUserData(userId, {'name': name.trim()});
  }

  Future<void> updatePhoneNumber(String? phoneNumber, {bool? isVerified}) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");
    Map<String, dynamic> phoneUpdateData = {'phoneNumber': phoneNumber?.trim()};
    if (isVerified != null) { phoneUpdateData['phoneVerified'] = isVerified; }
    await _updateUserData(userId, phoneUpdateData);
  }

  Future<void> updateUserEmailInFirestore(String newEmail) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in");
    await _updateUserData(userId, {'email': newEmail.trim(), 'emailVerified': false});
  }

   Future<bool> isCurrentUserAdmin() async {
    final User? currentUser = _firebaseAuth.currentUser;

    // If no user is logged in, they are not an admin.
    if (currentUser == null) {
      return false;
    }

    try {
      final docSnapshot = await _firestore.collection('mm_users').doc(currentUser.uid).get();

      if (docSnapshot.exists && docSnapshot.data()?['isAdmin'] == true) {
        debugPrint("User is an admin.");
        return true;
      }
    } catch (e) {
      debugPrint("Error checking admin status: $e");
      return false;
    }

    debugPrint("User is not an admin.");
    return false;
  }

}