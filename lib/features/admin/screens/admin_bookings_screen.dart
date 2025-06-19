// lib/features/admin/screens/admin_bookings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_service.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _adminService.fetchBookingsForAdminVenues();
  }

  Future<void> _showUserDetailsDialog(BuildContext context, String userId) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _adminService.getUserDetails(userId),
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              content = const Text("Error loading user details.");
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              content = const Text("User not found.");
            } else {
              final userData = snapshot.data!.data();
              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${userData?['name'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Email: ${userData?['email'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Phone: ${userData?['phoneNumber'] ?? 'N/A'}'),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Booked By'),
              content: content,
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Bookings'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings found for your venues.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingInfoCard(
                bookingData: booking,
                onViewUserPressed: () {
                  _showUserDetailsDialog(context, booking['userId']);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingInfoCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final VoidCallback onViewUserPressed;

  const _BookingInfoCard({
    required this.bookingData,
    required this.onViewUserPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = (bookingData['bookingStartTime'] as Timestamp).toDate();
    final endTime = (bookingData['bookingEndTime'] as Timestamp).toDate();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bookingData['venueName'] ?? 'Venue Name N/A',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _BookingStatusChip(status: bookingData['status'] ?? 'unknown'),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'User Name',
              value: bookingData['userName'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: DateFormat.yMMMMd().format(startTime),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time_outlined,
              label: 'Slot',
              value: '${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View User Details'),
                onPressed: onViewUserPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(color: theme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _BookingStatusChip extends StatelessWidget {
  final String status;
  const _BookingStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        chipColor = Colors.green.shade100;
        label = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        chipColor = Colors.orange.shade100;
        label = 'Pending';
        icon = Icons.hourglass_empty_outlined;
        break;
      case 'cancelled_user':
      case 'cancelled_admin':
        chipColor = Colors.red.shade100;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey.shade300;
        label = 'Unknown';
        icon = Icons.help_outline;
    }
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white70,),
      backgroundColor: chipColor,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white70,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}