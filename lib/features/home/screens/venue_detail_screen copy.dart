// // // lib/features/home/screens/venue_detail_screen.dart

// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:mm_associates/features/bookings/screens/venue_availability_screen.dart';
// // import 'package:mm_associates/features/data/services/firestore_service.dart';
// // import 'package:mm_associates/features/user/services/user_service.dart';
// // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // import 'package:mm_associates/features/reviews/widgets/add_review_dialog.dart';
// // import 'package:mm_associates/features/reviews/widgets/review_list_item.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// // import 'package:share_plus/share_plus.dart';

// // class VenueDetailScreen extends StatefulWidget {
// //   final String venueId;
// //   final Map<String, dynamic>? initialVenueData;

// //   const VenueDetailScreen({
// //     super.key,
// //     required this.venueId,
// //     this.initialVenueData,
// //   });

// //   @override
// //   State<VenueDetailScreen> createState() => _VenueDetailScreenState();
// // }

// // class _VenueDetailScreenState extends State<VenueDetailScreen> {
// //   final FirestoreService _firestoreService = FirestoreService();
// //   final UserService _userService = UserService();
// //   final AuthService _authService = AuthService();

// //   Map<String, dynamic>? _venueData;
// //   bool _isLoadingDetails = true;
// //   String? _errorMessage;
// //   GoogleMapController? _mapController;
// //   Set<Marker> _markers = {};

// //   List<Map<String, dynamic>> _reviews = [];
// //   bool _isLoadingReviews = true;
// //   bool _isFavorite = false;
// //   bool _isLoadingFavorite = true;
// //   double _averageRating = 0.0;
// //   int _reviewCount = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _applyInitialData();
// //     _fetchAllDetails();
// //   }

// //   void _applyInitialData() {
// //     // Use initial data if provided for a faster first paint
// //     if (widget.initialVenueData != null && widget.initialVenueData!.isNotEmpty) {
// //       _venueData = widget.initialVenueData;
// //       // Pre-fill rating and review counts if available in initial data
// //       _averageRating =
// //           (widget.initialVenueData!['averageRating'] as num?)?.toDouble() ??
// //               0.0;
// //       _reviewCount =
// //           (widget.initialVenueData!['reviewCount'] as num?)?.toInt() ?? 0;
// //       _isLoadingDetails = false; // Already have some data
// //       _setupMapMarker(); // Setup map with initial data if possible
// //     } else {
// //       _isLoadingDetails = true; // No initial data, need to fetch everything
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _mapController?.dispose();
// //     super.dispose();
// //   }

// //   // Fetches venue details, reviews, and favorite status concurrently
// //   Future<void> _fetchAllDetails() async {
// //     if (!mounted) return;
// //     setState(() {
// //       // Set specific loading states
// //       if (_venueData == null) _isLoadingDetails = true; // Full load if no data yet
// //       _isLoadingReviews = true;
// //       _isLoadingFavorite = true; // Need to check fav status even if details exist
// //       _errorMessage = null; // Clear previous errors
// //     });

// //     try {
// //       // Fetch data in parallel for efficiency
// //       final results = await Future.wait([
// //         _firestoreService.getVenueDetails(widget.venueId),
// //         _firestoreService.getReviewsForVenue(widget.venueId, limit: 50), // Fetch up to 50 reviews
// //         // Only check favorite status if user is logged in
// //         _authService.getCurrentUser() != null
// //             ? _userService.isVenueFavorite(widget.venueId)
// //             : Future.value(false), // Default to not favorite if logged out
// //       ]);

// //       // Process results
// //       final venueDetailsData = results[0] as Map<String, dynamic>?;
// //       final reviewsData = results[1] as List<Map<String, dynamic>>;
// //       final isFavoriteData = results[2] as bool;

// //       // Update state only if the widget is still mounted
// //       if (mounted) {
// //         if (venueDetailsData != null) {
// //           setState(() {
// //             _venueData = venueDetailsData; // Overwrite initial data with latest
// //             _reviews = reviewsData;
// //             _isFavorite = isFavoriteData;
// //             _calculateAverageRating(); // Recalculate rating based on fetched reviews
// //             _isLoadingDetails = false; // All main details are loaded
// //             _isLoadingReviews = false; // Reviews loaded
// //             _isLoadingFavorite = false; // Favorite status loaded
// //             _errorMessage = null; // Clear any previous errors
// //             _setupMapMarker(); // Update map markers with fetched location
// //           });
// //         } else {
// //           // Venue not found or other fetch error for details
// //           setState(() {
// //             _isLoadingDetails = false; // Stop loading
// //             _isLoadingReviews = false;
// //             _isLoadingFavorite = false;
// //             _errorMessage = 'Venue details not found.'; // Specific error message
// //           });
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("Error fetching venue details/reviews/fav status: $e");
// //       if (mounted) {
// //          // Handle error differently based on whether we had initial data
// //          if (_venueData == null) { // If initial load failed completely
// //              setState(() {
// //                  _isLoadingDetails = false;
// //                  _isLoadingReviews = false;
// //                  _isLoadingFavorite = false;
// //                  _errorMessage = 'Failed to load venue details. Please try again.';
// //              });
// //          } else { // If refresh failed but we have old data, show less intrusive error
// //              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //                  content: Text(
// //                    "Could not refresh all details: ${e.toString().replaceFirst("Exception: ", "")}",
// //                     maxLines: 2, overflow: TextOverflow.ellipsis,
// //                  ),
// //                  backgroundColor: Colors.orangeAccent,
// //               ));
// //              // Stop loading indicators but keep showing stale data
// //              setState(() {
// //                 _isLoadingReviews = false;
// //                 _isLoadingFavorite = false;
// //               });
// //            }
// //         }
// //     }
// //   }

// //   // Calculates average rating based on the fetched _reviews list
// //   void _calculateAverageRating() {
// //     if (!mounted) return;
// //     if (_reviews.isEmpty) {
// //       // Set rating/count to 0 if there are no reviews
// //       setState(() {
// //         _averageRating = 0.0;
// //         _reviewCount = 0;
// //       });
// //       return;
// //     }
// //     double totalRating = 0;
// //     // Sum up ratings from all fetched reviews
// //     for (var review in _reviews) {
// //       totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
// //     }
// //     setState(() {
// //       _reviewCount = _reviews.length; // Update review count
// //       // Calculate average and round to one decimal place
// //       _averageRating = (totalRating / _reviewCount * 10).round() / 10;
// //     });
// //   }

// //   // Sets up the marker for the Google Map based on _venueData
// //   void _setupMapMarker() {
// //     if (_venueData == null || !mounted) return;

// //     final GeoPoint? geoPoint = _venueData!['location'] as GeoPoint?;
// //     final String name = _venueData!['name'] as String? ?? 'Venue Location';
// //     final String address = _venueData!['address'] as String? ?? '';

// //     if (geoPoint != null) {
// //       final marker = Marker(
// //         markerId: MarkerId(widget.venueId), // Use venue ID for marker ID
// //         position: LatLng(geoPoint.latitude, geoPoint.longitude),
// //         infoWindow: InfoWindow(title: name, snippet: address), // Show info on tap
// //       );
// //       // Update the state to display the marker
// //       setState(() {
// //         _markers = {marker};
// //       });

// //       // If map is already created, animate camera to the new marker
// //       _mapController?.animateCamera(
// //         CameraUpdate.newLatLngZoom(
// //             LatLng(geoPoint.latitude, geoPoint.longitude), 14.5), // Zoom level 14.5
// //       );
// //     } else {
// //        // If no location data, clear existing markers
// //       setState(() {
// //         _markers = {};
// //       });
// //     }
// //   }

// //   // Callback when the Google Map is created
// //   void _onMapCreated(GoogleMapController controller) {
// //      if (!mounted) return;
// //     _mapController = controller; // Store the controller
// //     _setupMapMarker(); // Setup markers now that the map is ready
// //   }

// //   // Utility function to launch external URLs (website, phone)
// //   Future<void> _launchUrl(String urlString) async {
// //      if (!mounted) return; // Check if widget is still active
// //      final Uri url = Uri.parse(urlString); // Parse the string into a Uri
// //      try {
// //         bool canLaunch = await canLaunchUrl(url); // Check if the URL can be launched
// //         if (canLaunch) {
// //            // Launch the URL using the preferred external application mode
// //            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
// //              throw 'Could not launch $urlString'; // Throw error if launch fails
// //            }
// //         } else {
// //            throw 'Could not launch $urlString'; // Throw error if system can't handle the URL scheme
// //          }
// //      } catch (e) {
// //         debugPrint("Error launching URL: $e");
// //         if (mounted) // Show error message to the user
// //          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //              content: Text('Could not open link: ${e.toString().replaceFirst("Exception: ", "")}'),
// //              backgroundColor: Colors.redAccent));
// //      }
// //    }

// //   // Toggles the favorite status of the venue for the logged-in user
// //   Future<void> _toggleFavorite() async {
// //      // Check if user is logged in
// //      if (_authService.getCurrentUser() == null) {
// //         if (!mounted) return;
// //        ScaffoldMessenger.of(context).showSnackBar(
// //            const SnackBar(content: Text("Please log in to manage favorites.")));
// //        return;
// //      }
// //       // Prevent multiple taps while processing
// //      if (_isLoadingFavorite || !mounted) return;

// //      setState(() => _isLoadingFavorite = true); // Show loading indicator on button
// //      final originalFavStatus = _isFavorite; // Store original state for rollback on error

// //      try {
// //        // Call the appropriate UserService method based on current status
// //        if (_isFavorite) {
// //          await _userService.removeFavorite(widget.venueId);
// //        } else {
// //          await _userService.addFavorite(widget.venueId);
// //        }

// //        // Update UI only after successful Firestore operation
// //        if (mounted) {
// //          setState(() {
// //            _isFavorite = !_isFavorite; // Toggle the favorite state visually
// //            // Show confirmation message
// //             ScaffoldMessenger.of(context).showSnackBar(
// //                SnackBar(
// //                    content: Text(_isFavorite ? "Added to Favorites" : "Removed from Favorites"),
// //                    duration: const Duration(seconds: 2) // Short duration for confirmation
// //                ),
// //             );
// //          });
// //        }
// //      } catch (e) {
// //        debugPrint("Error toggling favorite: $e");
// //        // Rollback UI change if there was an error
// //         if (mounted) {
// //           setState(() {
// //               _isFavorite = originalFavStatus; // Revert visual state
// //           });
// //          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //              content: Text("Error updating favorites: ${e.toString().replaceFirst("Exception: ", "")}"),
// //              backgroundColor: Colors.redAccent)); // Show error message
// //        }
// //      } finally {
// //         // Ensure loading indicator is removed regardless of success/failure
// //        if (mounted) setState(() => _isLoadingFavorite = false);
// //      }
// //    }

// //   // Shows the dialog for adding a new review
// //   void _showAddReviewDialog() {
// //      // Check if user is logged in
// //      if (_authService.getCurrentUser() == null) {
// //         if (!mounted) return;
// //        ScaffoldMessenger.of(context).showSnackBar(
// //            const SnackBar(content: Text("Please log in to write a review.")));
// //        return;
// //      }
// //       // Ensure venue data is loaded before allowing review
// //      if (_venueData == null) return;

// //      showDialog<bool>(
// //        context: context,
// //        barrierDismissible: false, // Prevent closing by tapping outside
// //        builder: (BuildContext context) {
// //           // Use the dedicated AddReviewDialog widget
// //          return AddReviewDialog(venueId: widget.venueId);
// //        },
// //      ).then((success) {
// //         // After the dialog is closed, check if review was successfully added
// //        if (success == true && mounted) {
// //          // If successful, re-fetch all details to update the review list and average rating
// //          _fetchAllDetails();
// //        }
// //      });
// //    }

// //   // Shares venue details using the share_plus package
// //   Future<void> _shareVenue() async {
// //       // Ensure venue data is loaded
// //       if (_venueData == null) {
// //          if (!mounted) return;
// //          ScaffoldMessenger.of(context)
// //              .showSnackBar(const SnackBar(content: Text("Venue data not loaded yet.")));
// //          return;
// //       }

// //       // Extract data to share
// //       final String name = _venueData!['name'] as String? ?? 'This Venue';
// //       final String address = _venueData!['address'] as String? ?? '';
// //       final String city = _venueData!['city'] as String? ?? '';
// //       final String? website = _venueData!['website'] as String?;

// //       // Construct the share text
// //       final String locationInfo = [address, city].where((s) => s.isNotEmpty).join(', ');
// //       String shareText = 'Check out this venue: $name';
// //       if (locationInfo.isNotEmpty) {
// //          shareText += '\nLocated at: $locationInfo';
// //       }
// //       if (website != null && website.isNotEmpty) {
// //            final uri = Uri.tryParse(website);
// //            if (uri != null && uri.isAbsolute) { // Simple validation for absolute URL
// //               shareText += '\nWebsite: $website';
// //            }
// //       }
// //       // TODO: Consider adding a dynamic link to your app here if configured

// //       try {
// //          // Find the render box of the context to position the share sheet on iPad
// //          final RenderBox? box = context.findRenderObject() as RenderBox?;
// //          // Use the share_plus package to initiate sharing
// //          await Share.share(
// //            shareText, // The text content to share
// //            subject: 'Venue Recommendation: $name', // Optional subject, mainly for email
// //             // Provides positioning reference for iPad share popovers
// //            sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null
// //         );
// //       } catch (e) {
// //         debugPrint("Error sharing: $e");
// //          if (mounted) {
// //              ScaffoldMessenger.of(context)
// //                  .showSnackBar(const SnackBar(content: Text("Could not open share options.")));
// //          }
// //       }
// //     }

// //   // Navigates to the Venue Availability Screen
// //   void _navigateToBookingScreen() {
// //       // Ensure venue data is loaded
// //       if (_venueData == null) return;
// //       // Ensure user is logged in
// //       if (_authService.getCurrentUser() == null) {
// //          if (!mounted) return;
// //          ScaffoldMessenger.of(context).showSnackBar(
// //            const SnackBar(content: Text("Please log in to book a venue.")),
// //          );
// //          return;
// //       }

// //       // Extract booking-related info, providing safe defaults
// //       final bool bookingEnabled = _venueData!['bookingEnabled'] as bool? ?? false;
// //        final int slotDuration = (_venueData!['slotDurationMinutes'] as num?)?.toInt() ?? 60; // Default to 60 min
// //       final Map<String, dynamic>? operatingHours = _venueData!['operatingHours'] as Map<String, dynamic>?; // Can be null

// //       // Check if booking is enabled and hours are configured
// //       if (!bookingEnabled) {
// //          if (!mounted) return;
// //          ScaffoldMessenger.of(context).showSnackBar(
// //            const SnackBar(content: Text("Bookings are not enabled for this venue.")),
// //          );
// //          return;
// //       }
// //        if (operatingHours == null || operatingHours.isEmpty) {
// //            if (!mounted) return;
// //            ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(content: Text("Booking hours are not set up for this venue.")),
// //            );
// //            return;
// //        }

// //       // Navigate to the availability screen, passing required parameters
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => VenueAvailabilityScreen(
// //              venueId: widget.venueId, // Current venue ID
// //              venueName: _venueData!['name'] as String? ?? 'Venue', // Venue name for display
// //              operatingHours: operatingHours, // Pass the operating hours map
// //              slotDurationMinutes: slotDuration, // Pass slot duration
// //            ),
// //          ),
// //        );
// //    }


// //   @override
// //   Widget build(BuildContext context) {
// //      String appBarTitle = 'Loading...'; // Default title while loading
// //      // Determine if content can be shown based on loading state and data presence
// //      final bool canShowContent = !_isLoadingDetails && _venueData != null;

// //      // Set AppBar title based on state
// //      if (canShowContent) {
// //        appBarTitle = _venueData!['name'] as String? ?? 'Venue Details';
// //      } else if (_errorMessage != null && _venueData == null) { // Show error title only if initial load failed
// //        appBarTitle = 'Error Loading Venue';
// //      }

// //      // Determine if the Book Now button should be shown
// //      final bool showBookButton = canShowContent && (_venueData!['bookingEnabled'] as bool? ?? false);

// //      return Scaffold(
// //        appBar: AppBar(
// //          title: Text(appBarTitle, overflow: TextOverflow.ellipsis), // Prevent long titles overflowing
// //          actions: [
// //            // Share button - only shown when content is ready
// //            if (canShowContent)
// //              IconButton(
// //                icon: const Icon(Icons.share_outlined),
// //                tooltip: 'Share Venue',
// //                onPressed: _shareVenue,
// //              ),
// //             // Favorite button - shown if content is ready and user is logged in
// //            if (canShowContent && _authService.getCurrentUser() != null)
// //              IconButton(
// //                icon: _isLoadingFavorite // Show spinner while loading fav status
// //                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
// //                    : Icon( // Show filled or bordered heart based on state
// //                        _isFavorite ? Icons.favorite : Icons.favorite_border,
// //                        color: _isFavorite ? Colors.redAccent[100] : null, // Light red when favorited
// //                        semanticLabel: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
// //                      ),
// //                tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
// //                onPressed: _toggleFavorite, // Action to toggle favorite
// //              ),
// //          ],
// //        ),
// //         // Use RefreshIndicator for pull-to-refresh functionality
// //        body: RefreshIndicator(
// //            onRefresh: _fetchAllDetails, // Call fetch function on refresh
// //            child: _buildBody(canShowContent), // Build the main body content
// //         ),
// //         // Display Floating Action Button for booking if enabled and loaded
// //         floatingActionButton: showBookButton
// //             ? FloatingActionButton.extended(
// //                 onPressed: _navigateToBookingScreen, // Navigate to booking screen
// //                 icon: const Icon(Icons.calendar_today_outlined),
// //                 label: const Text('Check Availability & Book'),
// //                 tooltip: 'Check Availability & Book',
// //                )
// //             : null, // Show no FAB if booking isn't enabled/loaded
// //           // Position FAB based on whether booking is enabled to avoid overlap with potential review button
// //        floatingActionButtonLocation: showBookButton ? FloatingActionButtonLocation.centerFloat : FloatingActionButtonLocation.endFloat,
// //      );
// //    }

// //    // Builds the main content body of the screen
// //   Widget _buildBody(bool canShowContent) {
// //      // Show loading indicator if details are loading and no initial data exists
// //      if (_isLoadingDetails && _venueData == null) {
// //        return const Center(child: CircularProgressIndicator());
// //      }
// //       // Show error message if the initial load failed completely
// //      if (_errorMessage != null && _venueData == null) {
// //         return Center(
// //           child: Padding(
// //             padding: const EdgeInsets.all(16.0),
// //             child: Column(
// //                mainAxisAlignment: MainAxisAlignment.center,
// //                children: [
// //                   const Icon(Icons.error_outline, color: Colors.red, size: 50),
// //                   const SizedBox(height: 10),
// //                   Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 16), textAlign: TextAlign.center),
// //                   const SizedBox(height: 10),
// //                    ElevatedButton.icon( // Add a retry button
// //                       icon: const Icon(Icons.refresh),
// //                       label: const Text("Try Again"),
// //                       onPressed: _fetchAllDetails,
// //                    ),
// //                 ],
// //              ),
// //            ),
// //         );
// //       }
// //      // Fallback if data somehow becomes null after initial check (shouldn't usually happen)
// //      if (!canShowContent || _venueData == null) {
// //        return const Center(child: Text('Venue data not available.'));
// //      }


// //      // --- Extract data safely now that _venueData is guaranteed non-null ---
// //      final String name = _venueData!['name'] as String? ?? 'Unnamed Venue';
// //      final String description = _venueData!['description'] as String? ?? 'No description provided.';
// //      final String address = _venueData!['address'] as String? ?? 'Address not available';
// //      final String city = _venueData!['city'] as String? ?? 'Unknown City';
// //      final String country = _venueData!['country'] as String? ?? 'Unknown Country';
// //      final dynamic sportRaw = _venueData!['sportType'];
// //      final String? imageUrl = _venueData!['imageUrl'] as String?;
// //      final GeoPoint? geoPoint = _venueData!['location'] as GeoPoint?;
// //      final String? phoneNumber = _venueData!['phoneNumber'] as String?;
// //      final String? website = _venueData!['website'] as String?;
// //      final String? openingHours = _venueData!['openingHours'] as String?;
// //      final List<String> facilities = (_venueData!['facilities'] as List<dynamic>?)
// //              ?.cast<String>() // Ensure elements are Strings
// //              .where((f) => f.isNotEmpty) // Filter out empty strings if any
// //              .toList() ?? []; // Default to empty list if null
// //      final bool bookingEnabled = _venueData!['bookingEnabled'] as bool? ?? false;

// //      // Process sport types list into a display string
// //      String sport = 'Various Sports'; // Default value
// //      if (sportRaw is String && sportRaw.isNotEmpty) {
// //          sport = sportRaw; // Use directly if it's a non-empty string
// //      } else if (sportRaw is List && sportRaw.isNotEmpty) {
// //          sport = sportRaw.whereType<String>().where((s) => s.isNotEmpty).join(', '); // Join non-empty strings
// //          if (sport.isEmpty) sport = 'Various Sports'; // Fallback if list had only empty strings
// //       }
// //       // Combine address parts into a single display string
// //      final String fullAddress = [address, city, country].where((s) => s.isNotEmpty).join(', ');


// //      // Build the scrollable column layout
// //      return SingleChildScrollView(
// //        padding: const EdgeInsets.only(bottom: 90), // Padding at the bottom to avoid overlap with FAB
// //        child: Column(
// //          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
// //          children: [
// //            // --- Venue Image Section ---
// //             // Display image if available and valid URL, using Hero animation
// //            if (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
// //              Hero(
// //                tag: 'venue_image_${widget.venueId}', // Unique tag for animation
// //                child: Image.network(
// //                  imageUrl,
// //                  height: 250, // Fixed height for the image
// //                  width: double.infinity, // Take full width
// //                  fit: BoxFit.cover, // Cover the area, cropping if necessary
// //                  errorBuilder: (context, error, stackTrace) => Container( // Placeholder on error
// //                      height: 250, color: Colors.grey[200],
// //                      child: const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey))),
// //                  loadingBuilder: (context, child, loadingProgress) { // Show loading indicator
// //                    if (loadingProgress == null) return child; // Image loaded
// //                    return Container(
// //                        height: 250, color: Colors.grey[100],
// //                        child: Center(child: CircularProgressIndicator(
// //                                strokeWidth: 2,
// //                                value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null // Show progress % if possible
// //                            )));
// //                    },
// //                ),
// //              )
// //            else // Fallback placeholder if no valid image URL
// //              Container(
// //                  height: 250,
// //                  color: Theme.of(context).primaryColor.withOpacity(0.1), // Use theme color with opacity
// //                  child: Center(child: Icon(Icons.sports_rounded, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.6)))),


// //            // --- Main Content Area with Padding ---
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 16.0), // Add horizontal and top padding
// //               child: Column(
// //                  crossAxisAlignment: CrossAxisAlignment.start,
// //                  children: [
// //                     // Venue Name
// //                     Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
// //                     const SizedBox(height: 12), // Spacing

// //                     // --- Average Rating Display ---
// //                      Row(
// //                        children: [
// //                          // Show rating bar if rating is > 0
// //                           if (_averageRating > 0)
// //                            IgnorePointer( // Make the bar non-interactive
// //                              child: RatingBar.builder(
// //                                 initialRating: _averageRating,
// //                                 minRating: 1, // Minimum rating value
// //                                 direction: Axis.horizontal,
// //                                 allowHalfRating: true, // Allow showing half stars
// //                                 itemCount: 5, // Number of stars
// //                                 itemSize: 22.0, // Size of the stars
// //                                 itemPadding: const EdgeInsets.symmetric(horizontal: 0.0), // No horizontal padding between stars
// //                                 itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber), // Star icon
// //                                 onRatingUpdate: (rating) {}, // Callback not used for display
// //                               ),
// //                            )
// //                           // Show "No reviews yet" if loaded and rating is 0
// //                          else if (!_isLoadingReviews) // Only show if reviews have been checked
// //                             const Text("No reviews yet", style: TextStyle(color: Colors.grey)),

// //                          // Display numerical rating and count if available
// //                           if (_averageRating > 0)
// //                            Padding(
// //                              padding: const EdgeInsets.only(left: 8.0),
// //                              child: Text(
// //                                // Format average rating to one decimal place, show review count
// //                                '${_averageRating.toStringAsFixed(1)} ($_reviewCount review${_reviewCount != 1 ? 's' : ''})',
// //                                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
// //                              ),
// //                            ),
// //                          // Show a small spinner while reviews are initially loading if count is 0
// //                          if (_isLoadingReviews && _reviewCount == 0)
// //                            const Padding(
// //                              padding: EdgeInsets.only(left: 8.0),
// //                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
// //                            ),
// //                        ],
// //                      ),
// //                     const SizedBox(height: 12), // Spacing

// //                     // --- Detailed Info Rows ---
// //                      _buildInfoRow(context, Icons.location_on_outlined, fullAddress), // Display combined address
// //                      _buildInfoRow(context, Icons.fitness_center, sport, iconColor: Colors.deepPurple[300]), // Display sports
// //                      // Conditionally display Phone number if available, make tappable
// //                      if (phoneNumber != null && phoneNumber.isNotEmpty)
// //                         _buildInfoRow(context, Icons.phone_outlined, phoneNumber, onTap: () => _launchUrl('tel:$phoneNumber')),
// //                      // Conditionally display Website if available and valid, make tappable
// //                      if (website != null && website.isNotEmpty)
// //                          _buildInfoRow(context, Icons.language_outlined, website, onTap: () => _launchUrl(website)),
// //                       // Conditionally display Opening Hours if available
// //                      if (openingHours != null && openingHours.isNotEmpty)
// //                          _buildInfoRow(context, Icons.access_time_outlined, openingHours),

// //                     // --- Description Section ---
// //                     Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), // Section title
// //                     const SizedBox(height: 6), // Spacing
// //                      // Display description or fallback text
// //                      Text(
// //                         description.isEmpty ? 'No description available.' : description,
// //                         style: const TextStyle(fontSize: 15, height: 1.4), // Style for readability
// //                        ),

// //                     // --- Facilities Section ---
// //                     // Only show section if facilities list is not empty
// //                     if (facilities.isNotEmpty) ...[
// //                         const SizedBox(height: 16), // Spacing before section
// //                         Text('Facilities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), // Section title
// //                         const SizedBox(height: 8), // Spacing
// //                          // Use Wrap to display facility chips, handling overflow
// //                          Wrap(
// //                            spacing: 8.0, // Horizontal spacing between chips
// //                            runSpacing: 4.0, // Vertical spacing between lines of chips
// //                            children: facilities.map((facility) => Chip(
// //                                   label: Text(facility),
// //                                   avatar: _getFacilityIcon(facility), // Add relevant icon if available
// //                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Chip padding
// //                                   labelStyle: const TextStyle(fontSize: 13), // Style for chip text
// //                                )).toList(), // Convert mapped chips to a list
// //                           )
// //                       ]

// //                   ],
// //               ),
// //            ), // End Main Content Padding


// //           // --- Reviews Section ---
// //           // --- Reviews Section Separator and Title/Button Row ---
// // const Divider(height: 30, thickness: 1, indent: 16, endIndent: 16),
// // Padding(
// //     padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 4), // Reduce bottom padding if needed
// //     child: Row( // Use Row to place title and button side-by-side
// //        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push items to ends
// //        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
// //        children: [
// //           // Section Title (Takes available space)
// //           Flexible( // Use Flexible so Title doesn't overflow if button is wide
// //             child: Text(
// //                'Reviews (${_reviewCount})',
// //                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
// //                 overflow: TextOverflow.ellipsis, // Prevent overflow if title is very long
// //               ),
// //            ),

// //           // Write Review Button (Only show if user is logged in)
// //            if (_authService.getCurrentUser() != null) // Check if logged in
// //               TextButton.icon(
// //                  onPressed: _showAddReviewDialog, // Call your existing dialog function
// //                  icon: const Icon(Icons.edit_note_outlined, size: 18),
// //                  label: const Text("Write"),
// //                  style: TextButton.styleFrom(
// //                    // Optional: customize padding, color etc.
// //                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// //                     // foregroundColor: Theme.of(context).primaryColor,
// //                    visualDensity: VisualDensity.compact, // Makes button a bit smaller
// //                  ),
// //                ),
// //         ],
// //      ),
// //  ),
// //  _buildReviewsList(), // The actual list of reviews// Build the list of reviews


// //           // --- Map Section ---
// //           const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16), // Separator line
// //            Padding(
// //                padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //               child: Text('Location on Map', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), // Section title
// //            ),
// //            const SizedBox(height: 10), // Spacing
// //             // Conditionally display Google Map if location data exists
// //            if (geoPoint != null)
// //              Container(
// //                height: 250, // Fixed height for the map container
// //                margin: const EdgeInsets.symmetric(horizontal: 16.0), // Margin around map
// //                clipBehavior: Clip.antiAlias, // Clip map to rounded corners
// //                decoration: BoxDecoration(
// //                    borderRadius: BorderRadius.circular(8), // Rounded corners
// //                    border: Border.all(color: Colors.grey[300]!) // Subtle border
// //                ),
// //                child: GoogleMap(
// //                  onMapCreated: _onMapCreated, // Callback when map is ready
// //                  initialCameraPosition: CameraPosition( // Initial camera view
// //                     target: LatLng(geoPoint.latitude, geoPoint.longitude), // Center on venue
// //                     zoom: 14.5, // Zoom level
// //                    ),
// //                  markers: _markers, // Set of markers to display (just the one for the venue)
// //                  zoomControlsEnabled: true, // Show zoom buttons
// //                  mapType: MapType.normal, // Standard map type
// //                 ),
// //              )
// //            else // Display message if map location is not available
// //              const Padding(
// //                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
// //                child: Center(child: Text('Map location not available for this venue.', style: TextStyle(color: Colors.grey))),
// //              ),


// //            const SizedBox(height: 20), // Final spacing at the bottom

// //           ],
// //        ),
// //      );
// //    }

// //   // Helper widget to build consistently styled info rows (Icon + Text)
// //   Widget _buildInfoRow(BuildContext context, IconData icon, String text, {Color? iconColor, VoidCallback? onTap}) {
// //       final color = iconColor ?? Colors.grey[700]; // Default icon color
// //       final style = TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.3); // Text style
// //       // Row containing the icon and text
// //       Widget content = Row(
// //          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
// //          children: [
// //             Padding(
// //                padding: const EdgeInsets.only(top: 2.0, right: 10.0), // Align icon nicely with text
// //                child: Icon(icon, size: 20, color: color), // Icon display
// //              ),
// //              Expanded(child: Text(text, style: style)), // Text, expands to fill space
// //           ],
// //         );
// //      // Wrap with InkWell for tappable feedback if onTap is provided
// //      return Padding(
// //        padding: const EdgeInsets.symmetric(vertical: 6.0), // Vertical spacing for the row
// //        child: onTap != null
// //            ? InkWell(
// //                onTap: onTap, // Action to perform on tap
// //                borderRadius: BorderRadius.circular(4), // Feedback shape
// //                child: Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: content)) // Inner padding for tap area
// //            : content, // Return row directly if not tappable
// //       );
// //    }

// //    // Helper widget to build the list of reviews
// //   Widget _buildReviewsList() {
// //       // Show loading indicator while reviews are loading
// //       if (_isLoadingReviews) {
// //         // Use a less intrusive loading indicator for refreshes
// //          return const Padding(padding: EdgeInsets.symmetric(vertical: 30.0), child: Center(child: Text("Loading reviews...", style: TextStyle(color: Colors.grey))));
// //       }
// //       // Show message if no reviews are available
// //       if (_reviews.isEmpty) {
// //          return const Padding(
// //            padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
// //             child: Center(child: Text("Be the first to write a review!", style: TextStyle(color: Colors.grey, fontSize: 16))),
// //           );
// //        }
// //       // Build the list using ListView.separated for dividers between items
// //       return ListView.separated(
// //          shrinkWrap: true, // Prevent unbounded height in Column
// //          physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
// //          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding around the list
// //          itemCount: _reviews.length, // Number of reviews
// //          itemBuilder: (context, index) {
// //            // Build each list item using the ReviewListItem widget
// //            return ReviewListItem(reviewData: _reviews[index]);
// //          },
// //          separatorBuilder: (context, index) => const Divider(height: 1), // Add divider between reviews
// //        );
// //    }

// //   // Helper to get an icon based on facility name (case-insensitive)
// //   Widget? _getFacilityIcon(String facilityName) {
// //       // Map of facility names (lowercase) to icons
// //      final Map<String, IconData> facilityIcons = {
// //        'parking': Icons.local_parking,
// //        'car parking': Icons.local_parking,
// //        'wifi': Icons.wifi,
// //        'wi-fi': Icons.wifi,
// //        'showers': Icons.shower,
// //        'lockers': Icons.lock_outline,
// //        'equipment rental': Icons.build_outlined,
// //        'rental': Icons.build_outlined,
// //        'first aid': Icons.medical_services_outlined,
// //        'refreshments': Icons.fastfood_outlined,
// //        'cafe': Icons.local_cafe_outlined,
// //        'food': Icons.restaurant_outlined,
// //        'changing rooms': Icons.checkroom_outlined,
// //        'changing room': Icons.checkroom_outlined,
// //        'washroom': Icons.wc_outlined,
// //        'restroom': Icons.wc_outlined,
// //        'toilets': Icons.wc_outlined,
// //        'wheelchair accessible': Icons.accessible_forward,
// //      };

// //      String lowerCaseFacility = facilityName.toLowerCase().trim(); // Normalize input
// //      IconData? iconData = facilityIcons[lowerCaseFacility]; // Lookup icon

// //      // Return Icon widget if found, otherwise null
// //      if (iconData != null) {
// //          return Icon(iconData, size: 16, color: Colors.grey[700]);
// //      }
// //      return null;
// //    }

// // } // End of _VenueDetailScreenState class


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:mm_associates/features/bookings/screens/venue_availability_screen.dart';
// import 'package:mm_associates/features/data/services/firestore_service.dart';
// import 'package:mm_associates/features/home/widgets/full_screen_image_viewer.dart';
// import 'package:mm_associates/features/user/services/user_service.dart';
// import 'package:mm_associates/features/auth/services/auth_service.dart';
// import 'package:mm_associates/features/reviews/widgets/add_review_dialog.dart';
// import 'package:mm_associates/features/reviews/widgets/review_list_item.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// import 'package:share_plus/share_plus.dart';

// // Import the new fullscreen image viewer

// class VenueDetailScreen extends StatefulWidget {
//   final String venueId;
//   final Map<String, dynamic>? initialVenueData;

//   const VenueDetailScreen({
//     super.key,
//     required this.venueId,
//     this.initialVenueData,
//   });

//   @override
//   State<VenueDetailScreen> createState() => _VenueDetailScreenState();
// }

// class _VenueDetailScreenState extends State<VenueDetailScreen> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final UserService _userService = UserService();
//   final AuthService _authService = AuthService();

//   Map<String, dynamic>? _venueData;
//   bool _isLoadingDetails = true;
//   String? _errorMessage;
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};

//   List<Map<String, dynamic>> _reviews = [];
//   bool _isLoadingReviews = true;
//   bool _isFavorite = false;
//   bool _isLoadingFavorite = true;
//   double _averageRating = 0.0;
//   int _reviewCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _applyInitialData();
//     _fetchAllDetails();
//   }

//   void _applyInitialData() {
//     if (widget.initialVenueData != null && widget.initialVenueData!.isNotEmpty) {
//       _venueData = widget.initialVenueData;
//       _averageRating =
//           (widget.initialVenueData!['averageRating'] as num?)?.toDouble() ??
//               0.0;
//       _reviewCount =
//           (widget.initialVenueData!['reviewCount'] as num?)?.toInt() ?? 0;
//       _isLoadingDetails = false;
//       _setupMapMarker();
//     } else {
//       _isLoadingDetails = true;
//     }
//   }

//   @override
//   void dispose() {
//     _mapController?.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchAllDetails() async {
//     if (!mounted) return;
//     setState(() {
//       if (_venueData == null) _isLoadingDetails = true;
//       _isLoadingReviews = true;
//       _isLoadingFavorite = true;
//       _errorMessage = null;
//     });

//     try {
//       final results = await Future.wait([
//         _firestoreService.getVenueDetails(widget.venueId),
//         _firestoreService.getReviewsForVenue(widget.venueId, limit: 50),
//         _authService.getCurrentUser() != null
//             ? _userService.isVenueFavorite(widget.venueId)
//             : Future.value(false),
//       ]);

//       final venueDetailsData = results[0] as Map<String, dynamic>?;
//       final reviewsData = results[1] as List<Map<String, dynamic>>;
//       final isFavoriteData = results[2] as bool;

//       if (mounted) {
//         if (venueDetailsData != null) {
//           setState(() {
//             _venueData = venueDetailsData;
//             _reviews = reviewsData;
//             _isFavorite = isFavoriteData;
//             _calculateAverageRating();
//             _isLoadingDetails = false;
//             _isLoadingReviews = false;
//             _isLoadingFavorite = false;
//             _errorMessage = null;
//             _setupMapMarker();
//           });
//         } else {
//           setState(() {
//             _isLoadingDetails = false;
//             _isLoadingReviews = false;
//             _isLoadingFavorite = false;
//             _errorMessage = 'Venue details not found.';
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Error fetching venue details/reviews/fav status: $e");
//       if (mounted) {
//          if (_venueData == null) {
//              setState(() {
//                  _isLoadingDetails = false;
//                  _isLoadingReviews = false;
//                  _isLoadingFavorite = false;
//                  _errorMessage = 'Failed to load venue details. Please try again.';
//              });
//          } else {
//              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                  content: Text(
//                    "Could not refresh all details: ${e.toString().replaceFirst("Exception: ", "")}",
//                     maxLines: 2, overflow: TextOverflow.ellipsis,
//                  ),
//                  backgroundColor: Colors.orangeAccent,
//               ));
//              setState(() {
//                 _isLoadingReviews = false;
//                 _isLoadingFavorite = false;
//               });
//            }
//         }
//     }
//   }

//   void _calculateAverageRating() {
//     if (!mounted) return;
//     if (_reviews.isEmpty) {
//       setState(() {
//         _averageRating = 0.0;
//         _reviewCount = 0;
//       });
//       return;
//     }
//     double totalRating = 0;
//     for (var review in _reviews) {
//       totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
//     }
//     setState(() {
//       _reviewCount = _reviews.length;
//       _averageRating = (totalRating / _reviewCount * 10).round() / 10;
//     });
//   }

//   void _setupMapMarker() {
//     if (_venueData == null || !mounted) return;

//     final GeoPoint? geoPoint = _venueData!['location'] as GeoPoint?;
//     final String name = _venueData!['name'] as String? ?? 'Venue Location';
//     final String address = _venueData!['address'] as String? ?? '';

//     if (geoPoint != null) {
//       final marker = Marker(
//         markerId: MarkerId(widget.venueId),
//         position: LatLng(geoPoint.latitude, geoPoint.longitude),
//         infoWindow: InfoWindow(title: name, snippet: address),
//       );
//       setState(() {
//         _markers = {marker};
//       });

//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(
//             LatLng(geoPoint.latitude, geoPoint.longitude), 14.5),
//       );
//     } else {
//       setState(() {
//         _markers = {};
//       });
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//      if (!mounted) return;
//     _mapController = controller;
//     _setupMapMarker();
//   }

//   Future<void> _launchUrl(String urlString) async {
//      if (!mounted) return;
//      final Uri url = Uri.parse(urlString);
//      try {
//         bool canLaunch = await canLaunchUrl(url);
//         if (canLaunch) {
//            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//              throw 'Could not launch $urlString';
//            }
//         } else {
//            throw 'Could not launch $urlString';
//          }
//      } catch (e) {
//         debugPrint("Error launching URL: $e");
//         if (mounted)
//          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//              content: Text('Could not open link: ${e.toString().replaceFirst("Exception: ", "")}'),
//              backgroundColor: Colors.redAccent));
//      }
//    }

//   Future<void> _toggleFavorite() async {
//      if (_authService.getCurrentUser() == null) {
//         if (!mounted) return;
//        ScaffoldMessenger.of(context).showSnackBar(
//            const SnackBar(content: Text("Please log in to manage favorites.")));
//        return;
//      }
//      if (_isLoadingFavorite || !mounted) return;

//      setState(() => _isLoadingFavorite = true);
//      final originalFavStatus = _isFavorite;

//      try {
//        if (_isFavorite) {
//          await _userService.removeFavorite(widget.venueId);
//        } else {
//          await _userService.addFavorite(widget.venueId);
//        }
//        if (mounted) {
//          setState(() {
//            _isFavorite = !_isFavorite;
//             ScaffoldMessenger.of(context).showSnackBar(
//                SnackBar(
//                    content: Text(_isFavorite ? "Added to Favorites" : "Removed from Favorites"),
//                    duration: const Duration(seconds: 2)
//                ),
//             );
//          });
//        }
//      } catch (e) {
//        debugPrint("Error toggling favorite: $e");
//         if (mounted) {
//           setState(() {
//               _isFavorite = originalFavStatus;
//           });
//          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//              content: Text("Error updating favorites: ${e.toString().replaceFirst("Exception: ", "")}"),
//              backgroundColor: Colors.redAccent));
//        }
//      } finally {
//        if (mounted) setState(() => _isLoadingFavorite = false);
//      }
//    }

//   void _showAddReviewDialog() {
//      if (_authService.getCurrentUser() == null) {
//         if (!mounted) return;
//        ScaffoldMessenger.of(context).showSnackBar(
//            const SnackBar(content: Text("Please log in to write a review.")));
//        return;
//      }
//      if (_venueData == null) return;

//      showDialog<bool>(
//        context: context,
//        barrierDismissible: false,
//        builder: (BuildContext context) {
//          return AddReviewDialog(venueId: widget.venueId);
//        },
//      ).then((success) {
//        if (success == true && mounted) {
//          _fetchAllDetails();
//        }
//      });
//    }

//   Future<void> _shareVenue() async {
//       if (_venueData == null) {
//          if (!mounted) return;
//          ScaffoldMessenger.of(context)
//              .showSnackBar(const SnackBar(content: Text("Venue data not loaded yet.")));
//          return;
//       }

//       final String name = _venueData!['name'] as String? ?? 'This Venue';
//       final String address = _venueData!['address'] as String? ?? '';
//       final String city = _venueData!['city'] as String? ?? '';
//       final String? website = _venueData!['website'] as String?;
//       final String? googleMapsUrl = _venueData!['googleMapsUrl'] as String?; // Get Google Maps URL


//       final String locationInfo = [address, city].where((s) => s.isNotEmpty).join(', ');
//       String shareText = 'Check out this venue: $name';
//       if (locationInfo.isNotEmpty) {
//          shareText += '\nLocated at: $locationInfo';
//       }

//       // Prefer Google Maps link if available for sharing location
//       if (googleMapsUrl != null && googleMapsUrl.isNotEmpty && Uri.tryParse(googleMapsUrl)?.isAbsolute == true) {
//         shareText += '\nFind it on Google Maps: $googleMapsUrl';
//       } else if (website != null && website.isNotEmpty) {
//            final uri = Uri.tryParse(website);
//            if (uri != null && uri.isAbsolute) {
//               shareText += '\nWebsite: $website';
//            }
//       }

//       try {
//          final RenderBox? box = context.findRenderObject() as RenderBox?;
//          await Share.share(
//            shareText,
//            subject: 'Venue Recommendation: $name',
//            sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null
//         );
//       } catch (e) {
//         debugPrint("Error sharing: $e");
//          if (mounted) {
//              ScaffoldMessenger.of(context)
//                  .showSnackBar(const SnackBar(content: Text("Could not open share options.")));
//          }
//       }
//     }

//   void _navigateToBookingScreen() {
//       if (_venueData == null) return;
//       if (_authService.getCurrentUser() == null) {
//          if (!mounted) return;
//          ScaffoldMessenger.of(context).showSnackBar(
//            const SnackBar(content: Text("Please log in to book a venue.")),
//          );
//          return;
//       }

//       final bool bookingEnabled = _venueData!['bookingEnabled'] as bool? ?? false;
//        final int slotDuration = (_venueData!['slotDurationMinutes'] as num?)?.toInt() ?? 60;
//       final Map<String, dynamic>? operatingHours = _venueData!['operatingHours'] as Map<String, dynamic>?;

//       if (!bookingEnabled) {
//          if (!mounted) return;
//          ScaffoldMessenger.of(context).showSnackBar(
//            const SnackBar(content: Text("Bookings are not enabled for this venue.")),
//          );
//          return;
//       }
//        if (operatingHours == null || operatingHours.isEmpty) {
//            if (!mounted) return;
//            ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Booking hours are not set up for this venue.")),
//            );
//            return;
//        }
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => VenueAvailabilityScreen(
//              venueId: widget.venueId,
//              venueName: _venueData!['name'] as String? ?? 'Venue',
//              operatingHours: operatingHours,
//              slotDurationMinutes: slotDuration,
//            ),
//          ),
//        );
//    }


//   @override
//   Widget build(BuildContext context) {
//      String appBarTitle = 'Loading...';
//      final bool canShowContent = !_isLoadingDetails && _venueData != null;

//      if (canShowContent) {
//        appBarTitle = _venueData!['name'] as String? ?? 'Venue Details';
//      } else if (_errorMessage != null && _venueData == null) {
//        appBarTitle = 'Error Loading Venue';
//      }

//      final bool showBookButton = canShowContent && (_venueData!['bookingEnabled'] as bool? ?? false);

//      return Scaffold(
//        appBar: AppBar(
//          title: Text(appBarTitle, overflow: TextOverflow.ellipsis),
//          actions: [
//            if (canShowContent)
//              IconButton(
//                icon: const Icon(Icons.share_outlined),
//                tooltip: 'Share Venue',
//                onPressed: _shareVenue,
//              ),
//            if (canShowContent && _authService.getCurrentUser() != null)
//              IconButton(
//                icon: _isLoadingFavorite
//                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                    : Icon(
//                        _isFavorite ? Icons.favorite : Icons.favorite_border,
//                        color: _isFavorite ? Colors.redAccent[100] : null,
//                        semanticLabel: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
//                      ),
//                tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
//                onPressed: _toggleFavorite,
//              ),
//          ],
//        ),
//        body: RefreshIndicator(
//            onRefresh: _fetchAllDetails,
//            child: _buildBody(canShowContent),
//         ),
//         floatingActionButton: showBookButton
//             ? FloatingActionButton.extended(
//                 onPressed: _navigateToBookingScreen,
//                 icon: const Icon(Icons.calendar_today_outlined),
//                 label: const Text('Check Availability & Book'),
//                 tooltip: 'Check Availability & Book',
//                )
//             : null,
//        floatingActionButtonLocation: showBookButton ? FloatingActionButtonLocation.centerFloat : FloatingActionButtonLocation.endFloat,
//      );
//    }

//   Widget _buildBody(bool canShowContent) {
//      if (_isLoadingDetails && _venueData == null) {
//        return const Center(child: CircularProgressIndicator());
//      }
//      if (_errorMessage != null && _venueData == null) {
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: [
//                   const Icon(Icons.error_outline, color: Colors.red, size: 50),
//                   const SizedBox(height: 10),
//                   Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 16), textAlign: TextAlign.center),
//                   const SizedBox(height: 10),
//                    ElevatedButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text("Try Again"),
//                       onPressed: _fetchAllDetails,
//                    ),
//                 ],
//              ),
//            ),
//         );
//       }
//      if (!canShowContent || _venueData == null) {
//        return const Center(child: Text('Venue data not available.'));
//      }

//      final String name = _venueData!['name'] as String? ?? 'Unnamed Venue';
//      final String description = _venueData!['description'] as String? ?? 'No description provided.';
//      final String address = _venueData!['address'] as String? ?? 'Address not available';
//      final String city = _venueData!['city'] as String? ?? 'Unknown City';
//      final String country = _venueData!['country'] as String? ?? 'Unknown Country';
//      final dynamic sportRaw = _venueData!['sportType'];
//      final String? imageUrl = _venueData!['imageUrl'] as String?;
//      final GeoPoint? geoPoint = _venueData!['location'] as GeoPoint?;
//      final String? phoneNumber = _venueData!['phoneNumber'] as String?;
//      final String? website = _venueData!['website'] as String?;
//      final Map<String, dynamic>? operatingHoursMap = _venueData!['operatingHours'] as Map<String, dynamic>?; // Use this for passing to booking screen
//      final List<String> facilities = (_venueData!['facilities'] as List<dynamic>?)
//              ?.cast<String>()
//              .where((f) => f.isNotEmpty)
//              .toList() ?? [];
//     //  final bool bookingEnabled = _venueData!['bookingEnabled'] as bool? ?? false;
//      final String? googleMapsUrl = _venueData!['googleMapsUrl'] as String?; // <<<< GET googleMapsUrl


//      String sport = 'Various Sports';
//      if (sportRaw is String && sportRaw.isNotEmpty) {
//          sport = sportRaw;
//      } else if (sportRaw is List && sportRaw.isNotEmpty) {
//          sport = sportRaw.whereType<String>().where((s) => s.isNotEmpty).join(', ');
//          if (sport.isEmpty) sport = 'Various Sports';
//       }
//      final String fullAddress = [address, city, country].where((s) => s.isNotEmpty).join(', ');
//       String openingHoursDisplay = "Not specified"; // Default for display
//         if (operatingHoursMap != null) {
//           final weekday = operatingHoursMap['weekday'];
//           if (weekday != null && weekday['start'] != null && weekday['end'] != null) {
//             if (weekday['start'].isNotEmpty || weekday['end'].isNotEmpty) {
//                openingHoursDisplay = "Weekdays: ${weekday['start']} - ${weekday['end']}";
//              }
//            }
//           // You could add more complex logic here to format Saturday/Sunday hours too
//          }

//      return SingleChildScrollView(
//        padding: const EdgeInsets.only(bottom: 90),
//        child: Column(
//          crossAxisAlignment: CrossAxisAlignment.start,
//          children: [
//            if (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
//              GestureDetector( // <<<< WRAPPED WITH GESTUREDETECTOR
//                onTap: () {
//                  Navigator.push(context, MaterialPageRoute(builder: (_) {
//                    return FullScreenImageViewer(imageUrl: imageUrl, heroTag: 'venue_image_${widget.venueId}');
//                  }));
//                },
//                child: Hero(
//                  tag: 'venue_image_${widget.venueId}',
//                  child: Image.network(
//                    imageUrl,
//                    height: 250,
//                    width: double.infinity,
//                    fit: BoxFit.cover,
//                    errorBuilder: (context, error, stackTrace) => Container(
//                        height: 250, color: Colors.grey[200],
//                        child: const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey))),
//                    loadingBuilder: (context, child, loadingProgress) {
//                      if (loadingProgress == null) return child;
//                      return Container(
//                          height: 250, color: Colors.grey[100],
//                          child: Center(child: CircularProgressIndicator(
//                                  strokeWidth: 2,
//                                  value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null
//                              )));
//                      },
//                  ),
//                ),
//              )
//            else
//              Container(
//                  height: 250,
//                  color: Theme.of(context).primaryColor.withOpacity(0.1),
//                  child: Center(child: Icon(Icons.sports_rounded, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.6)))),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 16.0),
//               child: Column(
//                  crossAxisAlignment: CrossAxisAlignment.start,
//                  children: [
//                     Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 12),
//                      Row(
//                        children: [
//                           if (_averageRating > 0)
//                            IgnorePointer(
//                              child: RatingBar.builder(
//                                 initialRating: _averageRating,
//                                 minRating: 1,
//                                 direction: Axis.horizontal,
//                                 allowHalfRating: true,
//                                 itemCount: 5,
//                                 itemSize: 22.0,
//                                 itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
//                                 itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
//                                 onRatingUpdate: (rating) {},
//                               ),
//                            )
//                          else if (!_isLoadingReviews)
//                             const Text("No reviews yet", style: TextStyle(color: Colors.grey)),
//                           if (_averageRating > 0)
//                            Padding(
//                              padding: const EdgeInsets.only(left: 8.0),
//                              child: Text(
//                                '${_averageRating.toStringAsFixed(1)} ($_reviewCount review${_reviewCount != 1 ? 's' : ''})',
//                                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
//                              ),
//                            ),
//                          if (_isLoadingReviews && _reviewCount == 0)
//                            const Padding(
//                              padding: EdgeInsets.only(left: 8.0),
//                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
//                            ),
//                        ],
//                      ),
//                     const SizedBox(height: 12),
//                      _buildInfoRow(context, Icons.location_on_outlined, fullAddress),
//                      _buildInfoRow(context, Icons.fitness_center, sport, iconColor: Colors.deepPurple[300]),
//                      if (phoneNumber != null && phoneNumber.isNotEmpty)
//                         _buildInfoRow(context, Icons.phone_outlined, phoneNumber, onTap: () => _launchUrl('tel:$phoneNumber')),
//                      if (website != null && website.isNotEmpty)
//                          _buildInfoRow(context, Icons.language_outlined, website, onTap: () => _launchUrl(website)),
//                     _buildInfoRow(context, Icons.access_time_outlined, openingHoursDisplay),


//                     Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 6),
//                      Text(
//                         description.isEmpty ? 'No description available.' : description,
//                         style: const TextStyle(fontSize: 15, height: 1.4),
//                        ),
//                     if (facilities.isNotEmpty) ...[
//                         const SizedBox(height: 16),
//                         Text('Facilities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//                         const SizedBox(height: 8),
//                          Wrap(
//                            spacing: 8.0,
//                            runSpacing: 4.0,
//                            children: facilities.map((facility) => Chip(
//                                   label: Text(facility),
//                                   avatar: _getFacilityIcon(facility),
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   labelStyle: const TextStyle(fontSize: 13),
//                                )).toList(),
//                           )
//                       ]
//                   ],
//               ),
//            ),


//         const Divider(height: 30, thickness: 1, indent: 16, endIndent: 16),
//         Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 4),
//             child: Row(
//                mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                crossAxisAlignment: CrossAxisAlignment.center,
//                children: [
//                   Flexible(
//                     child: Text(
//                        'Reviews ($_reviewCount)',
//                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                    ),
//                    if (_authService.getCurrentUser() != null)
//                       TextButton.icon(
//                          onPressed: _showAddReviewDialog,
//                          icon: const Icon(Icons.edit_note_outlined, size: 18),
//                          label: const Text("Write"),
//                          style: TextButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                            visualDensity: VisualDensity.compact,
//                          ),
//                        ),
//                 ],
//              ),
//          ),
//         _buildReviewsList(),


//           const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
//            Padding(
//                padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Text('Location on Map', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//            ),
//            const SizedBox(height: 5),
//            if (googleMapsUrl != null && googleMapsUrl.isNotEmpty && Uri.tryParse(googleMapsUrl)?.isAbsolute == true)
//              Padding(
//                padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0, bottom: 10.0),
//                child: Center(
//                  child: OutlinedButton.icon(
//                    icon: const Icon(Icons.open_in_new_outlined, size: 18),
//                    label: const Text('Open in Google Maps'),
//                    onPressed: () => _launchUrl(googleMapsUrl),
//                    style: OutlinedButton.styleFrom(
//                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                      // side: BorderSide(color: Theme.of(context).primaryColor),
//                    ),
//                  ),
//                ),
//              ),
//            const SizedBox(height: 20),
//           ],
//        ),
//      );
//    }

//   Widget _buildInfoRow(BuildContext context, IconData icon, String text, {Color? iconColor, VoidCallback? onTap}) {
//       final color = iconColor ?? Colors.grey[700];
//       final style = TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.3);
//       Widget content = Row(
//          crossAxisAlignment: CrossAxisAlignment.start,
//          children: [
//             Padding(
//                padding: const EdgeInsets.only(top: 2.0, right: 10.0),
//                child: Icon(icon, size: 20, color: color),
//              ),
//              Expanded(child: Text(text, style: style)),
//           ],
//         );
//      return Padding(
//        padding: const EdgeInsets.symmetric(vertical: 6.0),
//        child: onTap != null
//            ? InkWell(
//                onTap: onTap,
//                borderRadius: BorderRadius.circular(4),
//                child: Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: content))
//            : content,
//       );
//    }

//   Widget _buildReviewsList() {
//       if (_isLoadingReviews) {
//          return const Padding(padding: EdgeInsets.symmetric(vertical: 30.0), child: Center(child: Text("Loading reviews...", style: TextStyle(color: Colors.grey))));
//       }
//       if (_reviews.isEmpty) {
//          return const Padding(
//            padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
//             child: Center(child: Text("Be the first to write a review!", style: TextStyle(color: Colors.grey, fontSize: 16))),
//           );
//        }
//       return ListView.separated(
//          shrinkWrap: true,
//          physics: const NeverScrollableScrollPhysics(),
//          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//          itemCount: _reviews.length,
//          itemBuilder: (context, index) {
//            return ReviewListItem(reviewData: _reviews[index]);
//          },
//          separatorBuilder: (context, index) => const Divider(height: 1),
//        );
//    }

//   Widget? _getFacilityIcon(String facilityName) {
//      final Map<String, IconData> facilityIcons = {
//        'parking': Icons.local_parking,
//        'car parking': Icons.local_parking,
//        'wifi': Icons.wifi,
//        'wi-fi': Icons.wifi,
//        'showers': Icons.shower,
//        'lockers': Icons.lock_outline,
//        'equipment rental': Icons.build_outlined,
//        'rental': Icons.build_outlined,
//        'first aid': Icons.medical_services_outlined,
//        'refreshments': Icons.fastfood_outlined,
//        'cafe': Icons.local_cafe_outlined,
//        'food': Icons.restaurant_outlined,
//        'changing rooms': Icons.checkroom_outlined,
//        'changing room': Icons.checkroom_outlined,
//        'washroom': Icons.wc_outlined,
//        'restroom': Icons.wc_outlined,
//        'toilets': Icons.wc_outlined,
//        'wheelchair accessible': Icons.accessible_forward,
//      };

//      String lowerCaseFacility = facilityName.toLowerCase().trim();
//      IconData? iconData = facilityIcons[lowerCaseFacility];

//      if (iconData != null) {
//          return Icon(iconData, size: 16, color: Colors.grey[700]);
//      }
//      return null;
//    }
// }

// lib/features/home/screens/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mm_associates/features/bookings/screens/venue_availability_screen.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';
// Ensure this path is correct for your project structure
import 'package:mm_associates/features/home/widgets/full_screen_image_viewer.dart';
import 'package:mm_associates/features/user/services/user_service.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';
import 'package:mm_associates/features/reviews/widgets/add_review_dialog.dart';
import 'package:mm_associates/features/reviews/widgets/review_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';


class VenueDetailScreen extends StatefulWidget {
  final String venueId;
  final Map<String, dynamic>? initialVenueData;

  const VenueDetailScreen({
    super.key,
    required this.venueId,
    this.initialVenueData,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _venueData;
  bool _isLoadingDetails = true;
  String? _errorMessage;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _applyInitialData();
    _fetchAllDetails();
  }

  void _applyInitialData() {
    if (widget.initialVenueData != null && widget.initialVenueData!.isNotEmpty) {
      _venueData = widget.initialVenueData;
      _averageRating =
          (widget.initialVenueData!['averageRating'] as num?)?.toDouble() ??
              0.0;
      _reviewCount =
          (widget.initialVenueData!['reviewCount'] as num?)?.toInt() ?? 0;
      _isLoadingDetails = false;
      _setupMapMarker();
    } else {
      _isLoadingDetails = true;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAllDetails() async {
    if (!mounted) return;
    setState(() {
      if (_venueData == null) _isLoadingDetails = true;
      _isLoadingReviews = true;
      _isLoadingFavorite = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _firestoreService.getVenueDetails(widget.venueId),
        _firestoreService.getReviewsForVenue(widget.venueId, limit: 50),
        _authService.getCurrentUser() != null
            ? _userService.isVenueFavorite(widget.venueId)
            : Future.value(false),
      ]);

      final venueDetailsData = results[0] as Map<String, dynamic>?;
      final reviewsData = results[1] as List<Map<String, dynamic>>;
      final isFavoriteData = results[2] as bool;

      if (mounted) {
        if (venueDetailsData != null) {
          setState(() {
            _venueData = venueDetailsData;
            _reviews = reviewsData;
            _isFavorite = isFavoriteData;
            _calculateAverageRating();
            _isLoadingDetails = false;
            _isLoadingReviews = false;
            _isLoadingFavorite = false;
            _errorMessage = null;
            _setupMapMarker();
          });
        } else {
          setState(() {
            _isLoadingDetails = false;
            _isLoadingReviews = false;
            _isLoadingFavorite = false;
            _errorMessage = 'Venue details not found.';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching venue details/reviews/fav status: $e");
      if (mounted) {
         if (_venueData == null) {
             setState(() {
                 _isLoadingDetails = false;
                 _isLoadingReviews = false;
                 _isLoadingFavorite = false;
                 _errorMessage = 'Failed to load venue details. Please try again.';
             });
         } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(
                   "Could not refresh all details: ${e.toString().replaceFirst("Exception: ", "")}",
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                 ),
                 backgroundColor: Colors.orangeAccent,
              ));
             setState(() {
                _isLoadingReviews = false;
                _isLoadingFavorite = false;
              });
           }
        }
    }
  }

  void _calculateAverageRating() {
    if (!mounted) return;
    if (_reviews.isEmpty) {
      setState(() {
        _averageRating = 0.0;
        _reviewCount = 0;
      });
      return;
    }
    double totalRating = 0;
    for (var review in _reviews) {
      totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
    }
    setState(() {
      _reviewCount = _reviews.length;
      _averageRating = (totalRating / _reviewCount * 10).round() / 10;
    });
  }

  void _setupMapMarker() {
    if (_venueData == null || !mounted) return;

    final GeoPoint? geoPoint = _venueData!['location'] as GeoPoint?;
    final String name = _venueData!['name'] as String? ?? 'Venue Location';
    final String address = _venueData!['address'] as String? ?? '';

    if (geoPoint != null) {
      final marker = Marker(
        markerId: MarkerId(widget.venueId),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        infoWindow: InfoWindow(title: name, snippet: address),
      );
      setState(() {
        _markers = {marker};
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(geoPoint.latitude, geoPoint.longitude), 14.5),
      );
    } else {
      setState(() {
        _markers = {};
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
     if (!mounted) return;
    _mapController = controller;
    _setupMapMarker();
  }

  Future<void> _launchUrl(String urlString) async {
     if (!mounted) return;
     final Uri url = Uri.parse(urlString);
     try {
        bool canLaunch = await canLaunchUrl(url);
        if (canLaunch) {
           if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
             throw 'Could not launch $urlString';
           }
        } else {
           throw 'Could not launch $urlString';
         }
     } catch (e) {
        debugPrint("Error launching URL: $e");
        if (mounted)
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text('Could not open link: ${e.toString().replaceFirst("Exception: ", "")}'),
             backgroundColor: Colors.redAccent));
     }
   }

  Future<void> _toggleFavorite() async {
     if (_authService.getCurrentUser() == null) {
        if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Please log in to manage favorites.")));
       return;
     }
     if (_isLoadingFavorite || !mounted) return;

     setState(() => _isLoadingFavorite = true);
     final originalFavStatus = _isFavorite;

     try {
       if (_isFavorite) {
         await _userService.removeFavorite(widget.venueId);
       } else {
         await _userService.addFavorite(widget.venueId);
       }
       if (mounted) {
         setState(() {
           _isFavorite = !_isFavorite;
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                   content: Text(_isFavorite ? "Added to Favorites" : "Removed from Favorites"),
                   duration: const Duration(seconds: 2)
               ),
            );
         });
       }
     } catch (e) {
       debugPrint("Error toggling favorite: $e");
        if (mounted) {
          setState(() {
              _isFavorite = originalFavStatus;
          });
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text("Error updating favorites: ${e.toString().replaceFirst("Exception: ", "")}"),
             backgroundColor: Colors.redAccent));
       }
     } finally {
       if (mounted) setState(() => _isLoadingFavorite = false);
     }
   }

  void _showAddReviewDialog() {
     if (_authService.getCurrentUser() == null) {
        if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Please log in to write a review.")));
       return;
     }
     if (_venueData == null) return;

     showDialog<bool>(
       context: context,
       barrierDismissible: false,
       builder: (BuildContext context) {
         return AddReviewDialog(venueId: widget.venueId);
       },
     ).then((success) {
       if (success == true && mounted) {
         _fetchAllDetails();
       }
     });
   }

  Future<void> _shareVenue() async {
      if (_venueData == null) {
         if (!mounted) return;
         ScaffoldMessenger.of(context)
             .showSnackBar(const SnackBar(content: Text("Venue data not loaded yet.")));
         return;
      }

      final String name = _venueData!['name'] as String? ?? 'This Venue';
      final String address = _venueData!['address'] as String? ?? '';
      final String city = _venueData!['city'] as String? ?? '';
      final String? website = _venueData!['website'] as String?;
      final String? googleMapsUrl = _venueData!['googleMapsUrl'] as String?;


      final String locationInfo = [address, city].where((s) => s.isNotEmpty).join(', ');
      String shareText = 'Check out this venue: $name';
      if (locationInfo.isNotEmpty) {
         shareText += '\nLocated at: $locationInfo';
      }

      if (googleMapsUrl != null && googleMapsUrl.isNotEmpty && Uri.tryParse(googleMapsUrl)?.isAbsolute == true) {
        shareText += '\nFind it on Google Maps: $googleMapsUrl';
      } else if (website != null && website.isNotEmpty) {
           final uri = Uri.tryParse(website);
           if (uri != null && uri.isAbsolute) {
              shareText += '\nWebsite: $website';
           }
      }

      try {
         final RenderBox? box = context.findRenderObject() as RenderBox?;
         await Share.share(
           shareText,
           subject: 'Venue Recommendation: $name',
           sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null
        );
      } catch (e) {
        debugPrint("Error sharing: $e");
         if (mounted) {
             ScaffoldMessenger.of(context)
                 .showSnackBar(const SnackBar(content: Text("Could not open share options.")));
         }
      }
    }

  void _navigateToBookingScreen() {
      if (_venueData == null) return;
      if (_authService.getCurrentUser() == null) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Please log in to book a venue.")),
         );
         return;
      }

      final bool bookingEnabled = _venueData!['bookingEnabled'] as bool? ?? false;
       final int slotDuration = (_venueData!['slotDurationMinutes'] as num?)?.toInt() ?? 60;
      final Map<String, dynamic>? operatingHours = _venueData!['operatingHours'] as Map<String, dynamic>?;

      if (!bookingEnabled) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Bookings are not enabled for this venue.")),
         );
         return;
      }
       if (operatingHours == null || operatingHours.isEmpty) {
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Booking hours are not set up for this venue.")),
           );
           return;
       }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VenueAvailabilityScreen(
             venueId: widget.venueId,
             venueName: _venueData!['name'] as String? ?? 'Venue',
             operatingHours: operatingHours,
             slotDurationMinutes: slotDuration,
           ),
         ),
       );
   }


  @override
  Widget build(BuildContext context) {
     String appBarTitle = 'Loading...';
     final bool canShowContent = !_isLoadingDetails && _venueData != null;

     if (canShowContent) {
       appBarTitle = _venueData!['name'] as String? ?? 'Venue Details';
     } else if (_errorMessage != null && _venueData == null) {
       appBarTitle = 'Error Loading Venue';
     }

     final bool showBookButton = canShowContent && (_venueData!['bookingEnabled'] as bool? ?? false);

     return Scaffold(
       appBar: AppBar(
         title: Text(appBarTitle, overflow: TextOverflow.ellipsis),
         actions: [
           if (canShowContent)
             IconButton(
               icon: const Icon(Icons.share_outlined),
               tooltip: 'Share Venue',
               onPressed: _shareVenue,
             ),
           if (canShowContent && _authService.getCurrentUser() != null)
             IconButton(
               icon: _isLoadingFavorite
                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                   : Icon(
                       _isFavorite ? Icons.favorite : Icons.favorite_border,
                       color: _isFavorite ? Colors.redAccent[100] : null,
                       semanticLabel: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                     ),
               tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
               onPressed: _toggleFavorite,
             ),
         ],
       ),
       body: RefreshIndicator(
           onRefresh: _fetchAllDetails,
           child: _buildBody(canShowContent),
        ),
        floatingActionButton: showBookButton
            ? FloatingActionButton.extended(
                onPressed: _navigateToBookingScreen,
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Check Availability & Book'),
                tooltip: 'Check Availability & Book',
               )
            : null,
       floatingActionButtonLocation: showBookButton ? FloatingActionButtonLocation.centerFloat : FloatingActionButtonLocation.endFloat,
     );
   }

  Widget _buildBody(bool canShowContent) {
     if (_isLoadingDetails && _venueData == null) {
       return const Center(child: CircularProgressIndicator());
     }
     if (_errorMessage != null && _venueData == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                   ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                      onPressed: _fetchAllDetails,
                   ),
                ],
             ),
           ),
        );
      }
     if (!canShowContent || _venueData == null) {
       return const Center(child: Text('Venue data not available.'));
     }

     final String name = _venueData!['name'] as String? ?? 'Unnamed Venue';
     final String description = _venueData!['description'] as String? ?? 'No description provided.';
     final String address = _venueData!['address'] as String? ?? 'Address not available';
     final String city = _venueData!['city'] as String? ?? 'Unknown City';
     final String country = _venueData!['country'] as String? ?? 'Unknown Country';
     final dynamic sportRaw = _venueData!['sportType'];
     final String? imageUrl = _venueData!['imageUrl'] as String?;
     final GeoPoint? geoPoint = _venueData!['location'] as GeoPoint?;
     final String? phoneNumber = _venueData!['phoneNumber'] as String?;
     final String? website = _venueData!['website'] as String?;
     final Map<String, dynamic>? operatingHoursMap = _venueData!['operatingHours'] as Map<String, dynamic>?;
     final List<String> facilities = (_venueData!['facilities'] as List<dynamic>?)
             ?.cast<String>()
             .where((f) => f.isNotEmpty)
             .toList() ?? [];
     final String? googleMapsUrl = _venueData!['googleMapsUrl'] as String?;


     String sport = 'Various Sports';
     if (sportRaw is String && sportRaw.isNotEmpty) {
         sport = sportRaw;
     } else if (sportRaw is List && sportRaw.isNotEmpty) {
         sport = sportRaw.whereType<String>().where((s) => s.isNotEmpty).join(', ');
         if (sport.isEmpty) sport = 'Various Sports';
      }
     final String fullAddress = [address, city, country].where((s) => s.isNotEmpty).join(', ');

    // --- MODIFIED: Operating Hours Display Logic ---
    String formatDayHours(Map<String, dynamic>? dayHours, String dayPrefix) {
      if (dayHours != null) {
        final String start = dayHours['start'] as String? ?? '';
        final String end = dayHours['end'] as String? ?? '';
        if (start.isNotEmpty && end.isNotEmpty) {
          return '$dayPrefix: $start - $end';
        }
      }
      return '$dayPrefix: N/A';
    }

    List<String> hoursParts = [];
    if (operatingHoursMap != null) {
      hoursParts.add(formatDayHours(operatingHoursMap['weekday'] as Map<String, dynamic>?, 'Mon-Fri'));
      hoursParts.add(formatDayHours(operatingHoursMap['saturday'] as Map<String, dynamic>?, 'Sat'));
      hoursParts.add(formatDayHours(operatingHoursMap['sunday'] as Map<String, dynamic>?, 'Sun'));
    }
    final String openingHoursDisplay = hoursParts.isNotEmpty ? hoursParts.join(', ') : "Not specified";
    // --- END MODIFIED: Operating Hours Display Logic ---

     return SingleChildScrollView(
       padding: const EdgeInsets.only(bottom: 90),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           if (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
             GestureDetector(
               onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) {
                   return FullScreenImageViewer(imageUrl: imageUrl, heroTag: 'venue_image_${widget.venueId}');
                 }));
               },
               child: Hero(
                 tag: 'venue_image_${widget.venueId}',
                 child: Image.network(
                   imageUrl,
                   height: 250, // Keep as is for banner consistency
                   width: double.infinity,
                   fit: BoxFit.cover,
                   // --- MODIFIED: Image Quality Settings ---
                   filterQuality: FilterQuality.medium, // Improved filter quality
                   cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(), // Hint for better cache resolution width
                   cacheHeight: (250 * MediaQuery.of(context).devicePixelRatio).round(), // Hint for better cache resolution height (250 is the display height)
                   // --- END MODIFIED ---
                   errorBuilder: (context, error, stackTrace) => Container(
                       height: 250, color: Colors.grey[200],
                       child: const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey))),
                   loadingBuilder: (context, child, loadingProgress) {
                     if (loadingProgress == null) return child;
                     return Container(
                         height: 250, color: Colors.grey[100],
                         child: Center(child: CircularProgressIndicator(
                                 strokeWidth: 2,
                                 value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null
                             )));
                     },
                 ),
               ),
             )
           else
             Container(
                 height: 250,
                 color: Theme.of(context).primaryColor.withOpacity(0.1),
                 child: Center(child: Icon(Icons.sports_rounded, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.6)))),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 16.0),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                     Row(
                       children: [
                          if (_averageRating > 0)
                           IgnorePointer(
                             child: RatingBar.builder(
                                initialRating: _averageRating,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: 22.0,
                                itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                onRatingUpdate: (rating) {},
                              ),
                           )
                         else if (!_isLoadingReviews)
                            const Text("No reviews yet", style: TextStyle(color: Colors.grey)),
                          if (_averageRating > 0)
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: Text(
                               '${_averageRating.toStringAsFixed(1)} ($_reviewCount review${_reviewCount != 1 ? 's' : ''})',
                               style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                             ),
                           ),
                         if (_isLoadingReviews && _reviewCount == 0)
                           const Padding(
                             padding: EdgeInsets.only(left: 8.0),
                             child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
                           ),
                       ],
                     ),
                    const SizedBox(height: 12),
                     _buildInfoRow(context, Icons.location_on_outlined, fullAddress),
                     _buildInfoRow(context, Icons.fitness_center, sport, iconColor: Colors.deepPurple[300]),
                     if (phoneNumber != null && phoneNumber.isNotEmpty)
                        _buildInfoRow(context, Icons.phone_outlined, phoneNumber, onTap: () => _launchUrl('tel:$phoneNumber')),
                     if (website != null && website.isNotEmpty)
                         _buildInfoRow(context, Icons.language_outlined, website, onTap: () => _launchUrl(website)),
                    _buildInfoRow(context, Icons.access_time_outlined, openingHoursDisplay), // Using the new combined display string


                    Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                     Text(
                        description.isEmpty ? 'No description available.' : description,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                       ),
                    if (facilities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Facilities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                         Wrap(
                           spacing: 8.0,
                           runSpacing: 4.0,
                           children: facilities.map((facility) => Chip(
                                  label: Text(facility),
                                  avatar: _getFacilityIcon(facility),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: const TextStyle(fontSize: 13),
                               )).toList(),
                          )
                      ]
                  ],
              ),
           ),


        const Divider(height: 30, thickness: 1, indent: 16, endIndent: 16),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 4),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                  Flexible(
                    child: Text(
                       'Reviews ($_reviewCount)',
                       style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                   ),
                   if (_authService.getCurrentUser() != null)
                      TextButton.icon(
                         onPressed: _showAddReviewDialog,
                         icon: const Icon(Icons.edit_note_outlined, size: 18),
                         label: const Text("Write"),
                         style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                           visualDensity: VisualDensity.compact,
                         ),
                       ),
                ],
             ),
         ),
        _buildReviewsList(),


          const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
           Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Location on Map', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
           ),
           const SizedBox(height: 1), 
           if (googleMapsUrl != null && googleMapsUrl.isNotEmpty && Uri.tryParse(googleMapsUrl)?.isAbsolute == true)
             Padding(
               padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 10.0), // Symmetric padding is fine
               child: Center( // Button already centered, Center widget is okay.
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.open_in_new_outlined, size: 18),
                   label: const Text('Open in Google Maps'),
                   onPressed: () => _launchUrl(googleMapsUrl),
                   style: OutlinedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                   ),
                 ),
               ),
             ),
           const SizedBox(height: 20),
          ],
       ),
     );
   }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {Color? iconColor, VoidCallback? onTap}) {
      final color = iconColor ?? Colors.grey[700];
      final style = TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.3);
      Widget content = Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Padding(
               padding: const EdgeInsets.only(top: 2.0, right: 10.0),
               child: Icon(icon, size: 20, color: color),
             ),
             Expanded(child: Text(text, style: style)),
          ],
        );
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6.0),
       child: onTap != null
           ? InkWell(
               onTap: onTap,
               borderRadius: BorderRadius.circular(4),
               child: Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: content))
           : content,
      );
   }

  Widget _buildReviewsList() {
      if (_isLoadingReviews) {
         return const Padding(padding: EdgeInsets.symmetric(vertical: 30.0), child: Center(child: Text("Loading reviews...", style: TextStyle(color: Colors.grey))));
      }
      if (_reviews.isEmpty) {
         return const Padding(
           padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
            child: Center(child: Text("Be the first to write a review!", style: TextStyle(color: Colors.grey, fontSize: 16))),
          );
       }
      return ListView.separated(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
         itemCount: _reviews.length,
         itemBuilder: (context, index) {
           return ReviewListItem(reviewData: _reviews[index]);
         },
         separatorBuilder: (context, index) => const Divider(height: 1),
       );
   }

  Widget? _getFacilityIcon(String facilityName) {
     final Map<String, IconData> facilityIcons = {
       'parking': Icons.local_parking,
       'car parking': Icons.local_parking,
       'wifi': Icons.wifi,
       'wi-fi': Icons.wifi,
       'showers': Icons.shower,
       'lockers': Icons.lock_outline,
       'equipment rental': Icons.build_outlined,
       'rental': Icons.build_outlined,
       'first aid': Icons.medical_services_outlined,
       'refreshments': Icons.fastfood_outlined,
       'cafe': Icons.local_cafe_outlined,
       'food': Icons.restaurant_outlined,
       'changing rooms': Icons.checkroom_outlined,
       'changing room': Icons.checkroom_outlined,
       'washroom': Icons.wc_outlined,
       'restroom': Icons.wc_outlined,
       'toilets': Icons.wc_outlined,
       'wheelchair accessible': Icons.accessible_forward,
     };

     String lowerCaseFacility = facilityName.toLowerCase().trim();
     IconData? iconData = facilityIcons[lowerCaseFacility];

     if (iconData != null) {
         return Icon(iconData, size: 16, color: Colors.grey[700]);
     }
     return null;
   }
}