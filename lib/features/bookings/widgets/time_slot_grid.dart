import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TimeSlotStatus { available, booked, selected, past }

class TimeSlotGrid extends StatelessWidget {
  final List<DateTime> potentialSlots;
  final List<Map<String, dynamic>> existingBookings;
  final Function(DateTime selectedSlot) onSlotSelected;
  final List<DateTime> currentlySelectedSlots;

  const TimeSlotGrid({
    super.key,
    required this.potentialSlots,
    required this.existingBookings,
    required this.onSlotSelected,
    this.currentlySelectedSlots = const [],
  });

  // --- MODIFIED FUNCTION ---
  /// Checks if a given potential slot time falls within any existing, non-cancelled booking.
  bool isSlotBooked(DateTime potentialSlotTime) {
    for (var booking in existingBookings) {
      final bookingStart = (booking['bookingStartTime'] as Timestamp?)?.toDate();
      final bookingEnd = (booking['bookingEndTime'] as Timestamp?)?.toDate();
      final status = booking['status'] as String?;

      // Consider a slot booked if the booking is pending or confirmed
      bool isBookingActive = status == 'pending' || status == 'confirmed';

      if (isBookingActive && bookingStart != null && bookingEnd != null) {
        // Check if the potential slot's start time is within the booking range.
        // It's booked if:
        // potentialSlotTime >= bookingStart AND potentialSlotTime < bookingEnd
        // (A slot starting exactly at bookingEnd is considered available)
        if ((potentialSlotTime.isAtSameMomentAs(bookingStart) || potentialSlotTime.isAfter(bookingStart)) &&
            potentialSlotTime.isBefore(bookingEnd)) {
          // This potential slot falls within an active booking's time range.
          return true;
        }
      }
    }
    // If no active booking range contains this slot time, it's not booked.
    return false;
  }
  // --- END OF MODIFIED FUNCTION ---


  TimeSlotStatus getSlotStatus(DateTime slotTime) {
    // Check if the slot end time is in the past (more robust than just start time)
    // Assuming slotDurationMinutes is needed here - let's estimate or pass it if available.
    // For simplicity, we'll stick to the original check for now, but ideally,
    // you'd compare slotTime + slotDuration with DateTime.now().
    if (slotTime.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
       return TimeSlotStatus.past;
    }
    if (currentlySelectedSlots.any((selected) => selected.isAtSameMomentAs(slotTime))) {
      return TimeSlotStatus.selected;
    } else if (isSlotBooked(slotTime)) { // This now uses the updated logic
      return TimeSlotStatus.booked;
    } else {
      return TimeSlotStatus.available;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (potentialSlots.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No available slots found for this date.")));
    }

    final timeFormat = DateFormat.jm();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        const double minButtonWidth = 70.0;
        const double maxButtonWidth = 110.0;
        const double buttonHeight = 40.0;
        const double buttonSpacing = 8.0;
        const int maxItemsPerRow = 6;

        int itemsPerRow = (availableWidth + buttonSpacing) ~/ (minButtonWidth + buttonSpacing);
        if (itemsPerRow == 0) itemsPerRow = 1; // Ensure at least one item fits
        itemsPerRow = itemsPerRow.clamp(1, maxItemsPerRow); // Clamp to maxItemsPerRow

        double calculatedButtonWidth = (availableWidth - (itemsPerRow - 1) * buttonSpacing) / itemsPerRow;
        calculatedButtonWidth = calculatedButtonWidth.clamp(minButtonWidth, maxButtonWidth);

        return Wrap(
          spacing: buttonSpacing,
          runSpacing: buttonSpacing,
          alignment: WrapAlignment.center,
          children: potentialSlots.map((slotTime) {
            final status = getSlotStatus(slotTime);
            bool canSelect = status == TimeSlotStatus.available || status == TimeSlotStatus.selected;

            return SizedBox(
              width: calculatedButtonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: canSelect
                    ? () => onSlotSelected(slotTime)
                    : null, // Button is disabled if booked, past, or selection not allowed
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == TimeSlotStatus.available
                      ? Theme.of(context).primaryColorLight.withOpacity(0.7)
                      : status == TimeSlotStatus.selected
                          ? Theme.of(context).primaryColor
                          : status == TimeSlotStatus.past
                              ? Colors.grey[500] // Past slots
                              : Colors.grey[350], // Booked slots
                  foregroundColor: status == TimeSlotStatus.selected
                      ? Colors.white
                      : status == TimeSlotStatus.available
                          ? Theme.of(context).primaryColorDark
                          : status == TimeSlotStatus.past
                              ? Colors.white70 // Past text color
                              : Colors.grey[600], // Booked text color
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: status == TimeSlotStatus.selected ? 4 : 1,
                  // Ensure booked slots look distinctly disabled
                  disabledForegroundColor: Colors.grey[600]?.withOpacity(0.8),
                  disabledBackgroundColor: Colors.grey[350]?.withOpacity(0.8),
                ),
                child: Text(timeFormat.format(slotTime)),
              ),
            );
          }).toList(),
        );
      }
    );
  }
}