import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';
import 'package:mm_associates/features/home/screens/venue_detail_screen.dart';
import 'package:intl/intl.dart'; 

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _userReviews = [];
  Map<String, String> _venueNames = {}; // Cache for venue names {venueId: venueName}
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getCurrentUser()?.uid;
    if (_userId != null) {
      _loadUserReviews();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "You need to be logged in to see your reviews.";
      });
    }
  }

  Future<void> _loadUserReviews() async {
    if (!mounted || _userId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _userReviews = []; // Clear previous reviews
      _venueNames = {}; // Clear venue name cache
    });

    try {
      final reviews = await _firestoreService.getReviewsByUser(_userId!);

      if (mounted) {
        // Now fetch venue names for the fetched reviews
        await _fetchVenueNamesForReviews(reviews);

        setState(() {
          _userReviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
  }

  // Helper to fetch venue names efficiently (avoids N+1 reads if possible)
  Future<void> _fetchVenueNamesForReviews(List<Map<String, dynamic>> reviews) async {
     if (!mounted || reviews.isEmpty) return;

     // Get unique venue IDs from the reviews
     final Set<String> venueIds = reviews.map((r) => r['venueId'] as String?).whereType<String>().toSet();

     if (venueIds.isEmpty) return;

      // In a real-world scenario with potentially many reviews, consider batch fetching
      // For simplicity here, fetch one by one but store in cache (_venueNames)
      for (String venueId in venueIds) {
          if (_venueNames.containsKey(venueId)) continue; // Skip if already fetched

          try {
              final venueData = await _firestoreService.getVenueDetails(venueId);
              if (mounted) {
                _venueNames[venueId] = venueData?['name'] as String? ?? 'Unknown Venue';
              }
          } catch (e) {
              debugPrint("Could not fetch venue name for $venueId: $e");
               if (mounted) {
                 _venueNames[venueId] = 'Venue Error'; // Indicate error fetching name
               }
          }
      }
  }

  Future<void> _confirmAndDeleteReview(String venueId, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: const Text('Are you sure you want to permanently delete this review?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await _firestoreService.deleteReview(venueId, reviewId);

        // --- IMPORTANT: Trigger rating update for the venue ---
        // Call the client-side recalculation (less reliable) or rely on Cloud Function
        // Example: await _firestoreService.updateVenueRatingClientSide(venueId);
        // --------------------------------------------------------

         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Review deleted successfully.'), backgroundColor: Colors.green),
           );
            // Remove the review locally to update UI immediately
            setState(() {
              _userReviews.removeWhere((review) => review['id'] == reviewId && review['venueId'] == venueId);
            });
         }

      } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Failed to delete review: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
             );
          }
      }
    }
  }

  void _navigateToVenue(String venueId) {
     Navigator.push(
        context,
        MaterialPageRoute(
           // Pass only ID, let detail screen fetch fresh data including reviews
          builder: (context) => VenueDetailScreen(venueId: venueId,heroTagContext: 'my_reviews_list',),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light ? Colors.grey[100] : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Reviews'),
         elevation: 0,
         backgroundColor: theme.scaffoldBackgroundColor,
         foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserReviews,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
       return Center(
          child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, color: Colors.red, size: 50),
                   const SizedBox(height: 15),
                   Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 16), textAlign: TextAlign.center),
                   const SizedBox(height: 20),
                   ElevatedButton.icon(
                     icon: const Icon(Icons.refresh),
                     label: const Text("Try Again"),
                     onPressed: _loadUserReviews,
                    ),
                ],
             ),
          ),
       );
    }

    if (_userReviews.isEmpty) {
       return Center(
          child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.rate_review, color: Colors.grey[400], size: 60),
                   const SizedBox(height: 15),
                   Text(
                      'You haven\'t written any reviews yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                   Text( "Reviews you write will appear here.", style: TextStyle(color: Colors.grey[600]),)
                ],
             ),
          ),
       );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0), // Add padding around the list
      itemCount: _userReviews.length,
      itemBuilder: (context, index) {
        final review = _userReviews[index];
        final String venueId = review['venueId'] as String? ?? '';
        final String reviewId = review['id'] as String? ?? '';
        final String venueName = _venueNames[venueId] ?? 'Loading Venue...';

        // We need a slightly different list item structure here
        return _buildMyReviewCard(theme, review, venueName, venueId, reviewId);
      },
    );
  }


   // Specific Widget for displaying review in "My Reviews" list
  Widget _buildMyReviewCard(ThemeData theme, Map<String, dynamic> reviewData, String venueName, String venueId, String reviewId) {
     final double rating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;
     final String comment = reviewData['comment'] as String? ?? '';
     final Timestamp? timestamp = reviewData['createdAt'] as Timestamp?;
     final String dateString = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate()) // More precise date
        : 'Unknown date';


     return Card(
       margin: const EdgeInsets.only(bottom: 12.0), // Spacing between cards
       elevation: 1.5,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
       child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Venue Name (Clickable)
              InkWell(
                onTap: venueId.isNotEmpty ? () => _navigateToVenue(venueId) : null,
                child: Row(
                   children: [
                     Icon(Icons.sports_gymnastics, size: 18, color: theme.colorScheme.primary), // Or other relevant icon
                     const SizedBox(width: 8),
                     Expanded(
                        child: Text(
                           venueName,
                           style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                            overflow: TextOverflow.ellipsis,
                        ),
                      ),
                       if (venueId.isNotEmpty)
                          Icon(Icons.chevron_right, color: theme.colorScheme.secondary, size: 20),
                    ],
                ),
              ),
              const Divider(height: 16, thickness: 1),

              // Rating and Date
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     IgnorePointer( // Makes the rating bar non-interactive
                       child: RatingBar.builder(
                          initialRating: rating,
                          minRating: 1, direction: Axis.horizontal, allowHalfRating: false,
                          itemCount: 5, itemSize: 20.0,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 0.5),
                          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {}, // Required but unused
                       ),
                     ),
                      Text(dateString, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
               ),

               // Comment (if exists)
               if (comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(comment, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                ],

               // Delete Button aligned to the right
               Align(
                 alignment: Alignment.centerRight,
                 child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: IconButton(
                       icon: Icon(Icons.delete_outline, color: Colors.redAccent[100], size: 22),
                       tooltip: 'Delete Review',
                       onPressed: (venueId.isEmpty || reviewId.isEmpty) ? null : () => _confirmAndDeleteReview(venueId, reviewId),
                       // Visual density can make the tap target smaller/larger
                       // visualDensity: VisualDensity.compact,
                        // constraints: BoxConstraints(), // Remove default padding if needed
                        padding: EdgeInsets.zero, // Adjust padding if needed
                    ),
                 ),
               )
            ],
          ),
       ),
     );
   }
}