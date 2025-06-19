import 'package:flutter/material.dart';
import 'package:mm_associates/features/user/services/user_service.dart';
import 'package:mm_associates/features/home/screens/venue_detail_screen.dart'; // Reuse venue detail screen

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _favoriteVenues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final venues = await _userService.getFavoriteVenues();
      if (mounted) {
        setState(() {
          _favoriteVenues = venues;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Venues'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
     if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(onPressed: _loadFavorites, icon: const Icon(Icons.refresh), label: const Text("Try Again"))
               ],
           ),
         ),
       );
    }

    if (_favoriteVenues.isEmpty) {
      return Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.favorite_border, color: Colors.grey[400], size: 60),
               const SizedBox(height: 15),
               Text(
                 'You haven\'t favorited any venues yet.',
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 17, color: Colors.grey[600]),
               ),
                const SizedBox(height: 10),
               const Text( "Tap the heart icon on a venue to add it here.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center,)
             ],
           ),
         ),
       );
    }

    // Use ListView for favorites
    return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _favoriteVenues.length,
        itemBuilder: (context, index) {
          final venue = _favoriteVenues[index];
          return _buildFavoriteVenueTile(venue);
        },
      );
  }

  // Using ListTile for favorites screen for potentially longer text
   Widget _buildFavoriteVenueTile(Map<String, dynamic> venue) {
      final String name = venue['name'] as String? ?? 'Unnamed Venue';
      final dynamic sportRaw = venue['sportType'];
      String sport = (sportRaw is List) ? sportRaw.join(', ') : (sportRaw as String? ?? 'Various');
      final String city = venue['city'] as String? ?? '';
      final String address = venue['address'] as String? ?? 'No address';
      final String venueId = venue['id'] as String? ?? '';
      final String? imageUrl = venue['imageUrl'] as String?;
       // Assuming averageRating and reviewCount might be on the venue data now
      final double averageRating = (venue['averageRating'] as num?)?.toDouble() ?? 0.0;
      final int reviewCount = (venue['reviewCount'] as num?)?.toInt() ?? 0;


       return Card( // Wrap ListTile in Card for better separation
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: SizedBox( // Control size of the leading image
                 width: 60,
                 height: 60,
                 child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
                       ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: Icon(Icons.sports_rounded, color: Colors.grey[400])),
                         )
                       : Container(color: Colors.grey[200], child: Icon(Icons.sports_rounded, color: Colors.grey[400])),
                  ),
               ),
               title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
               subtitle: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const SizedBox(height: 4),
                      Text("$sport - $address, $city", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                       if (reviewCount > 0) ...[
                         const SizedBox(height: 4),
                         Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Text("($reviewCount reviews)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                             ],
                           ),
                       ],
                    ]
                  ),
               trailing: const Icon(Icons.chevron_right, color: Colors.grey),
               onTap: () {
                 Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => VenueDetailScreen(
                          venueId: venueId,
                          initialVenueData: venue,
                          heroTagContext: 'favorite_list',
                        ),
                      ),
                   ).then((_) {
                        // Refresh favorites list if a venue was removed from favorites on detail screen
                        // A more robust way would use Streams or state management
                         _loadFavorites();
                   });
                },
            ),
       );
    }
}