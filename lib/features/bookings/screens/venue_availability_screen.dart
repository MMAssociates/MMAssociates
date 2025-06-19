import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mm_associates/features/bookings/services/booking_service.dart';
import 'package:mm_associates/features/bookings/widgets/time_slot_grid.dart';

enum TimePeriod { morning, afternoon, evening, all }

class VenueAvailabilityScreen extends StatefulWidget {
  final String venueId;
  final String venueName;
  final Map<String, dynamic>? operatingHours;
  final int slotDurationMinutes;

  const VenueAvailabilityScreen({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.operatingHours,
    required this.slotDurationMinutes,
  });

  @override
  State<VenueAvailabilityScreen> createState() => _VenueAvailabilityScreenState();
}

class _VenueAvailabilityScreenState extends State<VenueAvailabilityScreen> {
  final BookingService _bookingService = BookingService();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final TextEditingController _notesController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DateTime> _allPotentialSlotsForDay = [];
  List<Map<String, dynamic>> _existingBookings = [];
  List<DateTime> _selectedSlotTimes = [];

  bool _isLoadingSlots = false;
  String? _slotLoadingError;
  bool _isBookingLoading = false;
  String? _bookingError;

  final int _maxSelectableSlots = 10;
  TimePeriod _activeDisplayFilter = TimePeriod.all;

  static const int morningEndHour = 12;
  static const int afternoonEndHour = 17;
  static const double wideScreenBreakpoint = 700;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _setDefaultTimePeriodDisplayFilter(_selectedDay!);
    _loadSlotsForDate(_selectedDay!);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _setDefaultTimePeriodDisplayFilter(DateTime date) {
    TimePeriod defaultFilter;
    if (isSameDay(date, DateTime.now())) {
      final currentHour = DateTime.now().hour;
      if (currentHour < morningEndHour) {
        defaultFilter = TimePeriod.morning;
      } else if (currentHour < afternoonEndHour) {
        defaultFilter = TimePeriod.afternoon;
      } else {
        defaultFilter = TimePeriod.evening;
      }
    } else {
      defaultFilter = TimePeriod.all;
    }
    if(mounted){
      setState(() {
        _activeDisplayFilter = defaultFilter;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedSlotTimes.clear();
        _allPotentialSlotsForDay = [];
        _existingBookings = [];
        _slotLoadingError = null;
        _bookingError = null;
        _setDefaultTimePeriodDisplayFilter(selectedDay);
      });
      _loadSlotsForDate(selectedDay);
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true;
      _slotLoadingError = null;
      _bookingError = null;
    });

    try {
      final results = await Future.wait([
        Future.value(_bookingService.getPotentialSlots(date, widget.operatingHours, widget.slotDurationMinutes)),
        _bookingService.getBookingsForDate(widget.venueId, date),
      ]);

      if (!mounted) return;

      setState(() {
         _allPotentialSlotsForDay = results[0] as List<DateTime>;
         _existingBookings = results[1] as List<Map<String, dynamic>>;
         _isLoadingSlots = false;
       });

    } catch (e) {
        if (mounted) {
           debugPrint("Error loading slots/bookings: $e");
            setState(() {
               _slotLoadingError = e is Exception ? e.toString().replaceFirst("Exception: ", "") : "Failed to load availability.";
               _isLoadingSlots = false;
             });
        }
    }
  }

  List<DateTime> _getDisplayFilteredPotentialSlots() {
    if (_allPotentialSlotsForDay.isEmpty) {
      return [];
    }
    if (_activeDisplayFilter == TimePeriod.all) {
      return List.from(_allPotentialSlotsForDay);
    }
    return _allPotentialSlotsForDay.where((slot) {
      switch (_activeDisplayFilter) {
        case TimePeriod.morning:
          return slot.hour < morningEndHour;
        case TimePeriod.afternoon:
          return slot.hour >= morningEndHour && slot.hour < afternoonEndHour;
        case TimePeriod.evening:
          return slot.hour >= afternoonEndHour;
        case TimePeriod.all:
          return true;
      }
    }).toList();
  }

  void _onSlotSelectedFromGrid(DateTime tappedSlot) {
     setState(() {
        final isCurrentlySelected = _selectedSlotTimes.any((slot) => slot.isAtSameMomentAs(tappedSlot));

        if (isCurrentlySelected) {
          _selectedSlotTimes.removeWhere((slot) => slot.isAtSameMomentAs(tappedSlot));
        } else {
          if (_selectedSlotTimes.length < _maxSelectableSlots) {
            _selectedSlotTimes.add(tappedSlot);
            _selectedSlotTimes.sort((a, b) => a.compareTo(b));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("You can select up to $_maxSelectableSlots slots."), duration: const Duration(seconds: 2)),
            );
          }
        }
        _bookingError = null;
     });
  }

  List<List<DateTime>> _groupConsecutiveSlots(List<DateTime> slots) {
    if (slots.isEmpty) return [];
    slots.sort((a, b) => a.compareTo(b));

    List<List<DateTime>> groups = [];
    List<DateTime> currentGroup = [slots.first];

    for (int i = 1; i < slots.length; i++) {
      Duration difference = slots[i].difference(slots[i-1]);
      if (difference == Duration(minutes: widget.slotDurationMinutes)) {
        currentGroup.add(slots[i]);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [slots[i]];
      }
    }
    groups.add(List.from(currentGroup));
    return groups;
  }


  Future<void> _confirmAndCreateBooking() async {
     if (_selectedSlotTimes.isEmpty) return;

      setState(() { _isBookingLoading = true; _bookingError = null; });

      final String? notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
      int successfulRequests = 0;
      int totalRequestsAttempted = 0;
      List<String> failedRequestDetails = [];

      final List<List<DateTime>> slotGroups = _groupConsecutiveSlots(List.from(_selectedSlotTimes));
      totalRequestsAttempted = slotGroups.length;

      for (List<DateTime> group in slotGroups) {
        if (group.isEmpty) continue;

        DateTime groupStartTime = group.first;
        int groupDurationMinutes = group.length * widget.slotDurationMinutes;

        try {
           final newBookingRef = await _bookingService.createBookingRequest(
                venueId: widget.venueId,
                venueName: widget.venueName,
                startTime: groupStartTime,
                durationMinutes: groupDurationMinutes,
                notes: notes,
           );
           debugPrint("Booking request created with ID: ${newBookingRef.id} for block starting ${DateFormat.jm().format(groupStartTime)} duration ${groupDurationMinutes}m");
           successfulRequests++;
         } catch (e) {
            debugPrint("Error creating booking for block starting ${DateFormat.jm().format(groupStartTime)}: $e");
            failedRequestDetails.add("Block from ${DateFormat.jm().format(groupStartTime)}: ${e.toString().replaceFirst("Exception: ","")}");
         }
      }

      if (mounted) {
        setState(() { _isBookingLoading = false; });

        if (successfulRequests == totalRequestsAttempted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successfulRequests > 1 ? "$successfulRequests booking requests sent successfully!" : "Booking request sent successfully!"),
                backgroundColor: Colors.green
              ),
            );
            setState(() {
              _selectedSlotTimes.clear();
              _notesController.clear();
              _setDefaultTimePeriodDisplayFilter(_selectedDay!);
            });
            _loadSlotsForDate(_selectedDay!);
        } else if (successfulRequests > 0) {
            _bookingError = "Some booking requests failed. Successfully sent $successfulRequests of $totalRequestsAttempted.\nFailures:\n${failedRequestDetails.join('\n')}";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Successfully sent $successfulRequests booking request(s). Some failed."), backgroundColor: Colors.orange),
            );
            _loadSlotsForDate(_selectedDay!);
            setState(() {
              _selectedSlotTimes.clear();
              _setDefaultTimePeriodDisplayFilter(_selectedDay!);
            });
        } else {
            _bookingError = "Could not send booking request(s). Errors:\n${failedRequestDetails.join('\n')}";
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("All booking requests failed."), backgroundColor: Colors.red),
             );
        }
      }
   }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.venueName}'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > wideScreenBreakpoint;

          Widget calendarWidget = _buildCalendarCard(theme);

          Widget slotSelectionContent = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: isWideScreen ? 0 : 8.0,
                    bottom: 8.0,
                    left: 0.0,
                    right: 0.0),
                child: Text(
                  _selectedDay != null ? 'Available Slots for ${DateFormat.yMMMd().format(_selectedDay!)}' : 'Select a Date',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildTimePeriodFilterSegmentedButton(theme),
              const SizedBox(height: 12),
              _buildSlotsSection(),
            ],
          );

          Widget slotSelectionWidget = Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.5),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: slotSelectionContent,
          );


          List<Widget> mainContentChildren;

          if (isWideScreen) {
            mainContentChildren = [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: calendarWidget,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: const VerticalDivider(thickness: 1, width: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: slotSelectionWidget,
                  ),
                ],
              ),
            ];
          } else {
            mainContentChildren = [
              calendarWidget,
              const SizedBox(height: 16),
              slotSelectionWidget,
            ];
          }

          if (_selectedSlotTimes.isNotEmpty) {
            mainContentChildren.addAll([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Divider(color: Colors.grey[300])
              ),
              _buildBookingConfirmationSection(),
            ]);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: mainContentChildren,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.5),
        child: TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 90)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: _onDaySelected,
          onPageChanged: (focusedDay) {
           if(mounted) {
             setState(() {
                _focusedDay = focusedDay;
             });
           }
          },
          calendarBuilders: CalendarBuilders(
            headerTitleBuilder: (context, date) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    DateFormat.yMMMM().format(date),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: theme.primaryColorLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: theme.textTheme.bodySmall ?? const TextStyle(),
            weekendTextStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary) ?? TextStyle(color: theme.primaryColor),
            selectedTextStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary) ?? const TextStyle(color: Colors.white),
            todayTextStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary) ?? TextStyle(color: theme.primaryColor),
            tablePadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            cellMargin: const EdgeInsets.all(1.5),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurfaceVariant, size: 18),
            rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 18),
            headerPadding: const EdgeInsets.symmetric(vertical: 0.0),
            titleTextStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(),
          ),
          availableGestures: AvailableGestures.horizontalSwipe,
          rowHeight: 36,
          daysOfWeekHeight: 16,
        ),
      ),
    );
  }

  // Widget _buildTimePeriodFilterSegmentedButton(ThemeData theme) {
  //   const labelTextStyle = TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold);
  //   const iconSize = 16.0;

  //   // Helper to create the label with FittedBox
  //   Widget _buildSegmentLabel(String text) {
  //     return FittedBox(
  //       fit: BoxFit.scaleDown,
  //       child: Text(text, style: labelTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis,),
  //     );
  //   }

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.0),
  //     child: SegmentedButton<TimePeriod>(
  //       segments: <ButtonSegment<TimePeriod>>[
  //         ButtonSegment<TimePeriod>(
  //             value: TimePeriod.all,
  //             label: _buildSegmentLabel('All'),
  //             icon: const Icon(Icons.all_inclusive, size: iconSize)
  //         ),
  //         ButtonSegment<TimePeriod>(
  //             value: TimePeriod.morning,
  //             label: _buildSegmentLabel('Morning'),
  //             icon: const Icon(Icons.wb_sunny_outlined, size: iconSize)
  //         ),
  //         ButtonSegment<TimePeriod>(
  //             value: TimePeriod.afternoon,
  //             label: _buildSegmentLabel('Afternoon'), // This will now scale down if needed
  //             icon: const Icon(Icons.brightness_medium_outlined, size: iconSize)
  //         ),
  //         ButtonSegment<TimePeriod>(
  //             value: TimePeriod.evening,
  //             label: _buildSegmentLabel('Evening'),
  //             icon: const Icon(Icons.nightlight_round_outlined, size: iconSize)
  //         ),
  //       ],
  //       selected: <TimePeriod>{_activeDisplayFilter},
  //       onSelectionChanged: (Set<TimePeriod> newSelection) {
  //         if (newSelection.isNotEmpty && mounted) {
  //           setState(() {
  //             _activeDisplayFilter = newSelection.first;
  //             _bookingError = null;
  //           });
  //         }
  //       },
  //       style: SegmentedButton.styleFrom(
  //         backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
  //         foregroundColor: theme.colorScheme.onSurfaceVariant,
  //         selectedForegroundColor: theme.colorScheme.onPrimary,
  //         selectedBackgroundColor: theme.colorScheme.primary,
  //         // Use the textStyle here for defaults if needed, but explicit style in Text will override
  //         // For instance, if you removed fontWeight from labelTextStyle, you could set it here.
  //         // textStyle: theme.textTheme.labelMedium?.copyWith(fontSize: 14 /* or another base size */),
  //         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Adjusted padding slightly
  //         side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
  //         tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Keep this
  //       ),
  //       showSelectedIcon: false,
  //     ),
  //   );
  // }

  Widget _buildTimePeriodFilterSegmentedButton(ThemeData theme) {
    // Adjusted for more compact and consistent sizing
    const labelTextStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold); // Reduced base font size
    const iconSize = 15.0; // Slightly reduced icon size

    // Helper to create the label with FittedBox
    Widget _buildSegmentLabel(String text) {
      return FittedBox(
        fit: BoxFit.scaleDown, // Ensures text scales down to fit if needed
        child: Text(
          text,
          style: labelTextStyle, // Applies the consistent base text style
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // Fallback, though scaleDown should prevent this
        ),
      );
    }

    return Padding(
      // Keep parent padding as is, or adjust if the whole button needs to be closer to screen edges
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.0),
      child: SegmentedButton<TimePeriod>(
        segments: <ButtonSegment<TimePeriod>>[
          ButtonSegment<TimePeriod>(
              value: TimePeriod.all,
              label: _buildSegmentLabel('All'),
              icon: const Icon(Icons.all_inclusive, size: iconSize)),
          ButtonSegment<TimePeriod>(
              value: TimePeriod.morning,
              label: _buildSegmentLabel('Morning'),
              icon: const Icon(Icons.wb_sunny_outlined, size: iconSize)),
          ButtonSegment<TimePeriod>(
              value: TimePeriod.afternoon,
              label: _buildSegmentLabel('Afternoon'),
              icon: const Icon(Icons.brightness_medium_outlined, size: iconSize)),
          ButtonSegment<TimePeriod>(
              value: TimePeriod.evening,
              label: _buildSegmentLabel('Evening'),
              icon: const Icon(Icons.nightlight_round_outlined, size: iconSize)),
        ],
        selected: <TimePeriod>{_activeDisplayFilter},
        onSelectionChanged: (Set<TimePeriod> newSelection) {
          if (newSelection.isNotEmpty && mounted) {
            setState(() {
              _activeDisplayFilter = newSelection.first;
              _bookingError = null;
            });
          }
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
          foregroundColor: theme.colorScheme.onSurfaceVariant, // For unselected icon and text
          selectedForegroundColor: theme.colorScheme.onPrimary, // For selected icon and text
          selectedBackgroundColor: theme.colorScheme.primary,
          
          // Reduced internal padding for each segment to make them more compact
          // This will reduce space to the left/right of content and implicitly make icon and text closer
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 7.0), // Adjusted horizontal and vertical padding

          side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Important for allowing segments to be compact

          // You can also explicitly set a textStyle here. If done, it merges with
          // the style provided in the Text widget. This can be an alternative way to set base font size.
          // textStyle: const TextStyle(fontSize: 12.5), // Example
        ),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildSlotsSection() {
     if (_isLoadingSlots) {
       return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
     }
     if (_slotLoadingError != null) {
        return Center(
           child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                   const SizedBox(height: 10),
                   Text(_slotLoadingError!, style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center),
                   const SizedBox(height: 10),
                   ElevatedButton(onPressed: () => _loadSlotsForDate(_selectedDay!), child: const Text("Try Again"))
                ],
             ),
            ),
         );
     }

     final displayFilteredSlots = _getDisplayFilteredPotentialSlots();

     if (displayFilteredSlots.isEmpty && _allPotentialSlotsForDay.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
            child: Text(
              _activeDisplayFilter == TimePeriod.all ? "No slots available for this day." : "No slots for selected period.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
            ),
          ),
        );
     }
      if (displayFilteredSlots.isEmpty && _allPotentialSlotsForDay.isEmpty && !_isLoadingSlots) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
            child: Text(
              "No slots available for this day.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
            ),
          ),
        );
     }

      return TimeSlotGrid(
         potentialSlots: displayFilteredSlots,
         existingBookings: _existingBookings,
         onSlotSelected: _onSlotSelectedFromGrid,
         currentlySelectedSlots: _selectedSlotTimes,
      );
  }

   Widget _buildBookingConfirmationSection() {
     final timeFormat = DateFormat.jm();
     final dateFormat = DateFormat.yMMMd();

     final List<List<DateTime>> displayGroups = _groupConsecutiveSlots(List.from(_selectedSlotTimes));

      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
                 Text("Confirm Your Booking(s)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  Card(
                     elevation: 1,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                 Text("Venue: ${widget.venueName}", style: const TextStyle(fontWeight: FontWeight.w500)),
                                 const SizedBox(height: 8),
                                 Text("Date: ${dateFormat.format(_selectedDay!)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                                 const SizedBox(height: 8),
                                 Text("Selected Time Block(s):", style: const TextStyle(fontWeight: FontWeight.w500)),
                                 const SizedBox(height: 4),
                                 if (displayGroups.isNotEmpty)
                                   ListView.builder(
                                       shrinkWrap: true,
                                       physics: const NeverScrollableScrollPhysics(),
                                       itemCount: displayGroups.length,
                                       itemBuilder: (context, index) {
                                         final group = displayGroups[index];
                                         if (group.isEmpty) return const SizedBox.shrink();
                                         final blockStartTime = group.first;
                                         final blockEndTime = group.last.add(Duration(minutes: widget.slotDurationMinutes));
                                         final blockDurationMinutes = group.length * widget.slotDurationMinutes;

                                         String durationText;
                                         int hours = blockDurationMinutes ~/ 60;
                                         int minutes = blockDurationMinutes % 60;
                                         if (hours > 0 && minutes > 0) {
                                           durationText = "$hours hr $minutes min";
                                         } else if (hours > 0) {
                                           durationText = "$hours hr";
                                         } else {
                                           durationText = "$minutes min";
                                         }

                                         return Padding(
                                           padding: const EdgeInsets.symmetric(vertical: 3.0),
                                           child: Text(
                                             "• ${timeFormat.format(blockStartTime)} - ${timeFormat.format(blockEndTime)} ($durationText)",
                                           ),
                                         );
                                       },
                                     )
                                 else
                                     const Text("No slots selected."),
                               ],
                             ),
                       ),
                    ),
                 const SizedBox(height: 15),
                 TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                           labelText: 'Booking Notes (Optional)',
                            hintText: 'e.g., Request for specific court, any special needs...',
                           border: OutlineInputBorder(),
                           contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                     ),
                 const SizedBox(height: 15),
                 if (_bookingError != null)
                     Padding(
                         padding: const EdgeInsets.only(bottom: 10.0),
                         child: Text(
                           _bookingError!,
                           style: TextStyle(color: Theme.of(context).colorScheme.error),
                           textAlign: TextAlign.center,
                           overflow: TextOverflow.ellipsis,
                           maxLines: 5,
                         ),
                       ),
                 ElevatedButton.icon(
                      onPressed: _isBookingLoading ? null : _confirmAndCreateBooking,
                       icon: _isBookingLoading
                         ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                         : const Icon(Icons.check_circle_outline),
                       label: Text(_isBookingLoading ? 'Sending Request(s)...' : 'Send Booking Request(s)'),
                       style: ElevatedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 14),
                         ),
                    ),
              ],
            ),
        );
     }
}