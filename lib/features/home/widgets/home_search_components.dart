// features/home/widgets/home_search_components.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:mm_associates/features/data/services/firestore_service.dart';
import 'package:mm_associates/features/home/screens/venue_detail_screen.dart';

// =========================================================================
// UNCHANGED: WebSearchBar - This component doesn't navigate directly, it
// just calls back to the HomeScreen, which handles the navigation correctly.
// Therefore, no changes are needed here.
// =========================================================================
class WebSearchBar extends StatefulWidget {
  final String initialValue;
  final String? cityFilter;
  final FirestoreService firestoreService;
  final Function(String query) onSearchSubmitted;
  final Function(String suggestionName) onSuggestionSelected;
  final VoidCallback onClear;

  const WebSearchBar({
    super.key,
    required this.initialValue,
    required this.cityFilter,
    required this.firestoreService,
    required this.onSearchSubmitted,
    required this.onSuggestionSelected,
    required this.onClear,
  });

  @override
  State<WebSearchBar> createState() => _WebSearchBarState();
}

class _WebSearchBarState extends State<WebSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  bool _isLoadingSuggestions = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant WebSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _controller.text.trim();
      if (query.isNotEmpty && _focusNode.hasFocus) {
        _fetchSuggestions(query);
      } else if (mounted) {
        setState(() {
          _suggestions = [];
        });
        _updateOverlay();
      }
    });
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
      final query = _controller.text.trim();
      if (query.isNotEmpty && _suggestions.isEmpty) {
        _fetchSuggestions(query);
      }
    } else {
      _hideOverlay();
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isLoadingSuggestions = true);
    _updateOverlay();

    try {
      final suggestions = await widget.firestoreService.getVenues(
        searchQuery: query,
        cityFilter: widget.cityFilter,
        limit: 500,
        forSuggestions: true,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      debugPrint("Error fetching web search suggestions: $e");
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
    } finally {
      _updateOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context, rootOverlay: true)?.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || _focusNode.hasFocus) return;
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final theme = Theme.of(context);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: _buildSuggestionBody(context, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionBody(BuildContext overlayContext, ThemeData theme) {
    if (_isLoadingSuggestions) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _controller.text.isEmpty && _focusNode.hasFocus ? "Start typing to search..." : "No suggestions found.",
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final venue = _suggestions[index];
        final String name = venue['name'] as String? ?? 'N/A';
        final String city = venue['city'] as String? ?? '';
        final String venueId = venue['id'] as String? ?? '';
        
        return ListTile(
          title: Text(name, style: const TextStyle(fontSize: 14)),
          subtitle: city.isNotEmpty ? Text(city, style: const TextStyle(fontSize: 12)) : null,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          onTap: () async {
            _focusNode.unfocus();
            await Navigator.of(overlayContext).push(MaterialPageRoute(
                builder: (context) => VenueDetailScreen(
                    venueId: venueId,
                    initialVenueData: venue,
                    // Pass a unique context for hero tags
                    heroTagContext: 'search_web_suggestion',
                ),
            ));
            
            if (mounted) {
              _controller.clear();
              widget.onClear();
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.remove();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: theme.textTheme.bodyMedium,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search venues by name, sport, or city...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              prefixIcon: Icon(Icons.search_outlined, color: theme.hintColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(left: 0, right: 10, top: 11, bottom: 11),
              isDense: true,
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 20, color: theme.hintColor),
                      tooltip: 'Clear Search',
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                      },
                      splashRadius: 18,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    )
                  : null,
            ),
            onSubmitted: (value) {
              _focusNode.unfocus();
              widget.onSearchSubmitted(value);
            },
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// MODIFIED SECTION: VenueSearchDelegate now passes the heroTagContext.
// =========================================================================
class VenueSearchDelegate extends SearchDelegate<String?> {
  final FirestoreService firestoreService;
  final String? initialCityFilter;

  Timer? _debounce;
  Future<List<Map<String, dynamic>>>? _suggestionFuture;
  String _lastQuery = '';

  VenueSearchDelegate({
    required this.firestoreService,
    this.initialCityFilter,
  }) : super(
          searchFieldLabel: initialCityFilter != null
              ? 'Search in $initialCityFilter...'
              : 'Search venues...',
        );

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  
  @override
  ThemeData appBarTheme(BuildContext context) {
    // ... same as before
    final theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;
    final Color appBarFgColor = theme.colorScheme.onPrimary;

    return theme.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: theme.canvasColor,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: primaryColor,
        elevation: 1.0,
        iconTheme: IconThemeData(color: appBarFgColor),
        actionsIconTheme: IconThemeData(color: appBarFgColor),
        titleTextStyle:
            theme.textTheme.titleLarge?.copyWith(color: appBarFgColor),
        toolbarTextStyle:
            theme.textTheme.bodyMedium?.copyWith(color: appBarFgColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: theme.textTheme.titleMedium
            ?.copyWith(color: appBarFgColor.withOpacity(0.7)),
        border: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: appBarFgColor,
          selectionColor: appBarFgColor.withOpacity(0.3),
          selectionHandleColor: appBarFgColor),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    // ... same as before
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.search_outlined),
          tooltip: 'Search',
          onPressed: () {
            if (query.trim().isNotEmpty) {
              showResults(context);
            }
          },
        ),
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          tooltip: 'Clear',
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // ... same as before
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      tooltip: 'Back',
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // ... same as before
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return _buildInfoWidget("Please enter a search term.");
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firestoreService.getVenues(
        searchQuery: trimmedQuery,
        cityFilter: initialCityFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint("SearchDelegate Results Error: ${snapshot.error}");
          return _buildErrorWidget(
              "Error searching venues. Please try again.");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoResultsWidget();
        }
        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final venue = results[index];
            return _buildVenueListTileForResult(context, venue);
          },
        );
      },
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    // ... same as before
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final String currentQuery = query.trim();

        if (currentQuery != _lastQuery) {
          _lastQuery = currentQuery;
          _debounce?.cancel();

          if (currentQuery.isEmpty) {
            setState(() {
              _suggestionFuture = null;
            });
          } else {
            _debounce = Timer(const Duration(milliseconds: 400), () {
              if (currentQuery == _lastQuery) {
                final newFuture = firestoreService.getVenues(
                  searchQuery: currentQuery,
                  cityFilter: initialCityFilter,
                  limit: 10,
                  forSuggestions: true,
                );
                setState(() {
                  _suggestionFuture = newFuture;
                });
              }
            });
          }
        }
        
        if (currentQuery.isEmpty || _suggestionFuture == null) {
          return _buildInfoWidget("Start typing to search for venues...");
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _suggestionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (snapshot.hasError) {
              debugPrint("Suggestion Error: ${snapshot.error}");
              return _buildErrorWidget("Could not load suggestions.");
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildInfoWidget('No suggestions found for "$currentQuery".');
            }

            final suggestions = snapshot.data!;
            return ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final venue = suggestions[index];
                return _buildSuggestionTile(context, venue);
              },
            );
          },
        );
      },
    );
  }

  // <<< MODIFIED to pass heroTagContext >>>
  Widget _buildSuggestionTile(BuildContext context, Map<String, dynamic> venue) {
    final String name = venue['name'] as String? ?? 'No Name';
    final String city = venue['city'] as String? ?? '';
    final String venueId = venue['id'] as String;

    return ListTile(
      leading: Icon(Icons.place_outlined, color: Theme.of(context).hintColor),
      title: Text(name),
      subtitle: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        close(context, null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
              builder: (context) => VenueDetailScreen(
                venueId: venueId,
                initialVenueData: venue,
                heroTagContext: 'search_suggestion', // Pass a unique context
              ),
            ));
          }
        });
      },
    );
  }

  // <<< MODIFIED to pass heroTagContext >>>
  Widget _buildVenueListTileForResult(BuildContext context, Map<String, dynamic> venue) {
    final String name = venue['name'] as String? ?? 'No Name';
    final String city = venue['city'] as String? ?? '';
    final String address = venue['address'] as String? ?? '';
    final String venueId = venue['id'] as String;
    final List<String> sports = (venue['sportType'] as List<dynamic>?)?.whereType<String>().toList() ?? [];
    final String? imageUrl = venue['imageUrl'] as String?;
    final double rating = (venue['averageRating'] as num?)?.toDouble() ?? 0.0;

    return ListTile(
      leading: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
          ? CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 25, backgroundColor: Colors.grey[200])
          : CircleAvatar(child: Icon(Icons.sports_soccer_outlined, size: 20), radius: 25, backgroundColor: Colors.grey[200]),
      title: Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text("${sports.isNotEmpty ? sports.join(', ') : 'Venue'} - ${address.isNotEmpty ? '$address, ' : ''}$city", maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      trailing: rating > 0 ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ]) : null,
      onTap: () {
        close(context, null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(builder: (context) => VenueDetailScreen(
              venueId: venueId, 
              initialVenueData: venue,
              heroTagContext: 'search_result', // Pass a unique context
            )));
          }
        });
      },
    );
  }
  
  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 15),
            Text('No venues found matching "$query"${initialCityFilter != null ? ' in $initialCityFilter' : ''}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey[600])),
            const SizedBox(height: 10),
            const Text("Try different keywords or check spelling.", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ),
    );
  }
}