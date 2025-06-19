// // lib/features/bookings/services/booking_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:mm_associates/features/auth/services/auth_service.dart'; // To get user name

// class BookingService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//   final AuthService _authService = AuthService(); // To get user details

//   static const String _bookingsCollection = 'bookings';

//   String? get _currentUserId => _firebaseAuth.currentUser?.uid;

//   // --- Slot Calculation ---

//   /// Calculates potential booking slots for a given date based on operating hours.
//   List<DateTime> getPotentialSlots(DateTime date, Map<String, dynamic>? operatingHoursData, int slotDurationMinutes) {
//     List<DateTime> slots = [];
//     if (operatingHoursData == null || slotDurationMinutes <= 0) {
//         debugPrint("Cannot calculate slots: Missing operating hours or invalid slot duration.");
//         return slots;
//     }

//     String dayKey = _getDayKey(date.weekday);
//     final dayHours = operatingHoursData[dayKey] as Map<String, dynamic>?;

//     // Enhanced check for dayHours and its content
//     if (dayHours == null || dayHours['start'] == null || dayHours['end'] == null || 
//         dayHours['start'] == 'null' || dayHours['end'] == 'null') { // ADDED CHECK FOR STRING "null"
//         debugPrint("Operating hours not defined, null, or string 'null' for $dayKey on $date. Start: ${dayHours?['start']}, End: ${dayHours?['end']}");
//         return slots;
//     }

//     try {
//       final String startTimeStr = dayHours['start'] as String; 
//       final String endTimeStr = dayHours['end'] as String;   

//       if (!startTimeStr.contains(':') || !endTimeStr.contains(':')) {
//           debugPrint("Operating hours format error for $dayKey on $date. Start: '$startTimeStr', End: '$endTimeStr'. Expected HH:MM.");
//           return slots;
//       }
      
//       final List<String> startParts = startTimeStr.split(':');
//       final List<String> endParts = endTimeStr.split(':');

//       if (startParts.length != 2 || endParts.length != 2) {
//           debugPrint("Operating hours format error (parts) for $dayKey on $date. Start: '$startTimeStr', End: '$endTimeStr'. Expected HH:MM.");
//           return slots;
//       }

//       final int? startHour = int.tryParse(startParts[0]);
//       final int? startMinute = int.tryParse(startParts[1]);
//       final int? endHour = int.tryParse(endParts[0]);
//       final int? endMinute = int.tryParse(endParts[1]);

//       if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
//         debugPrint("Operating hours format error (parsing int) for $dayKey on $date. Could not parse numbers from '$startTimeStr' or '$endTimeStr'.");
//         return slots;
//       }

//       DateTime currentSlotTime = DateTime(date.year, date.month, date.day, startHour, startMinute);
//       final closingTime = DateTime(date.year, date.month, date.day, endHour, endMinute);

//       if (currentSlotTime.isAfter(closingTime) || currentSlotTime.isAtSameMomentAs(closingTime)) {
//           debugPrint("Start time is at or after closing time for $dayKey on $date.");
//           return slots;
//       }

//       while (currentSlotTime.add(Duration(minutes: slotDurationMinutes)).isBefore(closingTime) ||
//              currentSlotTime.add(Duration(minutes: slotDurationMinutes)).isAtSameMomentAs(closingTime)) {
//         slots.add(currentSlotTime);
//         currentSlotTime = currentSlotTime.add(Duration(minutes: slotDurationMinutes));
//         if (slots.length > 100) { 
//             debugPrint("Potential infinite loop in slot generation for $dayKey on $date. Breaking after 100 slots.");
//             break;
//         }
//       }
//     } catch (e, stacktrace) { 
//        debugPrint("Error parsing operating hours or calculating slots for $date ($dayKey): $e\nStacktrace: $stacktrace");
//        return []; 
//     }

//     return slots;
//   }

//   // Helper to get the correct key for operatingHours map based on weekday
//   String _getDayKey(int weekday) {
//       // Assumes 1=Monday, 7=Sunday (DateTime.weekday)
//       // Match this to the keys used in your Firestore `operatingHours` map
//      switch (weekday) {
//          case DateTime.saturday: return 'saturday';
//          case DateTime.sunday: return 'sunday';
//          default: return 'weekday'; // Or handle Mon, Tue, etc. individually
//      }
//   }


//   // --- Booking Fetching ---

//   /// Fetches bookings for a specific venue on a given date range (usually a single day).
//   Future<List<Map<String, dynamic>>> getBookingsForDate(String venueId, DateTime date) async {
//     try {
//         // Create Timestamp range for the selected date
//         final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0));
//         final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));

//         final querySnapshot = await _firestore
//             .collection(_bookingsCollection)
//             .where('venueId', isEqualTo: venueId)
//             .where('bookingStartTime', isGreaterThanOrEqualTo: startOfDay)
//             .where('bookingStartTime', isLessThanOrEqualTo: endOfDay)
//             // Fetch all statuses to determine booked slots (pending, confirmed etc.)
//             .get();

//         return querySnapshot.docs.map((doc) {
//             final data = doc.data();
//             data['id'] = doc.id; // Add document ID
//             return data;
//         }).toList();
//     } catch (e) {
//       debugPrint("Error fetching bookings for $venueId on $date: $e");
//       throw Exception("Failed to load existing bookings.");
//     }
//   }

//   /// Fetches all bookings for the current user.
//   Future<List<Map<String, dynamic>>> getMyBookings() async {
//     final userId = _currentUserId;
//     if (userId == null) {
//        // User not logged in, return empty or throw error depending on context
//        debugPrint("getMyBookings: User not logged in.");
//        return [];
//     }

//     try {
//         final querySnapshot = await _firestore
//             .collection(_bookingsCollection)
//             .where('userId', isEqualTo: userId)
//             .orderBy('bookingStartTime', descending: true) // Show newest first
//             .get();

//         return querySnapshot.docs.map((doc) {
//            final data = doc.data();
//            data['id'] = doc.id; // Add document ID
//            return data;
//        }).toList();
//     } catch (e) {
//         debugPrint("Error fetching user bookings for $userId: $e");
//         throw Exception("Failed to load your bookings.");
//     }
//   }

//   // --- Booking Actions ---

//   /// Creates a new booking request document in Firestore.
//   Future<DocumentReference> createBookingRequest({
//     required String venueId,
//     required String venueName, // Denormalized
//     required DateTime startTime,
//     required int durationMinutes,
//     String? notes,
//   }) async {
//     final userId = _currentUserId;
//     final currentUser = _firebaseAuth.currentUser;

//     if (userId == null || currentUser == null) {
//         throw Exception("User must be logged in to book.");
//     }

//     // Fetch user name for denormalization
//     final userData = await _authService.getUserProfileData(); // Use existing service method
//     final userName = userData?['name'] as String? ?? currentUser.email?.split('@')[0] ?? 'User';

//     final DateTime endTime = startTime.add(Duration(minutes: durationMinutes));
//     final bookingData = {
//         'venueId': venueId,
//         'venueName': venueName,
//         'userId': userId,
//         'userName': userName,
//         'bookingStartTime': Timestamp.fromDate(startTime),
//         'bookingEndTime': Timestamp.fromDate(endTime),
//         'status': 'pending', // Initial status for MVP
//         'createdAt': FieldValue.serverTimestamp(),
//         if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
//     };

//     try {
//         // Add the new booking document
//         return await _firestore.collection(_bookingsCollection).add(bookingData);
//     } catch (e) {
//         debugPrint("Error creating booking request: $e");
//         throw Exception("Could not create booking request.");
//     }
//   }

//   /// Allows a user to cancel their own booking (if status allows).
//   Future<void> cancelUserBooking(String bookingId) async {
//     final userId = _currentUserId;
//     if (userId == null) throw Exception("User not logged in.");
//     if (bookingId.isEmpty) throw Exception("Invalid booking ID.");

//     final bookingRef = _firestore.collection(_bookingsCollection).doc(bookingId);

//     try {
//       final bookingDoc = await bookingRef.get();
//        if (!bookingDoc.exists) throw Exception("Booking not found.");

//       final bookingData = bookingDoc.data()!;
//        if (bookingData['userId'] != userId) throw Exception("Permission denied: Not your booking.");

//       final currentStatus = bookingData['status'];
//        // Allow cancellation only for 'pending' or 'confirmed' statuses by user
//       if (currentStatus != 'pending' && currentStatus != 'confirmed') {
//           throw Exception("Booking cannot be cancelled in its current state ($currentStatus).");
//       }

//       await bookingRef.update({
//         'status': 'cancelled_user',
//          // Optional: add cancellation timestamp
//          'cancelledAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//         debugPrint("Error cancelling booking $bookingId: $e");
//          if (e is FirebaseException) {
//             throw Exception("Could not cancel booking (${e.code}). Please try again.");
//          } else {
//             rethrow; // Rethrow specific exceptions like permission denied or cannot cancel
//          }
//     }
//   }

//     // Potential Future Methods:
//     // - updateBookingStatus (for Admins)
//     // - deleteBooking (handle carefully, maybe just mark as deleted)
// }



//-handling race condition---

// lib/features/bookings/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  static const String _bookingsCollection = 'bookings';

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  // UNCHANGED METHODS (getPotentialSlots, getDayKey, getBookingsForDate, getMyBookings)
  List<DateTime> getPotentialSlots(DateTime date, Map<String, dynamic>? operatingHoursData, int slotDurationMinutes) {
    List<DateTime> slots = [];
    if (operatingHoursData == null || slotDurationMinutes <= 0) {
        debugPrint("Cannot calculate slots: Missing operating hours or invalid slot duration.");
        return slots;
    }
    String dayKey = _getDayKey(date.weekday);
    final dayHours = operatingHoursData[dayKey] as Map<String, dynamic>?;
    if (dayHours == null || dayHours['start'] == null || dayHours['end'] == null || 
        dayHours['start'] == 'null' || dayHours['end'] == 'null') {
        debugPrint("Operating hours not defined, null, or string 'null' for $dayKey on $date. Start: ${dayHours?['start']}, End: ${dayHours?['end']}");
        return slots;
    }
    try {
      final String startTimeStr = dayHours['start'] as String; 
      final String endTimeStr = dayHours['end'] as String;   
      if (!startTimeStr.contains(':') || !endTimeStr.contains(':')) {
          debugPrint("Operating hours format error for $dayKey on $date. Start: '$startTimeStr', End: '$endTimeStr'. Expected HH:MM.");
          return slots;
      }
      final List<String> startParts = startTimeStr.split(':');
      final List<String> endParts = endTimeStr.split(':');
      if (startParts.length != 2 || endParts.length != 2) {
          debugPrint("Operating hours format error (parts) for $dayKey on $date. Start: '$startTimeStr', End: '$endTimeStr'. Expected HH:MM.");
          return slots;
      }
      final int? startHour = int.tryParse(startParts[0]);
      final int? startMinute = int.tryParse(startParts[1]);
      final int? endHour = int.tryParse(endParts[0]);
      final int? endMinute = int.tryParse(endParts[1]);
      if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
        debugPrint("Operating hours format error (parsing int) for $dayKey on $date. Could not parse numbers from '$startTimeStr' or '$endTimeStr'.");
        return slots;
      }
      DateTime currentSlotTime = DateTime(date.year, date.month, date.day, startHour, startMinute);
      final closingTime = DateTime(date.year, date.month, date.day, endHour, endMinute);
      if (currentSlotTime.isAfter(closingTime) || currentSlotTime.isAtSameMomentAs(closingTime)) {
          debugPrint("Start time is at or after closing time for $dayKey on $date.");
          return slots;
      }
      while (currentSlotTime.add(Duration(minutes: slotDurationMinutes)).isBefore(closingTime) ||
             currentSlotTime.add(Duration(minutes: slotDurationMinutes)).isAtSameMomentAs(closingTime)) {
        slots.add(currentSlotTime);
        currentSlotTime = currentSlotTime.add(Duration(minutes: slotDurationMinutes));
        if (slots.length > 100) { 
            debugPrint("Potential infinite loop in slot generation for $dayKey on $date. Breaking after 100 slots.");
            break;
        }
      }
    } catch (e, stacktrace) { 
       debugPrint("Error parsing operating hours or calculating slots for $date ($dayKey): $e\nStacktrace: $stacktrace");
       return []; 
    }
    return slots;
  }
  
  String _getDayKey(int weekday) {
     switch (weekday) {
         case DateTime.saturday: return 'saturday';
         case DateTime.sunday: return 'sunday';
         default: return 'weekday';
     }
  }

  Future<List<Map<String, dynamic>>> getBookingsForDate(String venueId, DateTime date) async {
    try {
        final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0));
        final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));
        final querySnapshot = await _firestore
            .collection(_bookingsCollection)
            .where('venueId', isEqualTo: venueId)
            .where('bookingStartTime', isGreaterThanOrEqualTo: startOfDay)
            .where('bookingStartTime', isLessThanOrEqualTo: endOfDay)
            .get();
        return querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
        }).toList();
    } catch (e) {
      debugPrint("Error fetching bookings for $venueId on $date: $e");
      throw Exception("Failed to load existing bookings.");
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final userId = _currentUserId;
    if (userId == null) {
       debugPrint("getMyBookings: User not logged in.");
       return [];
    }
    try {
        final querySnapshot = await _firestore
            .collection(_bookingsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('bookingStartTime', descending: true)
            .get();
        return querySnapshot.docs.map((doc) {
           final data = doc.data();
           data['id'] = doc.id;
           return data;
       }).toList();
    } catch (e) {
        debugPrint("Error fetching user bookings for $userId: $e");
        throw Exception("Failed to load your bookings.");
    }
  }


  // ===================== START OF CORRECTED METHOD =====================

  /// Creates a new booking request document in Firestore atomically using a transaction.
  /// This version correctly implements the conflict check.
  Future<DocumentReference> createBookingRequest({
    required String venueId,
    required String venueName,
    required DateTime startTime,
    required int durationMinutes,
    String? notes,
  }) async {
    final userId = _currentUserId;
    final currentUser = _firebaseAuth.currentUser;
    if (userId == null || currentUser == null) {
      throw Exception("User must be logged in to book.");
    }

    final userData = await _authService.getUserProfileData();
    final userName = userData?['name'] as String? ?? currentUser.email?.split('@')[0] ?? 'User';
    final DateTime endTime = startTime.add(Duration(minutes: durationMinutes));
    
    // Create a reference for the new booking *before* the transaction.
    final newBookingRef = _firestore.collection(_bookingsCollection).doc();

    try {
      // Use runTransaction to return a value, in this case, the new booking reference.
      final DocumentReference resultingRef = await _firestore.runTransaction((transaction) async {
        
        // 1. **Initial Read (Outside Transaction Scope but immediately before)**:
        //    Fetch documents that *might* conflict. This narrows down the documents
        //    we need to lock and re-read inside the transaction.
        final conflictQuery = _firestore
            .collection(_bookingsCollection)
            .where('venueId', isEqualTo: venueId)
            .where('status', whereIn: ['pending', 'confirmed'])
            .where('bookingStartTime', isLessThan: endTime);
        
        // Execute this initial query.
        final preliminaryConflictSnapshot = await conflictQuery.get();

        // 2. **Transactional Read and Validation**:
        //    Now we check each potential conflict inside the transaction.
        for (final doc in preliminaryConflictSnapshot.docs) {
          // Re-read the document using `transaction.get()`. This is the crucial part.
          // It ensures we have the latest version of the document and locks it
          // until our transaction is complete.
          final freshDoc = await transaction.get(doc.reference);

          final existingBookingEndTime = (freshDoc.data()?['bookingEndTime'] as Timestamp).toDate();

          // If the fresh data shows a conflict, abort by throwing an exception.
          if (existingBookingEndTime.isAfter(startTime)) {
            throw Exception("One or more of the selected time slots have just been booked. Please refresh and try again.");
          }
        }
        
        // 3. **Transactional Write**:
        //    If we reach here, no conflicts were found. Proceed with creating the new booking.
        final bookingData = {
          'venueId': venueId,
          'venueName': venueName,
          'userId': userId,
          'userName': userName,
          'bookingStartTime': Timestamp.fromDate(startTime),
          'bookingEndTime': Timestamp.fromDate(endTime),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        };

        transaction.set(newBookingRef, bookingData);

        // Return the reference to be passed out of the transaction on success.
        return newBookingRef;
      });

      return resultingRef;

    } catch (e) {
      debugPrint("Error during booking transaction: $e");
      if (e is Exception) {
         rethrow;
      }
      throw Exception("Could not create booking request. Please try again.");
    }
  }

  // ===================== END OF CORRECTED METHOD =====================


  /// Allows a user to cancel their own booking (if status allows).
  Future<void> cancelUserBooking(String bookingId) async {
    // UNCHANGED
    final userId = _currentUserId;
    if (userId == null) throw Exception("User not logged in.");
    if (bookingId.isEmpty) throw Exception("Invalid booking ID.");

    final bookingRef = _firestore.collection(_bookingsCollection).doc(bookingId);

    try {
      final bookingDoc = await bookingRef.get();
       if (!bookingDoc.exists) throw Exception("Booking not found.");

      final bookingData = bookingDoc.data()!;
       if (bookingData['userId'] != userId) throw Exception("Permission denied: Not your booking.");

      final currentStatus = bookingData['status'];
      if (currentStatus != 'pending' && currentStatus != 'confirmed') {
          throw Exception("Booking cannot be cancelled in its current state ($currentStatus).");
      }

      await bookingRef.update({
        'status': 'cancelled_user',
         'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
        debugPrint("Error cancelling booking $bookingId: $e");
         if (e is FirebaseException) {
            throw Exception("Could not cancel booking (${e.code}). Please try again.");
         } else {
            rethrow;
         }
    }
  }
}