// // features/home/screens/home_screen.dart

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
// import 'city_selection_screen.dart' show CitySelectionScreen, kAppAllCities;
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

//   // State Variables
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

//   final List<String> _supportedCities = [
//     'Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'
//   ];
//   final List<String> _quickSportFilters = [
//     'Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'
//   ];

//   bool get _isSearchingOrFiltering =>
//       (_searchQuery != null && _searchQuery!.isNotEmpty) ||
//       _selectedCityFilter != null ||
//       _selectedSportFilter != null;

//   @override
//   void initState() {
//     super.initState();
//     _currentUser = _authService.getCurrentUser();
//     _initializeScreen();
//   }
  
//   // <<< MODIFICATION 2: Changed return type from `void` to `Future<void>` to fix the await error. >>>
//   Future<void> _initializeScreen() async {
//     _fetchUserNameAndPic();
//     _setupFavoritesStream();

//     await _checkAndRequestLocationPermission();

//     if (_isSearchingOrFiltering) {
//       _onFilterOrSearchChanged();
//     } else {
//       _fetchPrimaryVenueData();
//     }
    
//     if(mounted) {
//        _updateSelectedCityIconFromFilter();
//     }
//   }

//   Future<void> _checkAndRequestLocationPermission() async {
//     if (!mounted) return;
//     setState(() {
//       _isFetchingLocation = true;
//       _locationStatusMessage = 'Initializing location services...';
//     });
    
//     try {
//       final position = await _locationService.getCurrentLocation();
//       if (mounted) {
//         setState(() {
//           _currentPosition = position;
//           _locationStatusMessage = position != null ? 'Location acquired.' : 'Could not determine location.';
//           _isFetchingLocation = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         debugPrint("Error in _checkAndRequestLocationPermission: $e");
//         setState(() {
//           _locationStatusMessage = 'Failed to get location.';
//           _isFetchingLocation = false;
//         });
//       }
//     }
//   }
  
//   Future<void> _fetchPrimaryVenueData() async {
//     if (!mounted) return;
//     await Future.wait([
//       _fetchNearbyVenuesScoped(), 
//       _fetchExploreVenuesFromOtherCities()
//     ]);
//   }
  
//   @override
//   void dispose() {
//     _favoritesSubscription?.cancel();
//     super.dispose();
//   }

//   void setStateIfMounted(VoidCallback fn) {
//     if (mounted) setState(fn);
//   }
  
//   Future<void> _fetchUserNameAndPic() async {
//     if (!mounted) return;
//     setState(() => _isLoadingName = true);
    
//     // <<< MODIFICATION 1: Changed `_auth.currentUser` to `_authService.getCurrentUser()`. >>>
//     final currentUser = _authService.getCurrentUser();
    
//     if (currentUser == null) {
//       if (mounted) {
//         setState(() {
//           _userName = 'Guest';
//           _userProfilePicUrl = null;
//           _isLoadingName = false;
//         });
//       }
//       return;
//     }
//     try {
//       final userData = await _userService.getUserProfileData();
//       if (!mounted) return;
//       final fetchedName = userData?['name'] as String? ??
//           currentUser.displayName ??
//           currentUser.email?.split('@')[0] ??
//           'User';
//       final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
//       setState(() {
//         _userName = fetchedName;
//         _userProfilePicUrl = fetchedPicUrl;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       final fallbackName = currentUser.displayName ??
//           currentUser.email?.split('@')[0] ??
//           'User';
//       setState(() {
//         _userName = fallbackName;
//         _userProfilePicUrl = null;
//       });
//       debugPrint("Error fetching user name: $e");
//     } finally {
//       if (mounted) setState(() => _isLoadingName = false);
//     }
//   }

//   void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
//     if (!mounted) return;

//     setState(() {
//       _searchQuery =
//           (explicitSearchQuery?.trim().isEmpty ?? true) ? null : explicitSearchQuery!.trim();
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
//         radiusInKm:
//             _selectedCityFilter != null ? null : (_currentPosition != null ? 50.0 : null),
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
//       setStateIfMounted(
//           () => _filteredVenueFetchError = "Could not load venues: ${e.toString()}");
//     } finally {
//       if (!mounted) return;
//       setStateIfMounted(() => _isLoadingFilteredVenues = false);
//     }
//   }

//   void _setupFavoritesStream() {
//     _favoritesSubscription?.cancel();
//     if (_currentUser != null) {
//       _favoritesStream = _userService.getFavoriteVenueIdsStream();
//       _favoritesSubscription = _favoritesStream?.listen((favoriteIds) {
//         if (mounted) {
//           final newIdsSet = favoriteIds.toSet();
//           final currentIdsSet = _favoriteVenueIds.toSet();
//           if (newIdsSet.difference(currentIdsSet).isNotEmpty ||
//               currentIdsSet.difference(newIdsSet).isNotEmpty) {
//             setStateIfMounted(() => _favoriteVenueIds = favoriteIds);
//           }
//         }
//       }, onError: (error) {
//         debugPrint("Error in favorites stream: $error");
//       });
//       if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);
//     } else {
//       if (mounted) {
//         setStateIfMounted(() {
//           _favoriteVenueIds = [];
//           _isLoadingFavorites = false;
//           _favoritesStream = null;
//           _favoritesSubscription = null;
//         });
//       }
//     }
//   }
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final currentAuthUser = _authService.getCurrentUser();
//     if (currentAuthUser?.uid != _currentUser?.uid) {
//       _currentUser = currentAuthUser;
//       _initializeScreen();
//     }
//   }

//   Future<void> _fetchNearbyVenuesScoped() async {
//     if (!mounted) return;
//     if (_currentPosition == null) {
//       if (mounted)
//         setStateIfMounted(() {
//           _isLoadingNearbyVenues = false;
//           _nearbyVenueFetchError = "Location not available.";
//           _nearbyVenues = [];
//         });
//       return;
//     }
//     setStateIfMounted(() {
//       _isLoadingNearbyVenues = true;
//       _nearbyVenueFetchError = null;
//       _nearbyVenues = [];
//     });
//     try {
//       final venuesData =
//           await _firestoreService.getVenues(userLocation: _currentPosition, radiusInKm: 25.0);
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
//     setStateIfMounted(() {
//       _isLoadingExploreVenues = true;
//       _exploreVenueFetchError = null;
//       _exploreVenues = [];
//     });
//     List<Map<String, dynamic>> allExploreVenues = [];
//     try {
//       for (String city in _supportedCities) {
//         final cityVenues = await _firestoreService.getVenues(
//             cityFilter: city, userLocation: _currentPosition, limit: 5);
//         allExploreVenues.addAll(cityVenues);
//         if (!mounted) return;
//       }
//       final uniqueExploreVenues = allExploreVenues.fold<Map<String, Map<String, dynamic>>>({},
//           (map, venue) {
//         final String? venueId = venue['id'] as String?;
//         if (venueId != null) map[venueId] = venue;
//         return map;
//       }).values.toList();

//       if (_currentPosition != null) {
//         uniqueExploreVenues.sort((a, b) {
//           final distA = a['distance'] as double?;
//           final distB = b['distance'] as double?;
//           if (distA != null && distB != null) return distA.compareTo(distB);
//           if (distA != null) return -1;
//           if (distB != null) return 1;
//           return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
//         });
//       } else {
//         uniqueExploreVenues
//             .sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
//       }
//       if (!mounted) return;
//       setStateIfMounted(() => _exploreVenues = uniqueExploreVenues.take(15).toList());
//     } catch (e) {
//       if (!mounted) return;
//       setStateIfMounted(() => _exploreVenueFetchError = "Could not load explore venues.");
//     } finally {
//       if (!mounted) return;
//       setStateIfMounted(() => _isLoadingExploreVenues = false);
//     }
//   }
  
//   void _updateSelectedCityIconFromFilter() {
//     if (_selectedCityFilter == null) {
//       _selectedCityIcon = Icons.my_location;
//     } else {
//       try {
//         final cityInfo =
//             kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
//         _selectedCityIcon = cityInfo.icon;
//       } catch (e) {
//         _selectedCityIcon = Icons.location_city_outlined;
//       }
//     }
//   }
  
//   Future<void> _handleRefresh() async {
//     if (mounted) {
//       setState(() {
//         _searchQuery = null;
//         _selectedSportFilter = null;
//       });
//       await _initializeScreen();
//     }
//   }

//   void _navigateToVenueDetail(Map<String, dynamic> venue) {
//     if (!context.mounted) return;
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (context) => VenueDetailScreen(
//                 venueId: venue['id'] as String, initialVenueData: venue)));
//   }

//   void _openSearchMobile() async {
//     if (!context.mounted) return;
//     final String? submittedQuery = await showSearch<String?>(
//         context: context,
//         delegate: VenueSearchDelegate(
//             firestoreService: _firestoreService, initialCityFilter: _selectedCityFilter));
//     _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
//   }

//   Future<void> _openCitySelectionScreen() async {
//     if (!context.mounted) return;
//     final String? newSelectedCityName = await Navigator.push<String?>(
//       context,
//       MaterialPageRoute(
//           builder: (context) =>
//               CitySelectionScreen(currentSelectedCity: _selectedCityFilter)),
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
//     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ??
//         theme.appBarTheme.iconTheme?.color ??
//         (kIsWeb
//             ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87)
//             : Colors.white);
//     final bool isLoggedIn = _currentUser != null;

//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 70.0,
//         automaticallyImplyLeading: false,
//         title: kIsWeb
//             ? _buildWebAppBarTitle(context)
//             : _buildMobileAppBarTitle(context, theme),
//         actions: _buildAppBarActions(context, isLoggedIn, actionsIconColor),
//         backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
//         elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
//         iconTheme: theme.iconTheme.copyWith(
//             color: kIsWeb
//                 ? (theme.brightness == Brightness.dark
//                     ? Colors.white70
//                     : Colors.black87)
//                 : Colors.white),
//         actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
//         titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
//                 color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ??
//             TextStyle(
//                 color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500),
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
//                       const SnackBar(
//                           content: Text("Venue list updated."),
//                           backgroundColor: Colors.blueAccent),
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
//     double screenWidth = MediaQuery.of(context).size.width;
//     double leadingWidth = 150 + (_userName != null ? 100 : 0);
//     double searchWidthFraction = 0.4;
//     double minSearchWidth = 200;
//     double maxSearchWidth = 500;
//     double actionsWidth =
//         80 + (_currentUser != null ? 120 : 0);
//     double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
//     double calculatedSearchWidth =
//         (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);
        
//     return Row(children: [
//       Text('MM Associates',
//           style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
//       const SizedBox(width: 24),
//       if (_isLoadingName && currentUser != null)
//         const Padding(
//             padding: EdgeInsets.only(right: 16.0),
//             child: SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2)))
//       else if (_userName != null && currentUser != null)
//         Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Text('Hi, ${_userName!.split(' ')[0]}!',
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: theme.textTheme.bodyLarge?.color),
//                 overflow: TextOverflow.ellipsis)),
//       const Spacer(),
//       SizedBox(
//         width: calculatedSearchWidth,
//         child: WebSearchBar(
//           key: ValueKey(_searchQuery ?? 'initial'),
//           initialValue: _searchQuery ?? '',
//           cityFilter: _selectedCityFilter,
//           firestoreService: _firestoreService,
//           onSearchSubmitted: (query) {
//             _onFilterOrSearchChanged(explicitSearchQuery: query);
//           },
//           onSuggestionSelected: (suggestionName) {
//             _onFilterOrSearchChanged(explicitSearchQuery: suggestionName);
//           },
//           onClear: () {
//             _onFilterOrSearchChanged(explicitSearchQuery: null);
//           },
//         ),
//       ),
//       const Spacer(),
//     ]);
//   }
  
//   List<Widget> _buildAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
//     final String cityNameText = _selectedCityFilter ?? 'Near Me';
//     const double textSize = 10.0;

//     final locationButton = Tooltip(
//       message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
//       child: Transform.translate(
//         offset: const Offset(0, 9.0),
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
//                 _selectedCityIcon ??
//                     (_selectedCityFilter == null
//                         ? Icons.my_location
//                         : Icons.location_city_outlined),
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

//     final profileButton = isLoggedIn
//         ? IconButton(
//             icon: Icon(Icons.person_outline_rounded, color: iconColor),
//             tooltip: 'My Profile',
//             onPressed: () {
//               if (!context.mounted) return;
//               Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => const ProfileScreen()))
//                   .then((_) => {if (mounted) _fetchUserNameAndPic()});
//             },
//           )
//         : null;

//     return [
//       Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: kIsWeb
//             ? [ // Web Layout
//                 locationButton,
//                 if (profileButton != null) const SizedBox(width: 8),
//                 if (profileButton != null) profileButton,
//                 const SizedBox(width: 8),
//               ]
//             : [ // Mobile Layout
//                 IconButton(
//                   icon: Icon(Icons.search_outlined, color: iconColor),
//                   tooltip: 'Search Venues',
//                   onPressed: _openSearchMobile,
//                 ),
//                 locationButton,
//                 if (profileButton != null) profileButton,
//                 if (profileButton == null) const SizedBox(width: 8),
//               ],
//       )
//     ];
//   }
  
//   Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
//     final titleStyle = theme.appBarTheme.titleTextStyle ??
//         theme.primaryTextTheme.titleLarge ??
//         const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
//     final currentUser = _currentUser;
//     return Row(children: [
//       if (currentUser != null)
//         GestureDetector(
//           onTap: () {
//             if (!context.mounted) return;
//             Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => const ProfileScreen()))
//                 .then((_) {
//               if (mounted) _fetchUserNameAndPic();
//             });
//           },
//           child: Tooltip(
//             message: "My Profile",
//             child: Padding(
//               padding: const EdgeInsets.only(right: 10.0),
//               child: CircleAvatar(
//                   radius: 18,
//                   backgroundColor: Colors.white24,
//                   backgroundImage:
//                       _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty
//                           ? NetworkImage(_userProfilePicUrl!)
//                           : null,
//                   child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty
//                       ? Icon(Icons.person_outline,
//                           size: 20, color: Colors.white.withOpacity(0.8))
//                       : null),
//             ),
//           ),
//         ),
//       if (_isLoadingName && currentUser != null)
//         const Padding(
//             padding: EdgeInsets.only(left: 6.0),
//             child: SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))))
//       else if (_userName != null && currentUser != null)
//         Expanded(
//           child: Padding(
//               padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
//               child: Text(
//                 'Hi, ${_userName!.split(' ')[0]}!',
//                 style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
//                 overflow: TextOverflow.ellipsis,
//               )),
//         )
//       else
//         Text('MM Associates', style: titleStyle),
//     ]);
//   }
  
//   Widget _buildBodyContent() {
//     return Column(children: [
//       _buildQuickSportFilters(),
//       Expanded(
//         child: RefreshIndicator(
//           onRefresh: _handleRefresh,
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               if (_isSearchingOrFiltering) ...[
//                 _buildSectionHeader(context,
//                     _searchQuery != null && _searchQuery!.isNotEmpty
//                         ? "Results for \"$_searchQuery\""
//                         : (_selectedCityFilter != null
//                             ? "Venues in $_selectedCityFilter"
//                             : (_selectedSportFilter != null
//                                 ? "Venues for $_selectedSportFilter"
//                                 : "Filtered Venues"))),
//                 _buildVenueList(_filteredVenues, _isLoadingFilteredVenues,
//                     _filteredVenueFetchError, "No venues found for your selection.", isNearbySection: false),
//               ] else ...[
//                  if (!_isFetchingLocation && _currentPosition == null)
//                   _buildNoLocationWarning(),
//                 if (_currentPosition != null || _isLoadingNearbyVenues)
//                   _buildSectionHeader(context, "Venues Near You"),
//                 _buildVenueList(
//                     _nearbyVenues,
//                     _isLoadingNearbyVenues,
//                     _nearbyVenueFetchError,
//                     "No venues found nearby. Try exploring other cities.",
//                     isNearbySection: true),
//                 const SizedBox(height: 16),
//                 _buildSectionHeader(context, "Explore Venues"),
//                 _buildVenueList(
//                     _exploreVenues,
//                     _isLoadingExploreVenues,
//                     _exploreVenueFetchError,
//                     "No venues to explore at the moment.", isNearbySection: false),
//               ],
//               const SizedBox(height: 80),
//             ],
//           ),
//         ),
//       ),
//     ]);
//   }

//   Widget _buildNoLocationWarning() {
//     return Container(
//       color: Colors.amber.withOpacity(0.1),
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//       child: Row(
//         children: [
//           Icon(Icons.location_off_outlined, color: Colors.amber.shade800),
//           const SizedBox(width: 12.0),
//           Expanded(
//             child: Text(
//               'Location is off or denied. "Venues Near You" will not be shown.',
//               style: TextStyle(color: Colors.amber.shade900),
//             ),
//           ),
//         ],
//       ),
//     );
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
//                   setStateIfMounted(() => _selectedSportFilter = null);
//                   _onFilterOrSearchChanged();
//                 }
//               },
//               selectedColor: theme.colorScheme.primary.withOpacity(0.2),
//               backgroundColor:
//                   theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
//               labelStyle: TextStyle(
//                   color: isSelected
//                       ? theme.colorScheme.primary
//                       : theme.textTheme.bodyMedium?.color,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                   fontSize: 13),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   side: BorderSide(
//                       color: isSelected
//                           ? theme.colorScheme.primary.withOpacity(0.5)
//                           : Colors.grey.shade300)),
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//               visualDensity: VisualDensity.compact,
//               showCheckmark: false,
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
//             backgroundColor:
//                 theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
//             labelStyle: TextStyle(
//                 color: isSelected
//                     ? theme.colorScheme.primary
//                     : theme.textTheme.bodyMedium?.color,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 fontSize: 13),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//                 side: BorderSide(
//                     color: isSelected
//                         ? theme.colorScheme.primary.withOpacity(0.5)
//                         : Colors.grey.shade300)),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//             visualDensity: VisualDensity.compact,
//             showCheckmark: false,
//           );
//         },
//       ),
//     );
//   }
  
//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Padding(
//         padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
//         child: Text(title,
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
//   }

//   Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg,
//       String emptyMsg, {bool isNearbySection = false}) {
//     if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
//     if (errorMsg != null)
//       return Center(
//           child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Text(errorMsg,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.red, fontSize: 16))));
//     if (venues.isEmpty)
//       return Center(
//           child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
//               child: Text(emptyMsg,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
//       gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//           maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
//           mainAxisSpacing: 16.0,
//           crossAxisSpacing: 16.0,
//           childAspectRatio: 0.70),
//       itemCount: venues.length,
//       itemBuilder: (context, index) {
//         final venue = venues[index];
//         final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
//         return _buildVenueGridCard(venue, isFavorite: isFavorite);
//       },
//     );
//   }

//   Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
//     return Shimmer.fromColors(
//         baseColor: Colors.grey[350]!,
//         highlightColor: Colors.grey[200]!,
//         child: GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             padding: const EdgeInsets.all(16.0),
//             gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//                 maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0,
//                 mainAxisSpacing: 16.0,
//                 crossAxisSpacing: 16.0,
//                 childAspectRatio: 0.70),
//             itemCount: itemCount,
//             itemBuilder: (context, index) => _buildVenueShimmerCard()));
//   }

//   Widget _buildVenueShimmerCard() {
//     return Card(
//         margin: EdgeInsets.zero,
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         clipBehavior: Clip.antiAlias,
//         child: Column(children: [
//           Container(height: 130, width: double.infinity, color: Colors.white),
//           Expanded(
//               child: Padding(
//                   padding: const EdgeInsets.all(10.0),
//                   child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                   width: double.infinity,
//                                   height: 18.0,
//                                   color: Colors.white,
//                                   margin: const EdgeInsets.only(bottom: 6)),
//                               Container(
//                                   width: MediaQuery.of(context).size.width * 0.3,
//                                   height: 14.0,
//                                   color: Colors.white,
//                                   margin: const EdgeInsets.only(bottom: 6)),
//                               Container(
//                                   width: MediaQuery.of(context).size.width * 0.2,
//                                   height: 12.0,
//                                   color: Colors.white)
//                             ]),
//                         Container(width: double.infinity, height: 12.0, color: Colors.white)
//                       ])))
//         ]));
//   }

//   Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite}) {
//     final String venueId = venue['id'] as String? ?? '';
//     return _VenueCardWidget(
//       key: ValueKey(venueId),
//       venue: venue,
//       isFavorite: isFavorite,
//       onTapCard: () => _navigateToVenueDetail(venue),
//       onTapFavorite: () => _toggleFavorite(venueId),
//     );
//   }

//   Future<void> _toggleFavorite(String venueId) async {
//     if (!mounted) return;
//     final currentUser = _currentUser;
//     if (currentUser == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("Please log in to manage favorites."),
//       ));
//       return;
//     }
//     if (venueId.isEmpty) return;

//     final currentIsFavorite = _favoriteVenueIds.contains(venueId);

//     try {
//       if (!currentIsFavorite) {
//         await _userService.addFavorite(venueId);
//       } else {
//         await _userService.removeFavorite(venueId);
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text("Error updating favorites: ${e.toString()}"),
//         ));
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
//       CurvedAnimation(
//           parent: _favoriteAnimationController,
//           curve: Curves.elasticOut,
//           reverseCurve: Curves.easeInCubic),
//     );
//     if(widget.isFavorite) {
//       _favoriteAnimationController.value = 1.0;
//     }
//   }

//   @override
//   void didUpdateWidget(_VenueCardWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isFavorite != oldWidget.isFavorite && mounted) {
//       if (widget.isFavorite) {
//         _favoriteAnimationController.forward(from: 0.0).catchError((e) {
//           if (e is! TickerCanceled) debugPrint("Error playing fav animation: $e");
//         });
//       } else {
//         _favoriteAnimationController.reverse().catchError((e) {
//           if (e is! TickerCanceled) debugPrint("Error reversing fav animation: $e");
//         });
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
//     final String sport = (sportRaw is String)
//         ? sportRaw
//         : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
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
//                       child: (imageUrl != null &&
//                               imageUrl.isNotEmpty &&
//                               Uri.tryParse(imageUrl)?.isAbsolute == true)
//                           ? Hero(
//                               tag: 'venue_image_$venueId',
//                               child: Image.network(
//                                 imageUrl,
//                                 height: 130,
//                                 width: double.infinity,
//                                 fit: BoxFit.cover,
//                                 loadingBuilder: (context, child, loadingProgress) =>
//                                     (loadingProgress == null)
//                                         ? child
//                                         : Container(
//                                             height: 130,
//                                             color: Colors.grey[200],
//                                             child: Center(
//                                                 child: CircularProgressIndicator(
//                                                     strokeWidth: 2,
//                                                     value: loadingProgress
//                                                                 .expectedTotalBytes !=
//                                                             null
//                                                         ? loadingProgress.cumulativeBytesLoaded /
//                                                             loadingProgress.expectedTotalBytes!
//                                                         : null))),
//                                 errorBuilder: (context, error, stackTrace) => Container(
//                                     height: 130,
//                                     color: Colors.grey[200],
//                                     child: Center(
//                                         child: Icon(Icons.broken_image_outlined,
//                                             color: Colors.grey[400], size: 40))),
//                               ),
//                             )
//                           : Container(
//                               height: 130,
//                               color: theme.primaryColor.withOpacity(0.08),
//                               child: Center(
//                                   child: Icon(Icons.sports_soccer_outlined,
//                                       size: 50, color: theme.primaryColor.withOpacity(0.7)))),
//                     ),
//                   ),
//                   Positioned(
//                     top: 6,
//                     right: 6,
//                     child: Material(
//                       color: Colors.black.withOpacity(0.45),
//                       shape: const CircleBorder(),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(20),
//                         onTap: widget.onTapFavorite,
//                         child: Padding(
//                           padding: const EdgeInsets.all(7.0),
//                           child: ScaleTransition(
//                             scale: _favoriteScaleAnimation,
//                             child: Icon(
//                               widget.isFavorite
//                                   ? Icons.favorite_rounded
//                                   : Icons.favorite_border_rounded,
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
//                       bottom: 6,
//                       left: 6,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                         decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.6),
//                             borderRadius: BorderRadius.circular(4)),
//                         child: Text('${distance.toStringAsFixed(1)} km',
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w500)),
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
//                           Text(name,
//                               style: theme.textTheme.titleMedium
//                                   ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis),
//                           const SizedBox(height: 4),
//                           Row(children: [
//                             Icon(Icons.sports_kabaddi_outlined,
//                                 size: 14, color: theme.colorScheme.secondary),
//                             const SizedBox(width: 4),
//                             Expanded(
//                                 child: Text(sport,
//                                     style: theme.textTheme.bodyMedium
//                                         ?.copyWith(color: Colors.grey[800], fontSize: 12),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis)),
//                           ]),
//                           if (reviewCount > 0)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 5.0),
//                               child: Row(children: [
//                                 Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
//                                 const SizedBox(width: 4),
//                                 Text(averageRating.toStringAsFixed(1),
//                                     style:
//                                         const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
//                                 const SizedBox(width: 4),
//                                 Text("($reviewCount reviews)",
//                                     style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
//                               ]),
//                             ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 4),
//                           Expanded(
//                               child: Text(city,
//                                   style: theme.textTheme.bodySmall
//                                       ?.copyWith(color: Colors.grey[700], fontSize: 12),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis)),
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



// features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';
import 'package:mm_associates/features/home/screens/venue_form.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';
import 'package:mm_associates/features/user/services/user_service.dart';
import 'package:mm_associates/core/services/location_service.dart';
import 'package:mm_associates/features/profile/screens/profile_screen.dart';
import 'venue_detail_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'city_selection_screen.dart' show CitySelectionScreen, kAppAllCities;
import 'package:mm_associates/features/home/widgets/home_search_components.dart';

class HomeScreen extends StatefulWidget {
  final bool showAddVenueButton;

  const HomeScreen({
    super.key,
    required this.showAddVenueButton,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();

  // State Variables
  String? _searchQuery;
  String? _selectedCityFilter;
  IconData? _selectedCityIcon;
  String? _selectedSportFilter;

  User? _currentUser;
  String? _userName;
  String? _userProfilePicUrl;
  bool _isLoadingName = true;

  List<Map<String, dynamic>> _filteredVenues = [];
  bool _isLoadingFilteredVenues = true;
  String? _filteredVenueFetchError;

  List<Map<String, dynamic>> _nearbyVenues = [];
  bool _isLoadingNearbyVenues = true;
  String? _nearbyVenueFetchError;

  List<Map<String, dynamic>> _exploreVenues = [];
  bool _isLoadingExploreVenues = true;
  String? _exploreVenueFetchError;

  Position? _currentPosition;
  bool _isFetchingLocation = false;
  String? _locationStatusMessage;

  // Favorites State
  List<String> _favoriteVenueIds = [];
  bool _isLoadingFavorites = true;
  Stream<List<String>>? _favoritesStream;
  StreamSubscription<List<String>>? _favoritesSubscription;

  final List<String> _supportedCities = [
    'Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Hyderabad', 'Chennai', 'Kolkata'
  ];
  final List<String> _quickSportFilters = [
    'Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'
  ];

  bool get _isSearchingOrFiltering =>
      (_searchQuery != null && _searchQuery!.isNotEmpty) ||
      _selectedCityFilter != null ||
      _selectedSportFilter != null;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _initializeScreen();
  }

  // <<< FIX 2 of 2: Changed return type from `void` to `Future<void>`.
  Future<void> _initializeScreen() async {
    _fetchUserNameAndPic();
    _setupFavoritesStream();

    await _checkAndRequestLocationPermission();

    if (_isSearchingOrFiltering) {
      _onFilterOrSearchChanged();
    } else {
      _fetchPrimaryVenueData();
    }

    if (mounted) {
      _updateSelectedCityIconFromFilter();
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    if (!mounted) return;
    setState(() {
      _isFetchingLocation = true;
      _locationStatusMessage = 'Initializing location services...';
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationStatusMessage =
              position != null ? 'Location acquired.' : 'Could not determine location.';
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Error in _checkAndRequestLocationPermission: $e");
        setState(() {
          _locationStatusMessage = 'Failed to get location.';
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchPrimaryVenueData() async {
    if (!mounted) return;
    await Future.wait(
        [_fetchNearbyVenuesScoped(), _fetchExploreVenuesFromOtherCities()]);
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _fetchUserNameAndPic() async {
    if (!mounted) return;
    setState(() => _isLoadingName = true);

    // <<< FIX 1 of 2: Changed `_auth.currentUser` to `_authService.getCurrentUser()`.
    final currentUser = _authService.getCurrentUser();

    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _userName = 'Guest';
          _userProfilePicUrl = null;
          _isLoadingName = false;
        });
      }
      return;
    }
    try {
      final userData = await _userService.getUserProfileData();
      if (!mounted) return;
      final fetchedName = userData?['name'] as String? ??
          currentUser.displayName ??
          currentUser.email?.split('@')[0] ??
          'User';
      final fetchedPicUrl = userData?['profilePictureUrl'] as String?;
      setState(() {
        _userName = fetchedName;
        _userProfilePicUrl = fetchedPicUrl;
      });
    } catch (e) {
      if (!mounted) return;
      final fallbackName = currentUser.displayName ??
          currentUser.email?.split('@')[0] ??
          'User';
      setState(() {
        _userName = fallbackName;
        _userProfilePicUrl = null;
      });
      debugPrint("Error fetching user name: $e");
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  void _onFilterOrSearchChanged({String? explicitSearchQuery}) {
    if (!mounted) return;

    setState(() {
      _searchQuery = (explicitSearchQuery?.trim().isEmpty ?? true)
          ? null
          : explicitSearchQuery!.trim();
    });

    if (_isSearchingOrFiltering) {
      _fetchVenuesForFilterOrSearch();
    } else {
      _fetchPrimaryVenueData();
    }
  }

  Future<void> _fetchVenuesForFilterOrSearch() async {
    if (!mounted) return;
    setStateIfMounted(() {
      _isLoadingFilteredVenues = true;
      _filteredVenueFetchError = null;
      _filteredVenues = [];
    });

    try {
      final venuesData = await _firestoreService.getVenues(
        userLocation: _currentPosition,
        radiusInKm: _selectedCityFilter != null
            ? null
            : (_currentPosition != null ? 50.0 : null),
        cityFilter: _selectedCityFilter,
        searchQuery: _searchQuery,
        sportFilter: _selectedSportFilter,
      );
      if (!mounted) return;
      setStateIfMounted(() {
        _filteredVenues = venuesData;
      });
    } catch (e) {
      debugPrint("Error fetching filtered/search venues: $e");
      if (!mounted) return;
      setStateIfMounted(
          () => _filteredVenueFetchError = "Could not load venues: ${e.toString()}");
    } finally {
      if (!mounted) return;
      setStateIfMounted(() => _isLoadingFilteredVenues = false);
    }
  }

  void _setupFavoritesStream() {
    _favoritesSubscription?.cancel();
    if (_currentUser != null) {
      _favoritesStream = _userService.getFavoriteVenueIdsStream();
      _favoritesSubscription = _favoritesStream?.listen((favoriteIds) {
        if (mounted) {
          final newIdsSet = favoriteIds.toSet();
          final currentIdsSet = _favoriteVenueIds.toSet();
          if (newIdsSet.difference(currentIdsSet).isNotEmpty ||
              currentIdsSet.difference(newIdsSet).isNotEmpty) {
            setStateIfMounted(() => _favoriteVenueIds = favoriteIds);
          }
        }
      }, onError: (error) {
        debugPrint("Error in favorites stream: $error");
      });
      if (mounted) setStateIfMounted(() => _isLoadingFavorites = false);
    } else {
      if (mounted) {
        setStateIfMounted(() {
          _favoriteVenueIds = [];
          _isLoadingFavorites = false;
          _favoritesStream = null;
          _favoritesSubscription = null;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentAuthUser = _authService.getCurrentUser();
    if (currentAuthUser?.uid != _currentUser?.uid) {
      _currentUser = currentAuthUser;
      _initializeScreen();
    }
  }

  Future<void> _fetchNearbyVenuesScoped() async {
    if (!mounted) return;
    if (_currentPosition == null) {
      if (mounted)
        setStateIfMounted(() {
          _isLoadingNearbyVenues = false;
          _nearbyVenueFetchError = "Location not available.";
          _nearbyVenues = [];
        });
      return;
    }
    setStateIfMounted(() {
      _isLoadingNearbyVenues = true;
      _nearbyVenueFetchError = null;
      _nearbyVenues = [];
    });
    try {
      final venuesData = await _firestoreService.getVenues(
          userLocation: _currentPosition, radiusInKm: 25.0);
      if (!mounted) return;
      setStateIfMounted(() => _nearbyVenues = venuesData);
    } catch (e) {
      if (!mounted) return;
      setStateIfMounted(
          () => _nearbyVenueFetchError = "Could not load nearby venues.");
    } finally {
      if (!mounted) return;
      setStateIfMounted(() => _isLoadingNearbyVenues = false);
    }
  }

  Future<void> _fetchExploreVenuesFromOtherCities() async {
    if (!mounted) return;
    setStateIfMounted(() {
      _isLoadingExploreVenues = true;
      _exploreVenueFetchError = null;
      _exploreVenues = [];
    });
    List<Map<String, dynamic>> allExploreVenues = [];
    try {
      for (String city in _supportedCities) {
        final cityVenues = await _firestoreService.getVenues(
            cityFilter: city, userLocation: _currentPosition, limit: 5);
        allExploreVenues.addAll(cityVenues);
        if (!mounted) return;
      }
      final uniqueExploreVenues = allExploreVenues
          .fold<Map<String, Map<String, dynamic>>>({}, (map, venue) {
        final String? venueId = venue['id'] as String?;
        if (venueId != null) map[venueId] = venue;
        return map;
      }).values.toList();

      if (_currentPosition != null) {
        uniqueExploreVenues.sort((a, b) {
          final distA = a['distance'] as double?;
          final distB = b['distance'] as double?;
          if (distA != null && distB != null) return distA.compareTo(distB);
          if (distA != null) return -1;
          if (distB != null) return 1;
          return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
        });
      } else {
        uniqueExploreVenues.sort(
            (a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
      }
      if (!mounted) return;
      setStateIfMounted(
          () => _exploreVenues = uniqueExploreVenues.take(15).toList());
    } catch (e) {
      if (!mounted) return;
      setStateIfMounted(
          () => _exploreVenueFetchError = "Could not load explore venues.");
    } finally {
      if (!mounted) return;
      setStateIfMounted(() => _isLoadingExploreVenues = false);
    }
  }

  void _updateSelectedCityIconFromFilter() {
    if (_selectedCityFilter == null) {
      _selectedCityIcon = Icons.my_location;
    } else {
      try {
        final cityInfo =
            kAppAllCities.firstWhere((city) => city.name == _selectedCityFilter);
        _selectedCityIcon = cityInfo.icon;
      } catch (e) {
        _selectedCityIcon = Icons.location_city_outlined;
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() {
        _searchQuery = null;
        _selectedSportFilter = null;
      });
      await _initializeScreen();
    }
  }

  // <<< MODIFIED: Now takes `heroTagContext` to pass down >>>
  void _navigateToVenueDetail(Map<String, dynamic> venue, String heroTagContext) {
    if (!context.mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VenueDetailScreen(
                venueId: venue['id'] as String,
                initialVenueData: venue,
                heroTagContext: heroTagContext))); // <<< MODIFIED: Pass the context
  }

  void _openSearchMobile() async {
    if (!context.mounted) return;
    final String? submittedQuery = await showSearch<String?>(
        context: context,
        delegate: VenueSearchDelegate(
            firestoreService: _firestoreService,
            initialCityFilter: _selectedCityFilter));
    _onFilterOrSearchChanged(explicitSearchQuery: submittedQuery);
  }

  Future<void> _openCitySelectionScreen() async {
    if (!context.mounted) return;
    final String? newSelectedCityName = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CitySelectionScreen(currentSelectedCity: _selectedCityFilter)),
    );

    if (mounted && newSelectedCityName != _selectedCityFilter) {
      setStateIfMounted(() {
        _selectedCityFilter = newSelectedCityName;
        _updateSelectedCityIconFromFilter();
      });
      _onFilterOrSearchChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... All build-related methods remain the same until we get to _buildVenueList and _buildVenueGridCard
    final theme = Theme.of(context);
    final appBarBackgroundColor =
        theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ??
        theme.appBarTheme.iconTheme?.color ??
        (kIsWeb
            ? (theme.brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87)
            : Colors.white);
    final bool isLoggedIn = _currentUser != null;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70.0,
        automaticallyImplyLeading: false,
        title: kIsWeb
            ? _buildWebAppBarTitle(context)
            : _buildMobileAppBarTitle(context, theme),
        actions: _buildAppBarActions(context, isLoggedIn, actionsIconColor),
        backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
        elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
        iconTheme: theme.iconTheme.copyWith(
            color: kIsWeb
                ? (theme.brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87)
                : Colors.white),
        actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ??
            TextStyle(
                color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500),
      ),
      floatingActionButton: widget.showAddVenueButton
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddVenueFormScreen()),
                ).then((result) {
                  if (result == true && mounted) {
                    _handleRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Venue list updated."),
                          backgroundColor: Colors.blueAccent),
                    );
                  }
                });
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text("Add Venue"),
              tooltip: 'Add New Venue',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _buildBodyContent(),
    );
  }

  // ... (All other UI build methods are exactly the same as before until _buildBodyContent) ...
   Widget _buildWebAppBarTitle(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = _currentUser;
    double screenWidth = MediaQuery.of(context).size.width;
    double leadingWidth = 150 + (_userName != null ? 100 : 0);
    double searchWidthFraction = 0.4;
    double minSearchWidth = 200;
    double maxSearchWidth = 500;
    double actionsWidth =
        80 + (_currentUser != null ? 120 : 0); // Simplified calculation
    double availableWidth = screenWidth - leadingWidth - actionsWidth - 32;
    double calculatedSearchWidth =
        (availableWidth * searchWidthFraction).clamp(minSearchWidth, maxSearchWidth);
        
    return Row(children: [
      Text('Secrets Of Sports',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color ?? theme.primaryColor)),
      const SizedBox(width: 24),
      if (_isLoadingName && currentUser != null)
        const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)))
      else if (_userName != null && currentUser != null)
        Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text('Hi, ${_userName!.split(' ')[0]}!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color),
                overflow: TextOverflow.ellipsis)),
      const Spacer(),
      SizedBox(
        width: calculatedSearchWidth,
        child: WebSearchBar(
          key: ValueKey(_searchQuery ?? 'initial'),
          initialValue: _searchQuery ?? '',
          cityFilter: _selectedCityFilter,
          firestoreService: _firestoreService,
          onSearchSubmitted: (query) {
            _onFilterOrSearchChanged(explicitSearchQuery: query);
          },
          onSuggestionSelected: (suggestionName) {
            _onFilterOrSearchChanged(explicitSearchQuery: suggestionName);
          },
          onClear: () {
            _onFilterOrSearchChanged(explicitSearchQuery: null);
          },
        ),
      ),
      const Spacer(),
    ]);
  }
  
  List<Widget> _buildAppBarActions(BuildContext context, bool isLoggedIn, Color iconColor) {
    final String cityNameText = _selectedCityFilter ?? 'Near Me';
    const double textSize = 10.0;

    final locationButton = Tooltip(
      message: _selectedCityFilter == null ? 'Filter: Near Me' : 'Filter: $_selectedCityFilter',
      child: Transform.translate(
        offset: const Offset(0, 9.0),
        child: TextButton(
          onPressed: _openCitySelectionScreen,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            foregroundColor: iconColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedCityIcon ??
                    (_selectedCityFilter == null
                        ? Icons.my_location
                        : Icons.location_city_outlined),
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                cityNameText,
                style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    final profileButton = isLoggedIn
        ? IconButton(
            icon: Icon(Icons.person_outline_rounded, color: iconColor),
            tooltip: 'My Profile',
            onPressed: () {
              if (!context.mounted) return;
              Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()))
                  .then((_) => {if (mounted) _fetchUserNameAndPic()});
            },
          )
        : null;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: kIsWeb
            ? [ // Web Layout
                locationButton,
                if (profileButton != null) const SizedBox(width: 8),
                if (profileButton != null) profileButton,
                const SizedBox(width: 8),
              ]
            : [ // Mobile Layout
                IconButton(
                  icon: Icon(Icons.search_outlined, color: iconColor),
                  tooltip: 'Search Venues',
                  onPressed: _openSearchMobile,
                ),
                locationButton,
                if (profileButton != null) profileButton,
                if (profileButton == null) const SizedBox(width: 8),
              ],
      )
    ];
  }
  
  Widget _buildMobileAppBarTitle(BuildContext context, ThemeData theme) {
    final titleStyle = theme.appBarTheme.titleTextStyle ??
        theme.primaryTextTheme.titleLarge ??
        const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
    final currentUser = _currentUser;
    return Row(children: [
      if (currentUser != null)
        GestureDetector(
          onTap: () {
            if (!context.mounted) return;
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()))
                .then((_) {
              if (mounted) _fetchUserNameAndPic();
            });
          },
          child: Tooltip(
            message: "My Profile",
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      _userProfilePicUrl != null && _userProfilePicUrl!.isNotEmpty
                          ? NetworkImage(_userProfilePicUrl!)
                          : null,
                  child: _userProfilePicUrl == null || _userProfilePicUrl!.isEmpty
                      ? Icon(Icons.person_outline,
                          size: 20, color: Colors.white.withOpacity(0.8))
                      : null),
            ),
          ),
        ),
      if (_isLoadingName && currentUser != null)
        const Padding(
            padding: EdgeInsets.only(left: 6.0),
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))))
      else if (_userName != null && currentUser != null)
        Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: currentUser != null ? 0 : 8.0),
              child: Text(
                'Hi, ${_userName!.split(' ')[0]}!',
                style: titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              )),
        )
      else
        Text('Secrets Of Sports', style: titleStyle),
    ]);
  }
  
  Widget _buildBodyContent() {
    return Column(children: [
      _buildQuickSportFilters(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (_isSearchingOrFiltering) ...[
                _buildSectionHeader(
                    context,
                    _searchQuery != null && _searchQuery!.isNotEmpty
                        ? "Results for \"$_searchQuery\""
                        : (_selectedCityFilter != null
                            ? "Venues in $_selectedCityFilter"
                            : (_selectedSportFilter != null
                                ? "Venues for $_selectedSportFilter"
                                : "Filtered Venues"))),
                // <<< MODIFIED: Pass section identifier >>>
                _buildVenueList(_filteredVenues, _isLoadingFilteredVenues,
                    _filteredVenueFetchError, "No venues found for your selection.",
                    sectionIdentifier: 'search', isNearbySection: false),
              ] else ...[
                 if (!_isFetchingLocation && _currentPosition == null)
                  _buildNoLocationWarning(),
                if (_currentPosition != null || _isLoadingNearbyVenues)
                  _buildSectionHeader(context, "Venues Near You"),
                // <<< MODIFIED: Pass section identifier >>>
                _buildVenueList(
                    _nearbyVenues,
                    _isLoadingNearbyVenues,
                    _nearbyVenueFetchError,
                    "No venues found nearby. Try exploring other cities.",
                    sectionIdentifier: 'nearby', isNearbySection: true),
                const SizedBox(height: 16),
                _buildSectionHeader(context, "Explore Venues"),
                // <<< MODIFIED: Pass section identifier >>>
                _buildVenueList(
                    _exploreVenues,
                    _isLoadingExploreVenues,
                    _exploreVenueFetchError,
                    "No venues to explore at the moment.",
                    sectionIdentifier: 'explore', isNearbySection: false),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildNoLocationWarning() {
    // ... same code ...
    return Container(
      color: Colors.amber.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, color: Colors.amber.shade800),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Location is off or denied. "Venues Near You" will not be shown.',
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSportFilters() {
    // ... same code ...
    final theme = Theme.of(context);
    return Container(
      height: 55,
      color: theme.cardColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: _quickSportFilters.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            final bool isSelected = _selectedSportFilter == null;
            return ChoiceChip(
              label: const Text('All Sports'),
              selected: isSelected,
              onSelected: (bool nowSelected) {
                if (nowSelected && _selectedSportFilter != null) {
                  setStateIfMounted(() => _selectedSportFilter = null);
                  _onFilterOrSearchChanged();
                }
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              backgroundColor:
                  theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
              labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.5)
                          : Colors.grey.shade300)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            );
          }
          final sport = _quickSportFilters[index - 1];
          final bool isSelected = _selectedSportFilter == sport;
          return ChoiceChip(
            label: Text(sport),
            selected: isSelected,
            onSelected: (bool isNowSelected) {
              final newFilter = isNowSelected ? sport : null;
              if (_selectedSportFilter != newFilter) {
                setStateIfMounted(() => _selectedSportFilter = newFilter);
                _onFilterOrSearchChanged();
              }
            },
            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            backgroundColor:
                theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
            labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : Colors.grey.shade300)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
          );
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
        child: Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)));
  }
  
  // <<< MODIFIED: Pass `sectionIdentifier` down >>>
  Widget _buildVenueList(List<Map<String, dynamic>> venues, bool isLoading, String? errorMsg,
      String emptyMsg, {required String sectionIdentifier, bool isNearbySection = false}) {
    if (isLoading) return _buildShimmerLoadingGrid(itemCount: isNearbySection ? 3 : 6);
    if (errorMsg != null)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16))));
    if (venues.isEmpty)
      return Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
              child: Text(emptyMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]))));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: kIsWeb ? 280.0 : 240.0,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 0.70),
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final venue = venues[index];
        final bool isFavorite = !_isLoadingFavorites && _favoriteVenueIds.contains(venue['id']);
        return _buildVenueGridCard(venue,
            isFavorite: isFavorite, heroTagContext: sectionIdentifier); // <<< MODIFIED: Pass identifier
      },
    );
  }

  Widget _buildShimmerLoadingGrid({int itemCount = 6}) {
    // ... same code ...
     return Shimmer.fromColors(
        baseColor: Colors.grey[350]!,
        highlightColor: Colors.grey[200]!,
        child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: kIsWeb ? 280.0 : 230.0,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.70),
            itemCount: itemCount,
            itemBuilder: (context, index) => _buildVenueShimmerCard()));
  }

  Widget _buildVenueShimmerCard() {
    // ... same code ...
     return Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(height: 130, width: double.infinity, color: Colors.white),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: double.infinity,
                                  height: 18.0,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 6)),
                              Container(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  height: 14.0,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 6)),
                              Container(
                                  width: MediaQuery.of(context).size.width * 0.2,
                                  height: 12.0,
                                  color: Colors.white)
                            ]),
                        Container(width: double.infinity, height: 12.0, color: Colors.white)
                      ])))
        ]));
  }
  
  // <<< MODIFIED: Added `heroTagContext` parameter >>>
  Widget _buildVenueGridCard(Map<String, dynamic> venue, {required bool isFavorite, required String heroTagContext}) {
      final String venueId = venue['id'] as String? ?? '';
      return _VenueCardWidget(
        key: ValueKey('${heroTagContext}_$venueId'), // <<< MODIFIED: Make ValueKey unique
        venue: venue,
        isFavorite: isFavorite,
        onTapCard: () => _navigateToVenueDetail(venue, heroTagContext), // <<< MODIFIED: Pass context
        onTapFavorite: () => _toggleFavorite(venueId),
        heroTagContext: heroTagContext, // <<< MODIFIED: Pass to widget
      );
  }

  Future<void> _toggleFavorite(String venueId) async {
    // ... same code ...
    if (!mounted) return;
    final currentUser = _currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please log in to manage favorites."),
      ));
      return;
    }
    if (venueId.isEmpty) return;

    final currentIsFavorite = _favoriteVenueIds.contains(venueId);

    try {
      if (!currentIsFavorite) {
        await _userService.addFavorite(venueId);
      } else {
        await _userService.removeFavorite(venueId);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error updating favorites: ${e.toString()}"),
        ));
    }
  }
}

class _VenueCardWidget extends StatefulWidget {
  final Map<String, dynamic> venue;
  final bool isFavorite;
  final VoidCallback onTapCard;
  final Future<void> Function() onTapFavorite;
  final String heroTagContext; // <<< MODIFIED: Added parameter

  const _VenueCardWidget({
    required Key key,
    required this.venue,
    required this.isFavorite,
    required this.onTapCard,
    required this.onTapFavorite,
    required this.heroTagContext, // <<< MODIFIED: Added parameter
  }) : super(key: key);

  @override
  _VenueCardWidgetState createState() => _VenueCardWidgetState();
}

class _VenueCardWidgetState extends State<_VenueCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteScaleAnimation;

  @override
  void initState() {
    super.initState();
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
          parent: _favoriteAnimationController,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeInCubic),
    );
    if(widget.isFavorite) {
      _favoriteAnimationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_VenueCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite && mounted) {
      if (widget.isFavorite) {
        _favoriteAnimationController.forward(from: 0.0).catchError((e) {
          if (e is! TickerCanceled) debugPrint("Error playing fav animation: $e");
        });
      } else {
        _favoriteAnimationController.reverse().catchError((e) {
          if (e is! TickerCanceled) debugPrint("Error reversing fav animation: $e");
        });
      }
    }
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = widget.venue['name'] as String? ?? 'Unnamed Venue';
    final dynamic sportRaw = widget.venue['sportType'];
    final String sport = (sportRaw is String)
        ? sportRaw
        : (sportRaw is List ? sportRaw.whereType<String>().join(', ') : 'Various Sports');
    final String? imageUrl = widget.venue['imageUrl'] as String?;
    final String city = widget.venue['city'] as String? ?? '';
    final String venueId = widget.venue['id'] as String? ?? '';
    final double? distance = widget.venue['distance'] as double?;
    final double averageRating = (widget.venue['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (widget.venue['reviewCount'] as num?)?.toInt() ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: widget.onTapCard,
                      child: (imageUrl != null &&
                              imageUrl.isNotEmpty &&
                              Uri.tryParse(imageUrl)?.isAbsolute == true)
                          ? Hero(
                              // <<< MODIFIED: Using the unique context in the Hero tag
                              tag: '${widget.heroTagContext}_venue_image_$venueId',
                              child: Image.network(
                                imageUrl,
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) =>
                                    (loadingProgress == null)
                                        ? child
                                        : Container(
                                            height: 130,
                                            color: Colors.grey[200],
                                            child: Center(
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null))),
                                errorBuilder: (context, error, stackTrace) => Container(
                                    height: 130,
                                    color: Colors.grey[200],
                                    child: Center(
                                        child: Icon(Icons.broken_image_outlined,
                                            color: Colors.grey[400], size: 40))),
                              ),
                            )
                          : Container(
                              height: 130,
                              color: theme.primaryColor.withOpacity(0.08),
                              child: Center(
                                  child: Icon(Icons.sports_soccer_outlined,
                                      size: 50, color: theme.primaryColor.withOpacity(0.7)))),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withOpacity(0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: widget.onTapFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: ScaleTransition(
                            scale: _favoriteScaleAnimation,
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: widget.isFavorite ? Colors.pinkAccent[100] : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (distance != null)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: widget.onTapCard,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.sports_kabaddi_outlined,
                                size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(sport,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.grey[800], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                          if (reviewCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Row(children: [
                                Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
                                const SizedBox(width: 4),
                                Text(averageRating.toStringAsFixed(1),
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(width: 4),
                                Text("($reviewCount reviews)",
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                              ]),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(city,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[700], fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}