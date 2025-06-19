import 'package:flutter/material.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';
import 'package:mm_associates/features/user/services/user_service.dart';
import 'package:mm_associates/features/home/screens/venue_detail_screen.dart'; // For navigation
import 'package:shimmer/shimmer.dart'; // For loading shimmer

class MyFavouritesScreen extends StatefulWidget {
  const MyFavouritesScreen({super.key});

  @override
  State<MyFavouritesScreen> createState() => _MyFavouritesScreenState();
}

class _MyFavouritesScreenState extends State<MyFavouritesScreen> {
  final UserService _userService = UserService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _favouriteVenues = [];
  bool _isLoading = true;
  String? _errorMessage;
  Stream<List<String>>? _favoritesStream;
  List<String> _currentFavoriteIds = [];

  @override
  void initState() {
    super.initState();
    _setupFavoritesListenerAndFetchDetails();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _setupFavoritesListenerAndFetchDetails() {
    _favoritesStream = _userService.getFavoriteVenueIdsStream();
    _favoritesStream?.listen((favoriteIds) {
      if (!mounted) return;
      // Check if the list of IDs has actually changed to avoid unnecessary refetches
      if (favoriteIds.toSet().difference(_currentFavoriteIds.toSet()).isNotEmpty ||
          _currentFavoriteIds.toSet().difference(favoriteIds.toSet()).isNotEmpty) {
        _currentFavoriteIds = List.from(favoriteIds); // Update current IDs
        _fetchFavouriteVenueDetails(favoriteIds);
      } else if (_favouriteVenues.isEmpty && favoriteIds.isNotEmpty && _isLoading) {
        // Initial load or empty list but favorites exist
        _currentFavoriteIds = List.from(favoriteIds);
        _fetchFavouriteVenueDetails(favoriteIds);
      } else if (favoriteIds.isEmpty) {
        // If all favorites are removed
        setStateIfMounted(() {
          _favouriteVenues = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error listening to favorites.";
          _favouriteVenues = [];
        });
      }
      debugPrint("Error in favorites stream: $error");
    });
  }


  Future<void> _fetchFavouriteVenueDetails(List<String> venueIds) async {
    if (!mounted) return;
    if (venueIds.isEmpty) {
      setStateIfMounted(() {
        _favouriteVenues = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Future<Map<String, dynamic>?>> futures = venueIds
          .map((id) => _firestoreService.getVenueDetails(id))
          .toList();

      final List<Map<String, dynamic>?> venueDetailsResults = await Future.wait(futures);
      
      if (!mounted) return;

      // Filter out nulls (if a venue was deleted but ID still in favorites)
      // and ensure correct type.
      final List<Map<String, dynamic>> validVenues = venueDetailsResults
          .where((details) => details != null)
          .cast<Map<String, dynamic>>()
          .toList();

      // Sort venues by name or any other preferred order
      validVenues.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));

      setStateIfMounted(() {
        _favouriteVenues = validVenues;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching favourite venue details: $e");
      if (mounted) {
        setStateIfMounted(() {
          _isLoading = false;
          _errorMessage = "Could not load your favourite venues.";
        });
      }
    }
  }

  void _navigateToVenueDetail(Map<String, dynamic> venue) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueDetailScreen(
          venueId: venue['id'] as String,
          initialVenueData: venue,
          heroTagContext: 'my_favourites',
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favourites'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerList();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 50),
              const SizedBox(height: 15),
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700], fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: () => _fetchFavouriteVenueDetails(_currentFavoriteIds), // Retry with current IDs
              ),
            ],
          ),
        ),
      );
    }

    if (_favouriteVenues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, color: Colors.grey[400], size: 60),
              const SizedBox(height: 15),
              Text(
                'No Favourites Yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the heart icon on venues to add them here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: _favouriteVenues.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final venue = _favouriteVenues[index];
        return _buildFavouriteVenueTile(venue);
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5, // Number of shimmer items
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 60, height: 60, color: Colors.white, margin: const EdgeInsets.only(right: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 16.0, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: MediaQuery.of(context).size.width * 0.5, height: 12.0, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavouriteVenueTile(Map<String, dynamic> venue) {
    final String name = venue['name'] as String? ?? 'Unnamed Venue';
    final String? imageUrl = venue['imageUrl'] as String?;
    final String city = venue['city'] as String? ?? 'N/A';
    final dynamic sportRaw = venue['sportType'];
    final String sport = (sportRaw is String) ? sportRaw : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');

    return ListTile(
      leading: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
          ? SizedBox(
              width: 60, height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
                ),
              ),
            )
          : Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.sports_soccer_outlined, color: Theme.of(context).primaryColor.withOpacity(0.7), size: 30),
            ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text("$sport - $city", maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => _navigateToVenueDetail(venue),
    );
  }
}