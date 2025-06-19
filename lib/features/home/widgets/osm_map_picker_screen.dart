// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:latlong2/latlong.dart' as latlng; // Alias to avoid conflict if Google's LatLng is also imported
// // import 'package:http/http.dart' as http; // For Nominatim reverse geocoding

// // class OsmMapPickerScreen extends StatefulWidget {
// //   final latlng.LatLng? initialPosition;

// //   const OsmMapPickerScreen({super.key, this.initialPosition});

// //   @override
// //   State<OsmMapPickerScreen> createState() => _OsmMapPickerScreenState();
// // }

// // class _OsmMapPickerScreenState extends State<OsmMapPickerScreen> {
// //   final MapController _mapController = MapController();
// //   latlng.LatLng? _pickedLocation;
// //   Marker? _selectedMarker;
// //   String _pickedAddress = "Tap on map to select location";
// //   bool _isLoadingAddress = false;

// //   // A default initial position (e.g., world view or specific region)
// //   static final latlng.LatLng _defaultInitialPosition = latlng.LatLng(20.5937, 78.9629); // India
// //   static const double _defaultInitialZoom = 5.0;
// //   static const double _pickedLocationZoom = 15.0;


// //   @override
// //   void initState() {
// //     super.initState();
// //     if (widget.initialPosition != null) {
// //       _pickedLocation = widget.initialPosition;
// //       // Delay map move until layout is complete, or use addPostFrameCallback
// //       WidgetsBinding.instance.addPostFrameCallback((_) {
// //         if (mounted && _pickedLocation != null) {
// //           _mapController.move(_pickedLocation!, _pickedLocationZoom);
// //           _updateMarkerAndAddress(_pickedLocation!);
// //         }
// //       });
// //     }
// //   }

// //   Future<void> _onMapTap(TapPosition tapPosition, latlng.LatLng position) async {
// //     setState(() {
// //       _pickedLocation = position;
// //     });
// //     await _updateMarkerAndAddress(position);
// //   }

// //   Future<void> _updateMarkerAndAddress(latlng.LatLng position) async {
// //     setState(() {
// //       _isLoadingAddress = true;
// //       _selectedMarker = Marker(
// //         width: 80.0,
// //         height: 80.0,
// //         point: position,
// //         child: Icon(
// //           Icons.location_pin,
// //           color: Colors.red.shade700,
// //           size: 40.0,
// //         ),
// //       );
// //     });

// //     // Nominatim Reverse Geocoding (Free OSM service)
// //     // IMPORTANT: Be mindful of Nominatim's usage policy (max 1 request per second, no bulk)
// //     // https://operations.osmfoundation.org/policies/nominatim/
// //     try {
// //       final url = Uri.parse(
// //           'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&accept-language=en');
// //       final response = await http.get(url, headers: {
// //         'User-Agent': 'YourAppName/1.0 (your-email@example.com)' // Good practice to set User-Agent
// //       });

// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         if (mounted) {
// //           setState(() {
// //             _pickedAddress = data['display_name'] ?? 'Address not found';
// //           });
// //         }
// //       } else {
// //         if (mounted) {
// //           setState(() {
// //             _pickedAddress = 'Failed to fetch address (${response.statusCode})';
// //           });
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("Nominatim Error: $e");
// //       if (mounted) {
// //         setState(() {
// //           _pickedAddress = 'Could not fetch address';
// //         });
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           _isLoadingAddress = false;
// //         });
// //       }
// //     }
// //   }


// //   void _confirmLocation() {
// //     if (_pickedLocation != null) {
// //       Navigator.pop(context, _pickedLocation);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please select a location on the map first.')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Pick Location (OSM)'),
// //         actions: [
// //           if (_pickedLocation != null)
// //             IconButton(
// //               icon: const Icon(Icons.check),
// //               onPressed: _confirmLocation,
// //               tooltip: 'Confirm Location',
// //             ),
// //         ],
// //       ),
// //       body: Stack(
// //         children: [
// //           FlutterMap(
// //             mapController: _mapController,
// //             options: MapOptions(
// //               initialCenter: widget.initialPosition ?? _pickedLocation ?? _defaultInitialPosition,
// //               initialZoom: widget.initialPosition != null || _pickedLocation != null ? _pickedLocationZoom : _defaultInitialZoom,
// //               onTap: _onMapTap,
// //               // interactionOptions: const InteractionOptions( // Keep defaults, they are good
// //               //   flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
// //               // ),
// //             ),
// //             children: [
// //               TileLayer(
// //                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
// //                 userAgentPackageName: 'com.example.yourappname', // Replace with your app's package name
// //                 // Additional tile providers can be found here:
// //                 // https://wiki.openstreetmap.org/wiki/Tile_servers
// //               ),
// //               if (_selectedMarker != null) MarkerLayer(markers: [_selectedMarker!]),
// //               // You can add more layers like attribution, etc.
// //               RichAttributionWidget(
// //                 attributions: [
// //                   TextSourceAttribution(
// //                     'OpenStreetMap contributors',
// //                     onTap: () {
// //                       // launchUrl(Uri.parse('https://openstreetmap.org/copyright')); // Requires url_launcher
// //                     },
// //                   ),
// //                 ],
// //                 alignment: AttributionAlignment.bottomLeft,
// //               ),
// //             ],
// //           ),
// //           // Simple Zoom Buttons
// //           Positioned(
// //             right: 15,
// //             bottom: 90, // Adjust to be above the info panel
// //             child: Column(
// //               children: <Widget>[
// //                 FloatingActionButton.small(
// //                   heroTag: "zoomInBtn",
// //                   onPressed: () {
// //                     _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
// //                   },
// //                   child: const Icon(Icons.add),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 FloatingActionButton.small(
// //                   heroTag: "zoomOutBtn",
// //                   onPressed: () {
// //                     _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
// //                   },
// //                   child: const Icon(Icons.remove),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Positioned(
// //             bottom: 0,
// //             left: 0,
// //             right: 0,
// //             child: Material(
// //               elevation: 4.0,
// //               child: Container(
// //                 padding: const EdgeInsets.all(12.0),
// //                 color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       _pickedLocation != null
// //                           ? 'Selected: Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}'
// //                           : 'No location selected',
// //                       style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 4),
// //                     _isLoadingAddress
// //                       ? const Row(children: [SizedBox(height: 16, width:16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text("Fetching address...")])
// //                       : Text(_pickedAddress, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis,),
// //                     const SizedBox(height: 10),
// //                     if (_pickedLocation != null)
// //                       SizedBox(
// //                         width: double.infinity,
// //                         child: ElevatedButton.icon(
// //                           icon: const Icon(Icons.check_circle_outline),
// //                           label: const Text('Use This Location'),
// //                           onPressed: _confirmLocation,
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geolocator/geolocator.dart'; // <<< ADD FOR CURRENT LOCATION
// import 'package:latlong2/latlong.dart' as latlng;
// import 'package:http/http.dart' as http;

// class OsmMapPickerScreen extends StatefulWidget {
//   final latlng.LatLng? initialPosition; // From previous form or last pick

//   const OsmMapPickerScreen({super.key, this.initialPosition});

//   @override
//   State<OsmMapPickerScreen> createState() => _OsmMapPickerScreenState();
// }

// class _OsmMapPickerScreenState extends State<OsmMapPickerScreen> {
//   final MapController _mapController = MapController();
//   latlng.LatLng? _pickedLocation;
//   Marker? _selectedMarker;
//   String _pickedAddress = "Tap on map to select location";
//   bool _isLoadingAddress = false;
//   bool _isFetchingCurrentLocation = false; // <<< NEW STATE

//   // A sensible default if no initial position or current location is found
//   static final latlng.LatLng _defaultFallbackPosition = latlng.LatLng(20.5937, 78.9629); // India
//   static const double _defaultInitialZoom = 5.0;
//   static const double _focusedZoom = 15.0; // Zoom level when a location is set

//   @override
//   void initState() {
//     super.initState();
//     _initializeMapPosition();
//   }

//   Future<void> _initializeMapPosition() async {
//     if (widget.initialPosition != null) {
//       _pickedLocation = widget.initialPosition;
//       _moveToPosition(widget.initialPosition!, _focusedZoom, updateMarkerAndAddress: true);
//     } else {
//       // Try to get current location if no initial position is provided
//       await _tryGetCurrentLocationAndMove();
//     }
//   }

//   Future<void> _tryGetCurrentLocationAndMove({bool updateMarkerAndAddress = false}) async {
//     if (!mounted) return;
//     setState(() {
//       _isFetchingCurrentLocation = true;
//     });

//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
//         _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom); // Move to default
//         setState(() => _isFetchingCurrentLocation = false);
//       }
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         if(mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
//           _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom); // Move to default
//           setState(() => _isFetchingCurrentLocation = false);
//         }
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
//         _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom); // Move to default
//         setState(() => _isFetchingCurrentLocation = false);
//       }
//       return;
//     }

//     try {
//       Position currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10) // Timeout for fetching location
//       );
//       if (!mounted) return;
//       final currentLatLng = latlng.LatLng(currentPosition.latitude, currentPosition.longitude);
//       _pickedLocation = currentLatLng; // Tentatively set picked location
//       _moveToPosition(currentLatLng, _focusedZoom, updateMarkerAndAddress: updateMarkerAndAddress);
//     } catch (e) {
//       debugPrint("Error fetching current location: $e");
//       if(mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch current location. Moving to default.')));
//         _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom); // Move to default on error
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isFetchingCurrentLocation = false;
//         });
//       }
//     }
//   }


//   // Helper to move map and optionally update marker/address
//   void _moveToPosition(latlng.LatLng position, double zoom, {bool updateMarkerAndAddress = false}) {
//     // Use addPostFrameCallback to ensure map is ready for move, especially during init
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         _mapController.move(position, zoom);
//         if (updateMarkerAndAddress) {
//           _updateMarkerAndAddress(position);
//         }
//       }
//     });
//   }


//   Future<void> _onMapTap(TapPosition tapPosition, latlng.LatLng position) async {
//     if (mounted) {
//       setState(() {
//         _pickedLocation = position;
//         // Optionally move camera to keep tapped point centered if desired
//         // _mapController.move(position, _mapController.camera.zoom);
//       });
//     }
//     await _updateMarkerAndAddress(position);
//   }

//   Future<void> _updateMarkerAndAddress(latlng.LatLng position) async {
//     if (!mounted) return;
//     setState(() {
//       _isLoadingAddress = true;
//       _selectedMarker = Marker(
//         width: 80.0,
//         height: 80.0,
//         point: position,
//         child: Icon(
//           Icons.location_pin,
//           color: Colors.red.shade700,
//           size: 40.0,
//         ),
//       );
//     });

//     try {
//       final url = Uri.parse(
//           'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&accept-language=en');
//       final response = await http.get(url, headers: {
//         'User-Agent': 'YourAppName/1.0 (your.email@example.com)'
//       }).timeout(const Duration(seconds: 10));

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _pickedAddress = data['display_name'] ?? 'Address not found for this pin.';
//           if (_pickedAddress.isEmpty) _pickedAddress = 'Address not found for this pin.';
//         });
//       } else {
//         setState(() {
//           _pickedAddress = 'Failed to fetch address (Code: ${response.statusCode})';
//         });
//       }
//     } catch (e) {
//       debugPrint("Nominatim Error: $e");
//       if (mounted) {
//         setState(() {
//           _pickedAddress = 'Could not fetch address. Check connection.';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingAddress = false;
//         });
//       }
//     }
//   }

//   void _confirmLocation() {
//     if (_pickedLocation != null) {
//       Navigator.pop(context, _pickedLocation);
//     } else {
//        if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please tap on the map to select a location first.')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pick Location (OSM)'),
//         actions: [
//           if (_pickedLocation != null)
//             IconButton(
//               icon: const Icon(Icons.check),
//               onPressed: _confirmLocation,
//               tooltip: 'Confirm Location',
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               // initialCenter will be handled by _initializeMapPosition or _moveToPosition
//               initialCenter: _pickedLocation ?? widget.initialPosition ?? _defaultFallbackPosition,
//               initialZoom: _pickedLocation != null || widget.initialPosition != null
//                            ? _focusedZoom
//                            : _defaultInitialZoom,
//               onTap: _onMapTap,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'your.app.package.name', // IMPORTANT
//               ),
//               if (_selectedMarker != null) MarkerLayer(markers: [_selectedMarker!]),
//               RichAttributionWidget(
//                 attributions: [
//                   TextSourceAttribution(
//                     'OpenStreetMap contributors',
//                     onTap: () { /* Consider launching OSM copyright URL */ },
//                   ),
//                 ],
//                 alignment: AttributionAlignment.bottomLeft,
//               ),
//             ],
//           ),
//           // "My Location" Button and Zoom Buttons
//           Positioned(
//             right: 15,
//             bottom: 160, // Adjust to be above the info panel
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 // My Location Button
//                 FloatingActionButton( // Changed to full size for more prominence
//                   heroTag: "osmMyLocationBtn",
//                   onPressed: _isFetchingCurrentLocation ? null : () => _tryGetCurrentLocationAndMove(updateMarkerAndAddress: true),
//                   child: _isFetchingCurrentLocation
//                       ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
//                       : const Icon(Icons.my_location),
//                   tooltip: 'Go to My Location',
//                 ),
//                 const SizedBox(height: 16), // Increased spacing
//                 // Zoom In
//                 FloatingActionButton.small(
//                   heroTag: "osmZoomInBtn",
//                   onPressed: () {
//                     var currentZoom = _mapController.camera.zoom;
//                     _mapController.move(_mapController.camera.center, currentZoom + 1);
//                   },
//                   child: const Icon(Icons.add),
//                 ),
//                 const SizedBox(height: 8),
//                 // Zoom Out
//                 FloatingActionButton.small(
//                   heroTag: "osmZoomOutBtn",
//                   onPressed: () {
//                      var currentZoom = _mapController.camera.zoom;
//                     _mapController.move(_mapController.camera.center, currentZoom - 1);
//                   },
//                   child: const Icon(Icons.remove),
//                 ),
//               ],
//             ),
//           ),
//           // Info Panel (same as before)
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Material( /* ... same info panel code ... */
//               elevation: 4.0,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 color: Theme.of(context).cardColor.withOpacity(0.95),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Text(
//                       _pickedLocation != null
//                           ? 'Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}'
//                           : 'No location selected',
//                       style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 4),
//                     if (_isLoadingAddress)
//                       const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
//                           SizedBox(width: 8),
//                           Text("Fetching address...")
//                         ]
//                       )
//                     else
//                       Text(
//                         _pickedAddress,
//                         style: Theme.of(context).textTheme.bodySmall,
//                         textAlign: TextAlign.center,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     const SizedBox(height: 10),
//                     if (_pickedLocation != null)
//                       ElevatedButton.icon(
//                         icon: const Icon(Icons.check_circle_outline),
//                         label: const Text('Use This Location'),
//                         onPressed: _confirmLocation,
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
// If you want to launch URLs for attribution:
// import 'package:url_launcher/url_launcher.dart';

class OsmMapPickerScreen extends StatefulWidget {
  final latlng.LatLng? initialPosition;

  const OsmMapPickerScreen({super.key, this.initialPosition});

  @override
  State<OsmMapPickerScreen> createState() => _OsmMapPickerScreenState();
}

class _OsmMapPickerScreenState extends State<OsmMapPickerScreen> {
  final MapController _mapController = MapController();
  latlng.LatLng? _pickedLocation;
  Marker? _selectedMarker;
  String _pickedAddress = "Tap on map to select location";
  bool _isLoadingAddress = false;
  bool _isFetchingCurrentLocation = false;

  static final latlng.LatLng _defaultFallbackPosition = latlng.LatLng(20.5937, 78.9629);
  static const double _defaultInitialZoom = 5.0;
  static const double _focusedZoom = 15.0;
  static const double _maxAllowedZoom = 20.0; // <<< INCREASED MAX ZOOM ALLOWED IN MAPOPTIONS
  static const int _maxTileLayerNativeZoom = 19; // <<< Max zoom provided by default OSM tiles (approx)
  static const int _maxTileLayerDisplayZoom = 20; // <<< Allow overzooming default tiles a bit


  // --- Tile Server Configuration ---
  // You can easily swap these out for testing different tile servers
  // Remember to check their usage policies and attribution!
  
  // Default OSM
  final String _tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  final List<String> _tileSubdomains = const []; // No subdomains for default OSM
  final String _tileAttributionText = 'OpenStreetMap contributors';
  final String? _tileAttributionUrl = 'https://openstreetmap.org/copyright';
  final int _currentTileMaxNativeZoom = _maxTileLayerNativeZoom;
  final int _currentTileMaxDisplayZoom = _maxTileLayerDisplayZoom;

  // Example: OpenTopoMap (check policy)
  // final String _tileUrlTemplate = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  // final List<String> _tileSubdomains = const ['a', 'b', 'c'];
  // final String _tileAttributionText = '© OpenTopoMap (CC-BY-SA)';
  // final String? _tileAttributionUrl = 'https://opentopomap.org';
  // final int _currentTileMaxNativeZoom = 17; // OpenTopoMap might have different max native zoom
  // final int _currentTileMaxDisplayZoom = 18;

  // Example: Stadia Maps OSM Bright (REQUIRES API KEY & registration)
  // final String _yourStadiaApiKey = 'YOUR_STADIA_API_KEY_HERE'; // Replace this
  // final String _tileUrlTemplate = 'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}.png?api_key=$_yourStadiaApiKey';
  // final List<String> _tileSubdomains = const [];
  // final String _tileAttributionText = '© Stadia Maps, © OpenMapTiles © OpenStreetMap contributors';
  // final String? _tileAttributionUrl = 'https://stadiamaps.com/';
  // final int _currentTileMaxNativeZoom = 20; // Stadia offers higher native zoom
  // final int _currentTileMaxDisplayZoom = 22;


  @override
  void initState() {
    super.initState();
    _initializeMapPosition();
  }

  Future<void> _initializeMapPosition() async {
    // ... (same as before)
    if (widget.initialPosition != null) {
      _pickedLocation = widget.initialPosition;
      _moveToPosition(widget.initialPosition!, _focusedZoom, updateMarkerAndAddress: true);
    } else {
      await _tryGetCurrentLocationAndMove();
    }
  }

  Future<void> _tryGetCurrentLocationAndMove({bool updateMarkerAndAddress = false}) async {
    // ... (same as before)
     if (!mounted) return;
    setState(() {
      _isFetchingCurrentLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom);
        setState(() => _isFetchingCurrentLocation = false);
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
          _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom);
          setState(() => _isFetchingCurrentLocation = false);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom);
        setState(() => _isFetchingCurrentLocation = false);
      }
      return;
    }

    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10)
      );
      if (!mounted) return;
      final currentLatLng = latlng.LatLng(currentPosition.latitude, currentPosition.longitude);
      _pickedLocation = currentLatLng; 
      _moveToPosition(currentLatLng, _focusedZoom, updateMarkerAndAddress: updateMarkerAndAddress);
    } catch (e) {
      debugPrint("Error fetching current location: $e");
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch current location.')));
        _moveToPosition(_defaultFallbackPosition, _defaultInitialZoom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _moveToPosition(latlng.LatLng position, double zoom, {bool updateMarkerAndAddress = false}) {
    // ... (same as before)
     WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(position, zoom);
        if (updateMarkerAndAddress) {
          _updateMarkerAndAddress(position);
        }
      }
    });
  }

  Future<void> _onMapTap(TapPosition tapPosition, latlng.LatLng position) async {
    // ... (same as before)
     if (mounted) {
      setState(() {
        _pickedLocation = position;
      });
    }
    await _updateMarkerAndAddress(position);
  }

  Future<void> _updateMarkerAndAddress(latlng.LatLng position) async {
    // ... (same as before, but ensure User-Agent is set correctly for Nominatim)
     if (!mounted) return;
    setState(() {
      _isLoadingAddress = true;
      _selectedMarker = Marker(
        width: 80.0,
        height: 80.0,
        point: position,
        child: Icon(
          Icons.location_pin,
          color: Colors.red.shade700,
          size: 40.0,
        ),
      );
    });

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&accept-language=en');
      final response = await http.get(url, headers: {
        // IMPORTANT: Replace with your actual app name and contact email for Nominatim policy
        'User-Agent': 'YourAppName/1.0 (contact@yourappdomain.com)' 
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pickedAddress = data['display_name'] ?? 'Address not found for this pin.';
          if (_pickedAddress.isEmpty) _pickedAddress = 'Address not found for this pin.';
        });
      } else {
        setState(() {
          _pickedAddress = 'Failed to fetch address (Code: ${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint("Nominatim Error: $e");
      if (mounted) {
        setState(() {
          _pickedAddress = 'Could not fetch address. Check connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _confirmLocation() {
    // ... (same as before)
    if (_pickedLocation != null) {
      Navigator.pop(context, _pickedLocation);
    } else {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please tap on the map to select a location first.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location (OSM)'),
        // ... (actions same as before)
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmLocation,
              tooltip: 'Confirm Location',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation ?? widget.initialPosition ?? _defaultFallbackPosition,
              initialZoom: _pickedLocation != null || widget.initialPosition != null
                           ? _focusedZoom
                           : _defaultInitialZoom,
              maxZoom: _maxAllowedZoom, // <<< Use the defined max zoom for map interaction
              minZoom: 3.0, // Prevent zooming out too far
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrlTemplate, // Use configured tile URL
                subdomains: _tileSubdomains,    // Use configured subdomains
                userAgentPackageName: 'your.app.package.name', // IMPORTANT
                maxZoom: _currentTileMaxDisplayZoom.toDouble(),         // <<< Max zoom for this tile layer (display)
                maxNativeZoom: _currentTileMaxNativeZoom,  // <<< Native max zoom of this tile layer
                // tileProvider: CancellableNetworkTileProvider(), // Good for performance and cancelling requests
              ),
              if (_selectedMarker != null) MarkerLayer(markers: [_selectedMarker!]),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    _tileAttributionText, // Use configured attribution text
                    onTap: () async {
                      if (_tileAttributionUrl != null) {
                        // final Uri attributionUri = Uri.parse(_tileAttributionUrl!);
                        // if (await canLaunchUrl(attributionUri)) {
                        //   await launchUrl(attributionUri);
                        // }
                        // Note: url_launcher would be needed here. For simplicity, omitting actual launch.
                        debugPrint("Attribution tapped: $_tileAttributionUrl");
                      }
                    },
                  ),
                ],
                alignment: AttributionAlignment.bottomLeft,
              ),
            ],
          ),
          // ... (My Location Button and Zoom Buttons - same layout as before)
          Positioned(
            right: 15,
            bottom: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FloatingActionButton( 
                  heroTag: "osmMyLocationBtn",
                  onPressed: _isFetchingCurrentLocation ? null : () => _tryGetCurrentLocationAndMove(updateMarkerAndAddress: true),
                  child: _isFetchingCurrentLocation
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Icon(Icons.my_location),
                  tooltip: 'Go to My Location',
                ),
                const SizedBox(height: 16),
                FloatingActionButton.small(
                  heroTag: "osmZoomInBtn",
                  onPressed: () {
                    var newZoom = _mapController.camera.zoom + 1;
                    if (newZoom <= _maxAllowedZoom) { // Respect overall max zoom
                         _mapController.move(_mapController.camera.center, newZoom);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "osmZoomOutBtn",
                  onPressed: () {
                     var newZoom = _mapController.camera.zoom - 1;
                      _mapController.move(_mapController.camera.center, newZoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          // ... (Info Panel - same layout as before)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: Theme.of(context).cardColor.withOpacity(0.95),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _pickedLocation != null
                          ? 'Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}'
                          : 'No location selected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (_isLoadingAddress)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text("Fetching address...")
                        ]
                      )
                    else
                      Text(
                        _pickedAddress,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),
                    if (_pickedLocation != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Use This Location'),
                        onPressed: _confirmLocation,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}