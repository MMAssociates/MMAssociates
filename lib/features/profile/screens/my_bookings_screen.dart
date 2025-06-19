import 'package:flutter/material.dart';
// import 'package:mm_associates/features/user/services/user_service.dart'; // Assuming you have this
// import 'package:mm_associates/features/data/models/booking_model.dart'; // Assuming a Booking model
import 'package:shimmer/shimmer.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // final UserService _userService = UserService(); // Uncomment when ready
  List<Map<String, dynamic>> _bookings = []; // Or List<BookingModel>
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyBookings();
  }

  Future<void> _fetchMyBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with your actual data fetching logic
      // _bookings = await _userService.getUserBookings();
      // Simulate a delay and empty data for now
      await Future.delayed(const Duration(seconds: 1));
      // _bookings = []; // Example: Start with empty or mock data

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Could not load your bookings.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
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
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined, color: Colors.grey[400], size: 60),
              const SizedBox(height: 15),
              Text('No Bookings Yet!', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 8),
              const Text('Your active and past bookings will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        // TODO: Create a BookingListTile widget or build UI here
        return ListTile(
          title: Text(booking['venueName'] ?? 'Booking Details'), // Example field
          subtitle: Text('Date: ${booking['bookingDate'] ?? 'N/A'}'), // Example field
          // onTap: () { /* Navigate to booking detail screen if any */ },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder: (context, index) => ListTile(
          leading: Container(width: 40, height: 40, color: Colors.white),
          title: Container(height: 16, width: double.infinity, color: Colors.white),
          subtitle: Container(height: 12, width: MediaQuery.of(context).size.width * 0.5, color: Colors.white, margin: const EdgeInsets.only(top: 4)),
        ),
      ),
    );
  }
}