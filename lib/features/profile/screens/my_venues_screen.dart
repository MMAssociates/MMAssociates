import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';
import 'package:mm_associates/features/home/screens/venue_form.dart'; // For editing
import 'package:shimmer/shimmer.dart'; // For loading shimmer

class MyVenuesScreen extends StatefulWidget {
  const MyVenuesScreen({Key? key}) : super(key: key);

  @override
  _MyVenuesScreenState createState() => _MyVenuesScreenState();
}

class _MyVenuesScreenState extends State<MyVenuesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  List<Map<String, dynamic>> _myVenues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchMyVenues();
  }

  Future<void> _fetchMyVenues() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "You must be logged in to see your venues.";
      });
      return;
    }

    try {
      final venues = await _firestoreService.getVenuesByCreator(_currentUser!.uid);
      if (!mounted) return;
      setState(() {
        _myVenues = venues;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching admin's venues: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load your venues. Please try again.";
      });
    }
  }

  Future<void> _navigateToEditVenue(Map<String, dynamic> venueData) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddVenueFormScreen(
          venueIdToEdit: venueData['id'] as String,
          initialData: venueData,
        ),
      ),
    );
    if (result == true && mounted) {
      _fetchMyVenues(); // Refresh the list if a venue was updated
    }
  }

  Future<void> _confirmDeleteVenue(String venueId, String venueName) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the venue "$venueName"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleting "$venueName"...'), duration: const Duration(seconds: 2)),
      );
      try {
        await _firestoreService.deleteVenue(venueId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venue "$venueName" deleted successfully.'), backgroundColor: Colors.green),
        );
        _fetchMyVenues(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete venue: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Widget _buildShimmerLoadingList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6, // Number of shimmer items
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48.0,
                height: 48.0,
                color: Colors.white,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 8.0,
                      color: Colors.white,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.0),
                    ),
                    Container(
                      width: double.infinity,
                      height: 8.0,
                      color: Colors.white,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.0),
                    ),
                    Container(
                      width: 40.0,
                      height: 8.0,
                      color: Colors.white,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Venues'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyVenues,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return _buildShimmerLoadingList();
            }
            if (_errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 50),
                      const SizedBox(height: 10),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: _fetchMyVenues,
                      )
                    ],
                  ),
                ),
              );
            }
            if (_myVenues.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_photography_outlined, size: 60, color: Theme.of(context).hintColor),
                      const SizedBox(height: 16),
                      Text(
                        'You haven\'t added any venues yet.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Venues you create will appear here.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                       const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Add New Venue'),
                          onPressed: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (context) => const AddVenueFormScreen()),
                              );
                              if (result == true && mounted) {
                                _fetchMyVenues(); // Refresh if a venue was added
                              }
                          },
                        ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: _myVenues.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final venue = _myVenues[index];
                final String venueName = venue['name'] as String? ?? 'Unnamed Venue';
                final String venueCity = venue['city'] as String? ?? 'N/A';
                final bool isActive = venue['isActive'] as bool? ?? false;
                final String? imageUrl = venue['imageUrl'] as String?;

                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Icon(Icons.broken_image, color: Theme.of(context).hintColor),
                          loadingBuilder: (ctx, child, progress) => progress == null ? child : const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      : Icon(Icons.location_city, color: Theme.of(context).hintColor),
                  ),
                  title: Text(venueName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text("$venueCity - ${isActive ? 'Active' : 'Inactive'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                        tooltip: 'Edit Venue',
                        onPressed: () => _navigateToEditVenue(venue),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        tooltip: 'Delete Venue',
                        onPressed: () => _confirmDeleteVenue(venue['id'] as String, venueName),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToEditVenue(venue), // Also allow tapping tile to edit
                );
              },
            );
          },
        ),
      ),
    );
  }
}