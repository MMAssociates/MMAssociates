// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:mm_associates/core/services/location_service.dart'; // Assuming this is the correct path

// // class FirestoreService {
// //   final FirebaseFirestore _db = FirebaseFirestore.instance;
// //   final LocationService _locationService = LocationService();

// //   static const String _usersCollection = 'mm_users';
// //   static const String _venuesCollection = 'mm_venues';
// //   static const String _reviewsSubCollection = 'mm_reviews';

// // Future<bool> checkVenueNameExists(String nameLowercase, String? currentVenueIdToExclude) async {
// //   Query query = _db.collection('mm_venues').where('name_lowercase', isEqualTo: nameLowercase);
// //   // If in edit mode, we want to see if *another* venue has this name.
// //   // So, we exclude the current venue being edited from the check.
// //   if (currentVenueIdToExclude != null) {
// //     query = query.where(FieldPath.documentId, isNotEqualTo: currentVenueIdToExclude);
// //   }
// //   final snapshot = await query.limit(1).get();
// //   return snapshot.docs.isNotEmpty;
// // }

// //   Future<Map<String, dynamic>?> getUserData(String uid) async {
// //     try {
// //       DocumentSnapshot doc = await _db.collection(_usersCollection).doc(uid).get();
// //       if (doc.exists) {
// //         return doc.data() as Map<String, dynamic>?;
// //       }
// //       return null;
// //     } catch (e) {
// //       debugPrint('Error fetching user data for UID $uid from FirestoreService: $e');
// //       return null;
// //     }
// //   }

// // Future<List<Map<String, dynamic>>> getVenues({
// //     Position? userLocation,
// //     double? radiusInKm,
// //     String? cityFilter,
// //     String? searchQuery,
// //     String? sportFilter,
// //     int? limit,
// //     bool forSuggestions = false, // Hint to distinguish calls
// //   }) async {
// //     try {
// //       Query query = _db.collection(_venuesCollection).where('isActive', isEqualTo: true);

// //       // --- SERVER-SIDE FILTERING ---

// //       if (cityFilter != null && cityFilter.isNotEmpty) {
// //         query = query.where('city', isEqualTo: cityFilter);
// //         debugPrint("FirestoreService: Applying SERVER-SIDE city filter: '$cityFilter'");
// //       }

// //       final bool hasSearchQuery = searchQuery != null && searchQuery.trim().isNotEmpty;

// //       if (hasSearchQuery) {
// //         // Split the search query into individual lowercase words/terms
// //         // Using a Set first removes duplicates if user types "new new"
// //         List<String> searchTerms = searchQuery.trim().toLowerCase().split(' ').where((term) => term.isNotEmpty).toSet().toList();

// //         if (searchTerms.isNotEmpty) {
// //           // Use array-contains-any for matching keywords
// //           // Firestore limits array-contains-any to 10 items in the 'values' list.
// //           // If searchTerms could be longer, you might need to take only the first 10
// //           // or perform multiple queries (more complex). For typical search, <10 is common.
// //           query = query.where('searchKeywords', arrayContainsAny: searchTerms.take(10).toList());
// //           debugPrint("FirestoreService: Applying SERVER-SIDE keyword search (arrayContainsAny on searchKeywords): $searchTerms");
// //         }
// //       }

// //       // Sport Filter:
// //       // If you have a search query using arrayContainsAny, adding another arrayContains
// //       // for sportFilter on the server might require very specific composite indexes
// //       // or might not be supported directly with complex arrayContainsAny.
// //       // It's often safer to apply sport filter client-side when a keyword search is active.
// //       if (sportFilter != null && sportFilter.isNotEmpty) {
// //         if (!hasSearchQuery) { // Apply server-side only if no keyword search
// //           query = query.where('sportType', arrayContains: sportFilter);
// //           debugPrint("FirestoreService: Applying SERVER-SIDE sport filter (arrayContains): '$sportFilter'");
// //         } else {
// //           debugPrint("FirestoreService: Sport filter ('$sportFilter') will be applied CLIENT-SIDE due to active keyword search.");
// //         }
// //       }
// //       if ((!hasSearchQuery || !forSuggestions)) { // Default sort for general lists or if search doesn't dictate order
// //           query = query.orderBy('name');
// //       }
// //       if (forSuggestions && hasSearchQuery) {
// //           query = query.orderBy('name'); // Assuming index supports this
// //       }


// //       if (limit != null && limit > 0) {
// //         query = query.limit(limit);
// //       }

// //       debugPrint("FirestoreService: Final Query (before .get()): ${query.parameters}"); // Helps see constructed query

// //       QuerySnapshot snapshot = await query.get();

// //       List<Map<String, dynamic>> fetchedVenues = snapshot.docs.map((doc) {
// //         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
// //         data['id'] = doc.id;
// //         data['averageRating'] = data['averageRating'] ?? 0.0;
// //         data['reviewCount'] = data['reviewCount'] ?? 0;
// //         return data;
// //       }).toList();

// //       debugPrint("FirestoreService: Fetched ${fetchedVenues.length} venues from server (Query: '$searchQuery', Limit: $limit, ForSuggestions: $forSuggestions)");
// //       if (fetchedVenues.isEmpty && hasSearchQuery) {
// //           debugPrint("FirestoreService: No venues found directly from server keyword search for '$searchQuery'.");
// //       }

// //       List<Map<String, dynamic>> results = fetchedVenues;


// //       if (hasSearchQuery && sportFilter != null && sportFilter.isNotEmpty) {
// //         String lowerCaseSportFilter = sportFilter.trim().toLowerCase();
// //         results = results.where((venue) {
// //           final List<String> sportTypesInVenue = (venue['sportType'] as List<dynamic>?)
// //               ?.whereType<String>().map((s) => s.toLowerCase()).toList() ?? [];
// //           return sportTypesInVenue.contains(lowerCaseSportFilter);
// //         }).toList();
// //         debugPrint("FirestoreService: Applied CLIENT-SIDE sport filter. Results count: ${results.length}");
// //       }
// //       if (hasSearchQuery && !forSuggestions && results.isNotEmpty) {
// //           String fullQueryLower = searchQuery.trim().toLowerCase();
// //           List<Map<String, dynamic>> clientSideRefinedResults = results.where((venue) {
// //               final String name = (venue['name'] as String? ?? '').toLowerCase();
// //               if (name.contains(fullQueryLower)) return true;
// //               return false; // if no explicit client-side match criteria here pass, then rely on server only.
// //           }).toList();
// //       }


// //       if (userLocation != null) {
// //         for (var venue in results) {
// //           final GeoPoint? venueGeoPoint = venue['location'] as GeoPoint?;
// //           final num? venueLatNum = venue['latitude'] as num?;
// //           final num? venueLngNum = venue['longitude'] as num?;
// //           double? venueLat, venueLng;

// //           if (venueGeoPoint != null) {
// //             venueLat = venueGeoPoint.latitude;
// //             venueLng = venueGeoPoint.longitude;
// //           } else if (venueLatNum != null && venueLngNum != null) {
// //             venueLat = venueLatNum.toDouble();
// //             venueLng = venueLngNum.toDouble();
// //           }

// //           if (venueLat != null && venueLng != null) {
// //             try {
// //               venue['distance'] = _locationService.calculateDistance(
// //                 userLocation.latitude, userLocation.longitude, venueLat, venueLng,
// //               );
// //             } catch (e) {
// //               debugPrint("Error calculating distance for venue ${venue['id']}: $e");
// //               venue['distance'] = null;
// //             }
// //           } else {
// //             venue['distance'] = null;
// //           }
// //         }
// //       }

// //       if (radiusInKm != null && userLocation != null && results.any((v) => v['distance'] != null)) {
// //         if (!hasSearchQuery && (sportFilter == null || sportFilter.isEmpty)) { // Apply radius only if no search/sport filter
// //           debugPrint("FirestoreService: Applying proximity filter (radius: $radiusInKm km)");
// //           results = results.where((venue) {
// //             final distance = venue['distance'] as double?;
// //             return distance != null && distance <= radiusInKm;
// //           }).toList();
// //         }
// //       }

// //       // Client-Side Sorting (Important if server couldn't order perfectly or for distance)
// //       if (results.isNotEmpty) {
// //         results.sort((a, b) {
// //           final distA = a['distance'] as double?;
// //           final distB = b['distance'] as double?;

// //           // If userLocation is provided, distance is the primary sort criteria for "nearby" or relevance
// //           if (userLocation != null) {
// //             if (distA != null && distB != null) {
// //               int distComparison = distA.compareTo(distB);
// //               if (distComparison != 0) return distComparison;
// //             } else if (distA != null) { return -1; } // a has distance, b doesn't
// //             else if (distB != null) { return 1;  } // b has distance, a doesn't
// //           }

// //           // Fallback or secondary sort: by name (especially if no location or distances are equal)
// //           final String nameA = (a['name'] as String? ?? '').toLowerCase();
// //           final String nameB = (b['name'] as String? ?? '').toLowerCase();
// //           return nameA.compareTo(nameB);
// //         });
// //       }

// //       return results;

// //     } catch (e) {
// //       debugPrint("Error getting venues from FirestoreService: $e");
// //       if (e.toString().toLowerCase().contains('index') || (e is FirebaseException && e.code == 'failed-precondition')) {
// //         debugPrint("Firestore Error Details: Code: ${(e as FirebaseException).code}, Message: ${e.message}");
// //         debugPrint("An index is likely required. Check Firestore console for index creation suggestions or errors in logs.");
// //         throw Exception("Database query failed (likely missing index). Details: ${e.message}");
// //       }
// //       throw Exception("Failed to retrieve venues: ${e.toString()}");
// //     }
// //   }
// // //    Future<List<Map<String, dynamic>>> getVenues({
// // //      Position? userLocation,
// // //      double? radiusInKm,
// // //      String? cityFilter,
// // //      String? searchQuery,
// // //      String? sportFilter,
// // //      int? limit,
// // //    }) async {
// // //      try {
// // //        Query query = _db.collection(_venuesCollection).where('isActive', isEqualTo: true);

// // //        if (cityFilter != null && cityFilter.isNotEmpty) { 
// // //          query = query.where('city', isEqualTo: cityFilter);
// // //          debugPrint("Applying SERVER-SIDE city filter: '$cityFilter'");
// // //        }

// // //        // MODIFIED: Changed to arrayContains for sportFilter
// // //        if (sportFilter != null && sportFilter.isNotEmpty && (searchQuery == null || searchQuery.trim().isEmpty)) {
// // //          query = query.where('sportType', arrayContains: sportFilter); // <<< CHANGED HERE
// // //          debugPrint("Applying SERVER-SIDE sport filter (arrayContains): '$sportFilter'");
// // //        }
// // //        // If there's a search query, sport filtering might be done client-side after initial fetch,
// // //        // or you might decide to also apply arrayContains here if your index supports it with search.
// // //        // For now, the logic handles client-side sport filtering when a search query is present.

// // //        query = query.orderBy('name'); // Default ordering

// // //        if (limit != null && limit > 0) {
// // //          query = query.limit(limit);
// // //        }

// // //        QuerySnapshot snapshot = await query.get();

// // //        List<Map<String, dynamic>> fetchedVenues = snapshot.docs.map((doc) {
// // //          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
// // //          data['id'] = doc.id;
// // //          data['averageRating'] = data['averageRating'] ?? 0.0;
// // //          data['reviewCount'] = data['reviewCount'] ?? 0;
// // //          return data;
// // //        }).toList();

// // //       List<Map<String, dynamic>> results = fetchedVenues;
// // //       final bool hasSearchQuery = searchQuery != null && searchQuery.trim().isNotEmpty;
// // //       // Client-side sport filter is applied if there's a search query AND a sport filter
// // //       final bool applyClientSideSportFilter = sportFilter != null && sportFilter.isNotEmpty && hasSearchQuery;

// // //       if (hasSearchQuery || applyClientSideSportFilter) {
// // //         String lowerCaseQuery = searchQuery.trim().toLowerCase();
// // //         String lowerCaseSportFilter = sportFilter?.trim().toLowerCase() ?? "";
// // //         debugPrint("Applying CLIENT-SIDE filters: Query: '$lowerCaseQuery', Sport for client-side: '$lowerCaseSportFilter'");
// // // debugPrint("FirestoreService: Fetched ${fetchedVenues.length} venues from server BEFORE client-side filtering. For query: '$searchQuery'");
// // // for (var venueData in fetchedVenues) {
// // //     debugPrint("  - Server fetched: ${venueData['name']} (ID: ${venueData['id']}, isActive: ${venueData['isActive']})");
// // // }
// // //         results = fetchedVenues.where((venue) {
// // //           bool queryMatch = !hasSearchQuery; // True if no search query, otherwise needs to match
// // //           bool sportMatch = !applyClientSideSportFilter; // True if no client-side sport filter, otherwise needs to match

// // //           if (hasSearchQuery) {
// // //             final String name = (venue['name'] as String? ?? '').toLowerCase();
// // //             if (name.contains(lowerCaseQuery)) { queryMatch = true; }
// // //             final String address = (venue['address'] as String? ?? '').toLowerCase();
// // //             if (!queryMatch && address.contains(lowerCaseQuery)) { queryMatch = true; }
// // //             final String city = (venue['city'] as String? ?? '').toLowerCase();
// // //             if (!queryMatch && city.contains(lowerCaseQuery)) { queryMatch = true; }
// // //             final String description = (venue['description'] as String? ?? '').toLowerCase();
// // //             if (!queryMatch && description.contains(lowerCaseQuery)) { queryMatch = true; }
            
// // //             // Search within sportType array if no specific client-side sport filter is active OR if it is active but we also want to match query text in sports
// // //             final List<String> sportTypesInVenue = (venue['sportType'] as List<dynamic>?)
// // //                 ?.whereType<String>().map((s) => s.toLowerCase()).toList() ?? [];
// // //             if (!queryMatch && sportTypesInVenue.any((sport) => sport.contains(lowerCaseQuery))) {
// // //                 queryMatch = true;
// // //             }
            
// // //             final List<String> facilities = (venue['facilities'] as List<dynamic>?)
// // //                 ?.whereType<String>().map((s) => s.toLowerCase()).toList() ?? [];
// // //              if (!queryMatch && facilities.any((f) => f.contains(lowerCaseQuery))) {
// // //                  queryMatch = true;
// // //              }
// // //           }

// // //           if (applyClientSideSportFilter) {
// // //              final List<String> sportTypesInVenue = (venue['sportType'] as List<dynamic>?)
// // //                 ?.whereType<String>().map((s) => s.toLowerCase()).toList() ?? [];
// // //             if (sportTypesInVenue.contains(lowerCaseSportFilter)) {
// // //               sportMatch = true;
// // //             }
// // //           }
// // //           return queryMatch && sportMatch;
// // //        }).toList();
// // //        }

// // //        if (userLocation != null) {
// // //          for (var venue in results) {
// // //            // Assuming 'location' field is a GeoPoint in Firestore
// // //            // or 'latitude' and 'longitude' are separate number fields.
// // //            // Let's adjust based on your previous use of GeoPoint
// // //            final GeoPoint? venueGeoPoint = venue['location'] as GeoPoint?;
// // //            final num? venueLatNum = venue['latitude'] as num?;
// // //            final num? venueLngNum = venue['longitude'] as num?;

// // //            double? venueLat, venueLng;

// // //            if (venueGeoPoint != null) {
// // //              venueLat = venueGeoPoint.latitude;
// // //              venueLng = venueGeoPoint.longitude;
// // //            } else if (venueLatNum != null && venueLngNum != null) {
// // //              venueLat = venueLatNum.toDouble();
// // //              venueLng = venueLngNum.toDouble();
// // //            }

// // //            if (venueLat != null && venueLng != null) {
// // //              try {
// // //                 venue['distance'] = _locationService.calculateDistance(
// // //                   userLocation.latitude, userLocation.longitude,
// // //                   venueLat, venueLng,
// // //                 );
// // //              } catch (e) {
// // //                 debugPrint("Error calculating distance for venue ${venue['id']}: $e");
// // //                 venue['distance'] = null;
// // //              }
// // //            } else {
// // //              venue['distance'] = null;
// // //            }
// // //          }
// // //        }

// // //        // Proximity filtering
// // //        if (radiusInKm != null && userLocation != null && results.any((v) => v['distance'] != null) ) {
// // //             if (cityFilter == null && !hasSearchQuery && (sportFilter == null || sportFilter.isEmpty)) {
// // //                 // Only apply radius filter if no other major filters are active (for "Venues Near You" default view)
// // //                 debugPrint("Applying proximity filter (radius: $radiusInKm km)");
// // //                 results = results.where((venue) {
// // //                     final distance = venue['distance'] as double?;
// // //                     return distance != null && distance <= radiusInKm;
// // //                 }).toList();
// // //             }
// // //        }
       
// // //        // Sort results, prioritizing distance if available
// // //        if (results.isNotEmpty) {
// // //          results.sort((a, b) {
// // //            final distA = a['distance'] as double?;
// // //            final distB = b['distance'] as double?;

// // //            if (userLocation != null) { // If location is available, distance is primary sort
// // //              if (distA != null && distB != null) {
// // //                int distComparison = distA.compareTo(distB);
// // //                if (distComparison != 0) return distComparison;
// // //              } else if (distA != null) {
// // //                return -1; // a comes first if it has distance and b doesn't
// // //              } else if (distB != null) {
// // //                return 1;  // b comes first if it has distance and a doesn't
// // //              }
// // //            }
// // //            // Fallback to sorting by name if distances are equal or not available
// // //            final String nameA = (a['name'] as String? ?? '').toLowerCase();
// // //            final String nameB = (b['name'] as String? ?? '').toLowerCase();
// // //            return nameA.compareTo(nameB);
// // //          });
// // //        }

// // //        return results;

// // //      } catch (e) {
// // //        debugPrint("Error getting venues from FirestoreService: $e");
// // //        // Check if the error is related to an index.
// // //        if (e.toString().toLowerCase().contains('index') || (e is FirebaseException && e.code == 'failed-precondition')) {
// // //          debugPrint("Firestore Error: An index is likely required for the query being attempted. Please check Firebase console logs or look for index creation suggestions.");
// // //          // You could throw a more specific exception or return an empty list with a status.
// // //          throw Exception("Database query failed, possibly due to a missing index. Check server logs.");
// // //        }
// // //        throw Exception("Failed to retrieve venues.");
// // //      }
// // //    }

// //   Future<Map<String, dynamic>?> getVenueDetails(String venueId) async {
// //      try {
// //        DocumentSnapshot doc = await _db.collection(_venuesCollection).doc(venueId).get();
// //        if (doc.exists) {
// //          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
// //          data['id'] = doc.id;
// //          data['averageRating'] = data['averageRating'] ?? 0.0;
// //          data['reviewCount'] = data['reviewCount'] ?? 0;
// //          return data;
// //        }
// //        return null;
// //      } catch (e) {
// //        debugPrint('Error fetching venue details for ID $venueId: $e');
// //        rethrow;
// //      }
// //    }

// //      Future<void> addReviewForVenue(String venueId, String userId, String userName, double rating, String? comment) async {
// //         if (venueId.isEmpty || userId.isEmpty || userName.isEmpty) {
// //             throw Exception("Missing required review data.");
// //         }
// //         try {
// //             final reviewData = {
// //                 'userId': userId,
// //                 'userName': userName,
// //                 'rating': rating,
// //                 'venueId': venueId, 
// //                 'createdAt': FieldValue.serverTimestamp(),
// //                 'updatedAt': FieldValue.serverTimestamp(), 
// //                 if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
// //             };
// //             await _db.collection(_venuesCollection).doc(venueId).collection(_reviewsSubCollection).add(reviewData);
// //             debugPrint("Review added successfully for venue $venueId by user $userId");
// //         } catch (e) {
// //             debugPrint("Error adding review for venue $venueId by user $userId: $e");
// //             if (e is FirebaseException) {
// //               throw FirebaseException(
// //                 plugin: e.plugin,
// //                 code: e.code,
// //                 message: "Failed to submit review for $venueId. ${e.message}"
// //               );
// //             }
// //             throw Exception("Failed to submit review for $venueId.");
// //         }
// //    }

// //   Future<List<Map<String, dynamic>>> getReviewsForVenue(String venueId, {int limit = 20}) async {
// //     if (venueId.isEmpty) return [];
// //     try {
// //         QuerySnapshot snapshot = await _db.collection(_venuesCollection).doc(venueId)
// //             .collection(_reviewsSubCollection).orderBy('createdAt', descending: true).limit(limit).get();
// //         return snapshot.docs.map((doc) {
// //             Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
// //             data['id'] = doc.id;
// //             return data;
// //         }).toList();
// //     } catch (e) {
// //         debugPrint("Error fetching reviews for venue $venueId: $e");
// //         throw Exception("Could not load reviews.");
// //     }
// //   }

// //   Future<List<Map<String, dynamic>>> getReviewsByUser(String userId, {int limit = 50}) async {
// //     if (userId.isEmpty) return [];
// //     try {
// //         // Make sure _reviewsSubCollection is defined, e.g.,
// //         // static const String _reviewsSubCollection = "mm_reviews";
// //         // static const String _venuesCollection = "mm_venues";

// //         QuerySnapshot snapshot = await _db.collectionGroup(_reviewsSubCollection)
// //             .where('userId', isEqualTo: userId)
// //             .orderBy('createdAt', descending: true)
// //             .limit(limit)
// //             .get();

// //         List<Map<String, dynamic>> userReviews = [];
// //         for (var doc in snapshot.docs) {
// //             Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
// //             data['id'] = doc.id; // This is the reviewId
// //             String path = doc.reference.path;
// //             List<String> parts = path.split('/');

// //             // Path example: "mm_venues/THE_ACTUAL_VENUE_ID/mm_reviews/THE_ACTUAL_REVIEW_ID"
// //             // parts[0] = "mm_venues" (_venuesCollection)
// //             // parts[1] = "THE_ACTUAL_VENUE_ID" (This is what we want)
// //             // parts[2] = "mm_reviews" (_reviewsSubCollection)
// //             // parts[3] = "THE_ACTUAL_REVIEW_ID"

// //             if (parts.length >= 4 && parts[0] == _venuesCollection && parts[2] == _reviewsSubCollection) {
// //                 data['venueId'] = parts[1]; // Correctly assign the venueId
// //             } else {
// //                 data['venueId'] = null; // Fallback if path structure is unexpected
// //                 // Corrected line below:
// //                 debugPrint("Warning: Could not extract venueId from review path: $path. Path parts: ${parts.join('/')}. Expected structure: $_venuesCollection/{venueId}/$_reviewsSubCollection/{reviewId}");
// //             }

// //             data['venueName'] = null; // You'll need to fetch this separately if needed
// //             userReviews.add(data);
// //         }
// //         return userReviews;
// //     } catch (e) {
// //         debugPrint("Error fetching reviews for user $userId: $e");
// //         if (e.toString().toLowerCase().contains('index')) {
// //             debugPrint("Firestore Error: An index is likely required for the query. Check Firebase console logs or index suggestions.");
// //             throw Exception("Database index configuration needed. Please contact support or check logs.");
// //         }
// //         throw Exception("Could not load your reviews.");
// //     }
// // }

// //   Future<void> deleteReview(String venueId, String reviewId) async {
// //     if (venueId.isEmpty || reviewId.isEmpty) throw ArgumentError("Venue ID and Review ID cannot be empty.");
// //     try {
// //        await _db.collection(_venuesCollection).doc(venueId).collection(_reviewsSubCollection).doc(reviewId).delete();
// //     } catch (e) {
// //        debugPrint("Error deleting review $reviewId for venue $venueId: $e");
// //        throw Exception("Failed to delete review.");
// //     }
// //   }

// //   Future<DocumentReference> addVenue(Map<String, dynamic> venueData) async {
// //      try {
// //         // venueData['createdAt'] = FieldValue.serverTimestamp();
// //         // venueData['updatedAt'] = FieldValue.serverTimestamp(); // Also add updatedAt on creation
// //         // venueData['averageRating'] = 0.0;
// //         // venueData['reviewCount'] = 0;
// //         // venueData['isActive'] = true; // Default to active
// //         return await _db.collection(_venuesCollection).add(venueData);
// //      } catch (e) {
// //          debugPrint("Error adding venue in FirestoreService: $e");
// //          throw Exception("Failed to add venue data.");
// //      }
// //    }

// //   Future<void> updateVenue(String venueId, Map<String, dynamic> venueData) async {
// //        if (venueId.isEmpty) throw Exception("Venue ID cannot be empty.");
// //        try {
// //           venueData['updatedAt'] = FieldValue.serverTimestamp();
// //           await _db.collection(_venuesCollection).doc(venueId).update(venueData);
// //        } catch (e) {
// //            debugPrint("Error updating venue $venueId: $e");
// //            throw Exception("Failed to update venue data.");
// //        }
// //   }

// //    Future<void> deleteVenue(String venueId) async {
// //        if (venueId.isEmpty) throw Exception("Venue ID cannot be empty.");
// //        try {
// //            // Optionally, also delete subcollections like reviews if needed (requires more complex logic)
// //            await _db.collection(_venuesCollection).doc(venueId).delete();
// //        } catch (e) {
// //            debugPrint("Error deleting venue $venueId: $e");
// //            throw Exception("Failed to delete venue data.");
// //        }
// //   }
// // }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:mm_associates/core/services/location_service.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final LocationService _locationService = LocationService();

//   static const String _usersCollection = 'mm_users';
//   static const String _venuesCollection = 'mm_venues';
//   static const String _reviewsSubCollection = 'mm_reviews';

// Future<bool> checkVenueNameExists(String nameLowercase, String? currentVenueIdToExclude) async {
//   Query query = _db.collection('mm_venues').where('name_lowercase', isEqualTo: nameLowercase);
//   if (currentVenueIdToExclude != null) {
//     query = query.where(FieldPath.documentId, isNotEqualTo: currentVenueIdToExclude);
//   }
//   final snapshot = await query.limit(1).get();
//   return snapshot.docs.isNotEmpty;
// }

//   Future<Map<String, dynamic>?> getUserData(String uid) async {
//     try {
//       DocumentSnapshot doc = await _db.collection(_usersCollection).doc(uid).get();
//       if (doc.exists) {
//         return doc.data() as Map<String, dynamic>?;
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error fetching user data for UID $uid from FirestoreService: $e');
//       return null;
//     }
//   }

// Future<List<Map<String, dynamic>>> getVenues({
//     Position? userLocation,
//     double? radiusInKm,
//     String? cityFilter,
//     String? searchQuery,
//     String? sportFilter,
//     int? limit,
//     bool forSuggestions = false,
//   }) async {
//     try {
//       Query query = _db.collection(_venuesCollection).where('isActive', isEqualTo: true);

//       if (cityFilter != null && cityFilter.isNotEmpty) {
//         query = query.where('city', isEqualTo: cityFilter);
//         debugPrint("FirestoreService: Applying SERVER-SIDE city filter: '$cityFilter'");
//       }

//       final bool hasSearchQuery = searchQuery != null && searchQuery.trim().isNotEmpty;

//       if (hasSearchQuery) {
//         List<String> searchTerms = searchQuery.trim().toLowerCase().split(' ').where((term) => term.isNotEmpty).toSet().toList();
//         if (searchTerms.isNotEmpty) {
//           query = query.where('searchKeywords', arrayContainsAny: searchTerms.take(10).toList());
//           debugPrint("FirestoreService: Applying SERVER-SIDE keyword search (arrayContainsAny on searchKeywords): $searchTerms");
//         }
//       }

//       if (sportFilter != null && sportFilter.isNotEmpty) {
//         if (!hasSearchQuery) { 
//           query = query.where('sportType', arrayContains: sportFilter);
//           debugPrint("FirestoreService: Applying SERVER-SIDE sport filter (arrayContains): '$sportFilter'");
//         } else {
//           debugPrint("FirestoreService: Sport filter ('$sportFilter') will be applied CLIENT-SIDE due to active keyword search.");
//         }
//       }
      
//       // Default sort should usually be on a consistently available field
//       // If `forSuggestions` or a keyword search is active, name is good.
//       // Otherwise, you might want another default (e.g., creation date, popularity) if not already filtered heavily
//       if ((forSuggestions && hasSearchQuery) || !hasSearchQuery ) {
//           query = query.orderBy('name'); 
//       }
//       // If `hasSearchQuery` is true BUT `forSuggestions` is false (i.e., displaying search results, not just suggestions),
//       // the server's keyword matching should ideally be good enough for initial order,
//       // and client-side will refine with distance or other factors.
//       // Or you might add more complex server-side ordering if your search engine supports it.

//       if (limit != null && limit > 0) {
//         query = query.limit(limit);
//       }

//       debugPrint("FirestoreService: Final Query (before .get()): ${query.parameters}"); 

//       QuerySnapshot snapshot = await query.get();

//       List<Map<String, dynamic>> fetchedVenues = snapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         data['id'] = doc.id;
//         data['averageRating'] = data['averageRating'] ?? 0.0;
//         data['reviewCount'] = data['reviewCount'] ?? 0;
//         return data;
//       }).toList();

//       debugPrint("FirestoreService: Fetched ${fetchedVenues.length} venues from server (Query: '$searchQuery', Limit: $limit, ForSuggestions: $forSuggestions)");
      
//       List<Map<String, dynamic>> results = fetchedVenues;

//       // Client-side filtering if sportFilter was not applied on server
//       if (hasSearchQuery && sportFilter != null && sportFilter.isNotEmpty) {
//         String lowerCaseSportFilter = sportFilter.trim().toLowerCase();
//         results = results.where((venue) {
//           final List<String> sportTypesInVenue = (venue['sportType'] as List<dynamic>?)
//               ?.whereType<String>().map((s) => s.toLowerCase()).toList() ?? [];
//           return sportTypesInVenue.contains(lowerCaseSportFilter);
//         }).toList();
//         debugPrint("FirestoreService: Applied CLIENT-SIDE sport filter. Results count: ${results.length}");
//       }
//       // Client-side refinement of search query IF NEEDED (usually server 'searchKeywords' is enough)
//       // if (hasSearchQuery && !forSuggestions && results.isNotEmpty) {
//       //     String fullQueryLower = searchQuery.trim().toLowerCase();
//       //     results = results.where((venue) {
//       //         final String name = (venue['name'] as String? ?? '').toLowerCase();
//       //         // Add other fields to search client-side if needed, e.g., description
//       //         return name.contains(fullQueryLower);
//       //     }).toList();
//       //     debugPrint("FirestoreService: Applied CLIENT-SIDE query refinement. Results count: ${results.length}");
//       // }


//       if (userLocation != null) {
//         for (var venue in results) {
//           final GeoPoint? venueGeoPoint = venue['location'] as GeoPoint?;
//           double? venueLat, venueLng;

//           if (venueGeoPoint != null) {
//             venueLat = venueGeoPoint.latitude;
//             venueLng = venueGeoPoint.longitude;
//           }
//           // Remove num checks for lat/lng if 'location' GeoPoint is always primary source

//           if (venueLat != null && venueLng != null) {
//             try {
//               venue['distance'] = _locationService.calculateDistance(
//                 userLocation.latitude, userLocation.longitude, venueLat, venueLng,
//               );
//             } catch (e) {
//               debugPrint("Error calculating distance for venue ${venue['id']}: $e");
//               venue['distance'] = null;
//             }
//           } else {
//             venue['distance'] = null;
//           }
//         }
//       }

//       if (radiusInKm != null && userLocation != null && results.any((v) => v['distance'] != null)) {
//         if (!hasSearchQuery && (sportFilter == null || sportFilter.isEmpty)) { 
//           debugPrint("FirestoreService: Applying proximity filter (radius: $radiusInKm km)");
//           results = results.where((venue) {
//             final distance = venue['distance'] as double?;
//             return distance != null && distance <= radiusInKm;
//           }).toList();
//         }
//       }

//       if (results.isNotEmpty) {
//         results.sort((a, b) {
//           final distA = a['distance'] as double?;
//           final distB = b['distance'] as double?;

//           if (userLocation != null) {
//             if (distA != null && distB != null) {
//               int distComparison = distA.compareTo(distB);
//               if (distComparison != 0) return distComparison;
//             } else if (distA != null) { return -1; } 
//             else if (distB != null) { return 1;  } 
//           }

//           final String nameA = (a['name'] as String? ?? '').toLowerCase();
//           final String nameB = (b['name'] as String? ?? '').toLowerCase();
//           return nameA.compareTo(nameB);
//         });
//       }

//       return results;

//     } catch (e) {
//       debugPrint("Error getting venues from FirestoreService: $e");
//       if (e is FirebaseException && (e.toString().toLowerCase().contains('index') || e.code == 'failed-precondition')) {
//         debugPrint("Firestore Error Details: Code: ${e.code}, Message: ${e.message}");
//         debugPrint("An index is likely required. Check Firestore console for index creation suggestions or errors in logs.");
//         throw Exception("Database query failed (likely missing index). Details: ${e.message}");
//       }
//       throw Exception("Failed to retrieve venues: ${e.toString()}");
//     }
//   }

//   Future<Map<String, dynamic>?> getVenueDetails(String venueId) async {
//      try {
//        DocumentSnapshot doc = await _db.collection(_venuesCollection).doc(venueId).get();
//        if (doc.exists) {
//          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//          data['id'] = doc.id;
//          data['averageRating'] = data['averageRating'] ?? 0.0;
//          data['reviewCount'] = data['reviewCount'] ?? 0;
//          return data;
//        }
//        return null;
//      } catch (e) {
//        debugPrint('Error fetching venue details for ID $venueId: $e');
//        rethrow;
//      }
//    }

//   Future<void> addReviewForVenue(String venueId, String userId, String userName, double rating, String? comment) async {
//       if (venueId.isEmpty || userId.isEmpty || userName.isEmpty) {
//           throw Exception("Missing required review data.");
//       }
//       try {
//           final reviewData = {
//               'userId': userId,
//               'userName': userName,
//               'rating': rating,
//               'venueId': venueId, 
//               'createdAt': FieldValue.serverTimestamp(),
//               'updatedAt': FieldValue.serverTimestamp(), 
//               if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
//           };
//           await _db.collection(_venuesCollection).doc(venueId).collection(_reviewsSubCollection).add(reviewData);
//           debugPrint("Review added successfully for venue $venueId by user $userId");
//       } catch (e) {
//           debugPrint("Error adding review for venue $venueId by user $userId: $e");
//           if (e is FirebaseException) {
//             throw FirebaseException(
//               plugin: e.plugin,
//               code: e.code,
//               message: "Failed to submit review for $venueId. ${e.message}"
//             );
//           }
//           throw Exception("Failed to submit review for $venueId.");
//       }
//   }

//   Future<List<Map<String, dynamic>>> getReviewsForVenue(String venueId, {int limit = 20}) async {
//     if (venueId.isEmpty) return [];
//     try {
//         QuerySnapshot snapshot = await _db.collection(_venuesCollection).doc(venueId)
//             .collection(_reviewsSubCollection).orderBy('createdAt', descending: true).limit(limit).get();
//         return snapshot.docs.map((doc) {
//             Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//             data['id'] = doc.id;
//             return data;
//         }).toList();
//     } catch (e) {
//         debugPrint("Error fetching reviews for venue $venueId: $e");
//         throw Exception("Could not load reviews.");
//     }
//   }

//   Future<List<Map<String, dynamic>>> getReviewsByUser(String userId, {int limit = 50}) async {
//     if (userId.isEmpty) return [];
//     try {
//         QuerySnapshot snapshot = await _db.collectionGroup(_reviewsSubCollection)
//             .where('userId', isEqualTo: userId)
//             .orderBy('createdAt', descending: true)
//             .limit(limit)
//             .get();

//         List<Map<String, dynamic>> userReviews = [];
//         for (var doc in snapshot.docs) {
//             Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//             data['id'] = doc.id;
//             String path = doc.reference.path;
//             List<String> parts = path.split('/');
//             if (parts.length >= 4 && parts[0] == _venuesCollection && parts[2] == _reviewsSubCollection) {
//                 data['venueId'] = parts[1];
//             } else {
//                 data['venueId'] = null; 
//                 debugPrint("Warning: Could not extract venueId from review path: $path. Path parts: ${parts.join('/')}. Expected structure: $_venuesCollection/{venueId}/$_reviewsSubCollection/{reviewId}");
//             }
//             data['venueName'] = null; 
//             userReviews.add(data);
//         }
//         return userReviews;
//     } catch (e) {
//         debugPrint("Error fetching reviews for user $userId: $e");
//         if (e is FirebaseException && (e.toString().toLowerCase().contains('index') || e.code == 'failed-precondition')) {
//             debugPrint("Firestore Error: An index is likely required for the query. Check Firebase console logs or index suggestions.");
//             throw Exception("Database index configuration needed. Please contact support or check logs.");
//         }
//         throw Exception("Could not load your reviews.");
//     }
//   }

//   Future<void> deleteReview(String venueId, String reviewId) async {
//     if (venueId.isEmpty || reviewId.isEmpty) throw ArgumentError("Venue ID and Review ID cannot be empty.");
//     try {
//        await _db.collection(_venuesCollection).doc(venueId).collection(_reviewsSubCollection).doc(reviewId).delete();
//     } catch (e) {
//        debugPrint("Error deleting review $reviewId for venue $venueId: $e");
//        throw Exception("Failed to delete review.");
//     }
//   }

//   Future<DocumentReference> addVenue(Map<String, dynamic> venueData) async {
//      try {
//         return await _db.collection(_venuesCollection).add(venueData);
//      } catch (e) {
//          debugPrint("Error adding venue in FirestoreService: $e");
//          throw Exception("Failed to add venue data.");
//      }
//    }

//   Future<void> updateVenue(String venueId, Map<String, dynamic> venueData) async {
//        if (venueId.isEmpty) throw Exception("Venue ID cannot be empty.");
//        try {
//           venueData['updatedAt'] = FieldValue.serverTimestamp();
//           await _db.collection(_venuesCollection).doc(venueId).update(venueData);
//        } catch (e) {
//            debugPrint("Error updating venue $venueId: $e");
//            throw Exception("Failed to update venue data.");
//        }
//   }

//    // <<<< EXISTING deleteVenue method - no changes needed, it's already good >>>>
//    Future<void> deleteVenue(String venueId) async {
//        if (venueId.isEmpty) throw Exception("Venue ID cannot be empty.");
//        try {
//            // If you need to delete subcollections (like all reviews for this venue), 
//            // you'd typically do this via a Firebase Function or iterate and delete.
//            // For simplicity here, we're just deleting the venue document.
//            await _db.collection(_venuesCollection).doc(venueId).delete();
//            debugPrint("Venue $venueId deleted successfully.");
//        } catch (e) {
//            debugPrint("Error deleting venue $venueId: $e");
//            throw Exception("Failed to delete venue data.");
//        }
//   }

//   // <<<< NEW METHOD >>>>
//   Future<List<Map<String, dynamic>>> getVenuesByCreator(String creatorUid) async {
//     if (creatorUid.isEmpty) return [];
//     try {
//       final querySnapshot = await _db
//           .collection(_venuesCollection)
//           .where('creatorUid', isEqualTo: creatorUid)
//           .orderBy('name') // Optionally order by name or createdAt
//           .get();

//       return querySnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         // Ensure essential fields used in MyVenuesScreen ListTile are present or defaulted
//         data['name'] = data['name'] ?? 'Unnamed Venue';
//         data['city'] = data['city'] ?? 'N/A';
//         data['isActive'] = data['isActive'] ?? false; // Default if not present
//         data['imageUrl'] = data['imageUrl'] as String?;
//         return data;
//       }).toList();
//     } catch (e) {
//       debugPrint("Error fetching venues for creator $creatorUid: $e");
//       if (e is FirebaseException && (e.toString().toLowerCase().contains('index') || e.code == 'failed-precondition')) {
//         debugPrint("Firestore Error: An index on 'creatorUid' (and 'name' if ordered) is likely required for collection '$_venuesCollection'.");
//         throw Exception("Database index required. ${e.message}");
//       }
//       throw Exception("Could not load your created venues.");
//     }
//   }
// }



//------admin venue name check based on location
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mm_associates/core/services/location_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  static const String _usersCollection = 'mm_users';
  static const String _venuesCollection = 'mm_venues';
  static const String _reviewsSubCollection = 'mm_reviews';

  /// Checks if a venue name already exists within a specific city and area.
  ///
  /// This requires a composite index in Firestore on:
  /// `mm_venues`: `name_lowercase` (Ascending), `city` (Ascending), `area` (Ascending).
  Future<bool> checkVenueNameExists(String nameLowercase, String city, String area, String? currentVenueIdToExclude) async {
    // If identifying info is missing, a valid check can't be performed.
    // The form's validation should prevent this, but this is a safeguard.
    if (nameLowercase.isEmpty || city.isEmpty || area.isEmpty) {
      return false;
    }
    
    Query query = _db
        .collection(_venuesCollection)
        .where('name_lowercase', isEqualTo: nameLowercase)
        .where('city', isEqualTo: city)
        .where('area_lowercase', isEqualTo: area); // Assumes 'area' is stored consistently (e.g., trimmed)

    if (currentVenueIdToExclude != null) {
      query = query.where(FieldPath.documentId, isNotEqualTo: currentVenueIdToExclude);
    }
    
    final snapshot = await query.limit(1).get();
    debugPrint("Checking for venue: name='$nameLowercase', city='$city', area='$area'. Found: ${snapshot.docs.isNotEmpty}");
    return snapshot.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data for UID $uid from FirestoreService: $e');
      return null;
    }
  }

Future<List<Map<String, dynamic>>> getVenues({
    Position? userLocation,
    double? radiusInKm,
    String? cityFilter,
    String? searchQuery,
    String? sportFilter,
    int? limit,
    bool forSuggestions = false,
  }) async {
    try {
      Query query = _db.collection(_venuesCollection).where('isActive', isEqualTo: true);

      if (cityFilter != null && cityFilter.isNotEmpty) {
        query = query.where('city', isEqualTo: cityFilter);
        debugPrint("FirestoreService: Applying SERVER-SIDE city filter: '$cityFilter'");
      }

      final bool hasSearchQuery = searchQuery != null && searchQuery.trim().isNotEmpty;

      if (hasSearchQuery) {
        List<String> searchTerms = searchQuery.trim().toLowerCase().split(' ').where((term) => term.isNotEmpty).toSet().toList();
        if (searchTerms.isNotEmpty) {
          query = query.where('searchKeywords', arrayContainsAny: searchTerms.take(10).toList());
          debugPrint("FirestoreService: Applying SERVER-SIDE keyword search (arrayContainsAny on searchKeywords): $searchTerms");
        }
      }

      if (sportFilter != null && sportFilter.isNotEmpty) {
        if (!hasSearchQuery) { 
          query = query.where('sportType', arrayContains: sportFilter);
          debugPrint("FirestoreService: Applying SERVER-SIDE sport filter (arrayContains): '$sportFilter'");
        } else {
          debugPrint("FirestoreService: Sport filter ('$sportFilter') will be applied CLIENT-SIDE due to active keyword search.");
        }
      }
      
      // Default sort should usually be on a consistently available field
      // If `forSuggestions` or a keyword search is active, name is good.
      // Otherwise, you might want another default (e.g., creation date, popularity) if not already filtered heavily
      if ((forSuggestions && hasSearchQuery) || !hasSearchQuery ) {
          query = query.orderBy('name'); 
      }
      // If `hasSearchQuery` is true BUT `forSuggestions` is false (i.e., displaying search results, not just suggestions),
      // the server's keyword matching should ideally be good enough for initial order,
      // and client-side will refine with distance or other factors.
      // Or you might add more complex server-side ordering if your search engine supports it.

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      debugPrint("FirestoreService: Final Query (before .get()): ${query.parameters}"); 

      QuerySnapshot snapshot = await query.get();

      List<Map<String, dynamic>> fetchedVenues = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['averageRating'] = data['averageRating'] ?? 0.0;
        data['reviewCount'] = data['reviewCount'] ?? 0;
        return data;
      }).toList();

      debugPrint("FirestoreService: Fetched ${fetchedVenues.length} venues from server (Query: '$searchQuery', Limit: $limit, ForSuggestions: $forSuggestions)");
      
      List<Map<String, dynamic>> results = fetchedVenues;

      // Client-side filtering if sportFilter was not applied on server
      if (hasSearchQuery && sportFilter != null && sportFilter.isNotEmpty) {
        String lowerCaseSportFilter = sportFilter.trim().toLowerCase();
        results = results.where((venue) {
          final List<String> sportTypesInVenue = (venue['sportType'] as List<dynamic>?)
              ?.whereType<String>().map((s) => s.toLowerCase()).toList() ?? [];
          return sportTypesInVenue.contains(lowerCaseSportFilter);
        }).toList();
        debugPrint("FirestoreService: Applied CLIENT-SIDE sport filter. Results count: ${results.length}");
      }
      // Client-side refinement of search query IF NEEDED (usually server 'searchKeywords' is enough)
      // if (hasSearchQuery && !forSuggestions && results.isNotEmpty) {
      //     String fullQueryLower = searchQuery.trim().toLowerCase();
      //     results = results.where((venue) {
      //         final String name = (venue['name'] as String? ?? '').toLowerCase();
      //         // Add other fields to search client-side if needed, e.g., description
      //         return name.contains(fullQueryLower);
      //     }).toList();
      //     debugPrint("FirestoreService: Applied CLIENT-SIDE query refinement. Results count: ${results.length}");
      // }


      if (userLocation != null) {
        for (var venue in results) {
          final GeoPoint? venueGeoPoint = venue['location'] as GeoPoint?;
          double? venueLat, venueLng;

          if (venueGeoPoint != null) {
            venueLat = venueGeoPoint.latitude;
            venueLng = venueGeoPoint.longitude;
          }
          // Remove num checks for lat/lng if 'location' GeoPoint is always primary source

          if (venueLat != null && venueLng != null) {
            try {
              venue['distance'] = _locationService.calculateDistance(
                userLocation.latitude, userLocation.longitude, venueLat, venueLng,
              );
            } catch (e) {
              debugPrint("Error calculating distance for venue ${venue['id']}: $e");
              venue['distance'] = null;
            }
          } else {
            venue['distance'] = null;
          }
        }
      }

      if (radiusInKm != null && userLocation != null && results.any((v) => v['distance'] != null)) {
        if (!hasSearchQuery && (sportFilter == null || sportFilter.isEmpty)) { 
          debugPrint("FirestoreService: Applying proximity filter (radius: $radiusInKm km)");
          results = results.where((venue) {
            final distance = venue['distance'] as double?;
            return distance != null && distance <= radiusInKm;
          }).toList();
        }
      }

      if (results.isNotEmpty) {
        results.sort((a, b) {
          final distA = a['distance'] as double?;
          final distB = b['distance'] as double?;

          if (userLocation != null) {
            if (distA != null && distB != null) {
              int distComparison = distA.compareTo(distB);
              if (distComparison != 0) return distComparison;
            } else if (distA != null) { return -1; } 
            else if (distB != null) { return 1;  } 
          }

          final String nameA = (a['name'] as String? ?? '').toLowerCase();
          final String nameB = (b['name'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });
      }

      return results;

    } catch (e) {
      debugPrint("Error getting venues from FirestoreService: $e");
      if (e is FirebaseException && (e.toString().toLowerCase().contains('index') || e.code == 'failed-precondition')) {
        debugPrint("Firestore Error Details: Code: ${e.code}, Message: ${e.message}");
        debugPrint("An index is likely required. Check Firestore console for index creation suggestions or errors in logs.");
        throw Exception("Database query failed (likely missing index). Details: ${e.message}");
      }
      throw Exception("Failed to retrieve venues: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>?> getVenueDetails(String venueId) async {
     try {
       DocumentSnapshot doc = await _db.collection(_venuesCollection).doc(venueId).get();
       if (doc.exists) {
         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
         data['id'] = doc.id;
         data['averageRating'] = data['averageRating'] ?? 0.0;
         data['reviewCount'] = data['reviewCount'] ?? 0;
         return data;
       }
       return null;
     } catch (e) {
       debugPrint('Error fetching venue details for ID $venueId: $e');
       rethrow;
     }
   }

  Future<void> addReviewForVenue(String venueId, String userId, String userName, double rating, String? comment) async {
      if (venueId.isEmpty || userId.isEmpty || userName.isEmpty) {
          throw Exception("Missing required review data.");
      }
      try {
          final reviewData = {
              'userId': userId,
              'userName': userName,
              'rating': rating,
              'venueId': venueId, 
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(), 
              if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
          };
          await _db.collection(_venuesCollection).doc(venueId).collection(_reviewsSubCollection).add(reviewData);
          debugPrint("Review added successfully for venue $venueId by user $userId");
      } catch (e) {
          debugPrint("Error adding review for venue $venueId by user $userId: $e");
          if (e is FirebaseException) {
            throw FirebaseException(
              plugin: e.plugin,
              code: e.code,
              message: "Failed to submit review for $venueId. ${e.message}"
            );
          }
          throw Exception("Failed to submit review for $venueId.");
      }
  }

  Future<List<Map<String, dynamic>>> getReviewsForVenue(String venueId, {int limit = 20}) async {
    if (venueId.isEmpty) return [];
    try {
        QuerySnapshot snapshot = await _db.collection(_venuesCollection).doc(venueId)
            .collection(_reviewsSubCollection).orderBy('createdAt', descending: true).limit(limit).get();
        return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
        }).toList();
    } catch (e) {
        debugPrint("Error fetching reviews for venue $venueId: $e");
        throw Exception("Could not load reviews.");
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsByUser(String userId, {int limit = 50}) async {
    if (userId.isEmpty) return [];
    try {
        QuerySnapshot snapshot = await _db.collectionGroup(_reviewsSubCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        List<Map<String, dynamic>> userReviews = [];
        for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            String path = doc.reference.path;
            List<String> parts = path.split('/');
            if (parts.length >= 4 && parts[0] == _venuesCollection && parts[2] == _reviewsSubCollection) {
                data['venueId'] = parts[1];
            } else {
                data['venueId'] = null; 
                debugPrint("Warning: Could not extract venueId from review path: $path. Path parts: ${parts.join('/')}. Expected structure: $_venuesCollection/{venueId}/$_reviewsSubCollection/{reviewId}");
            }
            data['venueName'] = null; 
            userReviews.add(data);
        }
        return userReviews;
    } catch (e) {
        debugPrint("Error fetching reviews for user $userId: $e");
        if (e is FirebaseException && (e.toString().toLowerCase().contains('index') || e.code == 'failed-precondition')) {
            debugPrint("Firestore Error: An index is likely required for the query. Check Firebase console logs or index suggestions.");
            throw Exception("Database index configuration needed. Please contact support or check logs.");
        }
        throw Exception("Could not load your reviews.");
    }
  }

  Future<void> deleteReview(String venueId, String reviewId) async {
    if (venueId.isEmpty || reviewId.isEmpty) throw ArgumentError("Venue ID and Review ID cannot be empty.");
    try {
       await _db.collection(_venuesCollection).doc(venueId).collection(_reviewsSubCollection).doc(reviewId).delete();
    } catch (e) {
       debugPrint("Error deleting review $reviewId for venue $venueId: $e");
       throw Exception("Failed to delete review.");
    }
  }

  Future<DocumentReference> addVenue(Map<String, dynamic> venueData) async {
     try {
        return await _db.collection(_venuesCollection).add(venueData);
     } catch (e) {
         debugPrint("Error adding venue in FirestoreService: $e");
         throw Exception("Failed to add venue data.");
     }
   }

  Future<void> updateVenue(String venueId, Map<String, dynamic> venueData) async {
       if (venueId.isEmpty) throw Exception("Venue ID cannot be empty.");
       try {
          venueData['updatedAt'] = FieldValue.serverTimestamp();
          await _db.collection(_venuesCollection).doc(venueId).update(venueData);
       } catch (e) {
           debugPrint("Error updating venue $venueId: $e");
           throw Exception("Failed to update venue data.");
       }
  }

   // <<<< EXISTING deleteVenue method - no changes needed, it's already good >>>>
   Future<void> deleteVenue(String venueId) async {
       if (venueId.isEmpty) throw Exception("Venue ID cannot be empty.");
       try {
           // If you need to delete subcollections (like all reviews for this venue), 
           // you'd typically do this via a Firebase Function or iterate and delete.
           // For simplicity here, we're just deleting the venue document.
           await _db.collection(_venuesCollection).doc(venueId).delete();
           debugPrint("Venue $venueId deleted successfully.");
       } catch (e) {
           debugPrint("Error deleting venue $venueId: $e");
           throw Exception("Failed to delete venue data.");
       }
  }

  // <<<< NEW METHOD >>>>
  Future<List<Map<String, dynamic>>> getVenuesByCreator(String creatorUid) async {
    if (creatorUid.isEmpty) return [];
    try {
      final querySnapshot = await _db
          .collection(_venuesCollection)
          .where('creatorUid', isEqualTo: creatorUid)
          .orderBy('name') // Optionally order by name or createdAt
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        // Ensure essential fields used in MyVenuesScreen ListTile are present or defaulted
        data['name'] = data['name'] ?? 'Unnamed Venue';
        data['city'] = data['city'] ?? 'N/A';
        data['isActive'] = data['isActive'] ?? false; // Default if not present
        data['imageUrl'] = data['imageUrl'] as String?;
        return data;
      }).toList();
    } catch (e) {
      debugPrint("Error fetching venues for creator $creatorUid: $e");
      if (e is FirebaseException && (e.toString().toLowerCase().contains('index') || e.code == 'failed-precondition')) {
        debugPrint("Firestore Error: An index on 'creatorUid' (and 'name' if ordered) is likely required for collection '$_venuesCollection'.");
        throw Exception("Database index required. ${e.message}");
      }
      throw Exception("Could not load your created venues.");
    }
  }
}