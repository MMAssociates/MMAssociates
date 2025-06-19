// // // // // //------------original code starts here------------

// // // // // //// import 'package:flutter/material.dart';
// // // // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // // // import 'package:geolocator/geolocator.dart';
// // // // // // import 'package:mm_associates/features/data/services/firestore_service.dart';
// // // // // // import 'package:mm_associates/features/home/screens/venue_form.dart';
// // // // // // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // // // // // import 'package:mm_associates/features/user/services/user_service.dart';
// // // // // // import 'package:mm_associates/core/services/location_service.dart';
// // // // // // import 'package:mm_associates/features/profile/screens/profile_screen.dart';
// // // // // // import 'venue_detail_screen.dart';
// // // // // // import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// // // // // // import 'dart:async';
// // // // // // import 'package:shimmer/shimmer.dart';
// // // // // // import 'city_selection_screen.dart' show CitySelectionScreen, CityInfo, kAppAllCities;
// // // // // // import 'package:flutter/scheduler.dart';

// // // // // // class HomeScreen extends StatefulWidget {
// // // // // //   const HomeScreen({super.key});

// // // // // //   @override
// // // // // //   State<HomeScreen> createState() => _HomeScreenState();
// // // // // // }

// // // // // // class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
// // // // // //   final AuthService _authService = AuthService();
// // // // // //   final FirestoreService _firestoreService = FirestoreService();
// // // // // //   final LocationService _locationService = LocationService();
// // // // // //   final UserService _userService = UserService();

// // // // // //   final TextEditingController _webSearchController = TextEditingController();
// // // // // //   final FocusNode _webSearchFocusNode = FocusNode();
// // // // // //   List<Map<String, dynamic>> _webSearchSuggestions = [];
// // // // // //   bool _isLoadingWebSuggestions = false;
// // // // // //   bool _showWebSuggestions = false;
// // // // // //   Timer? _webSearchDebounce;

// // // // // //   User? _currentUser;
// // // // // //   String? _userName;
// // // // // //   String? _userProfilePicUrl;
// // // // // //   bool _isLoadingName = true;

// // // // // //   List<Map<String, dynamic>> _filteredVenues = [];
// // // // // //   bool _isLoadingFilteredVenues = true;
// // // // // //   String? _filteredVenueFetchError;

// // // // // //   List<Map<String, dynamic>> _nearbyVenues = [];
// // // // // //   bool _isLoadingNearbyVenues = true;
// // // // // //   String? _nearbyVenueFetchError;

// // // // // //   List<Map<String, dynamic>> _exploreVenues = [];
// // // // // //   bool _isLoadingExploreVenues = true;
// // // // // //   String? _exploreVenueFetchError;

// // // // // //   Position? _currentPosition;
// // // // // //   bool _isFetchingLocation = false;
// // // // // //   String? _locationStatusMessage;

// // // // // //   String? _selectedCityFilter;
// // // // // //   IconData? _selectedCityIcon; // ADDED: To store the icon of the selected city
// // // // // //   String? _selectedSportFilter;
// // // // // //   String? _searchQuery;

// // // // // //   final List<String> _supportedCities = ['Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'];
// // // // // //   final List<String> _quickSportFilters = ['Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'];

// // // // // //   List<String> _favoriteVenueIds = [];
// // // // // //   bool _isLoadingFavorites = true;
// // // // // //   Stream<List<String>>? _favoritesStream;
// // // // // //   StreamSubscription<List<String>>? _favoritesSubscription;

// // // // // //   bool get _isSearchingOrFiltering => (_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null;

// // // // // //   final GlobalKey _webSearchBarKey = GlobalKey();

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _currentUser = FirebaseAuth.instance.currentUser;
// // // // // //     _initializeScreen();
// // // // // //     _setupFavoritesStream();

// // // // // //     _webSearchController.addListener(_onWebSearchChanged);
// // // // // //     _webSearchFocusNode.addListener(_onWebSearchFocusChanged);

// // // // // //     // ADDED: Initialize selected city icon based on the current filter state
// // // // // //     _updateSelectedCityIconFromFilter();
// // // // // //   }

// // // // // //   // ADDED: Helper method to set the city icon based on _selectedCityFilter
// // // // // //   void _updateSelectedCityIconFromFilter() {
// // // // // //     if (_selectedCityFilter == null) {
// // // // // //       _selectedCityIcon = Icons.my_location; // Default "Near Me" icon
// // // // // //     } else {
// // // // // //       try {
// // // // // //         // Find the city in our global list (kAppAllCities) to get its icon
// // // // // //         final cityInfo = kAppAllCities.firstWhere(
// // // // // //           (city) => city.name == _selectedCityFilter,
// // // // // //         );
// // // // // //         _selectedCityIcon = cityInfo.icon;
// // // // // //       } catch (e) {
// // // // // //         // Fallback if city not found in list (should ideally not happen if data is consistent)
// // // // // //         _selectedCityIcon = Icons.location_city_outlined;
// // // // // //         debugPrint("HomeScreen initState: Selected city '$_selectedCityFilter' not found in kAppAllCities. Using fallback icon. Error: $e");
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _webSearchController.removeListener(_onWebSearchChanged);
// // // // // //     _webSearchController.dispose();
// // // // // //     _webSearchFocusNode.removeListener(_onWebSearchFocusChanged);
// // // // // //     _webSearchFocusNode.dispose();
// // // // // //     _webSearchDebounce?.cancel();
// // // // // //     _favoritesSubscription?.cancel();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   void _onWebSearchChanged() {
// // // // // //     if (_webSearchDebounce?.isActive ?? false) _webSearchDebounce!.cancel();
// // // // // //     _webSearchDebounce = Timer(const Duration(milliseconds: 500), () {
// // // // // //       if (mounted && _webSearchController.text.trim().isNotEmpty && _webSearchFocusNode.hasFocus) {
// // // // // //         _fetchWebSearchSuggestions(_webSearchController.text.trim());
// // // // // //       } else if (mounted) {
// // // // // //         setStateIfMounted(() {
// // // // // //           _webSearchSuggestions = [];
// // // // // //           _showWebSuggestions = false;
// // // // // //         });
// // // // // //       }
// // // // // //     });
// // // // // //     if (mounted) {
// // // // // //      setStateIfMounted(() {});
// // // // // //     }
// // // // // //   }

// // // // // //   void _onWebSearchFocusChanged() {
// // // // // //     if (!mounted) return;
// // // // // //     setStateIfMounted(() {
// // // // // //       if (_webSearchFocusNode.hasFocus && _webSearchController.text.trim().isNotEmpty) {
// // // // // //         _showWebSuggestions = true;
// // // // // //         if(_webSearchSuggestions.isEmpty && _webSearchController.text.trim().isNotEmpty) {
// // // // // //           _fetchWebSearchSuggestions(_webSearchController.text.trim());
// // // // // //         }
// // // // // //       } else if (_webSearchFocusNode.hasFocus && _webSearchController.text.trim().isEmpty) {
// // // // // //          _webSearchSuggestions = [];
// // // // // //          _showWebSuggestions = true;
// // // // // //       }
// // // // // //       else {
// // // // // //         Future.delayed(const Duration(milliseconds: 200), () {
// // // // // //            if (!mounted || !_webSearchFocusNode.hasFocus) {
// // // // // //               setStateIfMounted(() => _showWebSuggestions = false);
// // // // // //            }
// // // // // //         });
// // // // // //       }
// // // // // //     });
// // // // // //   }

// // // // // //   Future<void> _fetchWebSearchSuggestions(String query) async {
// // // // // //     if (query.isEmpty) {
// // // // // //       if(mounted) {
// // // // // //         setStateIfMounted(() {
// // // // // //           _webSearchSuggestions = [];
// // // // // //           _isLoadingWebSuggestions = false;
// // // // // //         });
// // // // // //       }
// // // // // //       return;
// // // // // //     }
// // // // // //     if(mounted) {
// // // // // //       setStateIfMounted(() {
// // // // // //         _isLoadingWebSuggestions = true;
// // // // // //         _showWebSuggestions = true;
// // // // // //       });
// // // // // //     }
// // // // // //     try {
// // // // // //       final suggestions = await _firestoreService.getVenues(
// // // // // //         searchQuery: query,
// // // // // //         cityFilter: _selectedCityFilter,
// // // // // //         limit: 500,
// // // // // //         forSuggestions: true,
// // // // // //       );
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() {
// // // // // //         _webSearchSuggestions = suggestions;
// // // // // //         _isLoadingWebSuggestions = false;
// // // // // //       });
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Error fetching web search suggestions: $e");
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() {
// // // // // //         _isLoadingWebSuggestions = false;
// // // // // //         _webSearchSuggestions = [];
// // // // // //       });
// // // // // //     }
// // // // // //   }


// // // // // //   Future<void> _initializeScreen() async {
// // // // // //     await _fetchUserNameAndPic();
// // // // // //     await _fetchPrimaryVenueData();
// // // // // //   }

// // // // // //   Future<void> _fetchPrimaryVenueData() async {
// // // // // //     if (!mounted) return;
// // // // // //     setStateIfMounted(() {
// // // // // //       _isFetchingLocation = true; _isLoadingNearbyVenues = true; _isLoadingExploreVenues = true;
// // // // // //       _locationStatusMessage = 'Fetching your location...';
// // // // // //       _nearbyVenues = []; _exploreVenues = [];
// // // // // //       _nearbyVenueFetchError = null; _exploreVenueFetchError = null;
// // // // // //     });
// // // // // //     _currentPosition = await _locationService.getCurrentLocation();
// // // // // //     if (!mounted) return;
// // // // // //     setStateIfMounted(() {
// // // // // //       _isFetchingLocation = false;
// // // // // //       _locationStatusMessage = _currentPosition != null ? 'Location acquired.' : 'Could not get location.';
// // // // // //     });
// // // // // //     await Future.wait([_fetchNearbyVenuesScoped(), _fetchExploreVenuesFromOtherCities()]);
// // // // // //   }

// // // // // //   void _setupFavoritesStream() {
// // // // // //     _favoritesSubscription?.cancel();
// // // // // //     if (_currentUser != null) {
// // // // // //         _favoritesStream = _userService.getFavoriteVenueIdsStream();
// // // // // //         _favoritesSubscription = _favoritesStream?.listen(
// // // // // //           (favoriteIds) {
// // // // // //             if (mounted) {
// // // // // //               final newIdsSet = favoriteIds.toSet();
// // // // // //               final currentIdsSet = _favoriteVenueIds.toSet();
// // // // // //               if (newIdsSet.difference(currentIdsSet).isNotEmpty || currentIdsSet.difference(newIdsSet).isNotEmpty) {
// // // // // //                 setStateIfMounted(() {
// // // // // //                   _favoriteVenueIds = favoriteIds;
// // // // // //                 });
// // // // // //               }
// // // // // //             }
// // // // // //           },
// // // // // //           onError: (error) {
// // // // // //             debugPrint("Error in favorites stream: $error");
// // // // // //              if (mounted) {
// // // // // //                 ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                     const SnackBar(content: Text("Could not update favorites."),
// // // // // //                     backgroundColor: Colors.orangeAccent,
// // // // // //                     behavior: SnackBarBehavior.floating)
// // // // // //                 );
// // // // // //              }
// // // // // //           }
// // // // // //         );
// // // // // //         if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);

// // // // // //     } else {
// // // // // //       if (mounted) {
// // // // // //          setStateIfMounted(() {
// // // // // //            _favoriteVenueIds = [];
// // // // // //            _isLoadingFavorites = false;
// // // // // //            _favoritesStream = null;
// // // // // //            _favoritesSubscription = null;
// // // // // //          });
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   void didChangeDependencies() {
// // // // // //     super.didChangeDependencies();
// // // // // //     final currentAuthUser = FirebaseAuth.instance.currentUser;
// // // // // //     if (currentAuthUser != _currentUser) {
// // // // // //       _currentUser = currentAuthUser;
// // // // // //       _initializeScreen();
// // // // // //       _setupFavoritesStream();
// // // // // //       // ADDED: Also update city icon if user changes, though it's not user-specific
// // // // // //       // this call is harmless and ensures consistency if _selectedCityFilter somehow depended on user.
// // // // // //       if (mounted) {
// // // // // //         setStateIfMounted(() {
// // // // // //           _updateSelectedCityIconFromFilter();
// // // // // //         });
// // // // // //       }
// // // // // //     }
// // // // // //   }


// // // // // //   void setStateIfMounted(VoidCallback fn) { if (mounted) setState(fn); }

// // // // // //   Future<void> _fetchVenuesForFilterOrSearch({String? newSearchQuery}) async {
// // // // // //     if (!mounted) return;
// // // // // //     final currentSearchQuery = newSearchQuery ?? (kIsWeb ? _webSearchController.text.trim() : _searchQuery);

// // // // // //     if (mounted) {
// // // // // //       setStateIfMounted(() {
// // // // // //         _isLoadingFilteredVenues = true; _filteredVenueFetchError = null;
// // // // // //         _searchQuery = currentSearchQuery;
// // // // // //         _filteredVenues = [];
// // // // // //         if(kIsWeb && currentSearchQuery == null) _webSearchController.clear();
// // // // // //         if(kIsWeb) _showWebSuggestions = false;
// // // // // //       });
// // // // // //     }

// // // // // //     try {
// // // // // //       debugPrint("Fetching FILTERED/SEARCH venues: City: $_selectedCityFilter, Sport: $_selectedSportFilter, Search: $_searchQuery, Location: $_currentPosition");
// // // // // //       final venuesData = await _firestoreService.getVenues(
// // // // // //         userLocation: _currentPosition,
// // // // // //         radiusInKm: _selectedCityFilter != null ? null : (_currentPosition != null ? 50.0 : null),
// // // // // //         cityFilter: _selectedCityFilter,
// // // // // //         searchQuery: _searchQuery,
// // // // // //         sportFilter: _selectedSportFilter,
// // // // // //       );
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() {
// // // // // //           _filteredVenues = venuesData;
// // // // // //         });
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Error fetching filtered/search venues: $e");
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() => _filteredVenueFetchError = "Could not load venues: ${e.toString().replaceFirst('Exception: ', '')}");
// // // // // //     } finally {
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() => _isLoadingFilteredVenues = false);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _fetchNearbyVenuesScoped() async {
// // // // // //     if (!mounted) return;
// // // // // //     if (_currentPosition == null) {
// // // // // //       if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = false; _nearbyVenueFetchError = "Location not available."; _nearbyVenues = []; });
// // // // // //       return;
// // // // // //     }
// // // // // //     if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = true; _nearbyVenueFetchError = null; _nearbyVenues = []; });
// // // // // //     try {
// // // // // //       final venuesData = await _firestoreService.getVenues(userLocation: _currentPosition, radiusInKm: 25.0);
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() {
// // // // // //         _nearbyVenues = venuesData;
// // // // // //       });
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Error fetching nearby venues: $e");
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() => _nearbyVenueFetchError = "Could not load nearby venues.");
// // // // // //     } finally {
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() => _isLoadingNearbyVenues = false);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _fetchExploreVenuesFromOtherCities() async {
// // // // // //     if (!mounted) return;
// // // // // //     setStateIfMounted(() { _isLoadingExploreVenues = true; _exploreVenueFetchError = null; _exploreVenues = [];});
// // // // // //     List<Map<String, dynamic>> allExploreVenues = [];
// // // // // //     try {
// // // // // //       for (String city in _supportedCities) {
// // // // // //         final cityVenues = await _firestoreService.getVenues(cityFilter: city, userLocation: _currentPosition, limit: 5);
// // // // // //         allExploreVenues.addAll(cityVenues);
// // // // // //         if (!mounted) return;
// // // // // //       }
// // // // // //       final uniqueExploreVenues = allExploreVenues.fold<Map<String, Map<String, dynamic>>>({}, (map, venue) {
// // // // // //           final String? venueId = venue['id'] as String?;
// // // // // //           if (venueId != null) map[venueId] = venue;
// // // // // //           return map;
// // // // // //         }).values.toList();

// // // // // //       if (_currentPosition != null) {
// // // // // //         uniqueExploreVenues.sort((a, b) {
// // // // // //           final distA = a['distance'] as double?; final distB = b['distance'] as double?;
// // // // // //           if (distA != null && distB != null) return distA.compareTo(distB);
// // // // // //           if (distA != null) return -1;
// // // // // //           if (distB != null) return 1;
// // // // // //           return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
// // // // // //         });
// // // // // //       } else {
// // // // // //          uniqueExploreVenues.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
// // // // // //       }
// // // // // //       if(!mounted) return;
// // // // // //       setStateIfMounted(() {
// // // // // //         _exploreVenues = uniqueExploreVenues.take(15).toList();
// // // // // //       });
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Error fetching explore venues: $e");
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() => _exploreVenueFetchError = "Could not load explore venues.");
// // // // // //     } finally {
// // // // // //       if (!mounted) return;
// // // // // //       setStateIfMounted(() => _isLoadingExploreVenues = false);
// // // // // //     }
// // // // // //   }


// // // // // //   Future<void> _fetchUserNameAndPic() async {
// // // // // //     _setLoadingName(true); final currentUser = _currentUser;
// // // // // //     if (currentUser == null) { if(mounted) _updateUserNameAndPic('Guest', null); _setLoadingName(false); return; }
// // // // // //     try {
// // // // // //       final userData = await _userService.getUserProfileData();
// // // // // //       if (!mounted) return;
// // // // // //       final fetchedName = userData?['name'] as String? ?? currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// // // // // //       final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
// // // // // //       _updateUserNameAndPic(fetchedName, fetchedPicUrl);
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Error fetching user name/pic via UserService: $e"); if (!mounted) return;
// // // // // //       final fallbackName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// // // // // //       _updateUserNameAndPic(fallbackName, null);
// // // // // //     } finally { if(mounted) _setLoadingName(false); }
// // // // // //   }


// // // // // //   void _setLoadingName(bool isLoading) => {if(mounted) setStateIfMounted(() => _isLoadingName = isLoading)};
// // // // // //   void _updateUserNameAndPic(String name, String? picUrl) => {if(mounted) setStateIfMounted(() { _userName = name; _userProfilePicUrl = picUrl; })};

// // // // // //   Future<void> _handleRefresh() async {
// // // // // //     if(mounted) {
// // // // // //       setStateIfMounted(() {
// // // // // //           _searchQuery = null;
// // // // // //           _selectedSportFilter = null;
// // // // // //           if (kIsWeb) {
// // // // // //               _webSearchController.clear();
// // // // // //               _showWebSuggestions = false;
// // // // // //               _webSearchSuggestions = [];
// // // // // //           }
// // // // // //       });
// // // // // //     }
// // // // // //     if (_isSearchingOrFiltering) {
// // // // // //       _onFilterOrSearchChanged();
// // // // // //     } else {
// // // // // //       await _fetchPrimaryVenueData();
// // // // // //     }
// // // // // //   }

// // // // // //   void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
// // // // // //       String? currentSearchText = explicitSearchQuery ?? (kIsWeb ? _webSearchController.text.trim() : _searchQuery);

// // // // // //       if (mounted) {
// // // // // //         setStateIfMounted(() {
// // // // // //           _searchQuery = currentSearchText;
// // // // // //           if(kIsWeb && currentSearchText != null) { _webSearchController.text = currentSearchText;}
// // // // // //           else if (kIsWeb && currentSearchText == null && _selectedCityFilter == null && _selectedSportFilter == null) {
// // // // // //               _webSearchController.clear();
// // // // // //           }
// // // // // //         });
// // // // // //       }

// // // // // //       if ((_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null) {
// // // // // //            _fetchVenuesForFilterOrSearch(newSearchQuery: _searchQuery);
// // // // // //       } else {
// // // // // //           _fetchPrimaryVenueData();
// // // // // //       }
// // // // // //   }

// // // // // //   Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
// // // // // //       if (!context.mounted) return;
// // // // // //       return showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext dialogContext) {
// // // // // //           return AlertDialog(title: const Text('Confirm Logout'), content: const SingleChildScrollView(child: ListBody(children: <Widget>[Text('Are you sure you want to sign out?')])),
// // // // // //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
// // // // // //             actions: <Widget>[
// // // // // //               TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
// // // // // //               TextButton(child: const Text('Logout', style: TextStyle(color: Colors.red)), onPressed: () async {
// // // // // //                   Navigator.of(dialogContext).pop(); try { await _authService.signOut();
// // // // // //                    } catch (e) {
// // // // // //                     debugPrint("Error during sign out: $e"); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(10)));
// // // // // //                   }},), ],); },);
// // // // // //     }


// // // // // //   void _navigateToVenueDetail(Map<String, dynamic> venue) {
// // // // // //     if (!context.mounted) return;
// // // // // //     Navigator.push(context, MaterialPageRoute(builder: (context) => VenueDetailScreen(venueId: venue['id'] as String, initialVenueData: venue))).then((_) {
// // // // // //     });
// // // // // //   }


// // // // // //   void _openSearchMobile() async {
// // // // // //      if (!context.mounted) return;
// // // // // //      final String? submittedQuery = await showSearch<String?>(
// // // // // //         context: context,
// // // // // //         delegate: VenueSearchDelegate(
// // // // // //             firestoreService: _firestoreService,
// // // // // //             initialCityFilter: _selectedCityFilter,
// // // // // //         )
// // // // // //     );
// // // // // //     if (submittedQuery != null && submittedQuery.isNotEmpty) {
// // // // // //         _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
// // // // // //     }
// // // // // //   }

// // // // // //   void _performWebSearch() {
// // // // // //     if(mounted) FocusScope.of(context).unfocus();
// // // // // //     _onFilterOrSearchChanged();
// // // // // //   }

// // // // // //   // MODIFIED: Method for city selection to also update the icon
// // // // // //   Future<void> _openCitySelectionScreen() async {
// // // // // //     if (!mounted) return;
// // // // // //     final String? newSelectedCityName = await Navigator.push<String?>(
// // // // // //       context,
// // // // // //       MaterialPageRoute(
// // // // // //         builder: (context) => CitySelectionScreen(currentSelectedCity: _selectedCityFilter),
// // // // // //       ),
// // // // // //     );

// // // // // //     if (mounted) {
// // // // // //       // Check if the city selection actually changed
// // // // // //       if (newSelectedCityName != _selectedCityFilter) {
// // // // // //         setStateIfMounted(() {
// // // // // //           _selectedCityFilter = newSelectedCityName; // null represents "Near Me"
// // // // // //           _updateSelectedCityIconFromFilter(); // Update the icon based on the new selection
// // // // // //         });
// // // // // //         _onFilterOrSearchChanged(); // Trigger data fetch with the new filter
// // // // // //       } else {
// // // // // //         // If the same city (or "Near Me") was re-selected, ensure the icon is correctly set.
// // // // // //         // This mainly handles cases where the icon might not have been set if _selectedCityFilter was initialized
// // // // // //         // through other means without also setting _selectedCityIcon (which initState now handles).
// // // // // //         IconData currentExpectedIcon = Icons.location_city_outlined; // Fallback
// // // // // //         if (_selectedCityFilter == null) {
// // // // // //             currentExpectedIcon = Icons.my_location;
// // // // // //         } else {
// // // // // //             try {
// // // // // //                 final cityInfo = kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
// // // // // //                 currentExpectedIcon = cityInfo.icon;
// // // // // //             } catch (e) {
// // // // // //                 debugPrint("Error re-validating icon for city '$_selectedCityFilter': $e. Using fallback.");
// // // // // //             }
// // // // // //         }
// // // // // //         if (_selectedCityIcon != currentExpectedIcon) {
// // // // // //             setStateIfMounted(() {
// // // // // //               _selectedCityIcon = currentExpectedIcon;
// // // // // //             });
// // // // // //         }
// // // // // //       }
// // // // // //     }
// // // // // //   }


// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = Theme.of(context);
// // // // // //     final appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
// // // // // //     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ?? theme.appBarTheme.iconTheme?.color ?? (kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white);
// // // // // //     final bool isLoggedIn = _currentUser != null;

// // // // // //     Widget mainScaffold = Scaffold(
// // // // // //       appBar: AppBar(
// // // // // //         automaticallyImplyLeading: false,
// // // // // //         title: kIsWeb ? _buildWebAppBarTitle(context) : _buildMobileAppBarTitle(context, theme),
// // // // // //         actions: kIsWeb ? _buildWebAppBarActions(context, isLoggedIn, actionsIconColor) : _buildMobileAppBarActions(context, isLoggedIn, actionsIconColor),
// // // // // //         backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
// // // // // //         elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
// // // // // //         iconTheme: theme.iconTheme.copyWith(color: kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white),
// // // // // //         actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
// // // // // //         titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ?? TextStyle(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
// // // // // //       ),
// // // // // //   floatingActionButton: FloatingActionButton.extended(
// // // // // //     onPressed: () {
// // // // // //       Navigator.push(
// // // // // //         context,
// // // // // //         MaterialPageRoute(builder: (context) => const AddVenueFormScreen()),
// // // // // //       ).then((result) {
// // // // // //         if (result == true && mounted) {
// // // // // //           _handleRefresh();
// // // // // //           ScaffoldMessenger.of(context).showSnackBar(
// // // // // //             const SnackBar(content: Text("Venue list updated."), backgroundColor: Colors.blueAccent),
// // // // // //           );
// // // // // //         }
// // // // // //       });
// // // // // //     },
// // // // // //     icon: const Icon(Icons.add_location_alt_outlined),
// // // // // //     label: const Text("Add Venue"),
// // // // // //     tooltip: 'Add New Venue',
// // // // // //   ),
// // // // // //   floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
// // // // // //   body: _buildBodyContent(),
// // // // // //     );

// // // // // //     if (kIsWeb) {
// // // // // //       Rect? searchBarRect;
// // // // // //       final searchBarContext = _webSearchBarKey.currentContext;
// // // // // //       if (searchBarContext != null) {
// // // // // //         final RenderBox? renderBox = searchBarContext.findRenderObject() as RenderBox?;
// // // // // //         if (renderBox != null && renderBox.hasSize) {
// // // // // //             final overlayContext = Overlay.of(context, rootOverlay: true)?.context;
// // // // // //             if (overlayContext != null) {
// // // // // //                  final RenderBox? overlayRenderBox = overlayContext.findRenderObject() as RenderBox?;
// // // // // //                  if (overlayRenderBox != null) {
// // // // // //                     final Offset offsetInOverlay = renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
// // // // // //                     searchBarRect = Rect.fromLTWH(offsetInOverlay.dx, offsetInOverlay.dy, renderBox.size.width, renderBox.size.height);
// // // // // //                  }
// // // // // //             }
// // // // // //         }
// // // // // //       }

// // // // // //       return Stack(
// // // // // //         children: [
// // // // // //           GestureDetector(
// // // // // //             onTap: () {
// // // // // //               if (_showWebSuggestions) {
// // // // // //                 if(mounted) {
// // // // // //                   setStateIfMounted(() {
// // // // // //                     _showWebSuggestions = false;
// // // // // //                     _webSearchFocusNode.unfocus();
// // // // // //                   });
// // // // // //                 }
// // // // // //               }
// // // // // //             },
// // // // // //             child: mainScaffold,
// // // // // //           ),
// // // // // //           if (_showWebSuggestions && searchBarRect != null)
// // // // // //             Positioned(
// // // // // //               top: searchBarRect.bottom + 4.0,
// // // // // //               left: searchBarRect.left,
// // // // // //               width: searchBarRect.width,
// // // // // //               child: Material(
// // // // // //                 elevation: 4.0,
// // // // // //                 borderRadius: BorderRadius.circular(8),
// // // // // //                 child: Container(
// // // // // //                   constraints: const BoxConstraints(maxHeight: 250),
// // // // // //                   decoration: BoxDecoration(
// // // // // //                     color: Theme.of(context).cardColor,
// // // // // //                     borderRadius: BorderRadius.circular(8),
// // // // // //                      boxShadow: [
// // // // // //                         BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0,3) )
// // // // // //                      ]
// // // // // //                   ),
// // // // // //                   child: _isLoadingWebSuggestions
// // // // // //                       ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
// // // // // //                       : _webSearchSuggestions.isEmpty
// // // // // //                           ? Padding(
// // // // // //                               padding: const EdgeInsets.all(16.0),
// // // // // //                               child: Text(
// // // // // //                                 _webSearchController.text.isEmpty && _webSearchFocusNode.hasFocus ? "Start typing to search..." : "No suggestions found.",
// // // // // //                                 textAlign: TextAlign.center,
// // // // // //                                 style: TextStyle(color: Theme.of(context).hintColor),
// // // // // //                               ),
// // // // // //                             )
// // // // // //                           : ListView.builder(
// // // // // //                               shrinkWrap: true,
// // // // // //                               padding: EdgeInsets.zero,
// // // // // //                               itemCount: _webSearchSuggestions.length,
// // // // // //                               itemBuilder: (context, index) {
// // // // // //                                 final venue = _webSearchSuggestions[index];
// // // // // //                                 final String name = venue['name'] as String? ?? 'N/A';
// // // // // //                                 final String city = venue['city'] as String? ?? '';
// // // // // //                                 return ListTile(
// // // // // //                                   title: Text(name, style: const TextStyle(fontSize: 14)),
// // // // // //                                   subtitle: city.isNotEmpty ? Text(city, style: const TextStyle(fontSize: 12)) : null,
// // // // // //                                   dense: true,
// // // // // //                                   contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
// // // // // //                                   onTap: () {
// // // // // //                                     _webSearchController.text = name;
// // // // // //                                     _webSearchController.selection = TextSelection.fromPosition(TextPosition(offset: _webSearchController.text.length));
// // // // // //                                     _performWebSearch();
// // // // // //                                     if(mounted) {
// // // // // //                                       _webSearchFocusNode.unfocus();
// // // // // //                                       setStateIfMounted(() => _showWebSuggestions = false);
// // // // // //                                     }
// // // // // //                                   },
// // // // // //                                 );
// // // // // //                               },
// // // // // //                             ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //         ],
// // // // // //       );
// // // // // //     }
// // // // // //     return mainScaffold;
// // // // // //   }


// // // // // //   Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
// // // // // //     final titleStyle = theme.appBarTheme.titleTextStyle ?? theme.primaryTextTheme.titleLarge ?? const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
// // // // // //     final currentUser = _currentUser;
// // // // // //     return Row(children: [
// // // // // //         if (currentUser != null)
// // // // // //           GestureDetector(
// // // // // //             onTap: () {
// // // // // //               if (!context.mounted) return;
// // // // // //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // // //                   .then((_) { if (mounted) _fetchUserNameAndPic(); });
// // // // // //             },
// // // // // //             child: Tooltip(
// // // // // //               message: "My Profile",
// // // // // //               child: Padding(
// // // // // //                 padding: const EdgeInsets.only(right: 10.0),
// // // // // //                 child: CircleAvatar(
// // // // // //                   radius: 18,
// // // // // //                   backgroundColor: Colors.white24,
// // // // // //                   backgroundImage: _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty ? NetworkImage(_userProfilePicUrl!) : null,
// // // // // //                   child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty ? Icon(Icons.person_outline, size: 20, color: Colors.white.withOpacity(0.8)) : null
// // // // // //                 )
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         if (_isLoadingName && currentUser != null)
// // // // // //           const Padding(
// // // // // //             padding: EdgeInsets.only(left: 6.0),
// // // // // //             child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)))
// // // // // //           )
// // // // // //         else if (_userName != null && currentUser != null)
// // // // // //           Expanded(
// // // // // //             child: Padding(
// // // // // //                padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
// // // // // //               child: Text(
// // // // // //                 'Hi, ${_userName!.split(' ')[0]}!',
// // // // // //                 style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
// // // // // //                 overflow: TextOverflow.ellipsis
// // // // // //               )
// // // // // //             )
// // // // // //           )
// // // // // //         else
// // // // // //           Text('MM Associates', style: titleStyle),
// // // // // //       ]
// // // // // //     );
// // // // // //   }

// // // // // //   // MODIFIED: To use _selectedCityIcon
// // // // // //   // List<Widget> _buildMobileAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // // // //   //   return [
// // // // // //   //     IconButton(
// // // // // //   //       icon: Icon(Icons.search_outlined, color: iconColor),
// // // // // //   //       tooltip: 'Search Venues',
// // // // // //   //       onPressed: _openSearchMobile,
// // // // // //   //       padding: const EdgeInsets.symmetric(horizontal: 8),
// // // // // //   //       constraints: const BoxConstraints()
// // // // // //   //     ),
// // // // // //   //     IconButton(
// // // // // //   //       icon: Icon(
// // // // // //   //         // Use the stored icon, with fallbacks
// // // // // //   //         _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // // // //   //         color: iconColor,
// // // // // //   //       ),
// // // // // //   //       tooltip: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // // // //   //       onPressed: _openCitySelectionScreen,
// // // // // //   //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
// // // // // //   //       constraints: const BoxConstraints(),
// // // // // //   //     ),
// // // // // //   //     if (isLoggedIn) IconButton(
// // // // // //   //       icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // // // //   //       tooltip: 'My Profile',
// // // // // //   //         onPressed: () { if (!context.mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())).then((_) { if (mounted) _fetchUserNameAndPic(); }); },
// // // // // //   //         padding: const EdgeInsets.symmetric(horizontal: 8), constraints: const BoxConstraints()),
// // // // // //   //   ];
// // // // // //   // }

// // // // // //   List<Widget> _buildMobileAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // // // //   final String cityNameText = _selectedCityFilter ?? 'Near Me';
// // // // // //   final double textSize = 10.0; // Small text size for below icon

// // // // // //   return [
// // // // // //     IconButton(
// // // // // //       icon: Icon(Icons.search_outlined, color: iconColor),
// // // // // //       tooltip: 'Search Venues',
// // // // // //       onPressed: _openSearchMobile,
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 8),
// // // // // //       constraints: const BoxConstraints(),
// // // // // //     ),
// // // // // //     Tooltip( // Added Tooltip here for consistency and for the composite icon
// // // // // //       message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // // // //       child: IconButton(
// // // // // //         icon: Column(
// // // // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // // // //           mainAxisSize: MainAxisSize.min, // Important to keep the column compact
// // // // // //           children: [
// // // // // //             Icon(
// // // // // //               _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // // // //               color: iconColor,
// // // // // //               size: 24, // Default IconButton icon size
// // // // // //             ),
// // // // // //             const SizedBox(height: 2), // Spacing between icon and text
// // // // // //             Text(
// // // // // //               cityNameText,
// // // // // //               style: TextStyle(
// // // // // //                 color: iconColor,
// // // // // //                 fontSize: textSize,
// // // // // //                 fontWeight: FontWeight.w500, // Slightly bolder for readability
// // // // // //               ),
// // // // // //               overflow: TextOverflow.ellipsis,
// // // // // //               maxLines: 1,
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //         onPressed: _openCitySelectionScreen,
// // // // // //         padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // Adjust padding if needed
// // // // // //         constraints: const BoxConstraints(),
// // // // // //       ),
// // // // // //     ),
// // // // // //     if (isLoggedIn)
// // // // // //       IconButton(
// // // // // //         icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // // // //         tooltip: 'My Profile',
// // // // // //         onPressed: () {
// // // // // //           if (!context.mounted) return;
// // // // // //           Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // // //               .then((_) {
// // // // // //             if (mounted) _fetchUserNameAndPic();
// // // // // //           });
// // // // // //         },
// // // // // //         padding: const EdgeInsets.symmetric(horizontal: 8),
// // // // // //         constraints: const BoxConstraints(),
// // // // // //       ),
// // // // // //   ];
// // // // // // }

// // // // // //   Widget _buildWebAppBarTitle(BuildContext context) {
// // // // // //      final theme = Theme.of(context);
// // // // // //      final currentUser = _currentUser;
// // // // // //      double screenWidth = MediaQuery.of(context).size.width;
// // // // // //      double leadingWidth = 150 + (_userName != null ? 100 : 0);
// // // // // //      double searchWidthFraction = 0.4;
// // // // // //      double minSearchWidth = 200;
// // // // // //      double maxSearchWidth = 500;
// // // // // //      double actionsWidth = 80 + (_currentUser != null ? 120 : 0);
// // // // // //      double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
// // // // // //      double calculatedSearchWidth = (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);
// // // // // //      double spacerFlexFactor = (availableWidth > calculatedSearchWidth + 40)
// // // // // //          ? (availableWidth - calculatedSearchWidth) / 2 / availableWidth
// // // // // //          : 0.05;
// // // // // //      int searchFlex = (searchWidthFraction * 100).toInt();
// // // // // //      int spacerFlex = (spacerFlexFactor * 100).toInt().clamp(5, 50);

// // // // // //      return Row(children: [
// // // // // //        Text('MM Associates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
// // // // // //        const SizedBox(width: 24),
// // // // // //        if (_isLoadingName && currentUser != null)
// // // // // //           const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
// // // // // //        else if (_userName != null && currentUser != null)
// // // // // //           Padding(
// // // // // //             padding: const EdgeInsets.only(right: 16.0),
// // // // // //             child: Text('Hi, ${_userName!.split(' ')[0]}!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)
// // // // // //           ),
// // // // // //        Spacer(flex: spacerFlex),
// // // // // //        Expanded(
// // // // // //          flex: searchFlex,
// // // // // //          child: Container(
// // // // // //            key: _webSearchBarKey,
// // // // // //            constraints: BoxConstraints(maxWidth: maxSearchWidth),
// // // // // //            height: 40,
// // // // // //            decoration: BoxDecoration(
// // // // // //              color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerLowest,
// // // // // //              borderRadius: BorderRadius.circular(20),
// // // // // //            ),
// // // // // //            child: Center(
// // // // // //              child: TextField(
// // // // // //                controller: _webSearchController,
// // // // // //                focusNode: _webSearchFocusNode,
// // // // // //                style: theme.textTheme.bodyMedium,
// // // // // //                textAlignVertical: TextAlignVertical.center,
// // // // // //                decoration: InputDecoration(
// // // // // //                  hintText: 'Search venues by name, sport, or city...',
// // // // // //                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
// // // // // //                  prefixIcon: Icon(Icons.search_outlined, color: theme.hintColor, size: 20),
// // // // // //                  border: InputBorder.none,
// // // // // //                  contentPadding: const EdgeInsets.only(left: 0, right: 10, top: 11, bottom: 11),
// // // // // //                  isDense: true,
// // // // // //                  suffixIcon: _webSearchController.text.isNotEmpty
// // // // // //                    ? IconButton(
// // // // // //                        icon: Icon(Icons.clear_rounded, size: 20, color: theme.hintColor),
// // // // // //                        tooltip: 'Clear Search',
// // // // // //                        onPressed: () {
// // // // // //                           _webSearchController.clear();
// // // // // //                            if (_webSearchFocusNode.hasFocus) {
// // // // // //                                _onWebSearchChanged();
// // // // // //                            }
// // // // // //                        },
// // // // // //                        splashRadius: 18,
// // // // // //                        constraints: const BoxConstraints(),
// // // // // //                        padding: EdgeInsets.zero,
// // // // // //                       )
// // // // // //                    : null
// // // // // //                 ),
// // // // // //                onSubmitted: (_) => _performWebSearch(),
// // // // // //              )
// // // // // //            )
// // // // // //          )
// // // // // //        ),
// // // // // //        Spacer(flex: spacerFlex),
// // // // // //      ]);
// // // // // //    }

// // // // // //   // MODIFIED: To use _selectedCityIcon
// // // // // //   // List<Widget> _buildWebAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // // // //   //   return [
// // // // // //   //     Tooltip(
// // // // // //   //       message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // // // //   //       child: IconButton(
// // // // // //   //         icon: Icon(
// // // // // //   //           // Use the stored icon, with fallbacks
// // // // // //   //           _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // // // //   //           color: iconColor,
// // // // // //   //         ),
// // // // // //   //         onPressed: _openCitySelectionScreen,
// // // // // //   //         padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // // //   //         constraints: const BoxConstraints(),
// // // // // //   //       ),
// // // // // //   //     ),
// // // // // //   //     if (isLoggedIn)
// // // // // //   //       Tooltip(
// // // // // //   //         message: 'My Profile',
// // // // // //   //         child: IconButton(
// // // // // //   //           icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // // // //   //           onPressed: () {
// // // // // //   //             if (!context.mounted) return;
// // // // // //   //             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // // //   //                 .then((_) { if (mounted) _fetchUserNameAndPic();});
// // // // // //   //           },
// // // // // //   //           padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // // //   //           constraints: const BoxConstraints(),
// // // // // //   //         ),
// // // // // //   //       ),
// // // // // //   //     const SizedBox(width: 8)
// // // // // //   //   ];
// // // // // //   // }

// // // // // // List<Widget> _buildWebAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // // // //   final String cityNameText = _selectedCityFilter ?? 'Near Me';
// // // // // //   final double textSize = 10.0; // Small text size

// // // // // //   return [
// // // // // //     Tooltip(
// // // // // //       message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // // // //       child: IconButton(
// // // // // //         icon: Column(
// // // // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // // // //           mainAxisSize: MainAxisSize.min, // Important
// // // // // //           children: [
// // // // // //             Icon(
// // // // // //               _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // // // //               color: iconColor,
// // // // // //               size: 24,
// // // // // //             ),
// // // // // //             const SizedBox(height: 2),
// // // // // //             Text(
// // // // // //               cityNameText,
// // // // // //               style: TextStyle(
// // // // // //                 color: iconColor,
// // // // // //                 fontSize: textSize,
// // // // // //                 fontWeight: FontWeight.w500,
// // // // // //               ),
// // // // // //               overflow: TextOverflow.ellipsis,
// // // // // //               maxLines: 1,
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //         onPressed: _openCitySelectionScreen,
// // // // // //         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // Adjust padding for web
// // // // // //         constraints: const BoxConstraints(),
// // // // // //       ),
// // // // // //     ),
// // // // // //     if (isLoggedIn)
// // // // // //       Tooltip(
// // // // // //         message: 'My Profile',
// // // // // //         child: IconButton(
// // // // // //           icon: Icon(Icons.person_outline_rounded, color: iconColor), // Kept this simple
// // // // // //           onPressed: () {
// // // // // //             if (!context.mounted) return;
// // // // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // // //                 .then((_) {
// // // // // //               if (mounted) _fetchUserNameAndPic();
// // // // // //             });
// // // // // //           },
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // // //           constraints: const BoxConstraints(),
// // // // // //         ),
// // // // // //       ),
// // // // // //     const SizedBox(width: 8)
// // // // // //   ];
// // // // // // }
// // // // // //   Widget _buildQuickSportFilters() {
// // // // // //     if (_quickSportFilters.isEmpty) return const SizedBox.shrink();
// // // // // //     final theme = Theme.of(context);
// // // // // //     return Container(
// // // // // //       height: 55,
// // // // // //       color: theme.cardColor,
// // // // // //       child: ListView.separated(
// // // // // //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// // // // // //         scrollDirection: Axis.horizontal,
// // // // // //         itemCount: _quickSportFilters.length + 1,
// // // // // //         separatorBuilder: (context, index) => const SizedBox(width: 10),
// // // // // //         itemBuilder: (context, index) {
// // // // // //           if (index == 0) {
// // // // // //             final bool isSelected = _selectedSportFilter == null;
// // // // // //             return ChoiceChip(
// // // // // //               label: const Text('All Sports'),
// // // // // //               selected: isSelected,
// // // // // //               onSelected: (bool nowSelected) {
// // // // // //                 if (nowSelected && _selectedSportFilter != null) {
// // // // // //                     setStateIfMounted(() => _selectedSportFilter = null);
// // // // // //                     _onFilterOrSearchChanged();
// // // // // //                 }
// // // // // //               },
// // // // // //               selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// // // // // //               backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// // // // // //               labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// // // // // //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// // // // // //               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// // // // // //               visualDensity: VisualDensity.compact,
// // // // // //                showCheckmark: false,
// // // // // //             );
// // // // // //           }
// // // // // //           final sport = _quickSportFilters[index - 1];
// // // // // //           final bool isSelected = _selectedSportFilter == sport;
// // // // // //           return ChoiceChip(
// // // // // //             label: Text(sport),
// // // // // //             selected: isSelected,
// // // // // //             onSelected: (bool isNowSelected) {
// // // // // //               String? newFilterValue = isNowSelected ? sport : null;
// // // // // //               if (_selectedSportFilter != newFilterValue) {
// // // // // //                 setStateIfMounted(() { _selectedSportFilter = newFilterValue; });
// // // // // //                 _onFilterOrSearchChanged();
// // // // // //               }
// // // // // //             },
// // // // // //             selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// // // // // //             backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// // // // // //             labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// // // // // //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// // // // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// // // // // //             visualDensity: VisualDensity.compact,
// // // // // //             showCheckmark: false,
// // // // // //           );
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildSectionHeader(BuildContext context, String title) {
// // // // // //     return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
// // // // // //       child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
// // // // // //   }

// // // // // //   Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg, String emptyMsg, {bool isNearbySection = false}) {
// // // // // //      if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
// // // // // //      if (errorMsg != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16))));
// // // // // //      if (venues.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

// // // // // //      return GridView.builder(
// // // // // //        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// // // // // //        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
// // // // // //        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// // // // // //            maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
// // // // // //            mainAxisSpacing: 16.0,
// // // // // //            crossAxisSpacing: 16.0,
// // // // // //            childAspectRatio: 0.70
// // // // // //         ),
// // // // // //        itemCount: venues.length,
// // // // // //        itemBuilder: (context, index) {
// // // // // //          final venue = venues[index];
// // // // // //          final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
// // // // // //          return _buildVenueGridCard(venue, isFavorite: isFavorite);
// // // // // //        },
// // // // // //      );
// // // // // //    }

// // // // // //   Widget _buildBodyContent() {
// // // // // //      return Column(children: [
// // // // // //          _buildQuickSportFilters(),
// // // // // //          Expanded(
// // // // // //            child: RefreshIndicator(
// // // // // //              onRefresh: _handleRefresh,
// // // // // //              child: ListView(
// // // // // //                padding: EdgeInsets.zero,
// // // // // //                children: [
// // // // // //                  if (_isSearchingOrFiltering) ...[
// // // // // //                    _buildSectionHeader(context,
// // // // // //                         _searchQuery != null && _searchQuery!.isNotEmpty
// // // // // //                             ? "Results for \"$_searchQuery\""
// // // // // //                             : (_selectedCityFilter != null
// // // // // //                                 ? "Venues in $_selectedCityFilter"
// // // // // //                                 : (_selectedSportFilter != null ? "Venues for $_selectedSportFilter" : "Filtered Venues")
// // // // // //                             )
// // // // // //                     ),
// // // // // //                    _buildVenueList(_filteredVenues, _isLoadingFilteredVenues, _filteredVenueFetchError, "No venues found for your selection.", isNearbySection: false),
// // // // // //                  ] else ...[
// // // // // //                    if (_currentPosition != null || _isLoadingNearbyVenues)
// // // // // //                        _buildSectionHeader(context, "Venues Near You"),
// // // // // //                    _buildVenueList(_nearbyVenues, _isLoadingNearbyVenues, _nearbyVenueFetchError, "No venues found nearby. Try exploring other cities or check location permissions.", isNearbySection: true),

// // // // // //                    const SizedBox(height: 16),
// // // // // //                    _buildSectionHeader(context, "Explore Venues"),
// // // // // //                    _buildVenueList(_exploreVenues, _isLoadingExploreVenues, _exploreVenueFetchError, "No venues to explore at the moment.", isNearbySection: false),
// // // // // //                   ],
// // // // // //                  const SizedBox(height: 80),
// // // // // //                ],
// // // // // //              ),
// // // // // //            ),
// // // // // //          ),
// // // // // //        ]
// // // // // //      );
// // // // // //   }

// // // // // //   Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
// // // // // //     return Shimmer.fromColors(baseColor: Colors.grey[350]!, highlightColor: Colors.grey[200]!,
// // // // // //       child: GridView.builder(
// // // // // //         shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // //         gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0, mainAxisSpacing: 16.0, crossAxisSpacing: 16.0, childAspectRatio: 0.70),
// // // // // //         itemCount: itemCount, itemBuilder: (context, index) => _buildVenueShimmerCard())
// // // // // //       );
// // // // // //   }
// // // // // //   Widget _buildVenueShimmerCard() {
// // // // // //     return Card(
// // // // // //       margin: EdgeInsets.zero, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
// // // // // //       child: Column(children: [
// // // // // //         Container(height: 130, width: double.infinity, color: Colors.white),
// // // // // //         Expanded(child: Padding(padding: const EdgeInsets.all(10.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// // // // // //           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// // // // // //             Container(width: double.infinity, height: 18.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// // // // // //             Container(width: MediaQuery.of(context).size.width * 0.3, height: 14.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// // // // // //             Container(width: MediaQuery.of(context).size.width * 0.2, height: 12.0, color: Colors.white)]),
// // // // // //           Container(width: double.infinity, height: 12.0, color: Colors.white)
// // // // // //           ])))
// // // // // //       ]));
// // // // // //   }

// // // // // //   Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite}) {
// // // // // //       final String venueId = venue['id'] as String? ?? '';
// // // // // //       return _VenueCardWidget(
// // // // // //         key: ValueKey(venueId),
// // // // // //         venue: venue,
// // // // // //         isFavorite: isFavorite,
// // // // // //         onTapCard: () => _navigateToVenueDetail(venue),
// // // // // //         onTapFavorite: () => _toggleFavorite(venueId, isFavorite, venue),
// // // // // //       );
// // // // // //     }

// // // // // //   Future<void> _toggleFavorite(String venueId, bool currentIsFavorite, Map<String, dynamic> venue) async {
// // // // // //     if (!mounted) return;
// // // // // //     final currentUser = _currentUser;
// // // // // //     if (currentUser == null) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("Please log in to manage favorites."), behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(10)),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //     if (venueId.isEmpty) return;

// // // // // //     try {
// // // // // //       if (!currentIsFavorite) {
// // // // // //         await _userService.addFavorite(venueId);
// // // // // //       } else {
// // // // // //         await _userService.removeFavorite(venueId);
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Error toggling favorite: $e");
// // // // // //       if (mounted) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(content: Text("Error updating favorites: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(10)),
// // // // // //         );
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // // } // End _HomeScreenState


// // // // // // // --- _VenueCardWidget (Stateful Card - Kept from your provided code) ---
// // // // // // class _VenueCardWidget extends StatefulWidget {
// // // // // //   final Map<String, dynamic> venue;
// // // // // //   final bool isFavorite;
// // // // // //   final VoidCallback onTapCard;
// // // // // //   final Future<void> Function() onTapFavorite;

// // // // // //   const _VenueCardWidget({
// // // // // //     required Key key,
// // // // // //     required this.venue,
// // // // // //     required this.isFavorite,
// // // // // //     required this.onTapCard,
// // // // // //     required this.onTapFavorite,
// // // // // //   }) : super(key: key);

// // // // // //   @override
// // // // // //   _VenueCardWidgetState createState() => _VenueCardWidgetState();
// // // // // // }

// // // // // // class _VenueCardWidgetState extends State<_VenueCardWidget> with SingleTickerProviderStateMixin {
// // // // // //   late AnimationController _favoriteAnimationController;
// // // // // //   late Animation<double> _favoriteScaleAnimation;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _favoriteAnimationController = AnimationController(
// // // // // //       duration: const Duration(milliseconds: 300),
// // // // // //       vsync: this,
// // // // // //     );
// // // // // //     _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
// // // // // //       CurvedAnimation(parent: _favoriteAnimationController, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   void didUpdateWidget(_VenueCardWidget oldWidget) {
// // // // // //     super.didUpdateWidget(oldWidget);
// // // // // //     if (widget.isFavorite != oldWidget.isFavorite && mounted) {
// // // // // //       if (widget.isFavorite) {
// // // // // //         _favoriteAnimationController.forward(from: 0.0).catchError((e) {
// // // // // //           if (e is! TickerCanceled) { debugPrint("Error playing fav add animation: $e"); }
// // // // // //         });
// // // // // //       } else {
// // // // // //          _favoriteAnimationController.reverse().catchError((e) {
// // // // // //              if (e is! TickerCanceled) { debugPrint("Error reversing fav remove animation: $e"); }
// // // // // //          });
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _favoriteAnimationController.dispose();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final ThemeData theme = Theme.of(context);
// // // // // //     final String name = widget.venue['name'] as String? ?? 'Unnamed Venue';
// // // // // //     final dynamic sportRaw = widget.venue['sportType'];
// // // // // //     final String sport = (sportRaw is String) ? sportRaw : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
// // // // // //     final String? imageUrl = widget.venue['imageUrl'] as String?;
// // // // // //     final String city = widget.venue['city'] as String? ?? '';
// // // // // //     final String venueId = widget.venue['id'] as String? ?? '';
// // // // // //     final double? distance = widget.venue['distance'] as double?;
// // // // // //     final double averageRating = (widget.venue['averageRating'] as num?)?.toDouble() ?? 0.0;
// // // // // //     final int reviewCount = (widget.venue['reviewCount'] as num?)?.toInt() ?? 0;

// // // // // //     return MouseRegion(
// // // // // //       cursor: SystemMouseCursors.click,
// // // // // //       child: Card(
// // // // // //         margin: EdgeInsets.zero,
// // // // // //         elevation: 3,
// // // // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // //         clipBehavior: Clip.antiAlias,
// // // // // //         child: Column(
// // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //           children: [
// // // // // //             SizedBox(
// // // // // //               height: 130,
// // // // // //               width: double.infinity,
// // // // // //               child: Stack(
// // // // // //                 children: [
// // // // // //                   Positioned.fill(
// // // // // //                     child: InkWell(
// // // // // //                       onTap: widget.onTapCard,
// // // // // //                       child: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
// // // // // //                           ? Hero(
// // // // // //                               tag: 'venue_image_$venueId',
// // // // // //                               child: Image.network(
// // // // // //                                 imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
// // // // // //                                 loadingBuilder: (context, child, loadingProgress) =>
// // // // // //                                     (loadingProgress == null) ? child : Container(height: 130, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null))),
// // // // // //                                 errorBuilder: (context, error, stackTrace) =>
// // // // // //                                     Container(height: 130, color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40))),
// // // // // //                               ),
// // // // // //                             )
// // // // // //                           : Container(height: 130, color: theme.primaryColor.withOpacity(0.08), child: Center(child: Icon(Icons.sports_soccer_outlined, size: 50, color: theme.primaryColor.withOpacity(0.7)))),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   Positioned(
// // // // // //                     top: 6, right: 6,
// // // // // //                     child: Material(
// // // // // //                       color: Colors.black.withOpacity(0.45), shape: const CircleBorder(),
// // // // // //                       child: InkWell(
// // // // // //                         borderRadius: BorderRadius.circular(20),
// // // // // //                         onTap: widget.onTapFavorite,
// // // // // //                         child: Padding(
// // // // // //                           padding: const EdgeInsets.all(7.0),
// // // // // //                           child: ScaleTransition(
// // // // // //                             scale: _favoriteScaleAnimation,
// // // // // //                             child: Icon(
// // // // // //                               widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
// // // // // //                               color: widget.isFavorite ? Colors.pinkAccent[100] : Colors.white,
// // // // // //                               size: 22,
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   if (distance != null)
// // // // // //                     Positioned(
// // // // // //                       bottom: 6, left: 6,
// // // // // //                       child: Container(
// // // // // //                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// // // // // //                         decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
// // // // // //                         child: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //             Expanded(
// // // // // //               child: InkWell(
// // // // // //                 onTap: widget.onTapCard,
// // // // // //                 child: Padding(
// // // // // //                   padding: const EdgeInsets.all(10.0),
// // // // // //                   child: Column(
// // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // //                     children: [
// // // // // //                       Column(
// // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                         mainAxisSize: MainAxisSize.min,
// // // // // //                         children: [
// // // // // //                           Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
// // // // // //                           const SizedBox(height: 4),
// // // // // //                           Row(children: [
// // // // // //                             Icon(Icons.sports_kabaddi_outlined, size: 14, color: theme.colorScheme.secondary),
// // // // // //                             const SizedBox(width: 4),
// // // // // //                             Expanded(child: Text(sport, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// // // // // //                           ]),
// // // // // //                           if (reviewCount > 0)
// // // // // //                             Padding(
// // // // // //                                padding: const EdgeInsets.only(top: 5.0),
// // // // // //                                child: Row(children: [
// // // // // //                                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
// // // // // //                                 const SizedBox(width: 4),
// // // // // //                                 Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
// // // // // //                                 const SizedBox(width: 4),
// // // // // //                                 Text("($reviewCount reviews)", style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
// // // // // //                               ]),
// // // // // //                              ),
// // // // // //                         ],
// // // // // //                       ),
// // // // // //                       Row(
// // // // // //                         children: [
// // // // // //                           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
// // // // // //                           const SizedBox(width: 4),
// // // // // //                           Expanded(child: Text(city, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// // // // // //                         ],
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }


// // // // // // // --- VenueSearchDelegate Class (Kept from your provided code) ---
// // // // // // class VenueSearchDelegate extends SearchDelegate<String?> {
// // // // // //   final FirestoreService firestoreService;
// // // // // //   final String? initialCityFilter;

// // // // // //   Timer? _debounce;
// // // // // //   Future<List<Map<String, dynamic>>>? _suggestionFuture;
// // // // // //   String _currentFetchingSuggestionQuery = "";

// // // // // //   VenueSearchDelegate({
// // // // // //     required this.firestoreService,
// // // // // //     this.initialCityFilter,
// // // // // //   }) : super(
// // // // // //           searchFieldLabel: initialCityFilter != null
// // // // // //               ? 'Search in $initialCityFilter...'
// // // // // //               : 'Search venues...',
// // // // // //         );

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _debounce?.cancel();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   void _updateSuggestionFuture(BuildContext delegateContext, String currentQuery) {
// // // // // //     if (currentQuery.isEmpty) {
// // // // // //       if (_suggestionFuture != null || _currentFetchingSuggestionQuery.isNotEmpty) {
// // // // // //         _currentFetchingSuggestionQuery = "";
// // // // // //         _suggestionFuture = Future.value([]);
// // // // // //         if(WidgetsBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
// // // // // //            WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // //               if(delegateContext.mounted) super.showSuggestions(delegateContext);
// // // // // //            });
// // // // // //         } else {
// // // // // //            if(delegateContext.mounted) super.showSuggestions(delegateContext);
// // // // // //         }
// // // // // //       }
// // // // // //       return;
// // // // // //     }

// // // // // //     if (currentQuery != _currentFetchingSuggestionQuery || _suggestionFuture == null) {
// // // // // //       _currentFetchingSuggestionQuery = currentQuery;
// // // // // //       _suggestionFuture = firestoreService.getVenues(
// // // // // //         searchQuery: currentQuery,
// // // // // //         cityFilter: initialCityFilter,
// // // // // //         limit: 700,
// // // // // //         forSuggestions: true,
// // // // // //       );
// // // // // //         if(WidgetsBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
// // // // // //            WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // //              if(delegateContext.mounted) super.showSuggestions(delegateContext);
// // // // // //            });
// // // // // //         } else {
// // // // // //            if(delegateContext.mounted) super.showSuggestions(delegateContext);
// // // // // //         }
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   void showSuggestions(BuildContext context) {
// // // // // //     super.showSuggestions(context);
// // // // // //     _debounce?.cancel();
// // // // // //     _debounce = Timer(const Duration(milliseconds: 350), () {
// // // // // //       final String trimmedQuery = query.trim();
// // // // // //       _updateSuggestionFuture(context, trimmedQuery);
// // // // // //     });
// // // // // //   }

// // // // // //   @override
// // // // // //   ThemeData appBarTheme(BuildContext context) {
// // // // // //     final theme = Theme.of(context);
// // // // // //     final Color primaryColor = theme.primaryColor;
// // // // // //     final Color appBarFgColor = theme.colorScheme.onPrimary;

// // // // // //     return theme.copyWith(
// // // // // //       primaryColor: primaryColor,
// // // // // //       scaffoldBackgroundColor: theme.canvasColor,
// // // // // //       appBarTheme: theme.appBarTheme.copyWith(
// // // // // //         backgroundColor: primaryColor,
// // // // // //         elevation: 1.0,
// // // // // //         iconTheme: IconThemeData(color: appBarFgColor),
// // // // // //         actionsIconTheme: IconThemeData(color: appBarFgColor),
// // // // // //         titleTextStyle:
// // // // // //             theme.textTheme.titleLarge?.copyWith(color: appBarFgColor),
// // // // // //         toolbarTextStyle:
// // // // // //             theme.textTheme.bodyMedium?.copyWith(color: appBarFgColor),
// // // // // //       ),
// // // // // //       inputDecorationTheme: InputDecorationTheme(
// // // // // //         hintStyle: theme.textTheme.titleMedium
// // // // // //             ?.copyWith(color: appBarFgColor.withOpacity(0.7)),
// // // // // //         border: InputBorder.none,
// // // // // //       ),
// // // // // //       textSelectionTheme: TextSelectionThemeData(
// // // // // //           cursorColor: appBarFgColor,
// // // // // //           selectionColor: appBarFgColor.withOpacity(0.3),
// // // // // //           selectionHandleColor: appBarFgColor),
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   List<Widget>? buildActions(BuildContext context) {
// // // // // //     return [
// // // // // //       if (query.isNotEmpty)
// // // // // //         IconButton(
// // // // // //           icon: const Icon(Icons.search_outlined),
// // // // // //           tooltip: 'Search',
// // // // // //           onPressed: () {
// // // // // //             if (query.trim().isNotEmpty) {
// // // // // //               close(context, query.trim());
// // // // // //             }
// // // // // //           },
// // // // // //         ),
// // // // // //       if (query.isNotEmpty)
// // // // // //         IconButton(
// // // // // //           icon: const Icon(Icons.clear_rounded),
// // // // // //           tooltip: 'Clear',
// // // // // //           onPressed: () {
// // // // // //             query = '';
// // // // // //           },
// // // // // //         ),
// // // // // //     ];
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget? buildLeading(BuildContext context) {
// // // // // //     return IconButton(
// // // // // //       icon: const Icon(Icons.arrow_back_ios_new_rounded),
// // // // // //       tooltip: 'Back',
// // // // // //       onPressed: () {
// // // // // //         close(context, null);
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget buildResults(BuildContext context) {
// // // // // //     final trimmedQuery = query.trim();

// // // // // //     if (trimmedQuery.isEmpty) {
// // // // // //       return _buildInfoWidget("Please enter a search term.");
// // // // // //     }

// // // // // //     debugPrint("VenueSearchDelegate: Building results for '$trimmedQuery'");

// // // // // //     return FutureBuilder<List<Map<String, dynamic>>>(
// // // // // //       future: firestoreService.getVenues(
// // // // // //         searchQuery: trimmedQuery,
// // // // // //         cityFilter: initialCityFilter,
// // // // // //       ),
// // // // // //       builder: (context, snapshot) {
// // // // // //         if (snapshot.connectionState == ConnectionState.waiting) {
// // // // // //           return const Center(child: CircularProgressIndicator());
// // // // // //         }
// // // // // //         if (snapshot.hasError) {
// // // // // //           debugPrint("SearchDelegate Results Error: ${snapshot.error}");
// // // // // //           return _buildErrorWidget(
// // // // // //               "Error searching venues. Please try again.");
// // // // // //         }
// // // // // //         if (!snapshot.hasData || snapshot.data!.isEmpty) {
// // // // // //           return _buildNoResultsWidget();
// // // // // //         }

// // // // // //         final results = snapshot.data!;
// // // // // //         return ListView.builder(
// // // // // //           itemCount: results.length,
// // // // // //           itemBuilder: (context, index) {
// // // // // //             final venue = results[index];
// // // // // //             return _buildVenueListTileForResult(context, venue);
// // // // // //           },
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget buildSuggestions(BuildContext context) {
// // // // // //     final currentQuery = query.trim();

// // // // // //     if (currentQuery.isEmpty) {
// // // // // //          return _buildInfoWidget("Start typing to search for venues...");
// // // // // //     }

// // // // // //     if (_suggestionFuture == null || _currentFetchingSuggestionQuery != currentQuery) {
// // // // // //         if (_debounce?.isActive ?? false) { 
// // // // // //              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
// // // // // //         }
// // // // // //         return const Center(child: CircularProgressIndicator(strokeWidth: 2));
// // // // // //     }

// // // // // //     return FutureBuilder<List<Map<String, dynamic>>>(
// // // // // //       future: _suggestionFuture,
// // // // // //       builder: (context, snapshot) {
// // // // // //         if (snapshot.connectionState == ConnectionState.waiting && currentQuery.isNotEmpty) {
// // // // // //           return const Center(child: CircularProgressIndicator(strokeWidth: 2));
// // // // // //         }
// // // // // //         if (snapshot.hasError) {
// // // // // //           debugPrint("Suggestion Error: ${snapshot.error}");
// // // // // //           return _buildErrorWidget("Could not load suggestions.");
// // // // // //         }

// // // // // //         if (!snapshot.hasData || snapshot.data!.isEmpty) {
// // // // // //              return _buildInfoWidget('No suggestions for "$currentQuery".');
// // // // // //         }

// // // // // //         final suggestions = snapshot.data!;
// // // // // //         return ListView.builder(
// // // // // //           itemCount: suggestions.length,
// // // // // //           itemBuilder: (context, index) {
// // // // // //             final venue = suggestions[index];
// // // // // //             return _buildSuggestionTile(context, venue);
// // // // // //           },
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }


// // // // // //   Widget _buildSuggestionTile(BuildContext context, Map<String, dynamic> venue) {
// // // // // //     final String name = venue['name'] as String? ?? 'No Name';
// // // // // //     final String city = venue['city'] as String? ?? '';
// // // // // //     return ListTile(
// // // // // //       leading: Icon(Icons.search_outlined, color: Theme.of(context).hintColor),
// // // // // //       title: Text(name),
// // // // // //       subtitle: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis),
// // // // // //       onTap: () {
// // // // // //         query = name;
// // // // // //         close(context, name);
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildVenueListTileForResult(
// // // // // //       BuildContext context, Map<String, dynamic> venue) {
// // // // // //     final String name = venue['name'] as String? ?? 'No Name';
// // // // // //     final String city = venue['city'] as String? ?? '';
// // // // // //     final String address = venue['address'] as String? ?? '';
// // // // // //     final String venueId = venue['id'] as String;
// // // // // //     final List<String> sports =
// // // // // //         (venue['sportType'] as List<dynamic>?)?.whereType<String>().toList() ?? [];
// // // // // //     final String? imageUrl = venue['imageUrl'] as String?;
// // // // // //     final double rating = (venue['averageRating'] as num?)?.toDouble() ?? 0.0;

// // // // // //     return ListTile(
// // // // // //       leading: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
// // // // // //           ? CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 25, backgroundColor: Colors.grey[200])
// // // // // //           : CircleAvatar(child: Icon(Icons.sports_soccer_outlined, size: 20), radius: 25, backgroundColor: Colors.grey[200]),
// // // // // //       title: Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
// // // // // //       subtitle: Text("${sports.isNotEmpty ? sports.join(', ') : 'Venue'} - ${address.isNotEmpty ? '$address, ' : ''}$city", maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
// // // // // //       trailing: rating > 0 ? Row(mainAxisSize: MainAxisSize.min, children: [
// // // // // //                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
// // // // // //                 const SizedBox(width: 4),
// // // // // //                 Text(rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
// // // // // //               ]) : null,
// // // // // //       onTap: () {
// // // // // //         close(context, null); 
// // // // // //         WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // //           if (context.mounted) {
// // // // // //              Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(builder: (context) => VenueDetailScreen(venueId: venueId, initialVenueData: venue)));
// // // // // //           }
// // // // // //         });
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildNoResultsWidget() {
// // // // // //     return Center(
// // // // // //       child: Padding(
// // // // // //         padding: const EdgeInsets.all(20.0),
// // // // // //         child: Column(
// // // // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // // // //           children: [
// // // // // //             Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
// // // // // //             const SizedBox(height: 15),
// // // // // //             Text('No venues found matching "$query"${initialCityFilter != null ? ' in $initialCityFilter' : ''}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey[600])),
// // // // // //             const SizedBox(height: 10),
// // // // // //             const Text("Try different keywords or check spelling.", style: TextStyle(color: Colors.grey))
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildErrorWidget(String message) {
// // // // // //     return Center(
// // // // // //       child: Padding(
// // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // //         child: Column(
// // // // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // // // //           children: [
// // // // // //             const Icon(Icons.error_outline_rounded, color: Colors.red, size: 50),
// // // // // //             const SizedBox(height: 10),
// // // // // //             Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildInfoWidget(String message) {
// // // // // //     return Center(
// // // // // //       child: Padding(
// // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // //         child: Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // //-----------------------seperated search components from homescreen-----------------------
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // // import 'package:geolocator/geolocator.dart';
// // // // // import 'package:mm_associates/features/data/services/firestore_service.dart';
// // // // // import 'package:mm_associates/features/home/screens/venue_form.dart';
// // // // // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // // // // import 'package:mm_associates/features/user/services/user_service.dart';
// // // // // import 'package:mm_associates/core/services/location_service.dart';
// // // // // import 'package:mm_associates/features/profile/screens/profile_screen.dart';
// // // // // import 'venue_detail_screen.dart';
// // // // // import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// // // // // import 'dart:async';
// // // // // import 'package:shimmer/shimmer.dart';
// // // // // import 'city_selection_screen.dart' show CitySelectionScreen, CityInfo, kAppAllCities;

// // // // // // Import the new search components file
// // // // // import 'package:mm_associates/features/home/widgets/home_search_components.dart';

// // // // // class HomeScreen extends StatefulWidget {
// // // // //   const HomeScreen({super.key});

// // // // //   @override
// // // // //   State<HomeScreen> createState() => _HomeScreenState();
// // // // // }

// // // // // class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
// // // // //   final AuthService _authService = AuthService();
// // // // //   final FirestoreService _firestoreService = FirestoreService();
// // // // //   final LocationService _locationService = LocationService();
// // // // //   final UserService _userService = UserService();

// // // // //   // Search and Filter State
// // // // //   String? _searchQuery;
// // // // //   String? _selectedCityFilter;
// // // // //   IconData? _selectedCityIcon;
// // // // //   String? _selectedSportFilter;

// // // // //   // User State
// // // // //   User? _currentUser;
// // // // //   String? _userName;
// // // // //   String? _userProfilePicUrl;
// // // // //   bool _isLoadingName = true;

// // // // //   // Venue Data State
// // // // //   List<Map<String, dynamic>> _filteredVenues = [];
// // // // //   bool _isLoadingFilteredVenues = true;
// // // // //   String? _filteredVenueFetchError;

// // // // //   List<Map<String, dynamic>> _nearbyVenues = [];
// // // // //   bool _isLoadingNearbyVenues = true;
// // // // //   String? _nearbyVenueFetchError;

// // // // //   List<Map<String, dynamic>> _exploreVenues = [];
// // // // //   bool _isLoadingExploreVenues = true;
// // // // //   String? _exploreVenueFetchError;

// // // // //   // Location State
// // // // //   Position? _currentPosition;
// // // // //   bool _isFetchingLocation = false;
// // // // //   String? _locationStatusMessage;

// // // // //   // Favorite Venues State
// // // // //   List<String> _favoriteVenueIds = [];
// // // // //   bool _isLoadingFavorites = true;
// // // // //   Stream<List<String>>? _favoritesStream;
// // // // //   StreamSubscription<List<String>>? _favoritesSubscription;

// // // // //   // UI Helper data
// // // // //   final List<String> _supportedCities = ['Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'];
// // // // //   final List<String> _quickSportFilters = ['Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'];

// // // // //   // Getter to determine if we are in a search/filter mode
// // // // //   bool get _isSearchingOrFiltering => (_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _currentUser = FirebaseAuth.instance.currentUser;
// // // // //     _initializeScreen();
// // // // //     _setupFavoritesStream();
// // // // //     _updateSelectedCityIconFromFilter();
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _favoritesSubscription?.cancel();
// // // // //     super.dispose();
// // // // //   }

// // // // //   void setStateIfMounted(VoidCallback fn) {
// // // // //     if (mounted) setState(fn);
// // // // //   }

// // // // //   void _updateSelectedCityIconFromFilter() {
// // // // //     if (_selectedCityFilter == null) {
// // // // //       _selectedCityIcon = Icons.my_location; // Default "Near Me" icon
// // // // //     } else {
// // // // //       try {
// // // // //         final cityInfo = kAppAllCities.firstWhere(
// // // // //           (city) => city.name == _selectedCityFilter,
// // // // //         );
// // // // //         _selectedCityIcon = cityInfo.icon;
// // // // //       } catch (e) {
// // // // //         _selectedCityIcon = Icons.location_city_outlined;
// // // // //         debugPrint("HomeScreen initState: Selected city '$_selectedCityFilter' not found in kAppAllCities. Using fallback icon. Error: $e");
// // // // //       }
// // // // //     }
// // // // //   }
  
// // // // //   Future<void> _initializeScreen() async {
// // // // //     await _fetchUserNameAndPic();
// // // // //     await _fetchPrimaryVenueData();
// // // // //   }

// // // // //   Future<void> _fetchPrimaryVenueData() async {
// // // // //     if (!mounted) return;
// // // // //     setStateIfMounted(() {
// // // // //       _isFetchingLocation = true; _isLoadingNearbyVenues = true; _isLoadingExploreVenues = true;
// // // // //       _locationStatusMessage = 'Fetching your location...';
// // // // //       _nearbyVenues = []; _exploreVenues = [];
// // // // //       _nearbyVenueFetchError = null; _exploreVenueFetchError = null;
// // // // //     });
// // // // //     _currentPosition = await _locationService.getCurrentLocation();
// // // // //     if (!mounted) return;
// // // // //     setStateIfMounted(() {
// // // // //       _isFetchingLocation = false;
// // // // //       _locationStatusMessage = _currentPosition != null ? 'Location acquired.' : 'Could not get location.';
// // // // //     });
// // // // //     await Future.wait([_fetchNearbyVenuesScoped(), _fetchExploreVenuesFromOtherCities()]);
// // // // //   }

// // // // //   void _setupFavoritesStream() {
// // // // //     _favoritesSubscription?.cancel();
// // // // //     if (_currentUser != null) {
// // // // //         _favoritesStream = _userService.getFavoriteVenueIdsStream();
// // // // //         _favoritesSubscription = _favoritesStream?.listen(
// // // // //           (favoriteIds) {
// // // // //             if (mounted) {
// // // // //               final newIdsSet = favoriteIds.toSet();
// // // // //               final currentIdsSet = _favoriteVenueIds.toSet();
// // // // //               if (newIdsSet.difference(currentIdsSet).isNotEmpty || currentIdsSet.difference(newIdsSet).isNotEmpty) {
// // // // //                 setStateIfMounted(() {
// // // // //                   _favoriteVenueIds = favoriteIds;
// // // // //                 });
// // // // //               }
// // // // //             }
// // // // //           },
// // // // //           onError: (error) {
// // // // //             debugPrint("Error in favorites stream: $error");
// // // // //              if (mounted) {
// // // // //                 ScaffoldMessenger.of(context).showSnackBar(
// // // // //                     const SnackBar(content: Text("Could not update favorites."),
// // // // //                     backgroundColor: Colors.orangeAccent,
// // // // //                     behavior: SnackBarBehavior.floating)
// // // // //                 );
// // // // //              }
// // // // //           }
// // // // //         );
// // // // //         if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);
// // // // //     } else {
// // // // //       if (mounted) {
// // // // //          setStateIfMounted(() {
// // // // //            _favoriteVenueIds = [];
// // // // //            _isLoadingFavorites = false;
// // // // //            _favoritesStream = null;
// // // // //            _favoritesSubscription = null;
// // // // //          });
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   void didChangeDependencies() {
// // // // //     super.didChangeDependencies();
// // // // //     final currentAuthUser = FirebaseAuth.instance.currentUser;
// // // // //     if (currentAuthUser != _currentUser) {
// // // // //       _currentUser = currentAuthUser;
// // // // //       _initializeScreen();
// // // // //       _setupFavoritesStream();
// // // // //       if (mounted) {
// // // // //         setStateIfMounted(() {
// // // // //           _updateSelectedCityIconFromFilter();
// // // // //         });
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   Future<void> _fetchVenuesForFilterOrSearch({String? newSearchQuery}) async {
// // // // //     if (!mounted) return;
// // // // //     setStateIfMounted(() {
// // // // //       _isLoadingFilteredVenues = true;
// // // // //       _filteredVenueFetchError = null;
// // // // //       _filteredVenues = [];
// // // // //     });

// // // // //     try {
// // // // //       debugPrint("Fetching FILTERED/SEARCH venues: City: $_selectedCityFilter, Sport: $_selectedSportFilter, Search: $newSearchQuery, Location: $_currentPosition");
// // // // //       final venuesData = await _firestoreService.getVenues(
// // // // //         userLocation: _currentPosition,
// // // // //         radiusInKm: _selectedCityFilter != null ? null : (_currentPosition != null ? 50.0 : null),
// // // // //         cityFilter: _selectedCityFilter,
// // // // //         searchQuery: newSearchQuery,
// // // // //         sportFilter: _selectedSportFilter,
// // // // //       );
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() {
// // // // //           _filteredVenues = venuesData;
// // // // //         });
// // // // //     } catch (e) {
// // // // //       debugPrint("Error fetching filtered/search venues: $e");
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() => _filteredVenueFetchError = "Could not load venues: ${e.toString().replaceFirst('Exception: ', '')}");
// // // // //     } finally {
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() => _isLoadingFilteredVenues = false);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _fetchNearbyVenuesScoped() async {
// // // // //     if (!mounted) return;
// // // // //     if (_currentPosition == null) {
// // // // //       if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = false; _nearbyVenueFetchError = "Location not available."; _nearbyVenues = []; });
// // // // //       return;
// // // // //     }
// // // // //     if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = true; _nearbyVenueFetchError = null; _nearbyVenues = []; });
// // // // //     try {
// // // // //       final venuesData = await _firestoreService.getVenues(userLocation: _currentPosition, radiusInKm: 25.0);
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() {
// // // // //         _nearbyVenues = venuesData;
// // // // //       });
// // // // //     } catch (e) {
// // // // //       debugPrint("Error fetching nearby venues: $e");
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() => _nearbyVenueFetchError = "Could not load nearby venues.");
// // // // //     } finally {
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() => _isLoadingNearbyVenues = false);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _fetchExploreVenuesFromOtherCities() async {
// // // // //     if (!mounted) return;
// // // // //     setStateIfMounted(() { _isLoadingExploreVenues = true; _exploreVenueFetchError = null; _exploreVenues = [];});
// // // // //     List<Map<String, dynamic>> allExploreVenues = [];
// // // // //     try {
// // // // //       for (String city in _supportedCities) {
// // // // //         final cityVenues = await _firestoreService.getVenues(cityFilter: city, userLocation: _currentPosition, limit: 5);
// // // // //         allExploreVenues.addAll(cityVenues);
// // // // //         if (!mounted) return;
// // // // //       }
// // // // //       final uniqueExploreVenues = allExploreVenues.fold<Map<String, Map<String, dynamic>>>({}, (map, venue) {
// // // // //           final String? venueId = venue['id'] as String?;
// // // // //           if (venueId != null) map[venueId] = venue;
// // // // //           return map;
// // // // //         }).values.toList();

// // // // //       if (_currentPosition != null) {
// // // // //         uniqueExploreVenues.sort((a, b) {
// // // // //           final distA = a['distance'] as double?; final distB = b['distance'] as double?;
// // // // //           if (distA != null && distB != null) return distA.compareTo(distB);
// // // // //           if (distA != null) return -1;
// // // // //           if (distB != null) return 1;
// // // // //           return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
// // // // //         });
// // // // //       } else {
// // // // //          uniqueExploreVenues.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
// // // // //       }
// // // // //       if(!mounted) return;
// // // // //       setStateIfMounted(() {
// // // // //         _exploreVenues = uniqueExploreVenues.take(15).toList();
// // // // //       });
// // // // //     } catch (e) {
// // // // //       debugPrint("Error fetching explore venues: $e");
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() => _exploreVenueFetchError = "Could not load explore venues.");
// // // // //     } finally {
// // // // //       if (!mounted) return;
// // // // //       setStateIfMounted(() => _isLoadingExploreVenues = false);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _fetchUserNameAndPic() async {
// // // // //     _setLoadingName(true); final currentUser = _currentUser;
// // // // //     if (currentUser == null) { if(mounted) _updateUserNameAndPic('Guest', null); _setLoadingName(false); return; }
// // // // //     try {
// // // // //       final userData = await _userService.getUserProfileData();
// // // // //       if (!mounted) return;
// // // // //       final fetchedName = userData?['name'] as String? ?? currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// // // // //       final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
// // // // //       _updateUserNameAndPic(fetchedName, fetchedPicUrl);
// // // // //     } catch (e) {
// // // // //       debugPrint("Error fetching user name/pic via UserService: $e"); if (!mounted) return;
// // // // //       final fallbackName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// // // // //       _updateUserNameAndPic(fallbackName, null);
// // // // //     } finally { if(mounted) _setLoadingName(false); }
// // // // //   }

// // // // //   void _setLoadingName(bool isLoading) => {if(mounted) setStateIfMounted(() => _isLoadingName = isLoading)};
// // // // //   void _updateUserNameAndPic(String name, String? picUrl) => {if(mounted) setStateIfMounted(() { _userName = name; _userProfilePicUrl = picUrl; })};

// // // // //   Future<void> _handleRefresh() async {
// // // // //     if(mounted) {
// // // // //       setStateIfMounted(() {
// // // // //           _searchQuery = null;
// // // // //           _selectedSportFilter = null;
// // // // //       });
// // // // //     }
// // // // //     // _onFilterOrSearchChanged handles both filter/search and default views
// // // // //     _onFilterOrSearchChanged();
// // // // //   }

// // // // //   void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
// // // // //     // If an explicit query is passed (from search bar), use it.
// // // // //     // Otherwise, use the existing state _searchQuery (e.g., when a filter changes).
// // // // //     final newSearchQuery = explicitSearchQuery ?? _searchQuery;

// // // // //     // Use a local variable to prevent race conditions with setState
// // // // //     bool queryChanged = _searchQuery != newSearchQuery;

// // // // //     if (mounted) {
// // // // //       setStateIfMounted(() {
// // // // //         // Always update the search query state.
// // // // //         _searchQuery = newSearchQuery;
// // // // //       });
// // // // //     }

// // // // //     if ((_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null) {
// // // // //         _fetchVenuesForFilterOrSearch(newSearchQuery: _searchQuery);
// // // // //     } else {
// // // // //         // If we are clearing all filters/search, fetch the primary data.
// // // // //         _fetchPrimaryVenueData();
// // // // //     }

// // // // //     // Unfocus on web if a new search was submitted
// // // // //     if (kIsWeb && queryChanged) {
// // // // //       FocusScope.of(context).unfocus();
// // // // //     }
// // // // //   }

// // // // //   Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
// // // // //       if (!context.mounted) return;
// // // // //       return showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext dialogContext) {
// // // // //           return AlertDialog(title: const Text('Confirm Logout'), content: const SingleChildScrollView(child: ListBody(children: <Widget>[Text('Are you sure you want to sign out?')])),
// // // // //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
// // // // //             actions: <Widget>[
// // // // //               TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
// // // // //               TextButton(child: const Text('Logout', style: TextStyle(color: Colors.red)), onPressed: () async {
// // // // //                   Navigator.of(dialogContext).pop(); try { await _authService.signOut();
// // // // //                    } catch (e) {
// // // // //                     debugPrint("Error during sign out: $e"); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(10)));
// // // // //                   }},), ],); },);
// // // // //     }

// // // // //   void _navigateToVenueDetail(Map<String, dynamic> venue) {
// // // // //     if (!context.mounted) return;
// // // // //     Navigator.push(context, MaterialPageRoute(builder: (context) => VenueDetailScreen(venueId: venue['id'] as String, initialVenueData: venue))).then((_) {
// // // // //     });
// // // // //   }

// // // // //   void _openSearchMobile() async {
// // // // //      if (!context.mounted) return;
// // // // //      final String? submittedQuery = await showSearch<String?>(
// // // // //         context: context,
// // // // //         delegate: VenueSearchDelegate(
// // // // //             firestoreService: _firestoreService,
// // // // //             initialCityFilter: _selectedCityFilter,
// // // // //         )
// // // // //     );
// // // // //     if (submittedQuery != null && submittedQuery.isNotEmpty) {
// // // // //         _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
// // // // //     }
// // // // //   }

// // // // //   Future<void> _openCitySelectionScreen() async {
// // // // //     if (!mounted) return;
// // // // //     final String? newSelectedCityName = await Navigator.push<String?>(
// // // // //       context,
// // // // //       MaterialPageRoute(
// // // // //         builder: (context) => CitySelectionScreen(currentSelectedCity: _selectedCityFilter),
// // // // //       ),
// // // // //     );

// // // // //     if (mounted) {
// // // // //       if (newSelectedCityName != _selectedCityFilter) {
// // // // //         setStateIfMounted(() {
// // // // //           _selectedCityFilter = newSelectedCityName; 
// // // // //           _updateSelectedCityIconFromFilter(); 
// // // // //         });
// // // // //         _onFilterOrSearchChanged(); 
// // // // //       } else {
// // // // //         IconData currentExpectedIcon = Icons.location_city_outlined; 
// // // // //         if (_selectedCityFilter == null) {
// // // // //             currentExpectedIcon = Icons.my_location;
// // // // //         } else {
// // // // //             try {
// // // // //                 final cityInfo = kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
// // // // //                 currentExpectedIcon = cityInfo.icon;
// // // // //             } catch (e) {
// // // // //                 debugPrint("Error re-validating icon for city '$_selectedCityFilter': $e. Using fallback.");
// // // // //             }
// // // // //         }
// // // // //         if (_selectedCityIcon != currentExpectedIcon) {
// // // // //             setStateIfMounted(() {
// // // // //               _selectedCityIcon = currentExpectedIcon;
// // // // //             });
// // // // //         }
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = Theme.of(context);
// // // // //     final appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
// // // // //     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ?? theme.appBarTheme.iconTheme?.color ?? (kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white);
// // // // //     final bool isLoggedIn = _currentUser != null;

// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         automaticallyImplyLeading: false,
// // // // //         title: kIsWeb ? _buildWebAppBarTitle(context) : _buildMobileAppBarTitle(context, theme),
// // // // //         actions: kIsWeb ? _buildWebAppBarActions(context, isLoggedIn, actionsIconColor) : _buildMobileAppBarActions(context, isLoggedIn, actionsIconColor),
// // // // //         backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
// // // // //         elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
// // // // //         iconTheme: theme.iconTheme.copyWith(color: kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white),
// // // // //         actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
// // // // //         titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ?? TextStyle(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
// // // // //       ),
// // // // //       floatingActionButton: FloatingActionButton.extended(
// // // // //         onPressed: () {
// // // // //           Navigator.push(
// // // // //             context,
// // // // //             MaterialPageRoute(builder: (context) => const AddVenueFormScreen()),
// // // // //           ).then((result) {
// // // // //             if (result == true && mounted) {
// // // // //               _handleRefresh();
// // // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // // //                 const SnackBar(content: Text("Venue list updated."), backgroundColor: Colors.blueAccent),
// // // // //               );
// // // // //             }
// // // // //           });
// // // // //         },
// // // // //         icon: const Icon(Icons.add_location_alt_outlined),
// // // // //         label: const Text("Add Venue"),
// // // // //         tooltip: 'Add New Venue',
// // // // //       ),
// // // // //       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
// // // // //       body: _buildBodyContent(),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
// // // // //     final titleStyle = theme.appBarTheme.titleTextStyle ?? theme.primaryTextTheme.titleLarge ?? const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
// // // // //     final currentUser = _currentUser;
// // // // //     return Row(children: [
// // // // //         if (currentUser != null)
// // // // //           GestureDetector(
// // // // //             onTap: () {
// // // // //               if (!context.mounted) return;
// // // // //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // //                   .then((_) { if (mounted) _fetchUserNameAndPic(); });
// // // // //             },
// // // // //             child: Tooltip(
// // // // //               message: "My Profile",
// // // // //               child: Padding(
// // // // //                 padding: const EdgeInsets.only(right: 10.0),
// // // // //                 child: CircleAvatar(
// // // // //                   radius: 18,
// // // // //                   backgroundColor: Colors.white24,
// // // // //                   backgroundImage: _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty ? NetworkImage(_userProfilePicUrl!) : null,
// // // // //                   child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty ? Icon(Icons.person_outline, size: 20, color: Colors.white.withOpacity(0.8)) : null
// // // // //                 )
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         if (_isLoadingName && currentUser != null)
// // // // //           const Padding(
// // // // //             padding: EdgeInsets.only(left: 6.0),
// // // // //             child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)))
// // // // //           )
// // // // //         else if (_userName != null && currentUser != null)
// // // // //           Expanded(
// // // // //             child: Padding(
// // // // //                padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
// // // // //               child: Text(
// // // // //                 'Hi, ${_userName!.split(' ')[0]}!',
// // // // //                 style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
// // // // //                 overflow: TextOverflow.ellipsis
// // // // //               )
// // // // //             )
// // // // //           )
// // // // //         else
// // // // //           Text('MM Associates', style: titleStyle),
// // // // //       ]
// // // // //     );
// // // // //   }
  
// // // // //   List<Widget> _buildMobileAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // // //     final String cityNameText = _selectedCityFilter ?? 'Near Me';
// // // // //     final double textSize = 10.0; 

// // // // //     return [
// // // // //       IconButton(
// // // // //         icon: Icon(Icons.search_outlined, color: iconColor),
// // // // //         tooltip: 'Search Venues',
// // // // //         onPressed: _openSearchMobile,
// // // // //         padding: const EdgeInsets.symmetric(horizontal: 8),
// // // // //         constraints: const BoxConstraints(),
// // // // //       ),
// // // // //       Tooltip( 
// // // // //         message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // // //         child: IconButton(
// // // // //           icon: Column(
// // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // //             mainAxisSize: MainAxisSize.min,
// // // // //             children: [
// // // // //               Icon(
// // // // //                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // // //                 color: iconColor,
// // // // //                 size: 24,
// // // // //               ),
// // // // //               const SizedBox(height: 2), 
// // // // //               Text(
// // // // //                 cityNameText,
// // // // //                 style: TextStyle(
// // // // //                   color: iconColor,
// // // // //                   fontSize: textSize,
// // // // //                   fontWeight: FontWeight.w500,
// // // // //                 ),
// // // // //                 overflow: TextOverflow.ellipsis,
// // // // //                 maxLines: 1,
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           onPressed: _openCitySelectionScreen,
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
// // // // //           constraints: const BoxConstraints(),
// // // // //         ),
// // // // //       ),
// // // // //       if (isLoggedIn)
// // // // //         IconButton(
// // // // //           icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // // //           tooltip: 'My Profile',
// // // // //           onPressed: () {
// // // // //             if (!context.mounted) return;
// // // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // //                 .then((_) {
// // // // //               if (mounted) _fetchUserNameAndPic();
// // // // //             });
// // // // //           },
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 8),
// // // // //           constraints: const BoxConstraints(),
// // // // //         ),
// // // // //     ];
// // // // //   }

// // // // //   Widget _buildWebAppBarTitle(BuildContext context) {
// // // // //     final theme = Theme.of(context);
// // // // //     final currentUser = _currentUser;
// // // // //     double screenWidth = MediaQuery.of(context).size.width;
// // // // //     double leadingWidth = 150 + (_userName != null ? 100 : 0);
// // // // //     double searchWidthFraction = 0.4;
// // // // //     double minSearchWidth = 200;
// // // // //     double maxSearchWidth = 500;
// // // // //     double actionsWidth = 80 + (_currentUser != null ? 120 : 0);
// // // // //     double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
// // // // //     double calculatedSearchWidth = (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);
// // // // //     double spacerFlexFactor = (availableWidth > calculatedSearchWidth + 40)
// // // // //         ? (availableWidth - calculatedSearchWidth) / 2 / availableWidth
// // // // //         : 0.05;
// // // // //     int searchFlex = (searchWidthFraction * 100).toInt();
// // // // //     int spacerFlex = (spacerFlexFactor * 100).toInt().clamp(5, 50);

// // // // //     return Row(children: [
// // // // //       Text('MM Associates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
// // // // //       const SizedBox(width: 24),
// // // // //       if (_isLoadingName && currentUser != null)
// // // // //         const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
// // // // //       else if (_userName != null && currentUser != null)
// // // // //         Padding(
// // // // //           padding: const EdgeInsets.only(right: 16.0),
// // // // //           child: Text('Hi, ${_userName!.split(' ')[0]}!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)
// // // // //         ),
// // // // //       Spacer(flex: spacerFlex),
// // // // //       Expanded(
// // // // //         flex: searchFlex,
// // // // //         child: Container(
// // // // //           constraints: BoxConstraints(maxWidth: maxSearchWidth),
// // // // //           child: WebSearchBar(
// // // // //             key: ValueKey(_searchQuery), // Helps re-render if needed, though props handle state
// // // // //             initialValue: _searchQuery ?? '',
// // // // //             cityFilter: _selectedCityFilter,
// // // // //             firestoreService: _firestoreService,
// // // // //             onSearchSubmitted: (query) {
// // // // //               if (query.trim().isNotEmpty) {
// // // // //                 _onFilterOrSearchChanged(explicitSearchQuery: query.trim());
// // // // //               }
// // // // //             },
// // // // //             onSuggestionSelected: (suggestionName) {
// // // // //               _onFilterOrSearchChanged(explicitSearchQuery: suggestionName);
// // // // //             },
// // // // //             onClear: () {
// // // // //               _onFilterOrSearchChanged(explicitSearchQuery: null);
// // // // //             },
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //       Spacer(flex: spacerFlex),
// // // // //     ]);
// // // // //   }

// // // // //   List<Widget> _buildWebAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // // //     final String cityNameText = _selectedCityFilter ?? 'Near Me';
// // // // //     final double textSize = 10.0;

// // // // //     return [
// // // // //       Tooltip(
// // // // //         message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // // //         child: IconButton(
// // // // //           icon: Column(
// // // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // // //             mainAxisSize: MainAxisSize.min,
// // // // //             children: [
// // // // //               Icon(
// // // // //                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // // //                 color: iconColor,
// // // // //                 size: 24,
// // // // //               ),
// // // // //               const SizedBox(height: 2),
// // // // //               Text(
// // // // //                 cityNameText,
// // // // //                 style: TextStyle(
// // // // //                   color: iconColor,
// // // // //                   fontSize: textSize,
// // // // //                   fontWeight: FontWeight.w500,
// // // // //                 ),
// // // // //                 overflow: TextOverflow.ellipsis,
// // // // //                 maxLines: 1,
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           onPressed: _openCitySelectionScreen,
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
// // // // //           constraints: const BoxConstraints(),
// // // // //         ),
// // // // //       ),
// // // // //       if (isLoggedIn)
// // // // //         Tooltip(
// // // // //           message: 'My Profile',
// // // // //           child: IconButton(
// // // // //             icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // // //             onPressed: () {
// // // // //               if (!context.mounted) return;
// // // // //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // // //                   .then((_) {
// // // // //                 if (mounted) _fetchUserNameAndPic();
// // // // //               });
// // // // //             },
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // //             constraints: const BoxConstraints(),
// // // // //           ),
// // // // //         ),
// // // // //       const SizedBox(width: 8)
// // // // //     ];
// // // // //   }

// // // // //   Widget _buildQuickSportFilters() {
// // // // //     if (_quickSportFilters.isEmpty) return const SizedBox.shrink();
// // // // //     final theme = Theme.of(context);
// // // // //     return Container(
// // // // //       height: 55,
// // // // //       color: theme.cardColor,
// // // // //       child: ListView.separated(
// // // // //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// // // // //         scrollDirection: Axis.horizontal,
// // // // //         itemCount: _quickSportFilters.length + 1,
// // // // //         separatorBuilder: (context, index) => const SizedBox(width: 10),
// // // // //         itemBuilder: (context, index) {
// // // // //           if (index == 0) {
// // // // //             final bool isSelected = _selectedSportFilter == null;
// // // // //             return ChoiceChip(
// // // // //               label: const Text('All Sports'),
// // // // //               selected: isSelected,
// // // // //               onSelected: (bool nowSelected) {
// // // // //                 if (nowSelected && _selectedSportFilter != null) {
// // // // //                     setStateIfMounted(() => _selectedSportFilter = null);
// // // // //                     _onFilterOrSearchChanged();
// // // // //                 }
// // // // //               },
// // // // //               selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// // // // //               backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// // // // //               labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// // // // //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// // // // //               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// // // // //               visualDensity: VisualDensity.compact,
// // // // //                showCheckmark: false,
// // // // //             );
// // // // //           }
// // // // //           final sport = _quickSportFilters[index - 1];
// // // // //           final bool isSelected = _selectedSportFilter == sport;
// // // // //           return ChoiceChip(
// // // // //             label: Text(sport),
// // // // //             selected: isSelected,
// // // // //             onSelected: (bool isNowSelected) {
// // // // //               String? newFilterValue = isNowSelected ? sport : null;
// // // // //               if (_selectedSportFilter != newFilterValue) {
// // // // //                 setStateIfMounted(() { _selectedSportFilter = newFilterValue; });
// // // // //                 _onFilterOrSearchChanged();
// // // // //               }
// // // // //             },
// // // // //             selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// // // // //             backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// // // // //             labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// // // // //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// // // // //             visualDensity: VisualDensity.compact,
// // // // //             showCheckmark: false,
// // // // //           );
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildSectionHeader(BuildContext context, String title) {
// // // // //     return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
// // // // //       child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
// // // // //   }

// // // // //   Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg, String emptyMsg, {bool isNearbySection = false}) {
// // // // //      if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
// // // // //      if (errorMsg != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16))));
// // // // //      if (venues.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

// // // // //      return GridView.builder(
// // // // //        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// // // // //        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
// // // // //        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// // // // //            maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
// // // // //            mainAxisSpacing: 16.0,
// // // // //            crossAxisSpacing: 16.0,
// // // // //            childAspectRatio: 0.70
// // // // //         ),
// // // // //        itemCount: venues.length,
// // // // //        itemBuilder: (context, index) {
// // // // //          final venue = venues[index];
// // // // //          final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
// // // // //          return _buildVenueGridCard(venue, isFavorite: isFavorite);
// // // // //        },
// // // // //      );
// // // // //    }

// // // // //   Widget _buildBodyContent() {
// // // // //      return Column(children: [
// // // // //          _buildQuickSportFilters(),
// // // // //          Expanded(
// // // // //            child: RefreshIndicator(
// // // // //              onRefresh: _handleRefresh,
// // // // //              child: ListView(
// // // // //                padding: EdgeInsets.zero,
// // // // //                children: [
// // // // //                  if (_isSearchingOrFiltering) ...[
// // // // //                    _buildSectionHeader(context,
// // // // //                         _searchQuery != null && _searchQuery!.isNotEmpty
// // // // //                             ? "Results for \"$_searchQuery\""
// // // // //                             : (_selectedCityFilter != null
// // // // //                                 ? "Venues in $_selectedCityFilter"
// // // // //                                 : (_selectedSportFilter != null ? "Venues for $_selectedSportFilter" : "Filtered Venues")
// // // // //                             )
// // // // //                     ),
// // // // //                    _buildVenueList(_filteredVenues, _isLoadingFilteredVenues, _filteredVenueFetchError, "No venues found for your selection.", isNearbySection: false),
// // // // //                  ] else ...[
// // // // //                    if (_currentPosition != null || _isLoadingNearbyVenues)
// // // // //                        _buildSectionHeader(context, "Venues Near You"),
// // // // //                    _buildVenueList(_nearbyVenues, _isLoadingNearbyVenues, _nearbyVenueFetchError, "No venues found nearby. Try exploring other cities or check location permissions.", isNearbySection: true),

// // // // //                    const SizedBox(height: 16),
// // // // //                    _buildSectionHeader(context, "Explore Venues"),
// // // // //                    _buildVenueList(_exploreVenues, _isLoadingExploreVenues, _exploreVenueFetchError, "No venues to explore at the moment.", isNearbySection: false),
// // // // //                   ],
// // // // //                  const SizedBox(height: 80),
// // // // //                ],
// // // // //              ),
// // // // //            ),
// // // // //          ),
// // // // //        ]
// // // // //      );
// // // // //   }

// // // // //   Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
// // // // //     return Shimmer.fromColors(baseColor: Colors.grey[350]!, highlightColor: Colors.grey[200]!,
// // // // //       child: GridView.builder(
// // // // //         shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// // // // //         padding: const EdgeInsets.all(16.0),
// // // // //         gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0, mainAxisSpacing: 16.0, crossAxisSpacing: 16.0, childAspectRatio: 0.70),
// // // // //         itemCount: itemCount, itemBuilder: (context, index) => _buildVenueShimmerCard())
// // // // //       );
// // // // //   }
// // // // //   Widget _buildVenueShimmerCard() {
// // // // //     return Card(
// // // // //       margin: EdgeInsets.zero, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
// // // // //       child: Column(children: [
// // // // //         Container(height: 130, width: double.infinity, color: Colors.white),
// // // // //         Expanded(child: Padding(padding: const EdgeInsets.all(10.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// // // // //           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// // // // //             Container(width: double.infinity, height: 18.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// // // // //             Container(width: MediaQuery.of(context).size.width * 0.3, height: 14.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// // // // //             Container(width: MediaQuery.of(context).size.width * 0.2, height: 12.0, color: Colors.white)]),
// // // // //           Container(width: double.infinity, height: 12.0, color: Colors.white)
// // // // //           ])))
// // // // //       ]));
// // // // //   }

// // // // //   Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite}) {
// // // // //       final String venueId = venue['id'] as String? ?? '';
// // // // //       return _VenueCardWidget(
// // // // //         key: ValueKey(venueId),
// // // // //         venue: venue,
// // // // //         isFavorite: isFavorite,
// // // // //         onTapCard: () => _navigateToVenueDetail(venue),
// // // // //         onTapFavorite: () => _toggleFavorite(venueId, isFavorite, venue),
// // // // //       );
// // // // //     }

// // // // //   Future<void> _toggleFavorite(String venueId, bool currentIsFavorite, Map<String, dynamic> venue) async {
// // // // //     if (!mounted) return;
// // // // //     final currentUser = _currentUser;
// // // // //     if (currentUser == null) {
// // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // //         const SnackBar(content: Text("Please log in to manage favorites."), behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(10)),
// // // // //       );
// // // // //       return;
// // // // //     }
// // // // //     if (venueId.isEmpty) return;

// // // // //     try {
// // // // //       if (!currentIsFavorite) {
// // // // //         await _userService.addFavorite(venueId);
// // // // //       } else {
// // // // //         await _userService.removeFavorite(venueId);
// // // // //       }
// // // // //     } catch (e) {
// // // // //       debugPrint("Error toggling favorite: $e");
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(content: Text("Error updating favorites: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(10)),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }

// // // // // } 

// // // // // class _VenueCardWidget extends StatefulWidget {
// // // // //   final Map<String, dynamic> venue;
// // // // //   final bool isFavorite;
// // // // //   final VoidCallback onTapCard;
// // // // //   final Future<void> Function() onTapFavorite;

// // // // //   const _VenueCardWidget({
// // // // //     required Key key,
// // // // //     required this.venue,
// // // // //     required this.isFavorite,
// // // // //     required this.onTapCard,
// // // // //     required this.onTapFavorite,
// // // // //   }) : super(key: key);

// // // // //   @override
// // // // //   _VenueCardWidgetState createState() => _VenueCardWidgetState();
// // // // // }

// // // // // class _VenueCardWidgetState extends State<_VenueCardWidget> with SingleTickerProviderStateMixin {
// // // // //   late AnimationController _favoriteAnimationController;
// // // // //   late Animation<double> _favoriteScaleAnimation;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _favoriteAnimationController = AnimationController(
// // // // //       duration: const Duration(milliseconds: 300),
// // // // //       vsync: this,
// // // // //     );
// // // // //     _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
// // // // //       CurvedAnimation(parent: _favoriteAnimationController, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   void didUpdateWidget(_VenueCardWidget oldWidget) {
// // // // //     super.didUpdateWidget(oldWidget);
// // // // //     if (widget.isFavorite != oldWidget.isFavorite && mounted) {
// // // // //       if (widget.isFavorite) {
// // // // //         _favoriteAnimationController.forward(from: 0.0).catchError((e) {
// // // // //           if (e is! TickerCanceled) { debugPrint("Error playing fav add animation: $e"); }
// // // // //         });
// // // // //       } else {
// // // // //          _favoriteAnimationController.reverse().catchError((e) {
// // // // //              if (e is! TickerCanceled) { debugPrint("Error reversing fav remove animation: $e"); }
// // // // //          });
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _favoriteAnimationController.dispose();
// // // // //     super.dispose();
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final ThemeData theme = Theme.of(context);
// // // // //     final String name = widget.venue['name'] as String? ?? 'Unnamed Venue';
// // // // //     final dynamic sportRaw = widget.venue['sportType'];
// // // // //     final String sport = (sportRaw is String) ? sportRaw : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
// // // // //     final String? imageUrl = widget.venue['imageUrl'] as String?;
// // // // //     final String city = widget.venue['city'] as String? ?? '';
// // // // //     final String venueId = widget.venue['id'] as String? ?? '';
// // // // //     final double? distance = widget.venue['distance'] as double?;
// // // // //     final double averageRating = (widget.venue['averageRating'] as num?)?.toDouble() ?? 0.0;
// // // // //     final int reviewCount = (widget.venue['reviewCount'] as num?)?.toInt() ?? 0;

// // // // //     return MouseRegion(
// // // // //       cursor: SystemMouseCursors.click,
// // // // //       child: Card(
// // // // //         margin: EdgeInsets.zero,
// // // // //         elevation: 3,
// // // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // //         clipBehavior: Clip.antiAlias,
// // // // //         child: Column(
// // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // //           children: [
// // // // //             SizedBox(
// // // // //               height: 130,
// // // // //               width: double.infinity,
// // // // //               child: Stack(
// // // // //                 children: [
// // // // //                   Positioned.fill(
// // // // //                     child: InkWell(
// // // // //                       onTap: widget.onTapCard,
// // // // //                       child: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
// // // // //                           ? Hero(
// // // // //                               tag: 'venue_image_$venueId',
// // // // //                               child: Image.network(
// // // // //                                 imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
// // // // //                                 loadingBuilder: (context, child, loadingProgress) =>
// // // // //                                     (loadingProgress == null) ? child : Container(height: 130, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null))),
// // // // //                                 errorBuilder: (context, error, stackTrace) =>
// // // // //                                     Container(height: 130, color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40))),
// // // // //                               ),
// // // // //                             )
// // // // //                           : Container(height: 130, color: theme.primaryColor.withOpacity(0.08), child: Center(child: Icon(Icons.sports_soccer_outlined, size: 50, color: theme.primaryColor.withOpacity(0.7)))),
// // // // //                     ),
// // // // //                   ),
// // // // //                   Positioned(
// // // // //                     top: 6, right: 6,
// // // // //                     child: Material(
// // // // //                       color: Colors.black.withOpacity(0.45), shape: const CircleBorder(),
// // // // //                       child: InkWell(
// // // // //                         borderRadius: BorderRadius.circular(20),
// // // // //                         onTap: widget.onTapFavorite,
// // // // //                         child: Padding(
// // // // //                           padding: const EdgeInsets.all(7.0),
// // // // //                           child: ScaleTransition(
// // // // //                             scale: _favoriteScaleAnimation,
// // // // //                             child: Icon(
// // // // //                               widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
// // // // //                               color: widget.isFavorite ? Colors.pinkAccent[100] : Colors.white,
// // // // //                               size: 22,
// // // // //                             ),
// // // // //                           ),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //                   if (distance != null)
// // // // //                     Positioned(
// // // // //                       bottom: 6, left: 6,
// // // // //                       child: Container(
// // // // //                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// // // // //                         decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
// // // // //                         child: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
// // // // //                       ),
// // // // //                     ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //             Expanded(
// // // // //               child: InkWell(
// // // // //                 onTap: widget.onTapCard,
// // // // //                 child: Padding(
// // // // //                   padding: const EdgeInsets.all(10.0),
// // // // //                   child: Column(
// // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //                     children: [
// // // // //                       Column(
// // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                         mainAxisSize: MainAxisSize.min,
// // // // //                         children: [
// // // // //                           Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
// // // // //                           const SizedBox(height: 4),
// // // // //                           Row(children: [
// // // // //                             Icon(Icons.sports_kabaddi_outlined, size: 14, color: theme.colorScheme.secondary),
// // // // //                             const SizedBox(width: 4),
// // // // //                             Expanded(child: Text(sport, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// // // // //                           ]),
// // // // //                           if (reviewCount > 0)
// // // // //                             Padding(
// // // // //                                padding: const EdgeInsets.only(top: 5.0),
// // // // //                                child: Row(children: [
// // // // //                                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
// // // // //                                 const SizedBox(width: 4),
// // // // //                                 Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
// // // // //                                 const SizedBox(width: 4),
// // // // //                                 Text("($reviewCount reviews)", style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
// // // // //                               ]),
// // // // //                              ),
// // // // //                         ],
// // // // //                       ),
// // // // //                       Row(
// // // // //                         children: [
// // // // //                           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
// // // // //                           const SizedBox(width: 4),
// // // // //                           Expanded(child: Text(city, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// // // // //                         ],
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // //---------search component seperated from homescree, plus added admin realted things-----------
// // // // // lib/features/home/screens/home_screen.dart
// // // // // I am providing the full updated code for this file for clarity.

// // // // import 'package:flutter/material.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:geolocator/geolocator.dart';
// // // // import 'package:mm_associates/features/data/services/firestore_service.dart';
// // // // import 'package:mm_associates/features/home/screens/venue_form.dart';
// // // // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // // // import 'package:mm_associates/features/user/services/user_service.dart';
// // // // import 'package:mm_associates/core/services/location_service.dart';
// // // // import 'package:mm_associates/features/profile/screens/profile_screen.dart';
// // // // import 'venue_detail_screen.dart';
// // // // import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// // // // import 'dart:async';
// // // // import 'package:shimmer/shimmer.dart';
// // // // import 'city_selection_screen.dart' show CitySelectionScreen, CityInfo, kAppAllCities;
// // // // import 'package:mm_associates/features/home/widgets/home_search_components.dart';

// // // // class HomeScreen extends StatefulWidget {
// // // //   /// Controls the visibility of the "Add Venue" Floating Action Button.
// // // //   final bool showAddVenueButton;

// // // //   const HomeScreen({
// // // //     super.key,
// // // //     required this.showAddVenueButton,
// // // //   });

// // // //   @override
// // // //   State<HomeScreen> createState() => _HomeScreenState();
// // // // }

// // // // class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
// // // //   final AuthService _authService = AuthService();
// // // //   final FirestoreService _firestoreService = FirestoreService();
// // // //   final LocationService _locationService = LocationService();
// // // //   final UserService _userService = UserService();

// // // //   // Search and Filter State
// // // //   String? _searchQuery;
// // // //   String? _selectedCityFilter;
// // // //   IconData? _selectedCityIcon;
// // // //   String? _selectedSportFilter;

// // // //   // User State
// // // //   User? _currentUser;
// // // //   String? _userName;
// // // //   String? _userProfilePicUrl;
// // // //   bool _isLoadingName = true;

// // // //   // Venue Data State
// // // //   List<Map<String, dynamic>> _filteredVenues = [];
// // // //   bool _isLoadingFilteredVenues = true;
// // // //   String? _filteredVenueFetchError;

// // // //   List<Map<String, dynamic>> _nearbyVenues = [];
// // // //   bool _isLoadingNearbyVenues = true;
// // // //   String? _nearbyVenueFetchError;

// // // //   List<Map<String, dynamic>> _exploreVenues = [];
// // // //   bool _isLoadingExploreVenues = true;
// // // //   String? _exploreVenueFetchError;

// // // //   // Location State
// // // //   Position? _currentPosition;
// // // //   bool _isFetchingLocation = false;
// // // //   String? _locationStatusMessage;

// // // //   // Favorite Venues State
// // // //   List<String> _favoriteVenueIds = [];
// // // //   bool _isLoadingFavorites = true;
// // // //   Stream<List<String>>? _favoritesStream;
// // // //   StreamSubscription<List<String>>? _favoritesSubscription;

// // // //   // UI Helper data
// // // //   final List<String> _supportedCities = ['Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'];
// // // //   final List<String> _quickSportFilters = ['Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'];

// // // //   // Getter to determine if we are in a search/filter mode
// // // //   bool get _isSearchingOrFiltering => (_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _currentUser = FirebaseAuth.instance.currentUser;
// // // //     _initializeScreen();
// // // //     _setupFavoritesStream();
// // // //     _updateSelectedCityIconFromFilter();
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _favoritesSubscription?.cancel();
// // // //     super.dispose();
// // // //   }

// // // //   void setStateIfMounted(VoidCallback fn) {
// // // //     if (mounted) setState(fn);
// // // //   }

// // // //   void _updateSelectedCityIconFromFilter() {
// // // //     if (_selectedCityFilter == null) {
// // // //       _selectedCityIcon = Icons.my_location;
// // // //     } else {
// // // //       try {
// // // //         final cityInfo = kAppAllCities.firstWhere(
// // // //           (city) => city.name == _selectedCityFilter,
// // // //         );
// // // //         _selectedCityIcon = cityInfo.icon;
// // // //       } catch (e) {
// // // //         _selectedCityIcon = Icons.location_city_outlined;
// // // //         debugPrint("HomeScreen initState: Selected city '$_selectedCityFilter' not found in kAppAllCities. Using fallback icon. Error: $e");
// // // //       }
// // // //     }
// // // //   }
  
// // // //   Future<void> _initializeScreen() async {
// // // //     await _fetchUserNameAndPic();
// // // //     await _fetchPrimaryVenueData();
// // // //   }

// // // //   Future<void> _fetchPrimaryVenueData() async {
// // // //     if (!mounted) return;
// // // //     setStateIfMounted(() {
// // // //       _isFetchingLocation = true; _isLoadingNearbyVenues = true; _isLoadingExploreVenues = true;
// // // //       _locationStatusMessage = 'Fetching your location...';
// // // //       _nearbyVenues = []; _exploreVenues = [];
// // // //       _nearbyVenueFetchError = null; _exploreVenueFetchError = null;
// // // //     });
// // // //     _currentPosition = await _locationService.getCurrentLocation();
// // // //     if (!mounted) return;
// // // //     setStateIfMounted(() {
// // // //       _isFetchingLocation = false;
// // // //       _locationStatusMessage = _currentPosition != null ? 'Location acquired.' : 'Could not get location.';
// // // //     });
// // // //     await Future.wait([_fetchNearbyVenuesScoped(), _fetchExploreVenuesFromOtherCities()]);
// // // //   }

// // // //   void _setupFavoritesStream() {
// // // //     _favoritesSubscription?.cancel();
// // // //     if (_currentUser != null) {
// // // //         _favoritesStream = _userService.getFavoriteVenueIdsStream();
// // // //         _favoritesSubscription = _favoritesStream?.listen(
// // // //           (favoriteIds) {
// // // //             if (mounted) {
// // // //               final newIdsSet = favoriteIds.toSet();
// // // //               final currentIdsSet = _favoriteVenueIds.toSet();
// // // //               if (newIdsSet.difference(currentIdsSet).isNotEmpty || currentIdsSet.difference(newIdsSet).isNotEmpty) {
// // // //                 setStateIfMounted(() {
// // // //                   _favoriteVenueIds = favoriteIds;
// // // //                 });
// // // //               }
// // // //             }
// // // //           },
// // // //           onError: (error) {
// // // //             debugPrint("Error in favorites stream: $error");
// // // //              if (mounted) {
// // // //                 ScaffoldMessenger.of(context).showSnackBar(
// // // //                     const SnackBar(content: Text("Could not update favorites."),
// // // //                     backgroundColor: Colors.orangeAccent,
// // // //                     behavior: SnackBarBehavior.floating)
// // // //                 );
// // // //              }
// // // //           }
// // // //         );
// // // //         if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);
// // // //     } else {
// // // //       if (mounted) {
// // // //          setStateIfMounted(() {
// // // //            _favoriteVenueIds = [];
// // // //            _isLoadingFavorites = false;
// // // //            _favoritesStream = null;
// // // //            _favoritesSubscription = null;
// // // //          });
// // // //       }
// // // //     }
// // // //   }

// // // //   @override
// // // //   void didChangeDependencies() {
// // // //     super.didChangeDependencies();
// // // //     final currentAuthUser = FirebaseAuth.instance.currentUser;
// // // //     if (currentAuthUser != _currentUser) {
// // // //       _currentUser = currentAuthUser;
// // // //       _initializeScreen();
// // // //       _setupFavoritesStream();
// // // //       if (mounted) {
// // // //         setStateIfMounted(() {
// // // //           _updateSelectedCityIconFromFilter();
// // // //         });
// // // //       }
// // // //     }
// // // //   }

// // // //   Future<void> _fetchVenuesForFilterOrSearch({String? newSearchQuery}) async {
// // // //     if (!mounted) return;
// // // //     setStateIfMounted(() {
// // // //       _isLoadingFilteredVenues = true;
// // // //       _filteredVenueFetchError = null;
// // // //       _filteredVenues = [];
// // // //     });

// // // //     try {
// // // //       debugPrint("Fetching FILTERED/SEARCH venues: City: $_selectedCityFilter, Sport: $_selectedSportFilter, Search: $newSearchQuery, Location: $_currentPosition");
// // // //       final venuesData = await _firestoreService.getVenues(
// // // //         userLocation: _currentPosition,
// // // //         radiusInKm: _selectedCityFilter != null ? null : (_currentPosition != null ? 50.0 : null),
// // // //         cityFilter: _selectedCityFilter,
// // // //         searchQuery: newSearchQuery,
// // // //         sportFilter: _selectedSportFilter,
// // // //       );
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() {
// // // //           _filteredVenues = venuesData;
// // // //         });
// // // //     } catch (e) {
// // // //       debugPrint("Error fetching filtered/search venues: $e");
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() => _filteredVenueFetchError = "Could not load venues: ${e.toString().replaceFirst('Exception: ', '')}");
// // // //     } finally {
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() => _isLoadingFilteredVenues = false);
// // // //     }
// // // //   }

// // // //   Future<void> _fetchNearbyVenuesScoped() async {
// // // //     if (!mounted) return;
// // // //     if (_currentPosition == null) {
// // // //       if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = false; _nearbyVenueFetchError = "Location not available."; _nearbyVenues = []; });
// // // //       return;
// // // //     }
// // // //     if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = true; _nearbyVenueFetchError = null; _nearbyVenues = []; });
// // // //     try {
// // // //       final venuesData = await _firestoreService.getVenues(userLocation: _currentPosition, radiusInKm: 25.0);
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() {
// // // //         _nearbyVenues = venuesData;
// // // //       });
// // // //     } catch (e) {
// // // //       debugPrint("Error fetching nearby venues: $e");
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() => _nearbyVenueFetchError = "Could not load nearby venues.");
// // // //     } finally {
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() => _isLoadingNearbyVenues = false);
// // // //     }
// // // //   }

// // // //   Future<void> _fetchExploreVenuesFromOtherCities() async {
// // // //     if (!mounted) return;
// // // //     setStateIfMounted(() { _isLoadingExploreVenues = true; _exploreVenueFetchError = null; _exploreVenues = [];});
// // // //     List<Map<String, dynamic>> allExploreVenues = [];
// // // //     try {
// // // //       for (String city in _supportedCities) {
// // // //         final cityVenues = await _firestoreService.getVenues(cityFilter: city, userLocation: _currentPosition, limit: 5);
// // // //         allExploreVenues.addAll(cityVenues);
// // // //         if (!mounted) return;
// // // //       }
// // // //       final uniqueExploreVenues = allExploreVenues.fold<Map<String, Map<String, dynamic>>>({}, (map, venue) {
// // // //           final String? venueId = venue['id'] as String?;
// // // //           if (venueId != null) map[venueId] = venue;
// // // //           return map;
// // // //         }).values.toList();

// // // //       if (_currentPosition != null) {
// // // //         uniqueExploreVenues.sort((a, b) {
// // // //           final distA = a['distance'] as double?; final distB = b['distance'] as double?;
// // // //           if (distA != null && distB != null) return distA.compareTo(distB);
// // // //           if (distA != null) return -1;
// // // //           if (distB != null) return 1;
// // // //           return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
// // // //         });
// // // //       } else {
// // // //          uniqueExploreVenues.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
// // // //       }
// // // //       if(!mounted) return;
// // // //       setStateIfMounted(() {
// // // //         _exploreVenues = uniqueExploreVenues.take(15).toList();
// // // //       });
// // // //     } catch (e) {
// // // //       debugPrint("Error fetching explore venues: $e");
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() => _exploreVenueFetchError = "Could not load explore venues.");
// // // //     } finally {
// // // //       if (!mounted) return;
// // // //       setStateIfMounted(() => _isLoadingExploreVenues = false);
// // // //     }
// // // //   }

// // // //   Future<void> _fetchUserNameAndPic() async {
// // // //     _setLoadingName(true); final currentUser = _currentUser;
// // // //     if (currentUser == null) { if(mounted) _updateUserNameAndPic('Guest', null); _setLoadingName(false); return; }
// // // //     try {
// // // //       final userData = await _userService.getUserProfileData();
// // // //       if (!mounted) return;
// // // //       final fetchedName = userData?['name'] as String? ?? currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// // // //       final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
// // // //       _updateUserNameAndPic(fetchedName, fetchedPicUrl);
// // // //     } catch (e) {
// // // //       debugPrint("Error fetching user name/pic via UserService: $e"); if (!mounted) return;
// // // //       final fallbackName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// // // //       _updateUserNameAndPic(fallbackName, null);
// // // //     } finally { if(mounted) _setLoadingName(false); }
// // // //   }

// // // //   void _setLoadingName(bool isLoading) => {if(mounted) setStateIfMounted(() => _isLoadingName = isLoading)};
// // // //   void _updateUserNameAndPic(String name, String? picUrl) => {if(mounted) setStateIfMounted(() { _userName = name; _userProfilePicUrl = picUrl; })};

// // // //   Future<void> _handleRefresh() async {
// // // //     if(mounted) {
// // // //       setStateIfMounted(() {
// // // //           _searchQuery = null;
// // // //           _selectedSportFilter = null;
// // // //       });
// // // //     }
// // // //     _onFilterOrSearchChanged();
// // // //   }

// // // //   void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
// // // //     final newSearchQuery = explicitSearchQuery ?? _searchQuery;
// // // //     bool queryChanged = _searchQuery != newSearchQuery;

// // // //     if (mounted) {
// // // //       setStateIfMounted(() {
// // // //         _searchQuery = newSearchQuery;
// // // //       });
// // // //     }

// // // //     if ((_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null) {
// // // //         _fetchVenuesForFilterOrSearch(newSearchQuery: _searchQuery);
// // // //     } else {
// // // //         _fetchPrimaryVenueData();
// // // //     }

// // // //     if (kIsWeb && queryChanged) {
// // // //       FocusScope.of(context).unfocus();
// // // //     }
// // // //   }

// // // //   Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
// // // //       if (!context.mounted) return;
// // // //       return showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext dialogContext) {
// // // //           return AlertDialog(title: const Text('Confirm Logout'), content: const SingleChildScrollView(child: ListBody(children: <Widget>[Text('Are you sure you want to sign out?')])),
// // // //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
// // // //             actions: <Widget>[
// // // //               TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
// // // //               TextButton(child: const Text('Logout', style: TextStyle(color: Colors.red)), onPressed: () async {
// // // //                   Navigator.of(dialogContext).pop(); try { await _authService.signOut();
// // // //                    } catch (e) {
// // // //                     debugPrint("Error during sign out: $e"); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(10)));
// // // //                   }},), ],); },);
// // // //     }

// // // //   void _navigateToVenueDetail(Map<String, dynamic> venue) {
// // // //     if (!context.mounted) return;
// // // //     Navigator.push(context, MaterialPageRoute(builder: (context) => VenueDetailScreen(venueId: venue['id'] as String, initialVenueData: venue))).then((_) {
// // // //     });
// // // //   }

// // // //   void _openSearchMobile() async {
// // // //      if (!context.mounted) return;
// // // //      final String? submittedQuery = await showSearch<String?>(
// // // //         context: context,
// // // //         delegate: VenueSearchDelegate(
// // // //             firestoreService: _firestoreService,
// // // //             initialCityFilter: _selectedCityFilter,
// // // //         )
// // // //     );
// // // //     if (submittedQuery != null && submittedQuery.isNotEmpty) {
// // // //         _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
// // // //     }
// // // //   }

// // // //   Future<void> _openCitySelectionScreen() async {
// // // //     if (!mounted) return;
// // // //     final String? newSelectedCityName = await Navigator.push<String?>(
// // // //       context,
// // // //       MaterialPageRoute(
// // // //         builder: (context) => CitySelectionScreen(currentSelectedCity: _selectedCityFilter),
// // // //       ),
// // // //     );

// // // //     if (mounted) {
// // // //       if (newSelectedCityName != _selectedCityFilter) {
// // // //         setStateIfMounted(() {
// // // //           _selectedCityFilter = newSelectedCityName; 
// // // //           _updateSelectedCityIconFromFilter(); 
// // // //         });
// // // //         _onFilterOrSearchChanged(); 
// // // //       } else {
// // // //         IconData currentExpectedIcon = Icons.location_city_outlined; 
// // // //         if (_selectedCityFilter == null) {
// // // //             currentExpectedIcon = Icons.my_location;
// // // //         } else {
// // // //             try {
// // // //                 final cityInfo = kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
// // // //                 currentExpectedIcon = cityInfo.icon;
// // // //             } catch (e) {
// // // //                 debugPrint("Error re-validating icon for city '$_selectedCityFilter': $e. Using fallback.");
// // // //             }
// // // //         }
// // // //         if (_selectedCityIcon != currentExpectedIcon) {
// // // //             setStateIfMounted(() {
// // // //               _selectedCityIcon = currentExpectedIcon;
// // // //             });
// // // //         }
// // // //       }
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = Theme.of(context);
// // // //     final appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
// // // //     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ?? theme.appBarTheme.iconTheme?.color ?? (kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white);
// // // //     final bool isLoggedIn = _currentUser != null;

// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         automaticallyImplyLeading: false,
// // // //         title: kIsWeb ? _buildWebAppBarTitle(context) : _buildMobileAppBarTitle(context, theme),
// // // //         actions: kIsWeb ? _buildWebAppBarActions(context, isLoggedIn, actionsIconColor) : _buildMobileAppBarActions(context, isLoggedIn, actionsIconColor),
// // // //         backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
// // // //         elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
// // // //         iconTheme: theme.iconTheme.copyWith(color: kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white),
// // // //         actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
// // // //         titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ?? TextStyle(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
// // // //       ),
// // // //       // *** THE ONLY CHANGE IN THIS WIDGET IS HERE ***
// // // //       floatingActionButton: widget.showAddVenueButton
// // // //           ? FloatingActionButton.extended(
// // // //               onPressed: () {
// // // //                 Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => const AddVenueFormScreen()),
// // // //                 ).then((result) {
// // // //                   if (result == true && mounted) {
// // // //                     _handleRefresh();
// // // //                     ScaffoldMessenger.of(context).showSnackBar(
// // // //                       const SnackBar(content: Text("Venue list updated."), backgroundColor: Colors.blueAccent),
// // // //                     );
// // // //                   }
// // // //                 });
// // // //               },
// // // //               icon: const Icon(Icons.add_location_alt_outlined),
// // // //               label: const Text("Add Venue"),
// // // //               tooltip: 'Add New Venue',
// // // //             )
// // // //           : null, // If false, hide the button
// // // //       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
// // // //       body: _buildBodyContent(),
// // // //     );
// // // //   }

// // // //   // ... (All other UI build methods remain exactly the same)
// // // //   // _buildMobileAppBarTitle, _buildMobileAppBarActions, _buildWebAppBarTitle, etc.
// // // //   // ... Paste all the build methods from your previous code here, unchanged ...
  
// // // //   Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
// // // //     final titleStyle = theme.appBarTheme.titleTextStyle ?? theme.primaryTextTheme.titleLarge ?? const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
// // // //     final currentUser = _currentUser;
// // // //     return Row(children: [
// // // //         if (currentUser != null)
// // // //           GestureDetector(
// // // //             onTap: () {
// // // //               if (!context.mounted) return;
// // // //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // //                   .then((_) { if (mounted) _fetchUserNameAndPic(); });
// // // //             },
// // // //             child: Tooltip(
// // // //               message: "My Profile",
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.only(right: 10.0),
// // // //                 child: CircleAvatar(
// // // //                   radius: 18,
// // // //                   backgroundColor: Colors.white24,
// // // //                   backgroundImage: _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty ? NetworkImage(_userProfilePicUrl!) : null,
// // // //                   child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty ? Icon(Icons.person_outline, size: 20, color: Colors.white.withOpacity(0.8)) : null
// // // //                 )
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         if (_isLoadingName && currentUser != null)
// // // //           const Padding(
// // // //             padding: EdgeInsets.only(left: 6.0),
// // // //             child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)))
// // // //           )
// // // //         else if (_userName != null && currentUser != null)
// // // //           Expanded(
// // // //             child: Padding(
// // // //                padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
// // // //               child: Text(
// // // //                 'Hi, ${_userName!.split(' ')[0]}!',
// // // //                 style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
// // // //                 overflow: TextOverflow.ellipsis
// // // //               )
// // // //             )
// // // //           )
// // // //         else
// // // //           Text('MM Associates', style: titleStyle),
// // // //       ]
// // // //     );
// // // //   }
  
// // // //   List<Widget> _buildMobileAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // //     final String cityNameText = _selectedCityFilter ?? 'Near Me';
// // // //     final double textSize = 10.0; 

// // // //     return [
// // // //       IconButton(
// // // //         icon: Icon(Icons.search_outlined, color: iconColor),
// // // //         tooltip: 'Search Venues',
// // // //         onPressed: _openSearchMobile,
// // // //         padding: const EdgeInsets.symmetric(horizontal: 8),
// // // //         constraints: const BoxConstraints(),
// // // //       ),
// // // //       Tooltip( 
// // // //         message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // //         child: IconButton(
// // // //           icon: Column(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             mainAxisSize: MainAxisSize.min,
// // // //             children: [
// // // //               Icon(
// // // //                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // //                 color: iconColor,
// // // //                 size: 24,
// // // //               ),
// // // //               const SizedBox(height: 2), 
// // // //               Text(
// // // //                 cityNameText,
// // // //                 style: TextStyle(
// // // //                   color: iconColor,
// // // //                   fontSize: textSize,
// // // //                   fontWeight: FontWeight.w500,
// // // //                 ),
// // // //                 overflow: TextOverflow.ellipsis,
// // // //                 maxLines: 1,
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           onPressed: _openCitySelectionScreen,
// // // //           padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
// // // //           constraints: const BoxConstraints(),
// // // //         ),
// // // //       ),
// // // //       if (isLoggedIn)
// // // //         IconButton(
// // // //           icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // //           tooltip: 'My Profile',
// // // //           onPressed: () {
// // // //             if (!context.mounted) return;
// // // //             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // //                 .then((_) {
// // // //               if (mounted) _fetchUserNameAndPic();
// // // //             });
// // // //           },
// // // //           padding: const EdgeInsets.symmetric(horizontal: 8),
// // // //           constraints: const BoxConstraints(),
// // // //         ),
// // // //     ];
// // // //   }

// // // //   Widget _buildWebAppBarTitle(BuildContext context) {
// // // //     final theme = Theme.of(context);
// // // //     final currentUser = _currentUser;
// // // //     double screenWidth = MediaQuery.of(context).size.width;
// // // //     double leadingWidth = 150 + (_userName != null ? 100 : 0);
// // // //     double searchWidthFraction = 0.4;
// // // //     double minSearchWidth = 200;
// // // //     double maxSearchWidth = 500;
// // // //     double actionsWidth = 80 + (_currentUser != null ? 120 : 0);
// // // //     double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
// // // //     double calculatedSearchWidth = (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);
// // // //     double spacerFlexFactor = (availableWidth > calculatedSearchWidth + 40)
// // // //         ? (availableWidth - calculatedSearchWidth) / 2 / availableWidth
// // // //         : 0.05;
// // // //     int searchFlex = (searchWidthFraction * 100).toInt();
// // // //     int spacerFlex = (spacerFlexFactor * 100).toInt().clamp(5, 50);

// // // //     return Row(children: [
// // // //       Text('MM Associates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
// // // //       const SizedBox(width: 24),
// // // //       if (_isLoadingName && currentUser != null)
// // // //         const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
// // // //       else if (_userName != null && currentUser != null)
// // // //         Padding(
// // // //           padding: const EdgeInsets.only(right: 16.0),
// // // //           child: Text('Hi, ${_userName!.split(' ')[0]}!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)
// // // //         ),
// // // //       Spacer(flex: spacerFlex),
// // // //       Expanded(
// // // //         flex: searchFlex,
// // // //         child: Container(
// // // //           constraints: BoxConstraints(maxWidth: maxSearchWidth),
// // // //           child: WebSearchBar(
// // // //             key: ValueKey(_searchQuery),
// // // //             initialValue: _searchQuery ?? '',
// // // //             cityFilter: _selectedCityFilter,
// // // //             firestoreService: _firestoreService,
// // // //             onSearchSubmitted: (query) {
// // // //               if (query.trim().isNotEmpty) {
// // // //                 _onFilterOrSearchChanged(explicitSearchQuery: query.trim());
// // // //               }
// // // //             },
// // // //             onSuggestionSelected: (suggestionName) {
// // // //               _onFilterOrSearchChanged(explicitSearchQuery: suggestionName);
// // // //             },
// // // //             onClear: () {
// // // //               _onFilterOrSearchChanged(explicitSearchQuery: null);
// // // //             },
// // // //           ),
// // // //         ),
// // // //       ),
// // // //       Spacer(flex: spacerFlex),
// // // //     ]);
// // // //   }

// // // //   List<Widget> _buildWebAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// // // //     final String cityNameText = _selectedCityFilter ?? 'Near Me';
// // // //     final double textSize = 10.0;

// // // //     return [
// // // //       Tooltip(
// // // //         message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// // // //         child: IconButton(
// // // //           icon: Column(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             mainAxisSize: MainAxisSize.min,
// // // //             children: [
// // // //               Icon(
// // // //                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// // // //                 color: iconColor,
// // // //                 size: 24,
// // // //               ),
// // // //               const SizedBox(height: 2),
// // // //               Text(
// // // //                 cityNameText,
// // // //                 style: TextStyle(
// // // //                   color: iconColor,
// // // //                   fontSize: textSize,
// // // //                   fontWeight: FontWeight.w500,
// // // //                 ),
// // // //                 overflow: TextOverflow.ellipsis,
// // // //                 maxLines: 1,
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           onPressed: _openCitySelectionScreen,
// // // //           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
// // // //           constraints: const BoxConstraints(),
// // // //         ),
// // // //       ),
// // // //       if (isLoggedIn)
// // // //         Tooltip(
// // // //           message: 'My Profile',
// // // //           child: IconButton(
// // // //             icon: Icon(Icons.person_outline_rounded, color: iconColor),
// // // //             onPressed: () {
// // // //               if (!context.mounted) return;
// // // //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// // // //                   .then((_) {
// // // //                 if (mounted) _fetchUserNameAndPic();
// // // //               });
// // // //             },
// // // //             padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //             constraints: const BoxConstraints(),
// // // //           ),
// // // //         ),
// // // //       const SizedBox(width: 8)
// // // //     ];
// // // //   }

// // // //   Widget _buildQuickSportFilters() {
// // // //     if (_quickSportFilters.isEmpty) return const SizedBox.shrink();
// // // //     final theme = Theme.of(context);
// // // //     return Container(
// // // //       height: 55,
// // // //       color: theme.cardColor,
// // // //       child: ListView.separated(
// // // //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// // // //         scrollDirection: Axis.horizontal,
// // // //         itemCount: _quickSportFilters.length + 1,
// // // //         separatorBuilder: (context, index) => const SizedBox(width: 10),
// // // //         itemBuilder: (context, index) {
// // // //           if (index == 0) {
// // // //             final bool isSelected = _selectedSportFilter == null;
// // // //             return ChoiceChip(
// // // //               label: const Text('All Sports'),
// // // //               selected: isSelected,
// // // //               onSelected: (bool nowSelected) {
// // // //                 if (nowSelected && _selectedSportFilter != null) {
// // // //                     setStateIfMounted(() => _selectedSportFilter = null);
// // // //                     _onFilterOrSearchChanged();
// // // //                 }
// // // //               },
// // // //               selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// // // //               backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// // // //               labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// // // //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// // // //               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// // // //               visualDensity: VisualDensity.compact,
// // // //                showCheckmark: false,
// // // //             );
// // // //           }
// // // //           final sport = _quickSportFilters[index - 1];
// // // //           final bool isSelected = _selectedSportFilter == sport;
// // // //           return ChoiceChip(
// // // //             label: Text(sport),
// // // //             selected: isSelected,
// // // //             onSelected: (bool isNowSelected) {
// // // //               String? newFilterValue = isNowSelected ? sport : null;
// // // //               if (_selectedSportFilter != newFilterValue) {
// // // //                 setStateIfMounted(() { _selectedSportFilter = newFilterValue; });
// // // //                 _onFilterOrSearchChanged();
// // // //               }
// // // //             },
// // // //             selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// // // //             backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// // // //             labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// // // //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// // // //             visualDensity: VisualDensity.compact,
// // // //             showCheckmark: false,
// // // //           );
// // // //         },
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildSectionHeader(BuildContext context, String title) {
// // // //     return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
// // // //       child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
// // // //   }

// // // //   Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg, String emptyMsg, {bool isNearbySection = false}) {
// // // //      if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
// // // //      if (errorMsg != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16))));
// // // //      if (venues.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

// // // //      return GridView.builder(
// // // //        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// // // //        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
// // // //        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// // // //            maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
// // // //            mainAxisSpacing: 16.0,
// // // //            crossAxisSpacing: 16.0,
// // // //            childAspectRatio: 0.70
// // // //         ),
// // // //        itemCount: venues.length,
// // // //        itemBuilder: (context, index) {
// // // //          final venue = venues[index];
// // // //          final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
// // // //          return _buildVenueGridCard(venue, isFavorite: isFavorite);
// // // //        },
// // // //      );
// // // //    }

// // // //   Widget _buildBodyContent() {
// // // //      return Column(children: [
// // // //          _buildQuickSportFilters(),
// // // //          Expanded(
// // // //            child: RefreshIndicator(
// // // //              onRefresh: _handleRefresh,
// // // //              child: ListView(
// // // //                padding: EdgeInsets.zero,
// // // //                children: [
// // // //                  if (_isSearchingOrFiltering) ...[
// // // //                    _buildSectionHeader(context,
// // // //                         _searchQuery != null && _searchQuery!.isNotEmpty
// // // //                             ? "Results for \"$_searchQuery\""
// // // //                             : (_selectedCityFilter != null
// // // //                                 ? "Venues in $_selectedCityFilter"
// // // //                                 : (_selectedSportFilter != null ? "Venues for $_selectedSportFilter" : "Filtered Venues")
// // // //                             )
// // // //                     ),
// // // //                    _buildVenueList(_filteredVenues, _isLoadingFilteredVenues, _filteredVenueFetchError, "No venues found for your selection.", isNearbySection: false),
// // // //                  ] else ...[
// // // //                    if (_currentPosition != null || _isLoadingNearbyVenues)
// // // //                        _buildSectionHeader(context, "Venues Near You"),
// // // //                    _buildVenueList(_nearbyVenues, _isLoadingNearbyVenues, _nearbyVenueFetchError, "No venues found nearby. Try exploring other cities or check location permissions.", isNearbySection: true),

// // // //                    const SizedBox(height: 16),
// // // //                    _buildSectionHeader(context, "Explore Venues"),
// // // //                    _buildVenueList(_exploreVenues, _isLoadingExploreVenues, _exploreVenueFetchError, "No venues to explore at the moment.", isNearbySection: false),
// // // //                   ],
// // // //                  const SizedBox(height: 80),
// // // //                ],
// // // //              ),
// // // //            ),
// // // //          ),
// // // //        ]
// // // //      );
// // // //   }

// // // //   Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
// // // //     return Shimmer.fromColors(baseColor: Colors.grey[350]!, highlightColor: Colors.grey[200]!,
// // // //       child: GridView.builder(
// // // //         shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0, mainAxisSpacing: 16.0, crossAxisSpacing: 16.0, childAspectRatio: 0.70),
// // // //         itemCount: itemCount, itemBuilder: (context, index) => _buildVenueShimmerCard())
// // // //       );
// // // //   }
// // // //   Widget _buildVenueShimmerCard() {
// // // //     return Card(
// // // //       margin: EdgeInsets.zero, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
// // // //       child: Column(children: [
// // // //         Container(height: 130, width: double.infinity, color: Colors.white),
// // // //         Expanded(child: Padding(padding: const EdgeInsets.all(10.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// // // //           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// // // //             Container(width: double.infinity, height: 18.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// // // //             Container(width: MediaQuery.of(context).size.width * 0.3, height: 14.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// // // //             Container(width: MediaQuery.of(context).size.width * 0.2, height: 12.0, color: Colors.white)]),
// // // //           Container(width: double.infinity, height: 12.0, color: Colors.white)
// // // //           ])))
// // // //       ]));
// // // //   }

// // // //   Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite}) {
// // // //       final String venueId = venue['id'] as String? ?? '';
// // // //       return _VenueCardWidget(
// // // //         key: ValueKey(venueId),
// // // //         venue: venue,
// // // //         isFavorite: isFavorite,
// // // //         onTapCard: () => _navigateToVenueDetail(venue),
// // // //         onTapFavorite: () => _toggleFavorite(venueId, isFavorite, venue),
// // // //       );
// // // //     }

// // // //   Future<void> _toggleFavorite(String venueId, bool currentIsFavorite, Map<String, dynamic> venue) async {
// // // //     if (!mounted) return;
// // // //     final currentUser = _currentUser;
// // // //     if (currentUser == null) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Please log in to manage favorites."), behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(10)),
// // // //       );
// // // //       return;
// // // //     }
// // // //     if (venueId.isEmpty) return;

// // // //     try {
// // // //       if (!currentIsFavorite) {
// // // //         await _userService.addFavorite(venueId);
// // // //       } else {
// // // //         await _userService.removeFavorite(venueId);
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint("Error toggling favorite: $e");
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Error updating favorites: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(10)),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // // }

// // // // class _VenueCardWidget extends StatefulWidget {
// // // //   final Map<String, dynamic> venue;
// // // //   final bool isFavorite;
// // // //   final VoidCallback onTapCard;
// // // //   final Future<void> Function() onTapFavorite;

// // // //   const _VenueCardWidget({
// // // //     required Key key,
// // // //     required this.venue,
// // // //     required this.isFavorite,
// // // //     required this.onTapCard,
// // // //     required this.onTapFavorite,
// // // //   }) : super(key: key);

// // // //   @override
// // // //   _VenueCardWidgetState createState() => _VenueCardWidgetState();
// // // // }

// // // // class _VenueCardWidgetState extends State<_VenueCardWidget> with SingleTickerProviderStateMixin {
// // // //   late AnimationController _favoriteAnimationController;
// // // //   late Animation<double> _favoriteScaleAnimation;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _favoriteAnimationController = AnimationController(
// // // //       duration: const Duration(milliseconds: 300),
// // // //       vsync: this,
// // // //     );
// // // //     _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
// // // //       CurvedAnimation(parent: _favoriteAnimationController, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
// // // //     );
// // // //   }

// // // //   @override
// // // //   void didUpdateWidget(_VenueCardWidget oldWidget) {
// // // //     super.didUpdateWidget(oldWidget);
// // // //     if (widget.isFavorite != oldWidget.isFavorite && mounted) {
// // // //       if (widget.isFavorite) {
// // // //         _favoriteAnimationController.forward(from: 0.0).catchError((e) {
// // // //           if (e is! TickerCanceled) { debugPrint("Error playing fav add animation: $e"); }
// // // //         });
// // // //       } else {
// // // //          _favoriteAnimationController.reverse().catchError((e) {
// // // //              if (e is! TickerCanceled) { debugPrint("Error reversing fav remove animation: $e"); }
// // // //          });
// // // //       }
// // // //     }
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _favoriteAnimationController.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final ThemeData theme = Theme.of(context);
// // // //     final String name = widget.venue['name'] as String? ?? 'Unnamed Venue';
// // // //     final dynamic sportRaw = widget.venue['sportType'];
// // // //     final String sport = (sportRaw is String) ? sportRaw : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
// // // //     final String? imageUrl = widget.venue['imageUrl'] as String?;
// // // //     final String city = widget.venue['city'] as String? ?? '';
// // // //     final String venueId = widget.venue['id'] as String? ?? '';
// // // //     final double? distance = widget.venue['distance'] as double?;
// // // //     final double averageRating = (widget.venue['averageRating'] as num?)?.toDouble() ?? 0.0;
// // // //     final int reviewCount = (widget.venue['reviewCount'] as num?)?.toInt() ?? 0;

// // // //     return MouseRegion(
// // // //       cursor: SystemMouseCursors.click,
// // // //       child: Card(
// // // //         margin: EdgeInsets.zero,
// // // //         elevation: 3,
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // //         clipBehavior: Clip.antiAlias,
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             SizedBox(
// // // //               height: 130,
// // // //               width: double.infinity,
// // // //               child: Stack(
// // // //                 children: [
// // // //                   Positioned.fill(
// // // //                     child: InkWell(
// // // //                       onTap: widget.onTapCard,
// // // //                       child: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
// // // //                           ? Hero(
// // // //                               tag: 'venue_image_$venueId',
// // // //                               child: Image.network(
// // // //                                 imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
// // // //                                 loadingBuilder: (context, child, loadingProgress) =>
// // // //                                     (loadingProgress == null) ? child : Container(height: 130, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null))),
// // // //                                 errorBuilder: (context, error, stackTrace) =>
// // // //                                     Container(height: 130, color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40))),
// // // //                               ),
// // // //                             )
// // // //                           : Container(height: 130, color: theme.primaryColor.withOpacity(0.08), child: Center(child: Icon(Icons.sports_soccer_outlined, size: 50, color: theme.primaryColor.withOpacity(0.7)))),
// // // //                     ),
// // // //                   ),
// // // //                   Positioned(
// // // //                     top: 6, right: 6,
// // // //                     child: Material(
// // // //                       color: Colors.black.withOpacity(0.45), shape: const CircleBorder(),
// // // //                       child: InkWell(
// // // //                         borderRadius: BorderRadius.circular(20),
// // // //                         onTap: widget.onTapFavorite,
// // // //                         child: Padding(
// // // //                           padding: const EdgeInsets.all(7.0),
// // // //                           child: ScaleTransition(
// // // //                             scale: _favoriteScaleAnimation,
// // // //                             child: Icon(
// // // //                               widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
// // // //                               color: widget.isFavorite ? Colors.pinkAccent[100] : Colors.white,
// // // //                               size: 22,
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                   if (distance != null)
// // // //                     Positioned(
// // // //                       bottom: 6, left: 6,
// // // //                       child: Container(
// // // //                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// // // //                         decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
// // // //                         child: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
// // // //                       ),
// // // //                     ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //             Expanded(
// // // //               child: InkWell(
// // // //                 onTap: widget.onTapCard,
// // // //                 child: Padding(
// // // //                   padding: const EdgeInsets.all(10.0),
// // // //                   child: Column(
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                     children: [
// // // //                       Column(
// // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // //                         mainAxisSize: MainAxisSize.min,
// // // //                         children: [
// // // //                           Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
// // // //                           const SizedBox(height: 4),
// // // //                           Row(children: [
// // // //                             Icon(Icons.sports_kabaddi_outlined, size: 14, color: theme.colorScheme.secondary),
// // // //                             const SizedBox(width: 4),
// // // //                             Expanded(child: Text(sport, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// // // //                           ]),
// // // //                           if (reviewCount > 0)
// // // //                             Padding(
// // // //                                padding: const EdgeInsets.only(top: 5.0),
// // // //                                child: Row(children: [
// // // //                                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
// // // //                                 const SizedBox(width: 4),
// // // //                                 Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
// // // //                                 const SizedBox(width: 4),
// // // //                                 Text("($reviewCount reviews)", style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
// // // //                               ]),
// // // //                              ),
// // // //                         ],
// // // //                       ),
// // // //                       Row(
// // // //                         children: [
// // // //                           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
// // // //                           const SizedBox(width: 4),
// // // //                           Expanded(child: Text(city, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// // // //                         ],
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // //-----------search issue resolved------------------
// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:mm_associates/features/data/services/firestore_service.dart';
// // import 'package:mm_associates/features/home/screens/venue_form.dart';
// // import 'package:mm_associates/features/auth/services/auth_service.dart';
// // import 'package:mm_associates/features/user/services/user_service.dart';
// // import 'package:mm_associates/core/services/location_service.dart';
// // import 'package:mm_associates/features/profile/screens/profile_screen.dart';
// // import 'venue_detail_screen.dart';
// // import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// // import 'dart:async';
// // import 'package:shimmer/shimmer.dart';
// // import 'city_selection_screen.dart' show CitySelectionScreen, CityInfo, kAppAllCities;
// // import 'package:mm_associates/features/home/widgets/home_search_components.dart';

// // class HomeScreen extends StatefulWidget {
// //   final bool showAddVenueButton;

// //   const HomeScreen({
// //     super.key,
// //     required this.showAddVenueButton,
// //   });

// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
// //   final AuthService _authService = AuthService();
// //   final FirestoreService _firestoreService = FirestoreService();
// //   final LocationService _locationService = LocationService();
// //   final UserService _userService = UserService();

// //   // --- State Variables ---
// //   String? _searchQuery;
// //   String? _selectedCityFilter;
// //   IconData? _selectedCityIcon;
// //   String? _selectedSportFilter;

// //   User? _currentUser;
// //   String? _userName;
// //   String? _userProfilePicUrl;
// //   bool _isLoadingName = true;

// //   List<Map<String, dynamic>> _filteredVenues = [];
// //   bool _isLoadingFilteredVenues = true;
// //   String? _filteredVenueFetchError;

// //   List<Map<String, dynamic>> _nearbyVenues = [];
// //   bool _isLoadingNearbyVenues = true;
// //   String? _nearbyVenueFetchError;

// //   List<Map<String, dynamic>> _exploreVenues = [];
// //   bool _isLoadingExploreVenues = true;
// //   String? _exploreVenueFetchError;

// //   Position? _currentPosition;
// //   bool _isFetchingLocation = false;
// //   String? _locationStatusMessage;

// //   // Favorites State
// //   List<String> _favoriteVenueIds = [];
// //   bool _isLoadingFavorites = true;
// //   Stream<List<String>>? _favoritesStream;
// //   StreamSubscription<List<String>>? _favoritesSubscription;

// //   final List<String> _supportedCities = ['Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'];
// //   final List<String> _quickSportFilters = ['Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'];

// //   bool get _isSearchingOrFiltering => (_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _currentUser = FirebaseAuth.instance.currentUser;
// //     _initializeScreen();
// //     _setupFavoritesStream();
// //     _updateSelectedCityIconFromFilter();
// //   }

// //   @override
// //   void dispose() {
// //     _favoritesSubscription?.cancel();
// //     super.dispose();
// //   }

// //   void setStateIfMounted(VoidCallback fn) {
// //     if (mounted) setState(fn);
// //   }

// //   // --- Core Logic & Data Fetching ---

// //   Future<void> _initializeScreen() async {
// //     await _fetchUserNameAndPic();
// //     await _fetchPrimaryVenueData();
// //   }

// //   /// **[CORRECTED & SIMPLIFIED]** This is the single, central function to handle any change
// //   /// that requires a data refresh (search, city filter, sport filter).
// //   void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
// //     if (!mounted) return;

// //     // A state change has occurred (e.g., sport filter selected, city changed, or search submitted).
// //     // First, update the search query state if a new one was provided.
// //     setState(() {
// //       _searchQuery = (explicitSearchQuery?.trim().isEmpty ?? true) ? null : explicitSearchQuery!.trim();
// //     });

// //     // Now, based on the *updated* state, decide which view to fetch data for.
// //     // The `_isSearchingOrFiltering` getter will now be accurate.
// //     if (_isSearchingOrFiltering) {
// //       // If any filter or search query exists, fetch the filtered results.
// //       _fetchVenuesForFilterOrSearch();
// //     } else {
// //       // If all filters and the search query are clear, fetch the default view.
// //       // This path is now correctly taken when the last filter is removed or search is cleared.
// //       _fetchPrimaryVenueData();
// //     }
// //   }

// //   /// Fetches venues for the filtered/search view.
// //   Future<void> _fetchVenuesForFilterOrSearch() async {
// //     if (!mounted) return;
// //     setStateIfMounted(() {
// //       _isLoadingFilteredVenues = true;
// //       _filteredVenueFetchError = null;
// //       _filteredVenues = [];
// //     });

// //     try {
// //       debugPrint("Fetching FILTERED/SEARCH venues: City: $_selectedCityFilter, Sport: $_selectedSportFilter, Search: $_searchQuery");
// //       final venuesData = await _firestoreService.getVenues(
// //         userLocation: _currentPosition,
// //         radiusInKm: _selectedCityFilter != null ? null : (_currentPosition != null ? 50.0 : null),
// //         cityFilter: _selectedCityFilter,
// //         searchQuery: _searchQuery,
// //         sportFilter: _selectedSportFilter,
// //       );
// //       if (!mounted) return;
// //       setStateIfMounted(() {
// //         _filteredVenues = venuesData;
// //       });
// //     } catch (e) {
// //       debugPrint("Error fetching filtered/search venues: $e");
// //       if (!mounted) return;
// //       setStateIfMounted(() => _filteredVenueFetchError = "Could not load venues: ${e.toString().replaceFirst('Exception: ', '')}");
// //     } finally {
// //       if (!mounted) return;
// //       setStateIfMounted(() => _isLoadingFilteredVenues = false);
// //     }
// //   }

// //   /// Fetches venues for the default home screen view (Nearby and Explore).
// //   Future<void> _fetchPrimaryVenueData() async {
// //     if (!mounted) return;
// //     setStateIfMounted(() {
// //       _isFetchingLocation = true;
// //       _isLoadingNearbyVenues = true;
// //       _isLoadingExploreVenues = true;
// //       _locationStatusMessage = 'Fetching your location...';
// //       _nearbyVenues = [];
// //       _exploreVenues = [];
// //       _nearbyVenueFetchError = null;
// //       _exploreVenueFetchError = null;
// //     });
    
// //     _currentPosition = await _locationService.getCurrentLocation();
    
// //     if (!mounted) return;
    
// //     setStateIfMounted(() {
// //       _isFetchingLocation = false;
// //       _locationStatusMessage = _currentPosition != null ? 'Location acquired.' : 'Could not get location.';
// //     });

// //     // Fetch both lists in parallel and update the state when they complete.
// //     await Future.wait([
// //       _fetchNearbyVenuesScoped(),
// //       _fetchExploreVenuesFromOtherCities(),
// //     ]);
// //   }

// //   Future<void> _handleRefresh() async {
// //     if (mounted) {
// //       // Reset filters and search query
// //       setState(() {
// //         _searchQuery = null;
// //         _selectedSportFilter = null;
// //         // NOTE: We don't clear the city filter on pull-to-refresh, which is standard UX.
// //       });
// //       // Trigger a fetch with the new (potentially cleared) state.
// //       _onFilterOrSearchChanged();
// //     }
// //   }
  
// //   // --- The rest of the file remains the same ---
// //   // --- All helper methods and build methods are unchanged ---

// //   void _updateSelectedCityIconFromFilter() {
// //     if (_selectedCityFilter == null) {
// //       _selectedCityIcon = Icons.my_location;
// //     } else {
// //       try {
// //         final cityInfo = kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
// //         _selectedCityIcon = cityInfo.icon;
// //       } catch (e) {
// //         _selectedCityIcon = Icons.location_city_outlined;
// //       }
// //     }
// //   }

// //   void _setupFavoritesStream() {
// //     _favoritesSubscription?.cancel();
// //     if (_currentUser != null) {
// //         _favoritesStream = _userService.getFavoriteVenueIdsStream();
// //         _favoritesSubscription = _favoritesStream?.listen(
// //           (favoriteIds) {
// //             if (mounted) {
// //               final newIdsSet = favoriteIds.toSet();
// //               final currentIdsSet = _favoriteVenueIds.toSet();
// //               if (newIdsSet.difference(currentIdsSet).isNotEmpty || currentIdsSet.difference(newIdsSet).isNotEmpty) {
// //                 setStateIfMounted(() => _favoriteVenueIds = favoriteIds);
// //               }
// //             }
// //           },
// //           onError: (error) { debugPrint("Error in favorites stream: $error"); }
// //         );
// //         if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);
// //     } else {
// //       if (mounted) {
// //          setStateIfMounted(() { _favoriteVenueIds = []; _isLoadingFavorites = false; _favoritesStream = null; _favoritesSubscription = null; });
// //       }
// //     }
// //   }

// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     final currentAuthUser = FirebaseAuth.instance.currentUser;
// //     if (currentAuthUser != _currentUser) {
// //       _currentUser = currentAuthUser;
// //       _initializeScreen();
// //       _setupFavoritesStream();
// //       if (mounted) setStateIfMounted(_updateSelectedCityIconFromFilter);
// //     }
// //   }

// //   Future<void> _fetchNearbyVenuesScoped() async {
// //     if (!mounted) return;
// //     if (_currentPosition == null) {
// //       if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = false; _nearbyVenueFetchError = "Location not available."; _nearbyVenues = []; });
// //       return;
// //     }
// //     if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = true; _nearbyVenueFetchError = null; _nearbyVenues = []; });
// //     try {
// //       final venuesData = await _firestoreService.getVenues(userLocation: _currentPosition, radiusInKm: 25.0);
// //       if (!mounted) return;
// //       setStateIfMounted(() => _nearbyVenues = venuesData);
// //     } catch (e) {
// //       if (!mounted) return;
// //       setStateIfMounted(() => _nearbyVenueFetchError = "Could not load nearby venues.");
// //     } finally {
// //       if (!mounted) return;
// //       setStateIfMounted(() => _isLoadingNearbyVenues = false);
// //     }
// //   }

// //   Future<void> _fetchExploreVenuesFromOtherCities() async {
// //     if (!mounted) return;
// //     setStateIfMounted(() { _isLoadingExploreVenues = true; _exploreVenueFetchError = null; _exploreVenues = [];});
// //     List<Map<String, dynamic>> allExploreVenues = [];
// //     try {
// //       for (String city in _supportedCities) {
// //         final cityVenues = await _firestoreService.getVenues(cityFilter: city, userLocation: _currentPosition, limit: 5);
// //         allExploreVenues.addAll(cityVenues);
// //         if (!mounted) return;
// //       }
// //       final uniqueExploreVenues = allExploreVenues.fold<Map<String, Map<String, dynamic>>>({}, (map, venue) {
// //           final String? venueId = venue['id'] as String?;
// //           if (venueId != null) map[venueId] = venue;
// //           return map;
// //         }).values.toList();

// //       if (_currentPosition != null) {
// //         uniqueExploreVenues.sort((a, b) {
// //           final distA = a['distance'] as double?; final distB = b['distance'] as double?;
// //           if (distA != null && distB != null) return distA.compareTo(distB);
// //           if (distA != null) return -1;
// //           if (distB != null) return 1;
// //           return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
// //         });
// //       } else {
// //          uniqueExploreVenues.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
// //       }
// //       if(!mounted) return;
// //       setStateIfMounted(() => _exploreVenues = uniqueExploreVenues.take(15).toList());
// //     } catch (e) {
// //       if (!mounted) return;
// //       setStateIfMounted(() => _exploreVenueFetchError = "Could not load explore venues.");
// //     } finally {
// //       if (!mounted) return;
// //       setStateIfMounted(() => _isLoadingExploreVenues = false);
// //     }
// //   }

// //   Future<void> _fetchUserNameAndPic() async {
// //     if (!mounted) return;
// //     _setLoadingName(true); final currentUser = _currentUser;
// //     if (currentUser == null) { if(mounted) _updateUserNameAndPic('Guest', null); _setLoadingName(false); return; }
// //     try {
// //       final userData = await _userService.getUserProfileData();
// //       if (!mounted) return;
// //       final fetchedName = userData?['name'] as String? ?? currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// //       final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
// //       _updateUserNameAndPic(fetchedName, fetchedPicUrl);
// //     } catch (e) {
// //       if (!mounted) return;
// //       final fallbackName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
// //       _updateUserNameAndPic(fallbackName, null);
// //     } finally { if(mounted) _setLoadingName(false); }
// //   }

// //   void _setLoadingName(bool isLoading) => {if(mounted) setStateIfMounted(() => _isLoadingName = isLoading)};
// //   void _updateUserNameAndPic(String name, String? picUrl) => {if(mounted) setStateIfMounted(() { _userName = name; _userProfilePicUrl = picUrl; })};

// //   void _navigateToVenueDetail(Map<String, dynamic> venue) {
// //     if (!context.mounted) return;
// //     Navigator.push(context, MaterialPageRoute(builder: (context) => VenueDetailScreen(venueId: venue['id'] as String, initialVenueData: venue)));
// //   }

// //   void _openSearchMobile() async {
// //      if (!context.mounted) return;
// //      final String? submittedQuery = await showSearch<String?>(
// //         context: context,
// //         delegate: VenueSearchDelegate(
// //             firestoreService: _firestoreService,
// //             initialCityFilter: _selectedCityFilter,
// //         )
// //     );
// //     _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
// //   }

// //   Future<void> _openCitySelectionScreen() async {
// //     if (!context.mounted) return;
// //     final String? newSelectedCityName = await Navigator.push<String?>(
// //       context,
// //       MaterialPageRoute(builder: (context) => CitySelectionScreen(currentSelectedCity: _selectedCityFilter)),
// //     );

// //     if (mounted && newSelectedCityName != _selectedCityFilter) {
// //       setStateIfMounted(() {
// //         _selectedCityFilter = newSelectedCityName; 
// //         _updateSelectedCityIconFromFilter(); 
// //       });
// //       _onFilterOrSearchChanged(); 
// //     }
// //   }
  
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
// //     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ?? theme.appBarTheme.iconTheme?.color ?? (kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white);
// //     final bool isLoggedIn = _currentUser != null;

// //     return Scaffold(
// //       appBar: AppBar(
// //         automaticallyImplyLeading: false,
// //         title: kIsWeb ? _buildWebAppBarTitle(context) : _buildMobileAppBarTitle(context, theme),
// //         actions: kIsWeb ? _buildWebAppBarActions(context, isLoggedIn, actionsIconColor) : _buildMobileAppBarActions(context, isLoggedIn, actionsIconColor),
// //         backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
// //         elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
// //         iconTheme: theme.iconTheme.copyWith(color: kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white),
// //         actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
// //         titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ?? TextStyle(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
// //       ),
// //       floatingActionButton: widget.showAddVenueButton
// //           ? FloatingActionButton.extended(
// //               onPressed: () {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(builder: (context) => const AddVenueFormScreen()),
// //                 ).then((result) {
// //                   if (result == true && mounted) {
// //                     _handleRefresh();
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       const SnackBar(content: Text("Venue list updated."), backgroundColor: Colors.blueAccent),
// //                     );
// //                   }
// //                 });
// //               },
// //               icon: const Icon(Icons.add_location_alt_outlined),
// //               label: const Text("Add Venue"),
// //               tooltip: 'Add New Venue',
// //             )
// //           : null,
// //       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
// //       body: _buildBodyContent(),
// //     );
// //   }

// //   Widget _buildWebAppBarTitle(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final currentUser = _currentUser;
// //     double screenWidth = MediaQuery.of(context).size.width;
// //     double leadingWidth = 150 + (_userName != null ? 100 : 0);
// //     double searchWidthFraction = 0.4;
// //     double minSearchWidth = 200;
// //     double maxSearchWidth = 500;
// //     double actionsWidth = 80 + (_currentUser != null ? 120 : 0);
// //     double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
// //     double calculatedSearchWidth = (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);
// //     double spacerFlexFactor = (availableWidth > calculatedSearchWidth + 40)
// //         ? (availableWidth - calculatedSearchWidth) / 2 / availableWidth
// //         : 0.05;
// //     int searchFlex = (searchWidthFraction * 100).toInt();
// //     int spacerFlex = (spacerFlexFactor * 100).toInt().clamp(5, 50);

// //     return Row(children: [
// //       Text('MM Associates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
// //       const SizedBox(width: 24),
// //       if (_isLoadingName && currentUser != null)
// //         const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
// //       else if (_userName != null && currentUser != null)
// //         Padding(
// //           padding: const EdgeInsets.only(right: 16.0),
// //           child: Text('Hi, ${_userName!.split(' ')[0]}!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)
// //         ),
// //       Spacer(flex: spacerFlex),
// //       Expanded(
// //         flex: searchFlex,
// //         child: Container(
// //           constraints: BoxConstraints(maxWidth: maxSearchWidth),
// //           child: WebSearchBar(
// //             key: ValueKey(_searchQuery ?? 'initial'),
// //             initialValue: _searchQuery ?? '',
// //             cityFilter: _selectedCityFilter,
// //             firestoreService: _firestoreService,
// //             onSearchSubmitted: (query) {
// //               _onFilterOrSearchChanged(explicitSearchQuery: query);
// //             },
// //             onSuggestionSelected: (suggestionName) {
// //               _onFilterOrSearchChanged(explicitSearchQuery: suggestionName);
// //             },
// //             onClear: () {
// //               _onFilterOrSearchChanged(explicitSearchQuery: null);
// //             },
// //           ),
// //         ),
// //       ),
// //       Spacer(flex: spacerFlex),
// //     ]);
// //   }
  
// //   List<Widget> _buildMobileAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// //     final String cityNameText = _selectedCityFilter ?? 'Near Me';
// //     final double textSize = 10.0; 

// //     return [
// //       IconButton(
// //         icon: Icon(Icons.search_outlined, color: iconColor),
// //         tooltip: 'Search Venues',
// //         onPressed: _openSearchMobile,
// //         padding: const EdgeInsets.symmetric(horizontal: 8),
// //         constraints: const BoxConstraints(),
// //       ),
// //       Tooltip( 
// //         message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// //         child: IconButton(
// //           icon: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Icon(
// //                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// //                 color: iconColor,
// //                 size: 24,
// //               ),
// //               const SizedBox(height: 2), 
// //               Text(
// //                 cityNameText,
// //                 style: TextStyle(
// //                   color: iconColor,
// //                   fontSize: textSize,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //                 overflow: TextOverflow.ellipsis,
// //                 maxLines: 1,
// //               ),
// //             ],
// //           ),
// //           onPressed: _openCitySelectionScreen,
// //           padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
// //           constraints: const BoxConstraints(),
// //         ),
// //       ),
// //       if (isLoggedIn)
// //         IconButton(
// //           icon: Icon(Icons.person_outline_rounded, color: iconColor),
// //           tooltip: 'My Profile',
// //           onPressed: () {
// //             if (!context.mounted) return;
// //             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// //                 .then((_) {
// //               if (mounted) _fetchUserNameAndPic();
// //             });
// //           },
// //           padding: const EdgeInsets.symmetric(horizontal: 8),
// //           constraints: const BoxConstraints(),
// //         ),
// //     ];
// //   }
  
// //   Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
// //     final titleStyle = theme.appBarTheme.titleTextStyle ?? theme.primaryTextTheme.titleLarge ?? const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
// //     final currentUser = _currentUser;
// //     return Row(children: [
// //         if (currentUser != null)
// //           GestureDetector(
// //             onTap: () {
// //               if (!context.mounted) return;
// //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// //                   .then((_) { if (mounted) _fetchUserNameAndPic(); });
// //             },
// //             child: Tooltip(
// //               message: "My Profile",
// //               child: Padding(
// //                 padding: const EdgeInsets.only(right: 10.0),
// //                 child: CircleAvatar(
// //                   radius: 18,
// //                   backgroundColor: Colors.white24,
// //                   backgroundImage: _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty ? NetworkImage(_userProfilePicUrl!) : null,
// //                   child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty ? Icon(Icons.person_outline, size: 20, color: Colors.white.withOpacity(0.8)) : null
// //                 )
// //               ),
// //             ),
// //           ),
// //         if (_isLoadingName && currentUser != null)
// //           const Padding(
// //             padding: EdgeInsets.only(left: 6.0),
// //             child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)))
// //           )
// //         else if (_userName != null && currentUser != null)
// //           Expanded(
// //             child: Padding(
// //                padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
// //               child: Text(
// //                 'Hi, ${_userName!.split(' ')[0]}!',
// //                 style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
// //                 overflow: TextOverflow.ellipsis
// //               )
// //             )
// //           )
// //         else
// //           Text('MM Associates', style: titleStyle),
// //       ]
// //     );
// //   }

// //   List<Widget> _buildWebAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
// //     final String cityNameText = _selectedCityFilter ?? 'Near Me';
// //     final double textSize = 10.0;

// //     return [
// //       Tooltip(
// //         message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
// //         child: IconButton(
// //           icon: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Icon(
// //                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
// //                 color: iconColor,
// //                 size: 24,
// //               ),
// //               const SizedBox(height: 2),
// //               Text(
// //                 cityNameText,
// //                 style: TextStyle(
// //                   color: iconColor,
// //                   fontSize: textSize,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //                 overflow: TextOverflow.ellipsis,
// //                 maxLines: 1,
// //               ),
// //             ],
// //           ),
// //           onPressed: _openCitySelectionScreen,
// //           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
// //           constraints: const BoxConstraints(),
// //         ),
// //       ),
// //       if (isLoggedIn)
// //         Tooltip(
// //           message: 'My Profile',
// //           child: IconButton(
// //             icon: Icon(Icons.person_outline_rounded, color: iconColor),
// //             onPressed: () {
// //               if (!context.mounted) return;
// //               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
// //                   .then((_) {
// //                 if (mounted) _fetchUserNameAndPic();
// //               });
// //             },
// //             padding: const EdgeInsets.symmetric(horizontal: 16),
// //             constraints: const BoxConstraints(),
// //           ),
// //         ),
// //       const SizedBox(width: 8)
// //     ];
// //   }

// //   Widget _buildQuickSportFilters() {
// //     final theme = Theme.of(context);
// //     return Container(
// //       height: 55,
// //       color: theme.cardColor,
// //       child: ListView.separated(
// //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// //         scrollDirection: Axis.horizontal,
// //         itemCount: _quickSportFilters.length + 1,
// //         separatorBuilder: (context, index) => const SizedBox(width: 10),
// //         itemBuilder: (context, index) {
// //           if (index == 0) {
// //             final bool isSelected = _selectedSportFilter == null;
// //             return ChoiceChip(
// //               label: const Text('All Sports'),
// //               selected: isSelected,
// //               onSelected: (bool nowSelected) {
// //                 if (nowSelected && _selectedSportFilter != null) {
// //                     setStateIfMounted(() => _selectedSportFilter = null);
// //                     _onFilterOrSearchChanged();
// //                 }
// //               },
// //               selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// //               backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// //               labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// //               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// //               visualDensity: VisualDensity.compact,
// //                showCheckmark: false,
// //             );
// //           }
// //           final sport = _quickSportFilters[index - 1];
// //           final bool isSelected = _selectedSportFilter == sport;
// //           return ChoiceChip(
// //             label: Text(sport),
// //             selected: isSelected,
// //             onSelected: (bool isNowSelected) {
// //               final newFilter = isNowSelected ? sport : null;
// //               if (_selectedSportFilter != newFilter) {
// //                 setStateIfMounted(() => _selectedSportFilter = newFilter);
// //                 _onFilterOrSearchChanged();
// //               }
// //             },
// //             selectedColor: theme.colorScheme.primary.withOpacity(0.2),
// //             backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
// //             labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
// //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
// //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// //             visualDensity: VisualDensity.compact,
// //             showCheckmark: false,
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildBodyContent() {
// //      return Column(children: [
// //          _buildQuickSportFilters(),
// //          Expanded(
// //            child: RefreshIndicator(
// //              onRefresh: _handleRefresh,
// //              child: ListView(
// //                padding: EdgeInsets.zero,
// //                children: [
// //                  if (_isSearchingOrFiltering) ...[
// //                    _buildSectionHeader(context,
// //                         _searchQuery != null && _searchQuery!.isNotEmpty
// //                             ? "Results for \"$_searchQuery\""
// //                             : (_selectedCityFilter != null
// //                                 ? "Venues in $_selectedCityFilter"
// //                                 : (_selectedSportFilter != null ? "Venues for $_selectedSportFilter" : "Filtered Venues")
// //                             )
// //                     ),
// //                    _buildVenueList(_filteredVenues, _isLoadingFilteredVenues, _filteredVenueFetchError, "No venues found for your selection.", isNearbySection: false),
// //                  ] else ...[
// //                    if (_currentPosition != null || _isLoadingNearbyVenues)
// //                        _buildSectionHeader(context, "Venues Near You"),
// //                    _buildVenueList(_nearbyVenues, _isLoadingNearbyVenues, _nearbyVenueFetchError, "No venues found nearby. Try exploring other cities.", isNearbySection: true),
// //                    const SizedBox(height: 16),
// //                    _buildSectionHeader(context, "Explore Venues"),
// //                    _buildVenueList(_exploreVenues, _isLoadingExploreVenues, _exploreVenueFetchError, "No venues to explore at the moment.", isNearbySection: false),
// //                   ],
// //                  const SizedBox(height: 80),
// //                ],
// //              ),
// //            ),
// //          ),
// //        ]
// //      );
// //   }
  
// //   Widget _buildSectionHeader(BuildContext context, String title) {
// //     return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
// //       child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
// //   }

// //   Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg, String emptyMsg, {bool isNearbySection = false}) {
// //      if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
// //      if (errorMsg != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16))));
// //      if (venues.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

// //      return GridView.builder(
// //        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// //        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
// //        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// //            maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
// //            mainAxisSpacing: 16.0,
// //            crossAxisSpacing: 16.0,
// //            childAspectRatio: 0.70
// //         ),
// //        itemCount: venues.length,
// //        itemBuilder: (context, index) {
// //          final venue = venues[index];
// //          final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
// //          return _buildVenueGridCard(venue, isFavorite: isFavorite);
// //        },
// //      );
// //    }

// //   Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
// //     return Shimmer.fromColors(baseColor: Colors.grey[350]!, highlightColor: Colors.grey[200]!,
// //       child: GridView.builder(
// //         shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
// //         padding: const EdgeInsets.all(16.0),
// //         gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0, mainAxisSpacing: 16.0, crossAxisSpacing: 16.0, childAspectRatio: 0.70),
// //         itemCount: itemCount, itemBuilder: (context, index) => _buildVenueShimmerCard())
// //       );
// //   }
// //   Widget _buildVenueShimmerCard() {
// //     return Card(
// //       margin: EdgeInsets.zero, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
// //       child: Column(children: [
// //         Container(height: 130, width: double.infinity, color: Colors.white),
// //         Expanded(child: Padding(padding: const EdgeInsets.all(10.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// //           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //             Container(width: double.infinity, height: 18.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// //             Container(width: MediaQuery.of(context).size.width * 0.3, height: 14.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
// //             Container(width: MediaQuery.of(context).size.width * 0.2, height: 12.0, color: Colors.white)]),
// //           Container(width: double.infinity, height: 12.0, color: Colors.white)
// //           ])))
// //       ]));
// //   }

// //   Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite}) {
// //       final String venueId = venue['id'] as String? ?? '';
// //       return _VenueCardWidget(
// //         key: ValueKey(venueId),
// //         venue: venue,
// //         isFavorite: isFavorite,
// //         onTapCard: () => _navigateToVenueDetail(venue),
// //         onTapFavorite: () => _toggleFavorite(venueId, isFavorite),
// //       );
// //     }

// //   Future<void> _toggleFavorite(String venueId, bool currentIsFavorite) async {
// //     if (!mounted) return;
// //     final currentUser = _currentUser;
// //     if (currentUser == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in to manage favorites.")));
// //       return;
// //     }
// //     if (venueId.isEmpty) return;
// //     try {
// //       if (!currentIsFavorite) {
// //         await _userService.addFavorite(venueId);
// //       } else {
// //         await _userService.removeFavorite(venueId);
// //       }
// //     } catch (e) {
// //       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating favorites: ${e.toString()}")));
// //     }
// //   }
// // }

// // class _VenueCardWidget extends StatefulWidget {
// //   final Map<String, dynamic> venue;
// //   final bool isFavorite;
// //   final VoidCallback onTapCard;
// //   final Future<void> Function() onTapFavorite;

// //   const _VenueCardWidget({
// //     required Key key,
// //     required this.venue,
// //     required this.isFavorite,
// //     required this.onTapCard,
// //     required this.onTapFavorite,
// //   }) : super(key: key);

// //   @override
// //   _VenueCardWidgetState createState() => _VenueCardWidgetState();
// // }

// // class _VenueCardWidgetState extends State<_VenueCardWidget> with SingleTickerProviderStateMixin {
// //   late AnimationController _favoriteAnimationController;
// //   late Animation<double> _favoriteScaleAnimation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _favoriteAnimationController = AnimationController(
// //       duration: const Duration(milliseconds: 300),
// //       vsync: this,
// //     );
// //     _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
// //       CurvedAnimation(parent: _favoriteAnimationController, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
// //     );
// //   }

// //   @override
// //   void didUpdateWidget(_VenueCardWidget oldWidget) {
// //     super.didUpdateWidget(oldWidget);
// //     if (widget.isFavorite != oldWidget.isFavorite && mounted) {
// //       if (widget.isFavorite) {
// //         _favoriteAnimationController.forward(from: 0.0).catchError((e) { if (e is! TickerCanceled) debugPrint("Error playing fav animation: $e"); });
// //       } else {
// //          _favoriteAnimationController.reverse().catchError((e) { if (e is! TickerCanceled) debugPrint("Error reversing fav animation: $e"); });
// //       }
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _favoriteAnimationController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final ThemeData theme = Theme.of(context);
// //     final String name = widget.venue['name'] as String? ?? 'Unnamed Venue';
// //     final dynamic sportRaw = widget.venue['sportType'];
// //     final String sport = (sportRaw is String) ? sportRaw : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
// //     final String? imageUrl = widget.venue['imageUrl'] as String?;
// //     final String city = widget.venue['city'] as String? ?? '';
// //     final String venueId = widget.venue['id'] as String? ?? '';
// //     final double? distance = widget.venue['distance'] as double?;
// //     final double averageRating = (widget.venue['averageRating'] as num?)?.toDouble() ?? 0.0;
// //     final int reviewCount = (widget.venue['reviewCount'] as num?)?.toInt() ?? 0;

// //     return MouseRegion(
// //       cursor: SystemMouseCursors.click,
// //       child: Card(
// //         margin: EdgeInsets.zero,
// //         elevation: 3,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         clipBehavior: Clip.antiAlias,
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             SizedBox(
// //               height: 130,
// //               width: double.infinity,
// //               child: Stack(
// //                 children: [
// //                   Positioned.fill(
// //                     child: InkWell(
// //                       onTap: widget.onTapCard,
// //                       child: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
// //                           ? Hero(
// //                               tag: 'venue_image_$venueId',
// //                               child: Image.network(
// //                                 imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
// //                                 loadingBuilder: (context, child, loadingProgress) => (loadingProgress == null) ? child : Container(height: 130, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null))),
// //                                 errorBuilder: (context, error, stackTrace) => Container(height: 130, color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40))),
// //                               ),
// //                             )
// //                           : Container(height: 130, color: theme.primaryColor.withOpacity(0.08), child: Center(child: Icon(Icons.sports_soccer_outlined, size: 50, color: theme.primaryColor.withOpacity(0.7)))),
// //                     ),
// //                   ),
// //                   Positioned(
// //                     top: 6, right: 6,
// //                     child: Material(
// //                       color: Colors.black.withOpacity(0.45), shape: const CircleBorder(),
// //                       child: InkWell(
// //                         borderRadius: BorderRadius.circular(20),
// //                         onTap: widget.onTapFavorite,
// //                         child: Padding(
// //                           padding: const EdgeInsets.all(7.0),
// //                           child: ScaleTransition(
// //                             scale: _favoriteScaleAnimation,
// //                             child: Icon(
// //                               widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
// //                               color: widget.isFavorite ? Colors.pinkAccent[100] : Colors.white,
// //                               size: 22,
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                   if (distance != null)
// //                     Positioned(
// //                       bottom: 6, left: 6,
// //                       child: Container(
// //                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// //                         decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
// //                         child: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //             Expanded(
// //               child: InkWell(
// //                 onTap: widget.onTapCard,
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(10.0),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         mainAxisSize: MainAxisSize.min,
// //                         children: [
// //                           Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
// //                           const SizedBox(height: 4),
// //                           Row(children: [
// //                             Icon(Icons.sports_kabaddi_outlined, size: 14, color: theme.colorScheme.secondary),
// //                             const SizedBox(width: 4),
// //                             Expanded(child: Text(sport, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// //                           ]),
// //                           if (reviewCount > 0)
// //                             Padding(
// //                                padding: const EdgeInsets.only(top: 5.0),
// //                                child: Row(children: [
// //                                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
// //                                 const SizedBox(width: 4),
// //                                 Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
// //                                 const SizedBox(width: 4),
// //                                 Text("($reviewCount reviews)", style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
// //                               ]),
// //                              ),
// //                         ],
// //                       ),
// //                       Row(
// //                         children: [
// //                           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
// //                           const SizedBox(width: 4),
// //                           Expanded(child: Text(city, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// //icons alignemnet-----
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:mm_associates/features/data/services/firestore_service.dart';
// import 'package:mm_associates/features/home/screens/venue_form.dart';
// import 'package:mm_associates/features/auth/services/auth_service.dart';
// import 'package:mm_associates/features/user/services/user_service.dart';
// import 'package:mm_associates/core/services/location_service.dart';
// import 'package:mm_associates/features/profile/screens/profile_screen.dart';
// import 'venue_detail_screen.dart';
// import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// import 'dart:async';
// import 'package:shimmer/shimmer.dart';
// import 'city_selection_screen.dart' show CitySelectionScreen, CityInfo, kAppAllCities;
// import 'package:mm_associates/features/home/widgets/home_search_components.dart';

// class HomeScreen extends StatefulWidget {
//   final bool showAddVenueButton;

//   const HomeScreen({
//     super.key,
//     required this.showAddVenueButton,
//   });

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   final AuthService _authService = AuthService();
//   final FirestoreService _firestoreService = FirestoreService();
//   final LocationService _locationService = LocationService();
//   final UserService _userService = UserService();

//   // --- State Variables ---
//   String? _searchQuery;
//   String? _selectedCityFilter;
//   IconData? _selectedCityIcon;
//   String? _selectedSportFilter;

//   User? _currentUser;
//   String? _userName;
//   String? _userProfilePicUrl;
//   bool _isLoadingName = true;

//   List<Map<String, dynamic>> _filteredVenues = [];
//   bool _isLoadingFilteredVenues = true;
//   String? _filteredVenueFetchError;

//   List<Map<String, dynamic>> _nearbyVenues = [];
//   bool _isLoadingNearbyVenues = true;
//   String? _nearbyVenueFetchError;

//   List<Map<String, dynamic>> _exploreVenues = [];
//   bool _isLoadingExploreVenues = true;
//   String? _exploreVenueFetchError;

//   Position? _currentPosition;
//   bool _isFetchingLocation = false;
//   String? _locationStatusMessage;

//   // Favorites State
//   List<String> _favoriteVenueIds = [];
//   bool _isLoadingFavorites = true;
//   Stream<List<String>>? _favoritesStream;
//   StreamSubscription<List<String>>? _favoritesSubscription;

//   final List<String> _supportedCities = ['Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'];
//   final List<String> _quickSportFilters = ['Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'];

//   bool get _isSearchingOrFiltering => (_searchQuery != null && _searchQuery!.isNotEmpty) || _selectedCityFilter != null || _selectedSportFilter != null;

//   @override
//   void initState() {
//     super.initState();
//     _currentUser = FirebaseAuth.instance.currentUser;
//     _initializeScreen();
//     _setupFavoritesStream();
//     _updateSelectedCityIconFromFilter();
//   }

//   @override
//   void dispose() {
//     _favoritesSubscription?.cancel();
//     super.dispose();
//   }

//   void setStateIfMounted(VoidCallback fn) {
//     if (mounted) setState(fn);
//   }

//   // --- Core Logic & Data Fetching ---

//   Future<void> _initializeScreen() async {
//     await _fetchUserNameAndPic();
//     await _fetchPrimaryVenueData();
//   }

//   void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
//     if (!mounted) return;

//     setState(() {
//       _searchQuery = (explicitSearchQuery?.trim().isEmpty ?? true) ? null : explicitSearchQuery!.trim();
//     });

//     if (_isSearchingOrFiltering) {
//       _fetchVenuesForFilterOrSearch();
//     } else {
//       _fetchPrimaryVenueData();
//     }
//   }

//   Future<void> _fetchVenuesForFilterOrSearch() async {
//     if (!mounted) return;
//     setStateIfMounted(() {
//       _isLoadingFilteredVenues = true;
//       _filteredVenueFetchError = null;
//       _filteredVenues = [];
//     });

//     try {
//       final venuesData = await _firestoreService.getVenues(
//         userLocation: _currentPosition,
//         radiusInKm: _selectedCityFilter != null ? null : (_currentPosition != null ? 50.0 : null),
//         cityFilter: _selectedCityFilter,
//         searchQuery: _searchQuery,
//         sportFilter: _selectedSportFilter,
//       );
//       if (!mounted) return;
//       setStateIfMounted(() {
//         _filteredVenues = venuesData;
//       });
//     } catch (e) {
//       debugPrint("Error fetching filtered/search venues: $e");
//       if (!mounted) return;
//       setStateIfMounted(() => _filteredVenueFetchError = "Could not load venues: ${e.toString().replaceFirst('Exception: ', '')}");
//     } finally {
//       if (!mounted) return;
//       setStateIfMounted(() => _isLoadingFilteredVenues = false);
//     }
//   }

//   Future<void> _fetchPrimaryVenueData() async {
//     if (!mounted) return;
//     setStateIfMounted(() {
//       _isFetchingLocation = true;
//       _isLoadingNearbyVenues = true;
//       _isLoadingExploreVenues = true;
//       _locationStatusMessage = 'Fetching your location...';
//       _nearbyVenues = [];
//       _exploreVenues = [];
//       _nearbyVenueFetchError = null;
//       _exploreVenueFetchError = null;
//     });
    
//     _currentPosition = await _locationService.getCurrentLocation();
    
//     if (!mounted) return;
    
//     setStateIfMounted(() {
//       _isFetchingLocation = false;
//       _locationStatusMessage = _currentPosition != null ? 'Location acquired.' : 'Could not get location.';
//     });

//     await Future.wait([
//       _fetchNearbyVenuesScoped(),
//       _fetchExploreVenuesFromOtherCities(),
//     ]);
//   }

//   Future<void> _handleRefresh() async {
//     if (mounted) {
//       setState(() {
//         _searchQuery = null;
//         _selectedSportFilter = null;
//       });
//       _onFilterOrSearchChanged();
//     }
//   }

//   void _updateSelectedCityIconFromFilter() {
//     if (_selectedCityFilter == null) {
//       _selectedCityIcon = Icons.my_location;
//     } else {
//       try {
//         final cityInfo = kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
//         _selectedCityIcon = cityInfo.icon;
//       } catch (e) {
//         _selectedCityIcon = Icons.location_city_outlined;
//       }
//     }
//   }

//   void _setupFavoritesStream() {
//     _favoritesSubscription?.cancel();
//     if (_currentUser != null) {
//         _favoritesStream = _userService.getFavoriteVenueIdsStream();
//         _favoritesSubscription = _favoritesStream?.listen(
//           (favoriteIds) {
//             if (mounted) {
//               final newIdsSet = favoriteIds.toSet();
//               final currentIdsSet = _favoriteVenueIds.toSet();
//               if (newIdsSet.difference(currentIdsSet).isNotEmpty || currentIdsSet.difference(newIdsSet).isNotEmpty) {
//                 setStateIfMounted(() => _favoriteVenueIds = favoriteIds);
//               }
//             }
//           },
//           onError: (error) { debugPrint("Error in favorites stream: $error"); }
//         );
//         if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);
//     } else {
//       if (mounted) {
//          setStateIfMounted(() { _favoriteVenueIds = []; _isLoadingFavorites = false; _favoritesStream = null; _favoritesSubscription = null; });
//       }
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final currentAuthUser = FirebaseAuth.instance.currentUser;
//     if (currentAuthUser != _currentUser) {
//       _currentUser = currentAuthUser;
//       _initializeScreen();
//       _setupFavoritesStream();
//       if (mounted) setStateIfMounted(_updateSelectedCityIconFromFilter);
//     }
//   }

//   Future<void> _fetchNearbyVenuesScoped() async {
//     if (!mounted) return;
//     if (_currentPosition == null) {
//       if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = false; _nearbyVenueFetchError = "Location not available."; _nearbyVenues = []; });
//       return;
//     }
//     if(mounted) setStateIfMounted(() { _isLoadingNearbyVenues = true; _nearbyVenueFetchError = null; _nearbyVenues = []; });
//     try {
//       final venuesData = await _firestoreService.getVenues(userLocation: _currentPosition, radiusInKm: 25.0);
//       if (!mounted) return;
//       setStateIfMounted(() => _nearbyVenues = venuesData);
//     } catch (e) {
//       if (!mounted) return;
//       setStateIfMounted(() => _nearbyVenueFetchError = "Could not load nearby venues.");
//     } finally {
//       if (!mounted) return;
//       setStateIfMounted(() => _isLoadingNearbyVenues = false);
//     }
//   }

//   Future<void> _fetchExploreVenuesFromOtherCities() async {
//     if (!mounted) return;
//     setStateIfMounted(() { _isLoadingExploreVenues = true; _exploreVenueFetchError = null; _exploreVenues = [];});
//     List<Map<String, dynamic>> allExploreVenues = [];
//     try {
//       for (String city in _supportedCities) {
//         final cityVenues = await _firestoreService.getVenues(cityFilter: city, userLocation: _currentPosition, limit: 5);
//         allExploreVenues.addAll(cityVenues);
//         if (!mounted) return;
//       }
//       final uniqueExploreVenues = allExploreVenues.fold<Map<String, Map<String, dynamic>>>({}, (map, venue) {
//           final String? venueId = venue['id'] as String?;
//           if (venueId != null) map[venueId] = venue;
//           return map;
//         }).values.toList();

//       if (_currentPosition != null) {
//         uniqueExploreVenues.sort((a, b) {
//           final distA = a['distance'] as double?; final distB = b['distance'] as double?;
//           if (distA != null && distB != null) return distA.compareTo(distB);
//           if (distA != null) return -1;
//           if (distB != null) return 1;
//           return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
//         });
//       } else {
//          uniqueExploreVenues.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
//       }
//       if(!mounted) return;
//       setStateIfMounted(() => _exploreVenues = uniqueExploreVenues.take(15).toList());
//     } catch (e) {
//       if (!mounted) return;
//       setStateIfMounted(() => _exploreVenueFetchError = "Could not load explore venues.");
//     } finally {
//       if (!mounted) return;
//       setStateIfMounted(() => _isLoadingExploreVenues = false);
//     }
//   }

//   Future<void> _fetchUserNameAndPic() async {
//     if (!mounted) return;
//     _setLoadingName(true); final currentUser = _currentUser;
//     if (currentUser == null) { if(mounted) _updateUserNameAndPic('Guest', null); _setLoadingName(false); return; }
//     try {
//       final userData = await _userService.getUserProfileData();
//       if (!mounted) return;
//       final fetchedName = userData?['name'] as String? ?? currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
//       final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
//       _updateUserNameAndPic(fetchedName, fetchedPicUrl);
//     } catch (e) {
//       if (!mounted) return;
//       final fallbackName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
//       _updateUserNameAndPic(fallbackName, null);
//     } finally { if(mounted) _setLoadingName(false); }
//   }

//   void _setLoadingName(bool isLoading) => {if(mounted) setStateIfMounted(() => _isLoadingName = isLoading)};
//   void _updateUserNameAndPic(String name, String? picUrl) => {if(mounted) setStateIfMounted(() { _userName = name; _userProfilePicUrl = picUrl; })};

//   void _navigateToVenueDetail(Map<String, dynamic> venue) {
//     if (!context.mounted) return;
//     Navigator.push(context, MaterialPageRoute(builder: (context) => VenueDetailScreen(venueId: venue['id'] as String, initialVenueData: venue)));
//   }

//   void _openSearchMobile() async {
//      if (!context.mounted) return;
//      final String? submittedQuery = await showSearch<String?>(
//         context: context,
//         delegate: VenueSearchDelegate(
//             firestoreService: _firestoreService,
//             initialCityFilter: _selectedCityFilter,
//         )
//     );
//     _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
//   }

//   Future<void> _openCitySelectionScreen() async {
//     if (!context.mounted) return;
//     final String? newSelectedCityName = await Navigator.push<String?>(
//       context,
//       MaterialPageRoute(builder: (context) => CitySelectionScreen(currentSelectedCity: _selectedCityFilter)),
//     );

//     if (mounted && newSelectedCityName != _selectedCityFilter) {
//       setStateIfMounted(() {
//         _selectedCityFilter = newSelectedCityName; 
//         _updateSelectedCityIconFromFilter(); 
//       });
//       _onFilterOrSearchChanged(); 
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
//     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ?? theme.appBarTheme.iconTheme?.color ?? (kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white);
//     final bool isLoggedIn = _currentUser != null;

//     return Scaffold(
//       appBar: AppBar(
//         // ----- THE KEY FIX: INCREASING THE APP BAR HEIGHT -----
//         toolbarHeight: 70.0, // This gives enough room for the translated widget
//         automaticallyImplyLeading: false,
//         title: kIsWeb ? _buildWebAppBarTitle(context) : _buildMobileAppBarTitle(context, theme),
//         actions: _buildAppBarActions(context, isLoggedIn, actionsIconColor),
//         backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
//         elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
//         iconTheme: theme.iconTheme.copyWith(color: kIsWeb ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87) : Colors.white),
//         actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
//         titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ?? TextStyle(color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
//       ),
//       floatingActionButton: widget.showAddVenueButton
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const AddVenueFormScreen()),
//                 ).then((result) {
//                   if (result == true && mounted) {
//                     _handleRefresh();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Venue list updated."), backgroundColor: Colors.blueAccent),
//                     );
//                   }
//                 });
//               },
//               icon: const Icon(Icons.add_location_alt_outlined),
//               label: const Text("Add Venue"),
//               tooltip: 'Add New Venue',
//             )
//           : null,
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       body: _buildBodyContent(),
//     );
//   }

//   Widget _buildWebAppBarTitle(BuildContext context) {
//     final theme = Theme.of(context);
//     final currentUser = _currentUser;
//     final bool isLoggedIn = _currentUser != null; 
    
//     double screenWidth = MediaQuery.of(context).size.width;
//     double leadingWidth = 150 + (_userName != null ? 100 : 0);
//     double searchWidthFraction = 0.4;
//     double minSearchWidth = 200;
//     double maxSearchWidth = 500;
//     double actionsWidth = kIsWeb ? (isLoggedIn ? 200 : 100) : (isLoggedIn ? 150 : 80);
//     double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
//     double calculatedSearchWidth = (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);

//     return Row(children: [
//       Text('MM Associates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
//       const SizedBox(width: 24),
//       if (_isLoadingName && currentUser != null)
//         const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
//       else if (_userName != null && currentUser != null)
//         Padding(
//           padding: const EdgeInsets.only(right: 16.0),
//           child: Text('Hi, ${_userName!.split(' ')[0]}!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)
//         ),
//       const Spacer(),
//       SizedBox(
//         width: calculatedSearchWidth,
//         child: WebSearchBar(
//           key: ValueKey(_searchQuery ?? 'initial'),
//           initialValue: _searchQuery ?? '',
//           cityFilter: _selectedCityFilter,
//           firestoreService: _firestoreService,
//           onSearchSubmitted: (query) => _onFilterOrSearchChanged(explicitSearchQuery: query),
//           onSuggestionSelected: (suggestionName) => _onFilterOrSearchChanged(explicitSearchQuery: suggestionName),
//           onClear: () => _onFilterOrSearchChanged(explicitSearchQuery: null),
//         ),
//       ),
//       const Spacer(),
//     ]);
//   }
  
//   Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
//     final titleStyle = theme.appBarTheme.titleTextStyle ?? theme.primaryTextTheme.titleLarge ?? const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
//     final currentUser = _currentUser;
//     return Row(children: [
//         if (currentUser != null)
//           GestureDetector(
//             onTap: () {
//               if (!context.mounted) return;
//               Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
//                   .then((_) { if (mounted) _fetchUserNameAndPic(); });
//             },
//             child: Tooltip(
//               message: "My Profile",
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 10.0),
//                 child: CircleAvatar(
//                   radius: 18,
//                   backgroundColor: Colors.white24,
//                   backgroundImage: _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty ? NetworkImage(_userProfilePicUrl!) : null,
//                   child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty ? Icon(Icons.person_outline, size: 20, color: Colors.white.withOpacity(0.8)) : null
//                 )
//               ),
//             ),
//           ),
//         if (_isLoadingName && currentUser != null)
//           const Padding(
//             padding: EdgeInsets.only(left: 6.0),
//             child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)))
//           )
//         else if (_userName != null && currentUser != null)
//           Expanded(
//             child: Padding(
//                padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
//               child: Text(
//                 'Hi, ${_userName!.split(' ')[0]}!',
//                 style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
//                 overflow: TextOverflow.ellipsis
//               )
//             )
//           )
//         else
//           Text('MM Associates', style: titleStyle),
//       ]
//     );
//   }

//   List<Widget> _buildAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
//     final String cityNameText = _selectedCityFilter ?? 'Near Me';
//     const double textSize = 10.0;

//     final locationButton = Tooltip(
//       message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
//       child: Transform.translate(
//         offset: const Offset(0, 9.0), // Pushes just this widget down
//         child: TextButton(
//           onPressed: _openCitySelectionScreen,
//           style: TextButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             foregroundColor: iconColor,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 _selectedCityIcon ?? (_selectedCityFilter == null ? Icons.my_location : Icons.location_city_outlined),
//                 size: 24,
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 cityNameText,
//                 style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w500),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );

//     final profileButton = isLoggedIn ? IconButton(
//       icon: Icon(Icons.person_outline_rounded, color: iconColor),
//       tooltip: 'My Profile',
//       onPressed: () {
//         if (!context.mounted) return;
//         Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
//             .then((_) => {if (mounted) _fetchUserNameAndPic()});
//       },
//     ) : null;

//     return [
//       Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: kIsWeb 
//         ? [ // Web Layout
//             locationButton,
//             if (profileButton != null) const SizedBox(width: 8),
//             if (profileButton != null) profileButton,
//             const SizedBox(width: 8),
//         ] 
//         : [ // Mobile Layout
//             IconButton(
//               icon: Icon(Icons.search_outlined, color: iconColor),
//               tooltip: 'Search Venues',
//               onPressed: _openSearchMobile,
//             ),
//             locationButton,
//             if (profileButton != null) profileButton,
//             if (profileButton == null) const SizedBox(width: 8), 
//         ],
//       )
//     ];
//   }


//   Widget _buildQuickSportFilters() {
//     final theme = Theme.of(context);
//     return Container(
//       height: 55,
//       color: theme.cardColor,
//       child: ListView.separated(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//         scrollDirection: Axis.horizontal,
//         itemCount: _quickSportFilters.length + 1,
//         separatorBuilder: (context, index) => const SizedBox(width: 10),
//         itemBuilder: (context, index) {
//           if (index == 0) {
//             final bool isSelected = _selectedSportFilter == null;
//             return ChoiceChip(
//               label: const Text('All Sports'),
//               selected: isSelected,
//               onSelected: (bool nowSelected) {
//                 if (nowSelected && _selectedSportFilter != null) {
//                     setStateIfMounted(() => _selectedSportFilter = null);
//                     _onFilterOrSearchChanged();
//                 }
//               },
//               selectedColor: theme.colorScheme.primary.withOpacity(0.2),
//               backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
//               labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//               visualDensity: VisualDensity.compact,
//                showCheckmark: false,
//             );
//           }
//           final sport = _quickSportFilters[index - 1];
//           final bool isSelected = _selectedSportFilter == sport;
//           return ChoiceChip(
//             label: Text(sport),
//             selected: isSelected,
//             onSelected: (bool isNowSelected) {
//               final newFilter = isNowSelected ? sport : null;
//               if (_selectedSportFilter != newFilter) {
//                 setStateIfMounted(() => _selectedSportFilter = newFilter);
//                 _onFilterOrSearchChanged();
//               }
//             },
//             selectedColor: theme.colorScheme.primary.withOpacity(0.2),
//             backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
//             labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey.shade300)),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//             visualDensity: VisualDensity.compact,
//             showCheckmark: false,
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBodyContent() {
//      return Column(children: [
//          _buildQuickSportFilters(),
//          Expanded(
//            child: RefreshIndicator(
//              onRefresh: _handleRefresh,
//              child: ListView(
//                padding: EdgeInsets.zero,
//                children: [
//                  if (_isSearchingOrFiltering) ...[
//                    _buildSectionHeader(context,
//                         _searchQuery != null && _searchQuery!.isNotEmpty
//                             ? "Results for \"$_searchQuery\""
//                             : (_selectedCityFilter != null
//                                 ? "Venues in $_selectedCityFilter"
//                                 : (_selectedSportFilter != null ? "Venues for $_selectedSportFilter" : "Filtered Venues")
//                             )
//                     ),
//                    _buildVenueList(_filteredVenues, _isLoadingFilteredVenues, _filteredVenueFetchError, "No venues found for your selection.", isNearbySection: false),
//                  ] else ...[
//                    if (_currentPosition != null || _isLoadingNearbyVenues)
//                        _buildSectionHeader(context, "Venues Near You"),
//                    _buildVenueList(_nearbyVenues, _isLoadingNearbyVenues, _nearbyVenueFetchError, "No venues found nearby. Try exploring other cities.", isNearbySection: true),
//                    const SizedBox(height: 16),
//                    _buildSectionHeader(context, "Explore Venues"),
//                    _buildVenueList(_exploreVenues, _isLoadingExploreVenues, _exploreVenueFetchError, "No venues to explore at the moment.", isNearbySection: false),
//                   ],
//                  const SizedBox(height: 80),
//                ],
//              ),
//            ),
//          ),
//        ]
//      );
//   }
  
//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
//       child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
//   }

//   Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg, String emptyMsg, {bool isNearbySection = false}) {
//      if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
//      if (errorMsg != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16))));
//      if (venues.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

//      return GridView.builder(
//        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
//        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
//        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//            maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
//            mainAxisSpacing: 16.0,
//            crossAxisSpacing: 16.0,
//            childAspectRatio: 0.70
//         ),
//        itemCount: venues.length,
//        itemBuilder: (context, index) {
//          final venue = venues[index];
//          final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
//          return _buildVenueGridCard(venue, isFavorite: isFavorite);
//        },
//      );
//    }

//   Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
//     return Shimmer.fromColors(baseColor: Colors.grey[350]!, highlightColor: Colors.grey[200]!,
//       child: GridView.builder(
//         shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16.0),
//         gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0, mainAxisSpacing: 16.0, crossAxisSpacing: 16.0, childAspectRatio: 0.70),
//         itemCount: itemCount, itemBuilder: (context, index) => _buildVenueShimmerCard())
//       );
//   }
//   Widget _buildVenueShimmerCard() {
//     return Card(
//       margin: EdgeInsets.zero, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
//       child: Column(children: [
//         Container(height: 130, width: double.infinity, color: Colors.white),
//         Expanded(child: Padding(padding: const EdgeInsets.all(10.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Container(width: double.infinity, height: 18.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
//             Container(width: MediaQuery.of(context).size.width * 0.3, height: 14.0, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
//             Container(width: MediaQuery.of(context).size.width * 0.2, height: 12.0, color: Colors.white)]),
//           Container(width: double.infinity, height: 12.0, color: Colors.white)
//           ])))
//       ]));
//   }

//   Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite}) {
//       final String venueId = venue['id'] as String? ?? '';
//       return _VenueCardWidget(
//         key: ValueKey(venueId),
//         venue: venue,
//         isFavorite: isFavorite,
//         onTapCard: () => _navigateToVenueDetail(venue),
//         onTapFavorite: () => _toggleFavorite(venueId, isFavorite),
//       );
//     }

//   Future<void> _toggleFavorite(String venueId, bool currentIsFavorite) async {
//     if (!mounted) return;
//     final currentUser = _currentUser;
//     if (currentUser == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in to manage favorites.")));
//       return;
//     }
//     if (venueId.isEmpty) return;
//     try {
//       if (!currentIsFavorite) {
//         await _userService.addFavorite(venueId);
//       } else {
//         await _userService.removeFavorite(venueId);
//       }
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating favorites: ${e.toString()}")));
//     }
//   }
// }

// class _VenueCardWidget extends StatefulWidget {
//   final Map<String, dynamic> venue;
//   final bool isFavorite;
//   final VoidCallback onTapCard;
//   final Future<void> Function() onTapFavorite;

//   const _VenueCardWidget({
//     required Key key,
//     required this.venue,
//     required this.isFavorite,
//     required this.onTapCard,
//     required this.onTapFavorite,
//   }) : super(key: key);

//   @override
//   _VenueCardWidgetState createState() => _VenueCardWidgetState();
// }

// class _VenueCardWidgetState extends State<_VenueCardWidget> with SingleTickerProviderStateMixin {
//   late AnimationController _favoriteAnimationController;
//   late Animation<double> _favoriteScaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _favoriteAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
//       CurvedAnimation(parent: _favoriteAnimationController, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
//     );
//   }

//   @override
//   void didUpdateWidget(_VenueCardWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isFavorite != oldWidget.isFavorite && mounted) {
//       if (widget.isFavorite) {
//         _favoriteAnimationController.forward(from: 0.0).catchError((e) { if (e is! TickerCanceled) debugPrint("Error playing fav animation: $e"); });
//       } else {
//          _favoriteAnimationController.reverse().catchError((e) { if (e is! TickerCanceled) debugPrint("Error reversing fav animation: $e"); });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _favoriteAnimationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final String name = widget.venue['name'] as String? ?? 'Unnamed Venue';
//     final dynamic sportRaw = widget.venue['sportType'];
//     final String sport = (sportRaw is String) ? sportRaw : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
//     final String? imageUrl = widget.venue['imageUrl'] as String?;
//     final String city = widget.venue['city'] as String? ?? '';
//     final String venueId = widget.venue['id'] as String? ?? '';
//     final double? distance = widget.venue['distance'] as double?;
//     final double averageRating = (widget.venue['averageRating'] as num?)?.toDouble() ?? 0.0;
//     final int reviewCount = (widget.venue['reviewCount'] as num?)?.toInt() ?? 0;

//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: Card(
//         margin: EdgeInsets.zero,
//         elevation: 3,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 130,
//               width: double.infinity,
//               child: Stack(
//                 children: [
//                   Positioned.fill(
//                     child: InkWell(
//                       onTap: widget.onTapCard,
//                       child: (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
//                           ? Hero(
//                               tag: 'venue_image_$venueId',
//                               child: Image.network(
//                                 imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
//                                 loadingBuilder: (context, child, loadingProgress) => (loadingProgress == null) ? child : Container(height: 130, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null))),
//                                 errorBuilder: (context, error, stackTrace) => Container(height: 130, color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40))),
//                               ),
//                             )
//                           : Container(height: 130, color: theme.primaryColor.withOpacity(0.08), child: Center(child: Icon(Icons.sports_soccer_outlined, size: 50, color: theme.primaryColor.withOpacity(0.7)))),
//                     ),
//                   ),
//                   Positioned(
//                     top: 6, right: 6,
//                     child: Material(
//                       color: Colors.black.withOpacity(0.45), shape: const CircleBorder(),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(20),
//                         onTap: widget.onTapFavorite,
//                         child: Padding(
//                           padding: const EdgeInsets.all(7.0),
//                           child: ScaleTransition(
//                             scale: _favoriteScaleAnimation,
//                             child: Icon(
//                               widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
//                               color: widget.isFavorite ? Colors.pinkAccent[100] : Colors.white,
//                               size: 22,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (distance != null)
//                     Positioned(
//                       bottom: 6, left: 6,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                         decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
//                         child: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: InkWell(
//                 onTap: widget.onTapCard,
//                 child: Padding(
//                   padding: const EdgeInsets.all(10.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
//                           const SizedBox(height: 4),
//                           Row(children: [
//                             Icon(Icons.sports_kabaddi_outlined, size: 14, color: theme.colorScheme.secondary),
//                             const SizedBox(width: 4),
//                             Expanded(child: Text(sport, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
//                           ]),
//                           if (reviewCount > 0)
//                             Padding(
//                                padding: const EdgeInsets.only(top: 5.0),
//                                child: Row(children: [
//                                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
//                                 const SizedBox(width: 4),
//                                 Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
//                                 const SizedBox(width: 4),
//                                 Text("($reviewCount reviews)", style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
//                               ]),
//                              ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 4),
//                           Expanded(child: Text(city, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }