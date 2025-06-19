// import 'package:flutter/material.dart';

// class CityInfo {
//   final String name;
//   final IconData icon; 

//   CityInfo({
//     required this.name,
//     required this.icon,
//   });
// }

// class CitySelectionScreen extends StatefulWidget {
//   final String? currentSelectedCity;

//   const CitySelectionScreen({Key? key, this.currentSelectedCity}) : super(key: key);

//   @override
//   State<CitySelectionScreen> createState() => _CitySelectionScreenState();
// }

// class _CitySelectionScreenState extends State<CitySelectionScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   late List<CityInfo> _filteredCities;

//   // IMPORTANT: This is an expanded example list with corrected and UNIQUE icons.
//   // CUSTOMIZE this list with cities relevant to your app.
//   // For actual logos, replace IconData with image asset paths.
//   // To use these icons on the HomeScreen, the HomeScreen will need access to this
//   // list (or a similar data structure) to map the returned city name to its icon.
//   // Consider making this list accessible globally or passing it to the HomeScreen.
//   final List<CityInfo> _allCities = [
//     // Metros & Tier 1 (Examples) - Icons have been changed for uniqueness
//     CityInfo(name: 'Agra', icon: Icons.camera_alt_outlined), // Taj Mahal (unique)
//     CityInfo(name: 'Ahmedabad', icon: Icons.architecture_outlined), // Sidi Saiyyed Mosque / Sabarmati Ashram (unique)
//     CityInfo(name: 'Aligarh', icon: Icons.lock_open_outlined), // Locks / University (unique)
//     CityInfo(name: 'Allahabad (Prayagraj)', icon: Icons.waves_outlined),// Sangam (unique)
//     CityInfo(name: 'Amritsar', icon: Icons.temple_hindu_outlined), // Golden Temple (generic temple, unique instance)
//     CityInfo(name: 'Aurangabad', icon: Icons.landscape_outlined), // Ajanta/Ellora nearby (unique)
//     CityInfo(name: 'Bangalore', icon: Icons.laptop_chromebook_outlined), // IT Hub (unique)
//     CityInfo(name: 'Bhopal', icon: Icons.water_drop_outlined), // City of Lakes (unique)
//     CityInfo(name: 'Bhubaneswar', icon: Icons.account_balance_outlined), // Temple City (unique)
//     CityInfo(name: 'Chandigarh', icon: Icons.grid_on_outlined),// Planned City / Rock Garden (unique)
//     CityInfo(name: 'Chennai', icon: Icons.beach_access_outlined), // Marina Beach / Temples (unique)
//     CityInfo(name: 'Coimbatore', icon: Icons.texture_outlined), // Textiles (unique)
//     CityInfo(name: 'Dehradun', icon: Icons.forest_outlined), // Doon Valley / IMA (unique)
//     CityInfo(name: 'Delhi', icon: Icons.flag_outlined), // India Gate / Capital (unique)
//     CityInfo(name: 'Dhanbad', icon: Icons.construction_outlined), // Coal Capital (unique)
//     CityInfo(name: 'Faridabad', icon: Icons.precision_manufacturing_outlined), // Industrial (unique)
//     CityInfo(name: 'Ghaziabad', icon: Icons.apartment_outlined), // NCR City (unique)
//     CityInfo(name: 'Gurgaon (Gurugram)', icon: Icons.business_center_outlined), // Corporate Hub (unique)
//     CityInfo(name: 'Guwahati', icon: Icons.self_improvement_outlined), // Kamakhya Temple (unique)
//     CityInfo(name: 'Gwalior', icon: Icons.shield_outlined), // Gwalior Fort (unique)
//     CityInfo(name: 'Howrah', icon: Icons.train_outlined), // Howrah Station (unique)
//     CityInfo(name: 'Hyderabad', icon: Icons.castle_outlined), // Charminar (unique)
//     CityInfo(name: 'Indore', icon: Icons.cleaning_services_outlined), // Cleanest City / Rajwada (unique)
//     CityInfo(name: 'Jabalpur', icon: Icons.layers_outlined), // Marble Rocks (unique)
//     CityInfo(name: 'Jaipur', icon: Icons.fort_outlined), // Hawa Mahal / Amber Fort (unique)
//     CityInfo(name: 'Jalandhar', icon: Icons.sports_soccer_outlined), // Sports Industry (unique)
//     CityInfo(name: 'Jodhpur', icon: Icons.brightness_3_outlined), // Blue City / Mehrangarh Fort (unique)
//     CityInfo(name: 'Kanpur', icon: Icons.factory_outlined), // Industrial City (unique)
//     CityInfo(name: 'Kochi (Cochin)', icon: Icons.sailing_outlined), // Chinese Fishing Nets / Backwaters (unique)
//     CityInfo(name: 'Kolkata', icon: Icons.museum_outlined), // Howrah Bridge / Victoria Memorial (unique, architecture_outlined used for Ahmedabad)
//     CityInfo(name: 'Kota', icon: Icons.school_outlined), // Coaching Hub (unique)
//     CityInfo(name: 'Lucknow', icon: Icons.mosque_outlined), // Bara Imambara (unique)
//     CityInfo(name: 'Ludhiana', icon: Icons.agriculture_outlined), // Industrial / Agricultural Hub (unique)
//     CityInfo(name: 'Madurai', icon: Icons.brightness_7_outlined), // Meenakshi Temple (unique)
//     CityInfo(name: 'Meerut', icon: Icons.sports_kabaddi_outlined), // Sports Goods / Historical (unique)
//     CityInfo(name: 'Mumbai', icon: Icons.account_balance_wallet_outlined), // Gateway of India / Financial Capital (unique)
//     CityInfo(name: 'Mysore (Mysuru)', icon: Icons.palette_outlined), // Mysore Palace (unique)
//     CityInfo(name: 'Nagpur', icon: Icons.public_outlined), // Central location / "Orange City" (generic, unique)
//     CityInfo(name: 'Nashik', icon: Icons.wine_bar_outlined), // Vineyards / Temples (unique)
//     CityInfo(name: 'Patna', icon: Icons.history_edu_outlined), // Golghar / Ancient City (unique)
//     CityInfo(name: 'Pune', icon: Icons.computer_outlined), // IT / Shaniwar Wada (unique)
//     CityInfo(name: 'Raipur', icon: Icons.park_outlined), // City with many parks (unique)
//     CityInfo(name: 'Rajkot', icon: Icons.engineering_outlined), // Engineering Hub (unique)
//     CityInfo(name: 'Ranchi', icon: Icons.waterfall_chart_outlined), // Waterfalls (unique)
//     CityInfo(name: 'Salem', icon: Icons.terrain_outlined), // Steel City / Yercaud Hills nearby (unique)
//     CityInfo(name: 'Srinagar', icon: Icons.downhill_skiing_outlined), // Dal Lake / Mountains (unique, landscape_outlined used for Aurangabad)
//     CityInfo(name: 'Surat', icon: Icons.diamond_outlined), // Diamond Industry (unique)
//     CityInfo(name: 'Thane', icon: Icons.directions_boat_outlined), // Lakes (unique, was waves, waves is used for Allahabad)
//     CityInfo(name: 'Tiruchirappalli', icon: Icons.security_outlined), // Rockfort Temple (generic fort-like, unique, fort_outlined used for Jaipur/Warangal)
//     CityInfo(name: 'Vadodara', icon: Icons.color_lens_outlined), // Art / Palace (unique)
//     CityInfo(name: 'Varanasi', icon: Icons.waving_hand_outlined), // Ghats / Spiritual (unique)
//     CityInfo(name: 'Vijayawada', icon: Icons.brightness_6_outlined),// Kanaka Durga (unique)
//     CityInfo(name: 'Visakhapatnam', icon: Icons.anchor_outlined),// Port City / Beaches (unique)
//     CityInfo(name: 'Warangal', icon: Icons.foundation_outlined), // Warangal Fort / Thousand Pillar Temple (unique)

//     // Add more cities as per your app's target audience and scope!
//     // Ensure each new city gets a unique icon.
//   ];


//   @override
//   void initState() {
//     super.initState();
//     // Sort cities alphabetically by name
//     _allCities.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
//     _filteredCities = _allCities;
//     _searchController.addListener(_filterCities);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_filterCities);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _filterCities() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredCities = _allCities.where((city) {
//         return city.name.toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   void _onCitySelected(String? cityName) {
//     // Returns the city name (or null for "Near Me").
//     // The HomeScreen will then need to use this cityName to find the
//     // corresponding CityInfo object (from a list like _allCities) to get its icon.
//     Navigator.pop(context, cityName);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Location'),
//         elevation: 1.0,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(60.0), // Height for the search bar container
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Center( // Center the TextField
//               child: SizedBox(
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: 'Search city...',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30.0),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: theme.brightness == Brightness.dark
//                         ? Colors.grey[800]
//                         : Colors.grey[200],
//                     contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
//                   ),
//                   textAlignVertical: TextAlignVertical.center,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: ListView.separated(
//         itemCount: _filteredCities.length + 1, // +1 for "Near Me" option
//         separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
//         itemBuilder: (context, index) {
//           // "Near Me" option as the first item
//           if (index == 0) {
//             bool isSelected = widget.currentSelectedCity == null;
//             return ListTile(
//               leading: Icon(
//                 Icons.my_location, // This icon can remain standard for "Near Me"
//                 color: isSelected ? theme.primaryColor : theme.iconTheme.color,
//               ),
//               title: Text(
//                 'Near Me',
//                 style: TextStyle(
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                   color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
//                 ),
//               ),
//               selected: isSelected,
//               selectedTileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
//               onTap: () {
//                 _onCitySelected(null); // null signifies "Near Me" behavior in HomeScreen
//               },
//             );
//           }

//           // City items
//           final city = _filteredCities[index - 1];
//           bool isSelected = widget.currentSelectedCity == city.name;

//           return ListTile(
//             // Example for using actual image assets:
//             // leading: Image.asset(city.logoAssetPath, width: 30, height: 30, fit: BoxFit.contain),
//             leading: Icon(
//               city.icon, // Now uses the unique icon assigned
//               color: isSelected ? theme.primaryColor : theme.iconTheme.color,
//               size: 28,
//             ),
//             title: Text(
//               city.name,
//               style: TextStyle(
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
//               ),
//             ),
//             selected: isSelected,
//             selectedTileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
//             onTap: () {
//               _onCitySelected(city.name);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// File: lib/features/home/screens/city_selection_screen.dart
import 'package:flutter/material.dart';

// Data model for city information.
class CityInfo {
  final String name;
  final IconData icon;

  const CityInfo({ // Made constructor const
    required this.name,
    required this.icon,
  });
}

// Moved the list of cities here to be globally accessible and pre-sorted.
// This list is the source of truth for city data including icons.
// You can keep this list updated here.
final List<CityInfo> kAppAllCities = [
  // Metros & Tier 1 (Examples) - Icons have been changed for uniqueness
  CityInfo(name: 'Agra', icon: Icons.camera_alt_outlined),
  CityInfo(name: 'Ahmedabad', icon: Icons.architecture_outlined),
  CityInfo(name: 'Aligarh', icon: Icons.lock_open_outlined),
  CityInfo(name: 'Allahabad (Prayagraj)', icon: Icons.waves_outlined),
  CityInfo(name: 'Amritsar', icon: Icons.temple_hindu_outlined),
  CityInfo(name: 'Aurangabad', icon: Icons.landscape_outlined),
  CityInfo(name: 'Bangalore', icon: Icons.laptop_chromebook_outlined),
  CityInfo(name: 'Bhopal', icon: Icons.water_drop_outlined),
  CityInfo(name: 'Bhubaneswar', icon: Icons.account_balance_outlined),
  CityInfo(name: 'Chandigarh', icon: Icons.grid_on_outlined),
  CityInfo(name: 'Chennai', icon: Icons.beach_access_outlined),
  CityInfo(name: 'Coimbatore', icon: Icons.texture_outlined),
  CityInfo(name: 'Dehradun', icon: Icons.forest_outlined),
  CityInfo(name: 'Delhi', icon: Icons.flag_outlined),
  CityInfo(name: 'Dhanbad', icon: Icons.construction_outlined),
  CityInfo(name: 'Faridabad', icon: Icons.precision_manufacturing_outlined),
  CityInfo(name: 'Ghaziabad', icon: Icons.apartment_outlined),
  CityInfo(name: 'Gurgaon (Gurugram)', icon: Icons.business_center_outlined),
  CityInfo(name: 'Guwahati', icon: Icons.self_improvement_outlined),
  CityInfo(name: 'Gwalior', icon: Icons.shield_outlined),
  CityInfo(name: 'Howrah', icon: Icons.train_outlined),
  CityInfo(name: 'Hyderabad', icon: Icons.castle_outlined),
  CityInfo(name: 'Indore', icon: Icons.cleaning_services_outlined),
  CityInfo(name: 'Jabalpur', icon: Icons.layers_outlined),
  CityInfo(name: 'Jaipur', icon: Icons.fort_outlined),
  CityInfo(name: 'Jalandhar', icon: Icons.sports_soccer_outlined),
  CityInfo(name: 'Jodhpur', icon: Icons.brightness_3_outlined),
  CityInfo(name: 'Kanpur', icon: Icons.factory_outlined),
  CityInfo(name: 'Kochi (Cochin)', icon: Icons.sailing_outlined),
  CityInfo(name: 'Kolkata', icon: Icons.museum_outlined),
  CityInfo(name: 'Kota', icon: Icons.school_outlined),
  CityInfo(name: 'Lucknow', icon: Icons.mosque_outlined),
  CityInfo(name: 'Ludhiana', icon: Icons.agriculture_outlined),
  CityInfo(name: 'Madurai', icon: Icons.brightness_7_outlined),
  CityInfo(name: 'Meerut', icon: Icons.sports_kabaddi_outlined),
  CityInfo(name: 'Mumbai', icon: Icons.account_balance_wallet_outlined),
  CityInfo(name: 'Mysore (Mysuru)', icon: Icons.palette_outlined),
  CityInfo(name: 'Nagpur', icon: Icons.public_outlined),
  CityInfo(name: 'Nashik', icon: Icons.wine_bar_outlined),
  CityInfo(name: 'Patna', icon: Icons.history_edu_outlined),
  CityInfo(name: 'Pune', icon: Icons.computer_outlined),
  CityInfo(name: 'Raipur', icon: Icons.park_outlined),
  CityInfo(name: 'Rajkot', icon: Icons.engineering_outlined),
  CityInfo(name: 'Ranchi', icon: Icons.waterfall_chart_outlined),
  CityInfo(name: 'Salem', icon: Icons.terrain_outlined),
  CityInfo(name: 'Srinagar', icon: Icons.downhill_skiing_outlined),
  CityInfo(name: 'Surat', icon: Icons.diamond_outlined),
  CityInfo(name: 'Thane', icon: Icons.directions_boat_outlined),
  CityInfo(name: 'Tiruchirappalli', icon: Icons.security_outlined),
  CityInfo(name: 'Vadodara', icon: Icons.color_lens_outlined),
  CityInfo(name: 'Varanasi', icon: Icons.waving_hand_outlined),
  CityInfo(name: 'Vijayawada', icon: Icons.brightness_6_outlined),
  CityInfo(name: 'Visakhapatnam', icon: Icons.anchor_outlined),
  CityInfo(name: 'Warangal', icon: Icons.foundation_outlined),
  // Add more cities as per your app's target audience and scope!
  // Ensure each new city gets a unique icon.
]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort the list once here

class CitySelectionScreen extends StatefulWidget {
  final String? currentSelectedCity;

  const CitySelectionScreen({Key? key, this.currentSelectedCity}) : super(key: key);

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<CityInfo> _filteredCities;

  // Note: _allCities instance variable is removed from here.
  // We will use kAppAllCities (the global final list) as the source.

  @override
  void initState() {
    super.initState();
    // Initialize _filteredCities with all cities from the globally sorted list
    _filteredCities = List.from(kAppAllCities);
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCities);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Filter from the original kAppAllCities list
      _filteredCities = kAppAllCities.where((city) {
        return city.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onCitySelected(String? cityName) {
    Navigator.pop(context, cityName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        elevation: 1.0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: SizedBox(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  textAlignVertical: TextAlignVertical.center,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: _filteredCities.length + 1, // +1 for "Near Me" option
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            bool isSelected = widget.currentSelectedCity == null;
            return ListTile(
              leading: Icon(
                Icons.my_location,
                color: isSelected ? theme.primaryColor : theme.iconTheme.color,
              ),
              title: Text(
                'Near Me',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                ),
              ),
              selected: isSelected,
              selectedTileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
              onTap: () {
                _onCitySelected(null);
              },
            );
          }
          final city = _filteredCities[index - 1];
          bool isSelected = widget.currentSelectedCity == city.name;
          return ListTile(
            leading: Icon(
              city.icon, // Uses the icon from CityInfo
              color: isSelected ? theme.primaryColor : theme.iconTheme.color,
              size: 28,
            ),
            title: Text(
              city.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
              ),
            ),
            selected: isSelected,
            selectedTileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
            onTap: () {
              _onCitySelected(city.name);
            },
          );
        },
      ),
    );
  }
}