// lib/features/bookings/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:mm_associates/features/bookings/services/booking_service.dart';
import 'package:mm_associates/features/bookings/widgets/booking_list_item.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
  }

  Future<void> _loadMyBookings({bool showLoadingIndicator = true}) async {
    if (!mounted) return;
     if (showLoadingIndicator) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
     }

    try {
      final bookingsData = await _bookingService.getMyBookings();
       if (!mounted) return;
      setState(() {
        _bookings = bookingsData;
        _isLoading = false;
      });
    } catch (e) {
       if (!mounted) return;
       debugPrint("Error loading user bookings: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = e is Exception
            ? e.toString().replaceFirst("Exception: ", "")
            : "Failed to load bookings.";
      });
    }
  }

  // Method to handle cancellation from the list item
  Future<void> _cancelBooking(String bookingId) async {
     if (!mounted) return;

    // Optional: Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this booking request?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false), // Not confirmed
            ),
            TextButton(
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true), // Confirmed
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // User pressed No or dismissed

     // Show loading feedback on the item potentially, or just globally?
     // For now, just show a general snackbar after operation.

    try {
        await _bookingService.cancelUserBooking(bookingId);
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Booking cancelled successfully."), backgroundColor: Colors.orange),
              );
             // Refresh the list without full loading indicator
              _loadMyBookings(showLoadingIndicator: false);
              // Alternatively, update the specific item state locally for instant feedback
              // setState(() {
              //   final index = _bookings.indexWhere((b) => b['id'] == bookingId);
              //   if (index != -1) {
              //     _bookings[index]['status'] = 'cancelled_user';
              //   }
              // });
         }
     } catch (e) {
        if (mounted) {
             debugPrint("Error cancelling booking via UI: $e");
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Failed to cancel booking: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: Colors.redAccent),
            );
         }
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMyBookings(showLoadingIndicator: true), // Full refresh on pull
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
                   ElevatedButton.icon(
                      onPressed: () => _loadMyBookings(showLoadingIndicator: true),
                      icon: const Icon(Icons.refresh),
                       label: const Text("Try Again")
                   )
               ],
           ),
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
               Text(
                 'You have no bookings yet.',
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 17, color: Colors.grey[600]),
               ),
                const SizedBox(height: 10),
               const Text( "Find a venue and book your next session!", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center,)
             ],
           ),
         ),
       );
    }

    // Display the list of bookings
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding around the whole list
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
          final booking = _bookings[index];
           final String bookingId = booking['id'] as String? ?? '';

          return BookingListItem(
             bookingData: booking,
             onCancel: bookingId.isNotEmpty ? () => _cancelBooking(bookingId) : null, // Pass cancel callback
          );
       },
     );
  }
}