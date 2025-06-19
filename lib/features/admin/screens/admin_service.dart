// lib/features/admin/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all bookings for venues created by the currently logged-in admin.
  Future<List<Map<String, dynamic>>> fetchBookingsForAdminVenues() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in.");
    }

    try {
      // Step 1: Find all venues created by the current admin.
      final venuesSnapshot = await _firestore
          .collection('mm_venues')
          .where('creatorUid', isEqualTo: currentUser.uid)
          .get();

      if (venuesSnapshot.docs.isEmpty) {
        // The admin has no venues, so there can be no bookings.
        return [];
      }

      // Step 2: Extract the IDs of these venues.
      final List<String> adminVenueIds =
          venuesSnapshot.docs.map((doc) => doc.id).toList();

      if (adminVenueIds.isEmpty) {
        return [];
      }

      // Step 3: Query the bookings collection for any booking whose venueId
      // is in the list of the admin's venue IDs.
      // Firestore 'whereIn' queries are limited to 30 items per query. 
      // If you expect more venues, this needs pagination. For now, this is sufficient.
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('venueId', whereIn: adminVenueIds)
          .orderBy('bookingStartTime', descending: true) // Show newest bookings first
          .get();

      // Combine booking data with its document ID
      return bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['bookingId'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      print("Error fetching admin bookings: $e");
      throw Exception("Failed to load bookings. Please try again.");
    }
  }
  
  /// Fetches a single user's profile data.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails(String userId) {
    return _firestore.collection('mm_users').doc(userId).get();
  }
}