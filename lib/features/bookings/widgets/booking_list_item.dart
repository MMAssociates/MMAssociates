// lib/features/bookings/widgets/booking_list_item.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingListItem extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final VoidCallback? onCancel; // Callback to trigger cancellation

  const BookingListItem({
    super.key,
    required this.bookingData,
    this.onCancel,
  });

  // Helper to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade800;
      case 'rejected':
      case 'cancelled_user':
      case 'cancelled_venue':
        return Colors.red.shade700;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper to format status text nicely
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 'Confirmed';
      case 'pending': return 'Pending Confirmation';
      case 'rejected': return 'Rejected';
      case 'cancelled_user': return 'Cancelled by You';
      case 'cancelled_venue': return 'Cancelled by Venue';
      case 'completed': return 'Completed';
      default: return status; // Show raw status if unknown
    }
  }

  @override
  Widget build(BuildContext context) {
    final String venueName = bookingData['venueName'] as String? ?? 'Unknown Venue';
    final Timestamp? startTimestamp = bookingData['bookingStartTime'] as Timestamp?;
    final Timestamp? endTimestamp = bookingData['bookingEndTime'] as Timestamp?;
    final String status = (bookingData['status'] as String?)?.toLowerCase() ?? 'unknown';
    final String? notes = bookingData['notes'] as String?;
    final bool canCancel = onCancel != null && (status == 'pending' || status == 'confirmed');

    String dateTimeString = "Date/Time Unavailable";
    if (startTimestamp != null && endTimestamp != null) {
      final startTime = startTimestamp.toDate();
      final endTime = endTimestamp.toDate();
      // Example Format: Wed, Aug 23, 2023 | 9:00 AM - 10:00 AM
      dateTimeString =
          "${DateFormat('E, MMM d, yyyy').format(startTime)} | ${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}";
    }

    final Color statusColor = _getStatusColor(status);
    final String formattedStatus = _formatStatus(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Venue Name and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    venueName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formattedStatus,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date & Time Row
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateTimeString,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Notes if available
            if (notes != null && notes.isNotEmpty) ...[
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey[700]),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                        notes,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800], fontStyle: FontStyle.italic),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 12),
            ],

            // Cancel Button (Conditional)
            if (canCancel) ...[
               const Divider(height: 16),
              Align(
                 alignment: Alignment.centerRight,
                 child: TextButton.icon(
                   icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("Cancel Booking"),
                    onPressed: onCancel, // Trigger the callback passed from parent
                    style: TextButton.styleFrom(
                       foregroundColor: Colors.red.shade700,
                       // visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
               ),
            ]
          ],
        ),
      ),
    );
  }
}