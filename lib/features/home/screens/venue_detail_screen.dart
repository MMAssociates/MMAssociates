// features/home/screens/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mm_associates/features/bookings/screens/venue_availability_screen.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';
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
  // <<< MODIFIED: Added heroTagContext to receive the section identifier >>>
  final String heroTagContext; 

  const VenueDetailScreen({
    super.key,
    required this.venueId,
    this.initialVenueData,
    required this.heroTagContext, // <<< MODIFIED: Made it required
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  // ... All the state variables and methods are exactly the same as before ...
  // ... The only change is in the build method where the Hero tag is constructed ...
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
    final String description =
        _venueData!['description'] as String? ?? 'No description provided.';
    final String address = _venueData!['address'] as String? ?? 'Address not available';
    final String city = _venueData!['city'] as String? ?? 'Unknown City';
    final String country = _venueData!['country'] as String? ?? 'Unknown Country';
    final dynamic sportRaw = _venueData!['sportType'];
    final String? imageUrl = _venueData!['imageUrl'] as String?;
    final String? phoneNumber = _venueData!['phoneNumber'] as String?;
    final String? website = _venueData!['website'] as String?;
    final Map<String, dynamic>? operatingHoursMap =
        _venueData!['operatingHours'] as Map<String, dynamic>?;
    final List<String> facilities = (_venueData!['facilities'] as List<dynamic>?)
            ?.cast<String>()
            .where((f) => f.isNotEmpty)
            .toList() ??
        [];
    final String? googleMapsUrl = _venueData!['googleMapsUrl'] as String?;

    String sport = 'Various Sports';
    if (sportRaw is String && sportRaw.isNotEmpty) {
      sport = sportRaw;
    } else if (sportRaw is List && sportRaw.isNotEmpty) {
      sport = sportRaw.whereType<String>().where((s) => s.isNotEmpty).join(', ');
      if (sport.isEmpty) sport = 'Various Sports';
    }
    final String fullAddress = [address, city, country].where((s) => s.isNotEmpty).join(', ');
    
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
      hoursParts.add(
          formatDayHours(operatingHoursMap['weekday'] as Map<String, dynamic>?, 'Mon-Fri'));
      hoursParts.add(formatDayHours(
          operatingHoursMap['saturday'] as Map<String, dynamic>?, 'Sat'));
      hoursParts.add(formatDayHours(
          operatingHoursMap['sunday'] as Map<String, dynamic>?, 'Sun'));
    }
    final String openingHoursDisplay =
        hoursParts.isNotEmpty ? hoursParts.join(', ') : "Not specified";

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
            GestureDetector(
              onTap: () {
                // <<< MODIFIED: Create unique hero tag for full screen view >>>
                final heroTag = '${widget.heroTagContext}_venue_image_${widget.venueId}';
                Navigator.push(context, MaterialPageRoute(builder: (_) {
                  return FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag);
                }));
              },
              child: Hero(
                // <<< MODIFIED: Construct Hero tag with the context >>>
                tag: '${widget.heroTagContext}_venue_image_${widget.venueId}',
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(),
                  cacheHeight: (250 * MediaQuery.of(context).devicePixelRatio).round(),
                  errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 50, color: Colors.grey))),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                        height: 250,
                        color: Colors.grey[100],
                        child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null)));
                  },
                ),
              ),
            )
          else
            Container(
                height: 250,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Center(
                    child: Icon(Icons.sports_rounded,
                        size: 80,
                        color:
                            Theme.of(context).primaryColor.withOpacity(0.6)))),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
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
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 0.0),
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {},
                        ),
                      )
                    else if (!_isLoadingReviews)
                      const Text("No reviews yet",
                          style: TextStyle(color: Colors.grey)),
                    if (_averageRating > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '${_averageRating.toStringAsFixed(1)} ($_reviewCount review${_reviewCount != 1 ? 's' : ''})',
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[700]),
                        ),
                      ),
                    if (_isLoadingReviews && _reviewCount == 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.location_on_outlined, fullAddress),
                _buildInfoRow(context, Icons.fitness_center, sport,
                    iconColor: Colors.deepPurple[300]),
                if (phoneNumber != null && phoneNumber.isNotEmpty)
                  _buildInfoRow(context, Icons.phone_outlined, phoneNumber,
                      onTap: () => _launchUrl('tel:$phoneNumber')),
                if (website != null && website.isNotEmpty)
                  _buildInfoRow(context, Icons.language_outlined, website,
                      onTap: () => _launchUrl(website)),
                _buildInfoRow(context, Icons.access_time_outlined,
                    openingHoursDisplay),
                Text('Description',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  description.isEmpty
                      ? 'No description available.'
                      : description,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                if (facilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Facilities',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: facilities
                        .map((facility) => Chip(
                              label: Text(facility),
                              avatar: _getFacilityIcon(facility),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              labelStyle: const TextStyle(fontSize: 13),
                            ))
                        .toList(),
                  )
                ]
              ],
            ),
          ),
          const Divider(height: 30, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Reviews ($_reviewCount)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_authService.getCurrentUser() != null)
                  TextButton.icon(
                    onPressed: _showAddReviewDialog,
                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                    label: const Text("Write"),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
            child: Text('Location on Map',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 5),
          if (googleMapsUrl != null &&
              googleMapsUrl.isNotEmpty &&
              Uri.tryParse(googleMapsUrl)?.isAbsolute == true)
            Padding(
              padding:
                  const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0, bottom: 10.0),
              child: Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: const Text('Open in Google Maps'),
                  onPressed: () => _launchUrl(googleMapsUrl),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text,
      {Color? iconColor, VoidCallback? onTap}) {
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
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: content))
          : content,
    );
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30.0),
          child: Center(
              child: Text("Loading reviews...",
                  style: TextStyle(color: Colors.grey))));
    }
    if (_reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
        child: Center(
            child: Text("Be the first to write a review!",
                style: TextStyle(color: Colors.grey, fontSize: 16))),
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