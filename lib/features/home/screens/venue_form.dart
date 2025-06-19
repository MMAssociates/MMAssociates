// import 'dart:async';
// import 'dart:io'; // For File, used for non-web image preview

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mm_associates/features/auth/services/auth_service.dart';
// import 'package:mm_associates/features/profile/screens/profile_screen.dart';
// import 'package:mm_associates/features/user/services/user_service.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../../../core/services/geocoding_service.dart';
// import '../../../../core/services/image_upload_service.dart';
// import '../../../../core/services/location_service.dart';
// import '../../../../features/data/services/firestore_service.dart';

// // Assuming 'CitySelectionScreen' is defined in this path.
// // The user has requested not to include its code here.
// // Please ensure this import path is correct for your project structure.
// import 'city_selection_screen.dart';


// class AddVenueFormScreen extends StatefulWidget {
//   final String? venueIdToEdit;
//   final Map<String, dynamic>? initialData;

//   /// True if an admin is landing here directly as their "home" page.
//   /// This will add a button to navigate to the user-facing app view.
//   final bool isDirectAdminAccess;

//   const AddVenueFormScreen({
//     super.key,
//     this.venueIdToEdit,
//     this.initialData,
//     this.isDirectAdminAccess = false,
//   });

//   @override
//   State<AddVenueFormScreen> createState() => _AddVenueFormScreenState();
// }

// class _AddVenueFormScreenState extends State<AddVenueFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirestoreService _firestoreService = FirestoreService();
//   final LocationService _locationService = LocationService();
//   final LocationIQService _geocodingService = LocationIQService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final AuthService _authService = AuthService();
//   final UserService _userService = UserService();

//   final ImageUploadService _imageUploadService = ImageUploadService();
//   final ImagePicker _picker = ImagePicker();

//   static const String _venueImageUploadPreset = 'mm_associates_venue_pics';

//   // Controllers
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _imageUrlController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _areaController = TextEditingController();
//   final _countryController = TextEditingController();
//   final _weekdayStartController = TextEditingController();
//   final _weekdayEndController = TextEditingController();
//   final _saturdayStartController = TextEditingController();
//   final _saturdayEndController = TextEditingController();
//   final _sundayStartController = TextEditingController();
//   final _sundayEndController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _websiteController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _facilitiesController = TextEditingController();
//   final _googleMapsUrlController = TextEditingController();

//   String? _selectedCity;

//   List<String> _selectedSports = [];
//   final _sportInputController = TextEditingController();
//   final _sportInputFocusNode = FocusNode();
//   String? _sportsErrorText;

//   bool _isActive = true;
//   bool _bookingEnabled = true;
//   bool _isLoading = false;
//   bool _isFetchingLocation = false;
//   bool _isGeocoding = false;
//   GeoPoint? _selectedLocation;
//   String? _locationStatusMessage;

//   Timer? _venueNameDebouncer;
//   bool _isCheckingVenueName = false;
//   bool _venueNameIsAvailable = true;
//   String? _venueNameErrorText;
//   String? _initialVenueNameLowercase;

//   XFile? _selectedImageFile;
//   bool _isUploadingImage = false;
//   String? _imageErrorText;

//   String? _userName;
//   String? _userProfilePicUrl;
//   bool _isLoadingName = true;
  
//   // MODIFICATION: Use an internal state variable to manage edit mode.
//   String? _currentVenueIdToEdit;
//   // MODIFICATION: Getter now uses the internal state variable.
//   bool get _isEditMode => _currentVenueIdToEdit != null;
//   AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

//   @override
//   void initState() {
//     super.initState();
//     // MODIFICATION: Initialize the internal state variable.
//     _currentVenueIdToEdit = widget.venueIdToEdit;
    
//     if (_isEditMode && widget.initialData != null) {
//       _prefillFormData(widget.initialData!);
//       _initialVenueNameLowercase =
//           widget.initialData!['name']?.toString().trim().toLowerCase();
//     }
//     _nameController.addListener(_onNameChanged);
//     _fetchUserNameAndPic();
//   }

//   void _prefillFormData(Map<String, dynamic> data) {
//     _nameController.text = data['name'] ?? '';
//     _selectedSports = (data['sportType'] as List<dynamic>?)
//             ?.map((s) => s.toString().trim())
//             .where((s) => s.isNotEmpty)
//             .toList() ??
//         [];
//     _descriptionController.text = data['description'] ?? '';
//     _addressController.text = data['address'] ?? '';
//     _areaController.text = data['area'] ?? '';
//     _selectedCity = data['city'] as String?;
//     _countryController.text = data['country'] ?? '';
//     _imageUrlController.text = data['imageUrl'] ?? '';
//     _isActive = data['isActive'] ?? true;
//     _bookingEnabled = data['bookingEnabled'] ?? true;
//     _phoneController.text = data['phoneNumber'] ?? '';
//     _websiteController.text = data['website'] ?? '';
//     _emailController.text = data['email'] ?? '';
//     _facilitiesController.text =
//         (data['facilities'] as List<dynamic>?)?.join(', ') ?? '';
//     _googleMapsUrlController.text = data['googleMapsUrl'] ?? '';

//     final GeoPoint? initialLocation = data['location'] as GeoPoint?;
//     if (initialLocation != null) {
//       _selectedLocation = initialLocation;
//       _locationStatusMessage =
//           'Current Location: Lat: ${initialLocation.latitude.toStringAsFixed(5)}, Lng: ${initialLocation.longitude.toStringAsFixed(5)}';
//     }

//     if (data['operatingHours'] is Map) {
//       final hoursMap = data['operatingHours'] as Map<String, dynamic>;
//       _weekdayStartController.text = hoursMap['weekday']?['start'] ?? '';
//       _weekdayEndController.text = hoursMap['weekday']?['end'] ?? '';
//       _saturdayStartController.text = hoursMap['saturday']?['start'] ?? '';
//       _saturdayEndController.text = hoursMap['saturday']?['end'] ?? '';
//       _sundayStartController.text = hoursMap['sunday']?['start'] ?? '';
//       _sundayEndController.text = hoursMap['sunday']?['end'] ?? '';
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.removeListener(_onNameChanged);
//     _nameController.dispose();
//     _venueNameDebouncer?.cancel();
//     _sportInputController.dispose();
//     _sportInputFocusNode.dispose();
//     _descriptionController.dispose();
//     _imageUrlController.dispose();
//     _addressController.dispose();
//     _areaController.dispose();
//     _countryController.dispose();
//     _weekdayStartController.dispose();
//     _weekdayEndController.dispose();
//     _saturdayStartController.dispose();
//     _saturdayEndController.dispose();
//     _sundayStartController.dispose();
//     _sundayEndController.dispose();
//     _phoneController.dispose();
//     _websiteController.dispose();
//     _emailController.dispose();
//     _facilitiesController.dispose();
//     _googleMapsUrlController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchUserNameAndPic() async {
//     if (!mounted) return;
//     setState(() => _isLoadingName = true);
//     final currentUser = _auth.currentUser;
//     if (currentUser == null) {
//       if (mounted)
//         setState(() {
//           _userName = 'Guest';
//           _userProfilePicUrl = null;
//           _isLoadingName = false;
//         });
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

//   void _addSportFromInput() {
//     final sportName = _sportInputController.text.trim();
//     if (sportName.isNotEmpty) {
//       final capitalizedSportName = sportName
//           .split(' ')
//           .map((word) => word.isNotEmpty
//               ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
//               : '')
//           .join(' ');

//       if (!_selectedSports
//           .any((s) => s.toLowerCase() == capitalizedSportName.toLowerCase())) {
//         setState(() {
//           _selectedSports.add(capitalizedSportName);
//           _sportsErrorText = null;
//         });
//       }
//       _sportInputController.clear();
//       _sportInputFocusNode.requestFocus();
//     }
//   }

//   void _removeSport(String sportName) {
//     setState(() {
//       _selectedSports.remove(sportName);
//       if (_selectedSports.isEmpty &&
//           _autovalidateMode == AutovalidateMode.onUserInteraction) {
//         _sportsErrorText = 'At least one sport is required.';
//       }
//     });
//   }

//   void _onNameChanged() {
//     if (_venueNameDebouncer?.isActive ?? false) _venueNameDebouncer!.cancel();
//     _venueNameDebouncer = Timer(const Duration(milliseconds: 750), () {
//       final name = _nameController.text.trim();
//       if (name.isNotEmpty) {
//         _checkVenueNameUniqueness(name);
//       } else {
//         setState(() {
//           _isCheckingVenueName = false;
//           _venueNameIsAvailable = true;
//           _venueNameErrorText = null;
//         });
//       }
//     });
//   }

//   Future<void> _checkVenueNameUniqueness(String name) async {
//     if (!mounted) return;
//     setState(() {
//       _isCheckingVenueName = true;
//       _venueNameIsAvailable = true;
//       _venueNameErrorText = null;
//     });
//     final nameLower = name.toLowerCase();
//     if (_isEditMode && nameLower == _initialVenueNameLowercase) {
//       setState(() {
//         _isCheckingVenueName = false;
//         _venueNameIsAvailable = true;
//         _venueNameErrorText = null;
//       });
//       return;
//     }
//     try {
//       final bool exists = await _firestoreService.checkVenueNameExists(
//           nameLower, _isEditMode ? _currentVenueIdToEdit : null); // Use state variable
//       if (!mounted) return;
//       setState(() {
//         _venueNameIsAvailable = !exists;
//         _venueNameErrorText = exists ? 'Venue name already exists.' : null;
//         _isCheckingVenueName = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _venueNameIsAvailable = false;
//         _venueNameErrorText = 'Error checking name. Please try again.';
//         _isCheckingVenueName = false;
//       });
//       debugPrint("Error checking venue name: $e");
//     }
//   }

//   Future<void> _selectTime(
//       BuildContext context, TextEditingController controller) async {
//     TimeOfDay? initialTime;
//     if (controller.text.isNotEmpty) {
//       try {
//         final parts = controller.text.split(':');
//         if (parts.length == 2)
//           initialTime =
//               TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
//       } catch (e) {
//         /* ignore */
//       }
//     }
//     final TimeOfDay? picked =
//         await showTimePicker(context: context, initialTime: initialTime ?? TimeOfDay.now());
//     if (picked != null) {
//       setState(() {
//         controller.text =
//             "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
//       });
//       if (_autovalidateMode == AutovalidateMode.onUserInteraction)
//         _formKey.currentState?.validate();
//     }
//   }

//   Future<void> _fetchAndSetCurrentLocation() async {
//     if (!mounted ||
//         _isLoading ||
//         _isFetchingLocation ||
//         _isGeocoding ||
//         _isUploadingImage) return;
//     setState(() {
//       _isFetchingLocation = true;
//       _locationStatusMessage = 'Fetching...';
//       _selectedLocation = null;
//     });
//     final Position? p = await _locationService.getCurrentLocation();
//     if (!mounted) return;
//     if (p != null) {
//       setState(() {
//         _selectedLocation = GeoPoint(p.latitude, p.longitude);
//         _locationStatusMessage =
//             'Selected: Lat: ${p.latitude.toStringAsFixed(5)}, Lng: ${p.longitude.toStringAsFixed(5)}';
//         _isFetchingLocation = false;
//       });
//       _showSnackBar('Location fetched!', isError: false);
//     } else {
//       setState(() {
//         _locationStatusMessage = 'Could not get location.';
//         _isFetchingLocation = false;
//         _selectedLocation = null;
//       });
//       _showSnackBar('Could not fetch location. Check permissions/service.',
//           isError: true);
//     }
//   }

//   Future<void> _geocodeAddress() async {
//     if (!mounted ||
//         _isLoading ||
//         _isFetchingLocation ||
//         _isGeocoding ||
//         _isUploadingImage) return;
//     FocusScope.of(context).unfocus();
//     final fullAddressQuery = [
//       _addressController.text.trim(),
//       _areaController.text.trim(),
//       _selectedCity ?? '',
//       _countryController.text.trim()
//     ].where((s) => s.isNotEmpty).join(', ');
//     if (fullAddressQuery.length < 5) {
//       _showSnackBar('Enter Address, Area, City, and Country.', isError: true);
//       return;
//     }
//     debugPrint("Geocoding: '$fullAddressQuery'");
//     setState(() {
//       _isGeocoding = true;
//       _locationStatusMessage = 'Finding for "$fullAddressQuery"...';
//       _selectedLocation = null;
//     });
//     try {
//       final GeoPoint? r =
//           await _geocodingService.getCoordsFromAddress(fullAddressQuery);
//       if (!mounted) return;
//       if (r != null) {
//         setState(() {
//           _selectedLocation = r;
//           _locationStatusMessage =
//               'Selected: Lat: ${r.latitude.toStringAsFixed(5)}, Lng: ${r.longitude.toStringAsFixed(5)}';
//           _isGeocoding = false;
//         });
//         _showSnackBar('Location found!', isError: false);
//       } else {
//         setState(() {
//           _locationStatusMessage = 'Could not find location.';
//           _isGeocoding = false;
//           _selectedLocation = null;
//         });
//         _showSnackBar('Address lookup failed.', isError: true);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       String err = e.toString().replaceFirst('Exception: ', '');
//       setState(() {
//         _locationStatusMessage = "Geocoding failed: $err";
//         _isGeocoding = false;
//         _selectedLocation = null;
//       });
//       _showSnackBar("Geocoding error: $err", isError: true);
//       debugPrint("Geocoding error: $e");
//     }
//   }

//   Future<void> _launchGoogleMaps() async {
//     final Uri googleMapsUri = Uri.parse('https://maps.google.com/');
//     try {
//       if (await canLaunchUrl(googleMapsUri)) {
//         await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
//       } else {
//         _showSnackBar('Could not open Google Maps. Please open it manually.',
//             isError: true);
//       }
//     } catch (e) {
//       _showSnackBar('Error opening Google Maps: $e', isError: true);
//     }
//   }

//   Future<void> _pickAndUploadImage() async {
//     if (_isUploadingImage) return;
//     setState(() {
//       _imageErrorText = null;
//     });

//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//           source: ImageSource.gallery,
//           imageQuality: 70,
//           maxWidth: 1024,
//           maxHeight: 1024);
//       if (pickedFile == null) return;

//       setState(() {
//         _selectedImageFile = pickedFile;
//         _isUploadingImage = true;
//         _imageUrlController.clear();
//       });
//       _showSnackBar('Uploading image...', isError: false, durationSeconds: 10);

//       final String? uploadedUrl =
//           await _imageUploadService.uploadImageToCloudinary(
//         pickedFile,
//         uploadPreset: _venueImageUploadPreset,
//         folder: 'venue_images',
//       );

//       if (!mounted) return;

//       if (uploadedUrl != null) {
//         setState(() {
//           _imageUrlController.text = uploadedUrl;
//           _selectedImageFile = null;
//           _isUploadingImage = false;
//         });
//         _showSnackBar('Image uploaded successfully!', isError: false);
//       } else {
//         throw Exception("Cloudinary returned a null URL.");
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isUploadingImage = false;
//       });
//       debugPrint("Image pick/upload error: $e");
//       _showSnackBar(
//           'Image upload failed: ${e.toString().replaceFirst("Exception: ", "")}',
//           isError: true);
//     }
//   }

//   void _clearImage() {
//     setState(() {
//       _imageUrlController.clear();
//       _selectedImageFile = null;
//       _isUploadingImage = false;
//       _imageErrorText = null;
//     });
//     _showSnackBar('Image removed.', isError: false);
//   }

//   void _resetFormForNewEntry() {
//     if (!mounted) return;
//     _formKey.currentState?.reset();
//     _nameController.clear();
//     _descriptionController.clear();
//     _imageUrlController.clear();
//     _addressController.clear();
//     _areaController.clear();
//     _countryController.clear();
//     _weekdayStartController.clear();
//     _weekdayEndController.clear();
//     _saturdayStartController.clear();
//     _saturdayEndController.clear();
//     _sundayStartController.clear();
//     _sundayEndController.clear();
//     _phoneController.clear();
//     _websiteController.clear();
//     _emailController.clear();
//     _facilitiesController.clear();
//     _googleMapsUrlController.clear();
//     _sportInputController.clear();
//     setState(() {
//       _selectedSports = [];
//       _selectedCity = null;
//       _selectedImageFile = null;
//       _isActive = true;
//       _bookingEnabled = true;
//       _selectedLocation = null;
//       _locationStatusMessage = null;
//       _venueNameIsAvailable = true;
//       _venueNameErrorText = null;
//       _initialVenueNameLowercase = null; // Clear this for new entries
//       _autovalidateMode = AutovalidateMode.disabled;
//     });
//   }

//   Future<void> _submitForm() async {
//     setState(() {
//       _imageErrorText = null;
//       _sportsErrorText = null;
//     });

//     if (_isLoading || _isUploadingImage) {
//       _showSnackBar('Please wait for current operations to complete.',
//           isError: true);
//       return;
//     }
//     if (_isCheckingVenueName) {
//       _showSnackBar('Venue name check in progress. Please wait.', isError: true);
//       return;
//     }
//     if (!_venueNameIsAvailable && _nameController.text.trim().isNotEmpty) {
//       _showSnackBar(_venueNameErrorText ?? 'Venue name is not available.',
//           isError: true);
//       setState(() {
//         _autovalidateMode = AutovalidateMode.onUserInteraction;
//       });
//       _formKey.currentState?.validate();
//       return;
//     }

//     bool isTextFormFieldsValid = _formKey.currentState!.validate();
//     bool isImagePresent = _imageUrlController.text.trim().isNotEmpty;
//     bool areSportsSelected = _selectedSports.isNotEmpty;

//     if (!isImagePresent) {
//       setState(() {
//         _imageErrorText = 'Venue image is required.';
//       });
//     }
//     if (!areSportsSelected) {
//       setState(() {
//         _sportsErrorText = 'At least one sport is required.';
//       });
//     }

//     if (isTextFormFieldsValid && isImagePresent && areSportsSelected) {
//       setState(() {
//         _isLoading = true;
//       });

//       if (!_isEditMode && _selectedLocation == null) {
//         _showSnackBar(
//             'Set venue location using "Use Current" or "Find Address".',
//             isError: true);
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       try {
//         List<String> sportTypes = List.from(_selectedSports);
//         if (sportTypes.isEmpty) sportTypes.add('General');

//         List<String> facilitiesList = _facilitiesController.text
//             .split(',')
//             .map((s) => s.trim())
//             .where((s) => s.isNotEmpty)
//             .toList();

//         Set<String> keywords = {};
//         void addWordsToKeywordsSet(String text) {
//           if (text.isNotEmpty) {
//             final words = text.toLowerCase().split(RegExp(r"[\s,.-]+"));
//             for (var word in words)
//               if (word.isNotEmpty && word.length > 1) keywords.add(word);
//           }
//         }

//         addWordsToKeywordsSet(_nameController.text.trim());
//         for (String sport in sportTypes) addWordsToKeywordsSet(sport);
//         addWordsToKeywordsSet(_addressController.text.trim());
//         addWordsToKeywordsSet(_areaController.text.trim());
//         addWordsToKeywordsSet(_selectedCity ?? '');
//         addWordsToKeywordsSet(_countryController.text.trim());
//         List<String> searchKeywordsList = keywords.toList();

//         Map<String, dynamic> venueData = {
//           'name': _nameController.text.trim(),
//           'name_lowercase': _nameController.text.trim().toLowerCase(),
//           'sportType': sportTypes,
//           'description': _descriptionController.text.trim(),
//           'address': _addressController.text.trim(),
//           'area': _areaController.text.trim(),
//           'city': _selectedCity,
//           'country': _countryController.text.trim(),
//           'imageUrl': _imageUrlController.text.trim(),
//           'isActive': _isActive,
//           'bookingEnabled': _bookingEnabled,
//           'slotDurationMinutes': 60,
//           'phoneNumber': _phoneController.text.trim(),
//           'website': _websiteController.text.trim(),
//           'email': _emailController.text.trim(),
//           'facilities': facilitiesList,
//           'searchKeywords': searchKeywordsList,
//           'googleMapsUrl': _googleMapsUrlController.text.trim(),
//           'operatingHours': {
//             'weekday': {
//               'start': _weekdayStartController.text.trim(),
//               'end': _weekdayEndController.text.trim()
//             },
//             'saturday': {
//               'start': _saturdayStartController.text.trim(),
//               'end': _saturdayEndController.text.trim()
//             },
//             'sunday': {
//               'start': _sundayStartController.text.trim(),
//               'end': _sundayEndController.text.trim()
//             },
//           },
//           if (_selectedLocation != null) 'location': _selectedLocation,
//           if (!_isEditMode) ...{
//             'creatorUid': _auth.currentUser?.uid,
//             'createdAt': FieldValue.serverTimestamp()
//           },
//         };

//         if (_isEditMode) {
//           venueData.remove('createdAt');
//           venueData.remove('creatorUid');
//           venueData['updatedAt'] = FieldValue.serverTimestamp();
//           // Use the state variable for the ID
//           await _firestoreService.updateVenue(_currentVenueIdToEdit!, venueData);
//           _showSnackBar('Venue updated successfully!', isError: false);
          
//           // MODIFICATION: After successful edit, reset the form to "create" mode
//           setState(() {
//             _currentVenueIdToEdit = null;
//           });
//           _resetFormForNewEntry();

//         } else {
//           await _firestoreService.addVenue(venueData);
//           _showSnackBar('Venue added successfully!', isError: false);
//           _resetFormForNewEntry();
//         }

//       } catch (e) {
//         debugPrint("Submit error: $e");
//         if (!mounted) return;
//         _showSnackBar(
//             'Failed to save venue: ${e.toString().replaceFirst("Exception: ", "")}',
//             isError: true);
//       } finally {
//         if (mounted)
//           setState(() {
//             _isLoading = false;
//           });
//       }
//     } else {
//       setState(() {
//         _autovalidateMode = AutovalidateMode.onUserInteraction;
//       });
//       String errorMessage = "Please fix errors in the form.";
//       if (!isTextFormFieldsValid) {
//         /* Errors shown by fields */
//       } else if (!isImagePresent && !areSportsSelected) {
//         errorMessage = "Please upload a venue image and add at least one sport.";
//       } else if (!isImagePresent) {
//         errorMessage = "Please upload a venue image.";
//       } else if (!areSportsSelected) {
//         errorMessage = "Please add at least one sport.";
//       }
//       _showSnackBar(errorMessage, isError: true);
//     }
//   }

//   void _showSnackBar(String message,
//       {required bool isError, int durationSeconds = 3}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).removeCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//       backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
//       behavior: SnackBarBehavior.floating,
//       margin: const EdgeInsets.all(10),
//       duration: Duration(seconds: message == 'Uploading image...' ? 10 : durationSeconds),
//     ));
//   }

//   AppBar _buildAppBar(BuildContext context) {
//     final theme = Theme.of(context);
//     final bool isLoggedIn = _auth.currentUser != null;
//     final appBarBackgroundColor =
//         theme.appBarTheme.backgroundColor ?? theme.primaryColor;
//     final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ??
//         theme.appBarTheme.iconTheme?.color ??
//         (kIsWeb
//             ? (theme.brightness == Brightness.dark
//                 ? Colors.white70
//                 : Colors.black87)
//             : Colors.white);
//     final titleTextStyle = theme.appBarTheme.titleTextStyle?.copyWith(
//             color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ??
//         TextStyle(
//             color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.w500);

//     return AppBar(
//       toolbarHeight: 70.0,
//       automaticallyImplyLeading: false,
//       backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
//       elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
//       iconTheme: theme.iconTheme.copyWith(
//           color: kIsWeb
//               ? (theme.brightness == Brightness.dark
//                   ? Colors.white70
//                   : Colors.black87)
//               : Colors.white),
//       actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
//       title: kIsWeb
//           ? Row(children: [
//               Text('MM Associates',
//                   style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: theme.textTheme.titleLarge?.color ??
//                           theme.primaryColor)),
//               const SizedBox(width: 24),
//               if (_isLoadingName && isLoggedIn)
//                 const Padding(
//                     padding: EdgeInsets.only(right: 16.0),
//                     child: SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(strokeWidth: 2)))
//               else if (_userName != null && isLoggedIn)
//                 Padding(
//                     padding: const EdgeInsets.only(right: 16.0),
//                     child: Text('Hi, ${_userName!.split(' ')[0]}!',
//                         style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: theme.textTheme.bodyLarge?.color),
//                         overflow: TextOverflow.ellipsis)),
//               const Spacer(),
//             ])
//           : Row(children: [
//               if (isLoggedIn)
//                 GestureDetector(
//                   onTap: () {
//                     if (!context.mounted) return;
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const ProfileScreen()));
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: CircleAvatar(
//                         radius: 18,
//                         backgroundColor: Colors.white24,
//                         backgroundImage: _userProfilePicUrl != null &&
//                                 _userProfilePicUrl!.isNotEmpty
//                             ? NetworkImage(_userProfilePicUrl!)
//                             : null,
//                         child: _userProfilePicUrl == null ||
//                                 _userProfilePicUrl!.isEmpty
//                             ? Icon(Icons.person_outline,
//                                 size: 20, color: Colors.white.withOpacity(0.8))
//                             : null),
//                   ),
//                 ),
//               if (_isLoadingName && isLoggedIn)
//                 const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor:
//                             AlwaysStoppedAnimation<Color>(Colors.white70)))
//               else if (_userName != null && isLoggedIn)
//                 Flexible(
//                   child: Text('Hi, ${_userName!.split(' ')[0]}!',
//                       style: titleTextStyle.copyWith(
//                           fontSize: 18, fontWeight: FontWeight.w500),
//                       overflow: TextOverflow.ellipsis),
//                 )
//               else
//                 Text('MM Associates', style: titleTextStyle),
//             ]),
//       centerTitle: false,
//       actions: [
//         if (isLoggedIn)
//           IconButton(
//             icon: Icon(Icons.person_outline_rounded, color: actionsIconColor),
//             tooltip: 'My Profile',
//             onPressed: () {
//               if (!context.mounted) return;
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const ProfileScreen()));
//             },
//           ),
//         if (kIsWeb) const SizedBox(width: 8),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool anyOperationInProgress = _isLoading ||
//         _isFetchingLocation ||
//         _isGeocoding ||
//         _isUploadingImage ||
//         _isCheckingVenueName;
//     final String submitBtnTxt = _isEditMode ? "Update Venue" : "Save Venue";
//     final IconData submitBtnIcon =
//         _isEditMode ? Icons.edit_outlined : Icons.save_alt_outlined;
//     final String pageTitle = _isEditMode ? 'Edit Venue' : 'Add New Venue';

//     Widget nameSuffixIcon;
//     if (_isCheckingVenueName) {
//       nameSuffixIcon = const SizedBox(
//           width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
//     } else if (_nameController.text.trim().isNotEmpty &&
//         (_isEditMode
//             ? _nameController.text.trim().toLowerCase() !=
//                 _initialVenueNameLowercase
//             : true)) {
//       nameSuffixIcon = _venueNameIsAvailable
//           ? const Icon(Icons.check_circle_outline, color: Colors.green)
//           : Icon(Icons.error_outline,
//               color: Theme.of(context).colorScheme.error);
//     } else {
//       nameSuffixIcon = const SizedBox.shrink();
//     }

//     return Scaffold(
//       appBar: _buildAppBar(context),
//       body: SingleChildScrollView(
//         child: GestureDetector(
//           onTap: () => FocusScope.of(context).unfocus(),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               autovalidateMode: _autovalidateMode,
//               child: AbsorbPointer(
//                 absorbing: anyOperationInProgress,
//                 child: Opacity(
//                   opacity: anyOperationInProgress ? 0.7 : 1.0,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Center(
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
//                           child: Text(
//                             pageTitle,
//                             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                       _buildSectionHeader("Core Details"),
//                       TextFormField(
//                           controller: _nameController,
//                           decoration: InputDecoration(
//                             labelText: 'Venue Name*',
//                             prefixIcon: const Icon(Icons.sports_soccer),
//                             suffixIcon: Padding(
//                                 padding: const EdgeInsets.only(right: 12.0),
//                                 child: nameSuffixIcon),
//                             errorText: ((_nameController.text.isNotEmpty &&
//                                         !_isCheckingVenueName &&
//                                         !_isEditMode) ||
//                                     (_nameController.text.isNotEmpty &&
//                                         !_isCheckingVenueName &&
//                                         _isEditMode &&
//                                         _nameController.text
//                                                 .trim()
//                                                 .toLowerCase() !=
//                                             _initialVenueNameLowercase))
//                                 ? _venueNameErrorText
//                                 : null,
//                           ),
//                           validator: (v) {
//                             if (v == null || v.trim().isEmpty) return 'Required';
//                             return null;
//                           },
//                           textCapitalization: TextCapitalization.words),
//                       const SizedBox(height: 15),
//                       _buildSportsInputSection(),
//                       const SizedBox(height: 15),
//                       TextFormField(
//                           controller: _descriptionController,
//                           decoration: const InputDecoration(
//                               labelText: 'Description',
//                               prefixIcon: Icon(Icons.description_outlined),
//                               alignLabelWithHint: true),
//                           maxLines: 3,
//                           textCapitalization: TextCapitalization.sentences),
//                       const SizedBox(height: 20),
//                       _buildSectionHeader("Venue Image*"),
//                       _buildImageUploadSection(),
//                       const SizedBox(height: 20),
//                       _buildSectionHeader("Address & Location*"),
//                       TextFormField(
//                           controller: _addressController,
//                           decoration: const InputDecoration(
//                               labelText: 'Address Line*',
//                               prefixIcon: Icon(Icons.location_on_outlined)),
//                           validator: (v) =>
//                               v!.trim().isEmpty ? 'Required' : null,
//                           textCapitalization: TextCapitalization.words),
//                       const SizedBox(height: 15),
//                       TextFormField(
//                           controller: _areaController,
//                           decoration: const InputDecoration(
//                               labelText: 'Area / Locality*',
//                               hintText: 'e.g., Borivali, Koramangala',
//                               prefixIcon: Icon(Icons.explore_outlined)),
//                           validator: (v) =>
//                               v!.trim().isEmpty ? 'Required' : null,
//                           textCapitalization: TextCapitalization.words),
//                       const SizedBox(height: 15),
//                       Row(children: [
//                         Expanded(
//                           child: FormField<String>(
//                             // Use a key to force rebuild when city changes externally
//                             key: ValueKey(_selectedCity),
//                             initialValue: _selectedCity,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'City is required';
//                               }
//                               return null;
//                             },
//                             builder: (FormFieldState<String> state) {
//                               void handleTap() async {
//                                 if (anyOperationInProgress) return;
//                                 final result = await Navigator.push<String?>(
//                                   context,
//                                   MaterialPageRoute(builder: (context) => CitySelectionScreen(currentSelectedCity: state.value)),
//                                 );
                                
//                                 if (result != null) {
//                                   state.didChange(result);
//                                   setState(() {
//                                     _selectedCity = result;
//                                   });
//                                 }
//                               }

//                               return InkWell(
//                                 onTap: handleTap,
//                                 child: InputDecorator(
//                                   decoration: InputDecoration(
//                                     labelText: 'City*',
//                                     prefixIcon: const Icon(Icons.location_city),
//                                     errorText: state.errorText,
//                                     border: const OutlineInputBorder(),
//                                     contentPadding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 16.0),
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           state.value ?? 'Tap to select city',
//                                           overflow: TextOverflow.ellipsis,
//                                           softWrap: false,
//                                           style: state.value == null
//                                             ? TextStyle(color: Theme.of(context).hintColor, fontSize: 16)
//                                             : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal),
//                                         ),
//                                       ),
//                                       const Icon(Icons.arrow_drop_down, color: Colors.grey),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                             child: TextFormField(
//                                 controller: _countryController,
//                                 decoration: const InputDecoration(
//                                     labelText: 'Country*',
//                                     prefixIcon: Icon(Icons.public)),
//                                 validator: (v) =>
//                                     v!.trim().isEmpty ? 'Required' : null,
//                                 textCapitalization: TextCapitalization.words))
//                       ]),
//                       const SizedBox(height: 15),
//                       Row(children: [
//                         Expanded(
//                             child: OutlinedButton.icon(
//                                 icon: _isFetchingLocation
//                                     ? _buildButtonSpinner()
//                                     : const Icon(Icons.my_location, size: 18),
//                                 label: const Text('Use Current'),
//                                 onPressed: anyOperationInProgress
//                                     ? null
//                                     : _fetchAndSetCurrentLocation,
//                                 style: OutlinedButton.styleFrom(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 12)))),
//                         const SizedBox(width: 10),
//                         Expanded(
//                             child: OutlinedButton.icon(
//                                 icon: _isGeocoding
//                                     ? _buildButtonSpinner()
//                                     : const Icon(Icons.location_searching,
//                                         size: 18),
//                                 label: const Text('Find Address'),
//                                 onPressed: anyOperationInProgress
//                                     ? null
//                                     : _geocodeAddress,
//                                 style: OutlinedButton.styleFrom(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 12))))
//                       ]),
//                       Padding(
//                           padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
//                           child: Text(
//                               _locationStatusMessage ??
//                                   (_isEditMode && _selectedLocation != null
//                                       ? 'Location previously set'
//                                       : 'Location not set* (Required for new venues)'),
//                               style: TextStyle(
//                                   fontSize: 13, color: Colors.grey[700]),
//                               textAlign: TextAlign.center)),
//                       _buildSectionHeader("Venue on Google Maps*"),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               icon: const Icon(Icons.map_outlined, size: 18),
//                               label: const Text('Open Google Maps'),
//                               onPressed:
//                                   anyOperationInProgress ? null : _launchGoogleMaps,
//                               style: OutlinedButton.styleFrom(
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 12),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
//                       TextFormField(
//                         controller: _googleMapsUrlController,
//                         decoration: const InputDecoration(
//                           labelText: 'Pasted Google Maps Link*',
//                           hintText: 'e.g., https://maps.app.goo.gl/xxxx',
//                           prefixIcon: Icon(Icons.link),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Google Maps link is required.';
//                           }
//                           final trimmedValue = value.trim();
//                           final uri = Uri.tryParse(trimmedValue);
//                           if (uri == null || !uri.isAbsolute) {
//                             return 'Please enter a valid URL.';
//                           }
//                           final lowerTrimmedValue = trimmedValue.toLowerCase();
//                           if (!lowerTrimmedValue.contains('maps.app.goo.gl') &&
//                               !lowerTrimmedValue.contains('google.') &&
//                               !lowerTrimmedValue.contains('goo.gl/maps')) {
//                             return 'Please paste a valid Google Maps link (e.g., from Share button).';
//                           }
//                           return null;
//                         },
//                         keyboardType: TextInputType.url,
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(
//                             top: 8.0, left: 4.0, right: 4.0, bottom: 5.0),
//                         child: Text(
//                           "1. Click 'Open Google Maps' above.\n"
//                           "2. In Google Maps, find the exact venue.\n"
//                           "3. Use the 'Share' option and 'Copy link'.\n"
//                           "4. Paste the link in the field above.",
//                           style: TextStyle(
//                               fontSize: 12.5,
//                               color: Theme.of(context).hintColor),
//                           textAlign: TextAlign.start,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       _buildSectionHeader("Operating Hours*"),
//                       _buildOperatingHoursRow(
//                           "Weekday", _weekdayStartController, _weekdayEndController),
//                       const SizedBox(height: 12),
//                       _buildOperatingHoursRow("Saturday", _saturdayStartController,
//                           _saturdayEndController),
//                       const SizedBox(height: 12),
//                       _buildOperatingHoursRow(
//                           "Sunday", _sundayStartController, _sundayEndController),
//                       const SizedBox(height: 20),
//                       _buildSectionHeader("Contact & Other Info"),
//                       TextFormField(
//                           controller: _phoneController,
//                           decoration: const InputDecoration(
//                               labelText: 'Phone*',
//                               prefixIcon: Icon(Icons.phone_outlined)),
//                           keyboardType: TextInputType.phone,
//                           validator: (v) {
//                             if (v == null || v.trim().isEmpty) {
//                               return 'Phone number is required';
//                             }
//                             return null;
//                           }),
//                       const SizedBox(height: 15),
//                       TextFormField(
//                           controller: _emailController,
//                           decoration: const InputDecoration(
//                               labelText: 'Email*',
//                               prefixIcon: Icon(Icons.email_outlined)),
//                           keyboardType: TextInputType.emailAddress,
//                           validator: (v) {
//                             if (v == null || v.trim().isEmpty) {
//                               return 'Email is required';
//                             }
//                             if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
//                                 .hasMatch(v.trim()))
//                               return 'Please enter a valid email address';
//                             return null;
//                           }),
//                       const SizedBox(height: 15),
//                       TextFormField(
//                           controller: _websiteController,
//                           decoration: const InputDecoration(
//                               labelText: 'Website (Optional)',
//                               prefixIcon: Icon(Icons.language_outlined)),
//                           keyboardType: TextInputType.url,
//                           validator: (v) {
//                             if (v!.trim().isNotEmpty &&
//                                 (Uri.tryParse(v.trim())?.isAbsolute ?? false) ==
//                                     false) return 'Invalid URL';
//                             return null;
//                           }),
//                       const SizedBox(height: 15),
//                       TextFormField(
//                           controller: _facilitiesController,
//                           decoration: const InputDecoration(
//                               labelText: 'Facilities*',
//                               hintText: 'e.g., Parking, Washroom, Cafe (Comma-separated)',
//                               prefixIcon: Icon(Icons.local_offer_outlined)),
//                           textCapitalization: TextCapitalization.words,
//                           validator: (v) {
//                             if (v == null || v.trim().isEmpty) {
//                               return 'At least one facility is required';
//                             }
//                             return null;
//                           }),
//                       const SizedBox(height: 20),
//                       _buildSectionHeader("Status & Settings"),
//                       SwitchListTile(
//                           title: const Text('Booking Enabled?'),
//                           subtitle: const Text(
//                               'Can users make bookings for this venue?'),
//                           value: _bookingEnabled,
//                           onChanged: anyOperationInProgress
//                               ? null
//                               : (v) => setState(() => _bookingEnabled = v),
//                           secondary: Icon(
//                               _bookingEnabled
//                                   ? Icons.event_available
//                                   : Icons.event_busy,
//                               color: _bookingEnabled
//                                   ? Theme.of(context).primaryColor
//                                   : Colors.grey),
//                           contentPadding: EdgeInsets.zero,
//                           dense: true),
//                       const SizedBox(height: 10),
//                       SwitchListTile(
//                           title: const Text('Venue is Active?'),
//                           subtitle: const Text(
//                               'Inactive venues won\'t appear in searches.'),
//                           value: _isActive,
//                           onChanged: anyOperationInProgress
//                               ? null
//                               : (v) => setState(() => _isActive = v),
//                           secondary: Icon(
//                               _isActive
//                                   ? Icons.check_circle
//                                   : Icons.cancel_outlined,
//                               color: _isActive ? Colors.green : Colors.grey),
//                           contentPadding: EdgeInsets.zero,
//                           dense: true),
//                       const SizedBox(height: 25),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             width: 200,
//                             child: ElevatedButton.icon(
//                                 icon: (anyOperationInProgress &&
//                                         (_isLoading || _isUploadingImage))
//                                     ? _buildButtonSpinner(
//                                         size: 20, color: Colors.white)
//                                     : Icon(submitBtnIcon),
//                                 label: Text((anyOperationInProgress &&
//                                         (_isLoading || _isUploadingImage))
//                                     ? 'Saving...'
//                                     : submitBtnTxt),
//                                 onPressed:
//                                     anyOperationInProgress ? null : _submitForm,
//                                 style: ElevatedButton.styleFrom(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 15),
//                                     textStyle: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold))),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageUploadSection() {
//     Widget imagePreview;
//     const double previewSize = 150.0;

//     if (_isUploadingImage && _selectedImageFile == null) {
//       imagePreview = const Center(child: CircularProgressIndicator());
//     } else if (_selectedImageFile != null) {
//       imagePreview = kIsWeb
//           ? Image.network(_selectedImageFile!.path,
//               width: previewSize, height: previewSize, fit: BoxFit.cover)
//           : Image.file(File(_selectedImageFile!.path),
//               width: previewSize, height: previewSize, fit: BoxFit.cover);
//     } else if (_imageUrlController.text.isNotEmpty) {
//       imagePreview = Image.network(
//         _imageUrlController.text,
//         width: previewSize,
//         height: previewSize,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) => const Center(
//             child: Icon(Icons.broken_image_outlined,
//                 size: 40, color: Colors.grey)),
//         loadingBuilder: (context, child, loadingProgress) {
//           if (loadingProgress == null) return child;
//           return Center(
//               child: CircularProgressIndicator(
//                   value: loadingProgress.expectedTotalBytes != null
//                       ? loadingProgress.cumulativeBytesLoaded /
//                           loadingProgress.expectedTotalBytes!
//                       : null));
//         },
//       );
//     } else {
//       imagePreview = Center(
//           child: Icon(Icons.add_a_photo_outlined,
//               size: 40,
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.7)));
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Center(
//           child: Column(
//             children: [
//               GestureDetector(
//                 onTap: _isUploadingImage ? null : _pickAndUploadImage,
//                 child: Container(
//                   height: previewSize,
//                   width: previewSize,
//                   margin: const EdgeInsets.only(bottom: 10.0),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .surfaceVariant
//                         .withOpacity(0.3),
//                     border: Border.all(
//                       color: _imageErrorText != null
//                           ? Theme.of(context).colorScheme.error
//                           : Theme.of(context)
//                               .colorScheme
//                               .outline
//                               .withOpacity(0.5),
//                       width: _imageErrorText != null ? 1.5 : 1.0,
//                     ),
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(7.0),
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         imagePreview,
//                         if (_isUploadingImage)
//                           Container(
//                             color: Colors.black.withOpacity(0.4),
//                             child: const Center(
//                                 child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 3,
//                             )),
//                           ),
//                         if (!_isUploadingImage &&
//                             (_imageUrlController.text.isNotEmpty ||
//                                 _selectedImageFile != null))
//                           Positioned(
//                             top: 4,
//                             right: 4,
//                             child: Material(
//                               color: Colors.black54,
//                               shape: const CircleBorder(),
//                               child: InkWell(
//                                 customBorder: const CircleBorder(),
//                                 onTap: _isUploadingImage ? null : _clearImage,
//                                 child: const Padding(
//                                   padding: EdgeInsets.all(6.0),
//                                   child:
//                                       Icon(Icons.close, color: Colors.white, size: 18),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               if (!_isUploadingImage)
//                 OutlinedButton.icon(
//                   icon: Icon(
//                       _imageUrlController.text.isNotEmpty ||
//                               _selectedImageFile != null
//                           ? Icons.edit_outlined
//                           : Icons.add_photo_alternate_outlined,
//                       size: 18),
//                   label: Text(_imageUrlController.text.isNotEmpty ||
//                           _selectedImageFile != null
//                       ? 'Change Image'
//                       : 'Select Image*'),
//                   onPressed: _pickAndUploadImage,
//                   style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 10)),
//                 ),
//             ],
//           ),
//         ),
//         if (_isUploadingImage)
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 10.0),
//               child: Text("Uploading, please wait...",
//                   style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                       fontStyle: FontStyle.italic)),
//             ),
//           ),
//         if (_imageErrorText != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Center(
//               child: Text(
//                 _imageErrorText!,
//                 style: TextStyle(
//                     color: Theme.of(context).colorScheme.error, fontSize: 12),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         Visibility(
//           visible: false,
//           maintainState: true,
//           child: TextFormField(
//             controller: _imageUrlController,
//             decoration: const InputDecoration(labelText: 'Image URL'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSportsInputSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextFormField(
//           controller: _sportInputController,
//           focusNode: _sportInputFocusNode,
//           textCapitalization: TextCapitalization.words,
//           decoration: InputDecoration(
//             hintText: 'e.g., Cricket, Football (Type & press Enter)*',
//             prefixIcon: const Icon(Icons.fitness_center),
//             border: OutlineInputBorder(
//               borderSide: BorderSide(
//                   color: _sportsErrorText != null
//                       ? Theme.of(context).colorScheme.error
//                       : Theme.of(context).colorScheme.outline),
//               borderRadius: BorderRadius.circular(4.0),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderSide: BorderSide(
//                   color: _sportsErrorText != null
//                       ? Theme.of(context).colorScheme.error
//                       : Theme.of(context).primaryColor,
//                   width: 1.5),
//               borderRadius: BorderRadius.circular(4.0),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderSide: BorderSide(
//                   color: _sportsErrorText != null
//                       ? Theme.of(context).colorScheme.error
//                       : Theme.of(context).colorScheme.outline.withOpacity(0.8)),
//               borderRadius: BorderRadius.circular(4.0),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderSide: BorderSide(
//                   color: Theme.of(context).colorScheme.error, width: 1.5),
//               borderRadius: BorderRadius.circular(4.0),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderSide: BorderSide(
//                   color: Theme.of(context).colorScheme.error, width: 1.5),
//               borderRadius: BorderRadius.circular(4.0),
//             ),
//           ),
//           onFieldSubmitted: (_) => _addSportFromInput(),
//         ),
//         if (_selectedSports.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 4.0),
//               child: Wrap(
//                 spacing: 8.0,
//                 runSpacing: 4.0,
//                 children: _selectedSports.map((sport) {
//                   return InputChip(
//                     label: Text(sport),
//                     labelStyle: TextStyle(
//                         color: Theme.of(context).colorScheme.onSecondaryContainer),
//                     backgroundColor: Theme.of(context)
//                         .colorScheme
//                         .secondaryContainer
//                         .withOpacity(0.7),
//                     deleteIconColor: Theme.of(context)
//                         .colorScheme
//                         .onSecondaryContainer
//                         .withOpacity(0.7),
//                     onDeleted: () => _removeSport(sport),
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     padding: const EdgeInsets.all(6),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         if (_sportsErrorText != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0, left: 12.0),
//             child: Text(
//               _sportsErrorText!,
//               style: TextStyle(
//                   color: Theme.of(context).colorScheme.error, fontSize: 12),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildButtonSpinner({double size = 16, Color? color}) {
//     final resolvedColor = color ?? Theme.of(context).primaryColor;
//     return SizedBox(
//         width: size,
//         height: size,
//         child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(resolvedColor)));
//   }

//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
//       child: Text(title,
//           style: Theme.of(context)
//               .textTheme
//               .titleMedium
//               ?.copyWith(fontWeight: FontWeight.bold)),
//     );
//   }

//   Widget _buildOperatingHoursRow(String dayLabel,
//       TextEditingController startController, TextEditingController endController) {
//     const double dayLabelColumnWidth = 90.0;
//     const double gapBetweenLabelAndTimes = 8.0;
//     const double preferredTimeFieldWidth = 105.0;
//     const double horizontalPaddingForToText = 5.0;
//     String? timeValidator(String? value) {
//       if (value == null || value.trim().isEmpty) return 'Required';
//       if (!RegExp(r"^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$")
//           .hasMatch(value.trim())) return 'HH:MM';
//       return null;
//     }

//     Widget buildCoreTimeInput(TextEditingController controller, String labelText) {
//       return InkWell(
//           onTap: () => _selectTime(context, controller),
//           child: AbsorbPointer(
//               child: TextFormField(
//                   controller: controller,
//                   textAlign: TextAlign.center,
//                   decoration: InputDecoration(
//                       labelText: labelText,
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 4.0, vertical: 8.0),
//                       isDense: true,
//                       border: const OutlineInputBorder(),
//                       suffixIcon: const Icon(Icons.access_time, size: 18)),
//                   validator: timeValidator)));
//     }

//     Widget dayLabelWidget = SizedBox(
//         width: dayLabelColumnWidth,
//         child: Text(dayLabel,
//             style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
//             textAlign: TextAlign.start));
//     if (kIsWeb) {
//       Widget buildWebTimeInput(TextEditingController controller, String labelText) {
//         return SizedBox(
//             width: preferredTimeFieldWidth,
//             child: buildCoreTimeInput(controller, labelText));
//       }

//       final TextPainter textPainter = TextPainter(
//           text: const TextSpan(text: "to", style: TextStyle(fontSize: 14)),
//           maxLines: 1,
//           textDirection: TextDirection.ltr)
//         ..layout(minWidth: 0, maxWidth: double.infinity);
//       final double widthOfToTextWithPadding =
//           textPainter.width + (2 * horizontalPaddingForToText);
//       final double requiredWidthForTimeControlsGroupWeb =
//           (2 * preferredTimeFieldWidth) + widthOfToTextWithPadding;
//       return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
//         final double totalAvailableWidth = constraints.maxWidth;
//         final double singleLineRequiredWidthWeb =
//             dayLabelColumnWidth + gapBetweenLabelAndTimes + requiredWidthForTimeControlsGroupWeb;
//         if (totalAvailableWidth >= singleLineRequiredWidthWeb) {
//           return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
//             dayLabelWidget,
//             const SizedBox(width: gapBetweenLabelAndTimes),
//             Expanded(
//                 child: Row(children: [
//               Flexible(child: buildWebTimeInput(startController, 'Start')),
//               Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: horizontalPaddingForToText),
//                   child: Text("to", style: const TextStyle(fontSize: 14))),
//               Flexible(child: buildWebTimeInput(endController, 'End')),
//               const Spacer()
//             ]))
//           ]);
//         } else {
//           return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 dayLabelWidget,
//                 const SizedBox(height: 8.0),
//                 Padding(
//                     padding: const EdgeInsets.only(left: 0.0),
//                     child:
//                         Row(mainAxisSize: MainAxisSize.min, children: [
//                       buildWebTimeInput(startController, 'Start'),
//                       Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: horizontalPaddingForToText),
//                           child: Text("to", style: const TextStyle(fontSize: 14))),
//                       buildWebTimeInput(endController, 'End')
//                     ]))
//               ]);
//         }
//       });
//     } else {
//       return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
//         dayLabelWidget,
//         const SizedBox(width: gapBetweenLabelAndTimes),
//         Expanded(child: buildCoreTimeInput(startController, 'Start')),
//         Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: horizontalPaddingForToText),
//             child: Text("to", style: const TextStyle(fontSize: 14))),
//         Expanded(child: buildCoreTimeInput(endController, 'End'))
//       ]);
//     }
//   }
// }


//---venue name check based on location

import 'dart:async';
import 'dart:io'; // For File, used for non-web image preview

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';
import 'package:mm_associates/features/profile/screens/profile_screen.dart';
import 'package:mm_associates/features/user/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../features/data/services/firestore_service.dart';

// Assuming 'CitySelectionScreen' is defined in this path.
// The user has requested not to include its code here.
// Please ensure this import path is correct for your project structure.
import 'city_selection_screen.dart';


class AddVenueFormScreen extends StatefulWidget {
  final String? venueIdToEdit;
  final Map<String, dynamic>? initialData;

  /// True if an admin is landing here directly as their "home" page.
  /// This will add a button to navigate to the user-facing app view.
  final bool isDirectAdminAccess;

  const AddVenueFormScreen({
    super.key,
    this.venueIdToEdit,
    this.initialData,
    this.isDirectAdminAccess = false,
  });

  @override
  State<AddVenueFormScreen> createState() => _AddVenueFormScreenState();
}

class _AddVenueFormScreenState extends State<AddVenueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final LocationIQService _geocodingService = LocationIQService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  static const String _venueImageUploadPreset = 'mm_associates_venue_pics';

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _countryController = TextEditingController();
  final _weekdayStartController = TextEditingController();
  final _weekdayEndController = TextEditingController();
  final _saturdayStartController = TextEditingController();
  final _saturdayEndController = TextEditingController();
  final _sundayStartController = TextEditingController();
  final _sundayEndController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final _googleMapsUrlController = TextEditingController();

  String? _selectedCity;

  List<String> _selectedSports = [];
  final _sportInputController = TextEditingController();
  final _sportInputFocusNode = FocusNode();
  String? _sportsErrorText;

  bool _isActive = true;
  bool _bookingEnabled = true;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _isGeocoding = false;
  GeoPoint? _selectedLocation;
  String? _locationStatusMessage;

  // Uniqueness check state
  Timer? _venueNameDebouncer;
  bool _isCheckingVenueName = false;
  bool _venueNameIsAvailable = true;
  String? _venueNameErrorText;
  bool _hasRunUniquenessCheck = false;

  // Initial values for edit mode comparison
  String? _initialVenueNameLowercase;
  String? _initialCity;
  String? _initialArea;

  XFile? _selectedImageFile;
  bool _isUploadingImage = false;
  String? _imageErrorText;

  String? _userName;
  String? _userProfilePicUrl;
  bool _isLoadingName = true;
  
  String? _currentVenueIdToEdit;
  bool get _isEditMode => _currentVenueIdToEdit != null;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _currentVenueIdToEdit = widget.venueIdToEdit;
    
    if (_isEditMode && widget.initialData != null) {
      _prefillFormData(widget.initialData!);
      _initialVenueNameLowercase = widget.initialData!['name']?.toString().trim().toLowerCase();
      _initialCity = widget.initialData!['city'] as String?;
      _initialArea = widget.initialData!['area'] as String?;
    }
    
    // Listen to changes on all identifying fields to re-trigger the uniqueness check
    _nameController.addListener(_onIdentityFieldsChanged);
    _areaController.addListener(_onIdentityFieldsChanged);

    _fetchUserNameAndPic();
  }

  void _prefillFormData(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _selectedSports = (data['sportType'] as List<dynamic>?)
            ?.map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    _descriptionController.text = data['description'] ?? '';
    _addressController.text = data['address'] ?? '';
    _areaController.text = data['area'] ?? '';
    _selectedCity = data['city'] as String?;
    _countryController.text = data['country'] ?? '';
    _imageUrlController.text = data['imageUrl'] ?? '';
    _isActive = data['isActive'] ?? true;
    _bookingEnabled = data['bookingEnabled'] ?? true;
    _phoneController.text = data['phoneNumber'] ?? '';
    _websiteController.text = data['website'] ?? '';
    _emailController.text = data['email'] ?? '';
    _facilitiesController.text =
        (data['facilities'] as List<dynamic>?)?.join(', ') ?? '';
    _googleMapsUrlController.text = data['googleMapsUrl'] ?? '';

    final GeoPoint? initialLocation = data['location'] as GeoPoint?;
    if (initialLocation != null) {
      _selectedLocation = initialLocation;
      _locationStatusMessage =
          'Current Location: Lat: ${initialLocation.latitude.toStringAsFixed(5)}, Lng: ${initialLocation.longitude.toStringAsFixed(5)}';
    }

    if (data['operatingHours'] is Map) {
      final hoursMap = data['operatingHours'] as Map<String, dynamic>;
      _weekdayStartController.text = hoursMap['weekday']?['start'] ?? '';
      _weekdayEndController.text = hoursMap['weekday']?['end'] ?? '';
      _saturdayStartController.text = hoursMap['saturday']?['start'] ?? '';
      _saturdayEndController.text = hoursMap['saturday']?['end'] ?? '';
      _sundayStartController.text = hoursMap['sunday']?['start'] ?? '';
      _sundayEndController.text = hoursMap['sunday']?['end'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onIdentityFieldsChanged);
    _areaController.removeListener(_onIdentityFieldsChanged);
    _nameController.dispose();
    _areaController.dispose();
    _venueNameDebouncer?.cancel();
    _sportInputController.dispose();
    _sportInputFocusNode.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _weekdayStartController.dispose();
    _weekdayEndController.dispose();
    _saturdayStartController.dispose();
    _saturdayEndController.dispose();
    _sundayStartController.dispose();
    _sundayEndController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _facilitiesController.dispose();
    _googleMapsUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserNameAndPic() async {
    if (!mounted) return;
    setState(() => _isLoadingName = true);
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted)
        setState(() {
          _userName = 'Guest';
          _userProfilePicUrl = null;
          _isLoadingName = false;
        });
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

  void _addSportFromInput() {
    final sportName = _sportInputController.text.trim();
    if (sportName.isNotEmpty) {
      final capitalizedSportName = sportName
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '')
          .join(' ');

      if (!_selectedSports
          .any((s) => s.toLowerCase() == capitalizedSportName.toLowerCase())) {
        setState(() {
          _selectedSports.add(capitalizedSportName);
          _sportsErrorText = null;
        });
      }
      _sportInputController.clear();
      _sportInputFocusNode.requestFocus();
    }
  }

  void _removeSport(String sportName) {
    setState(() {
      _selectedSports.remove(sportName);
      if (_selectedSports.isEmpty &&
          _autovalidateMode == AutovalidateMode.onUserInteraction) {
        _sportsErrorText = 'At least one sport is required.';
      }
    });
  }

  void _onIdentityFieldsChanged() {
    if (_venueNameDebouncer?.isActive ?? false) _venueNameDebouncer!.cancel();
    _venueNameDebouncer = Timer(const Duration(milliseconds: 750), () {
      final name = _nameController.text.trim();
      final area = _areaController.text.trim();
      final city = _selectedCity;

      // Don't run the check unless all three identifying fields are filled.
      if (name.isEmpty || area.isEmpty || city == null || city.isEmpty) {
        setState(() {
          _isCheckingVenueName = false;
          _hasRunUniquenessCheck = false;
          _venueNameIsAvailable = true; // No known conflict
          _venueNameErrorText = null;
        });
        return;
      }

      _checkVenueNameUniqueness(name, city, area);
    });
  }

  Future<void> _checkVenueNameUniqueness(String name, String city, String area) async {
    if (!mounted) return;
    setState(() {
      _isCheckingVenueName = true;
      _hasRunUniquenessCheck = false;
      _venueNameIsAvailable = true;
      _venueNameErrorText = null;
    });

    final nameLower = name.toLowerCase();
    
    // In edit mode, if the identifying combination is the same as the initial one, it's valid.
    if (_isEditMode && nameLower == _initialVenueNameLowercase && city == _initialCity && area == _initialArea) {
      setState(() {
        _isCheckingVenueName = false;
        _hasRunUniquenessCheck = true; // A check was "made" and it passed
        _venueNameIsAvailable = true;
        _venueNameErrorText = null;
      });
      return;
    }
    
    try {
      final bool exists = await _firestoreService.checkVenueNameExists(
        nameLower, city, area.toLowerCase(), _currentVenueIdToEdit
      );
      if (!mounted) return;
      setState(() {
        _venueNameIsAvailable = !exists;
        _venueNameErrorText = exists ? 'Name already exists in this City and Area.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _venueNameIsAvailable = false;
        _venueNameErrorText = 'Error checking name. Please try again.';
      });
      debugPrint("Error checking venue name: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVenueName = false;
          _hasRunUniquenessCheck = true; // Mark that a check has completed.
        });
      }
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay? initialTime;
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2)
          initialTime =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        /* ignore */
      }
    }
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: initialTime ?? TimeOfDay.now());
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
      if (_autovalidateMode == AutovalidateMode.onUserInteraction)
        _formKey.currentState?.validate();
    }
  }

  Future<void> _fetchAndSetCurrentLocation() async {
    if (!mounted ||
        _isLoading ||
        _isFetchingLocation ||
        _isGeocoding ||
        _isUploadingImage) return;
    setState(() {
      _isFetchingLocation = true;
      _locationStatusMessage = 'Fetching...';
      _selectedLocation = null;
    });
    final Position? p = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (p != null) {
      setState(() {
        _selectedLocation = GeoPoint(p.latitude, p.longitude);
        _locationStatusMessage =
            'Selected: Lat: ${p.latitude.toStringAsFixed(5)}, Lng: ${p.longitude.toStringAsFixed(5)}';
        _isFetchingLocation = false;
      });
      _showSnackBar('Location fetched!', isError: false);
    } else {
      setState(() {
        _locationStatusMessage = 'Could not get location.';
        _isFetchingLocation = false;
        _selectedLocation = null;
      });
      _showSnackBar('Could not fetch location. Check permissions/service.',
          isError: true);
    }
  }

  Future<void> _geocodeAddress() async {
    if (!mounted ||
        _isLoading ||
        _isFetchingLocation ||
        _isGeocoding ||
        _isUploadingImage) return;
    FocusScope.of(context).unfocus();
    final fullAddressQuery = [
      _addressController.text.trim(),
      _areaController.text.trim(),
      _selectedCity ?? '',
      _countryController.text.trim()
    ].where((s) => s.isNotEmpty).join(', ');
    if (fullAddressQuery.length < 5) {
      _showSnackBar('Enter Address, Area, City, and Country.', isError: true);
      return;
    }
    debugPrint("Geocoding: '$fullAddressQuery'");
    setState(() {
      _isGeocoding = true;
      _locationStatusMessage = 'Finding for "$fullAddressQuery"...';
      _selectedLocation = null;
    });
    try {
      final GeoPoint? r =
          await _geocodingService.getCoordsFromAddress(fullAddressQuery);
      if (!mounted) return;
      if (r != null) {
        setState(() {
          _selectedLocation = r;
          _locationStatusMessage =
              'Selected: Lat: ${r.latitude.toStringAsFixed(5)}, Lng: ${r.longitude.toStringAsFixed(5)}';
          _isGeocoding = false;
        });
        _showSnackBar('Location found!', isError: false);
      } else {
        setState(() {
          _locationStatusMessage = 'Could not find location.';
          _isGeocoding = false;
          _selectedLocation = null;
        });
        _showSnackBar('Address lookup failed.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      String err = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _locationStatusMessage = "Geocoding failed: $err";
        _isGeocoding = false;
        _selectedLocation = null;
      });
      _showSnackBar("Geocoding error: $err", isError: true);
      debugPrint("Geocoding error: $e");
    }
  }

  Future<void> _launchGoogleMaps() async {
    final Uri googleMapsUri = Uri.parse('https://maps.google.com/');
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open Google Maps. Please open it manually.',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening Google Maps: $e', isError: true);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage) return;
    setState(() {
      _imageErrorText = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1024,
          maxHeight: 1024);
      if (pickedFile == null) return;

      setState(() {
        _selectedImageFile = pickedFile;
        _isUploadingImage = true;
        _imageUrlController.clear();
      });
      _showSnackBar('Uploading image...', isError: false, durationSeconds: 10);

      final String? uploadedUrl =
          await _imageUploadService.uploadImageToCloudinary(
        pickedFile,
        uploadPreset: _venueImageUploadPreset,
        folder: 'venue_images',
      );

      if (!mounted) return;

      if (uploadedUrl != null) {
        setState(() {
          _imageUrlController.text = uploadedUrl;
          _selectedImageFile = null;
          _isUploadingImage = false;
        });
        _showSnackBar('Image uploaded successfully!', isError: false);
      } else {
        throw Exception("Cloudinary returned a null URL.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      debugPrint("Image pick/upload error: $e");
      _showSnackBar(
          'Image upload failed: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true);
    }
  }

  void _clearImage() {
    setState(() {
      _imageUrlController.clear();
      _selectedImageFile = null;
      _isUploadingImage = false;
      _imageErrorText = null;
    });
    _showSnackBar('Image removed.', isError: false);
  }

  void _resetFormForNewEntry() {
    if (!mounted) return;
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _addressController.clear();
    _areaController.clear();
    _countryController.clear();
    _weekdayStartController.clear();
    _weekdayEndController.clear();
    _saturdayStartController.clear();
    _saturdayEndController.clear();
    _sundayStartController.clear();
    _sundayEndController.clear();
    _phoneController.clear();
    _websiteController.clear();
    _emailController.clear();
    _facilitiesController.clear();
    _googleMapsUrlController.clear();
    _sportInputController.clear();
    setState(() {
      _selectedSports = [];
      _selectedCity = null;
      _selectedImageFile = null;
      _isActive = true;
      _bookingEnabled = true;
      _selectedLocation = null;
      _locationStatusMessage = null;
      _venueNameIsAvailable = true;
      _venueNameErrorText = null;
      _hasRunUniquenessCheck = false;
      _initialVenueNameLowercase = null; 
      _initialCity = null;
      _initialArea = null;
      _autovalidateMode = AutovalidateMode.disabled;
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      _imageErrorText = null;
      _sportsErrorText = null;
    });

    if (_isLoading || _isUploadingImage) {
      _showSnackBar('Please wait for current operations to complete.',
          isError: true);
      return;
    }
    if (_isCheckingVenueName) {
      _showSnackBar('Venue name check in progress. Please wait.', isError: true);
      return;
    }
    // Final check for name availability before submitting
    if (_hasRunUniquenessCheck && !_venueNameIsAvailable) {
        _showSnackBar(_venueNameErrorText ?? 'Venue name is not available.', isError: true);
        setState(() { _autovalidateMode = AutovalidateMode.onUserInteraction; });
        _formKey.currentState?.validate();
        return;
    }


    bool isTextFormFieldsValid = _formKey.currentState!.validate();
    bool isImagePresent = _imageUrlController.text.trim().isNotEmpty;
    bool areSportsSelected = _selectedSports.isNotEmpty;

    if (!isImagePresent) {
      setState(() {
        _imageErrorText = 'Venue image is required.';
      });
    }
    if (!areSportsSelected) {
      setState(() {
        _sportsErrorText = 'At least one sport is required.';
      });
    }

    if (isTextFormFieldsValid && isImagePresent && areSportsSelected) {
      setState(() {
        _isLoading = true;
      });

      if (!_isEditMode && _selectedLocation == null) {
        _showSnackBar(
            'Set venue location using "Use Current" or "Find Address".',
            isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        List<String> sportTypes = List.from(_selectedSports);
        if (sportTypes.isEmpty) sportTypes.add('General');

        List<String> facilitiesList = _facilitiesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        Set<String> keywords = {};
        void addWordsToKeywordsSet(String text) {
          if (text.isNotEmpty) {
            final words = text.toLowerCase().split(RegExp(r"[\s,.-]+"));
            for (var word in words)
              if (word.isNotEmpty && word.length > 1) keywords.add(word);
          }
        }

        addWordsToKeywordsSet(_nameController.text.trim());
        for (String sport in sportTypes) addWordsToKeywordsSet(sport);
        addWordsToKeywordsSet(_addressController.text.trim());
        addWordsToKeywordsSet(_areaController.text.trim());
        addWordsToKeywordsSet(_selectedCity ?? '');
        addWordsToKeywordsSet(_countryController.text.trim());
        List<String> searchKeywordsList = keywords.toList();

        Map<String, dynamic> venueData = {
          'name': _nameController.text.trim(),
          'name_lowercase': _nameController.text.trim().toLowerCase(),
          'sportType': sportTypes,
          'description': _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'area': _areaController.text.trim(),
          'city': _selectedCity,
          'country': _countryController.text.trim(),
          'imageUrl': _imageUrlController.text.trim(),
          'isActive': _isActive,
          'bookingEnabled': _bookingEnabled,
          'slotDurationMinutes': 60,
          'phoneNumber': _phoneController.text.trim(),
          'website': _websiteController.text.trim(),
          'email': _emailController.text.trim(),
          'facilities': facilitiesList,
          'searchKeywords': searchKeywordsList,
          'googleMapsUrl': _googleMapsUrlController.text.trim(),
          'operatingHours': {
            'weekday': {
              'start': _weekdayStartController.text.trim(),
              'end': _weekdayEndController.text.trim()
            },
            'saturday': {
              'start': _saturdayStartController.text.trim(),
              'end': _saturdayEndController.text.trim()
            },
            'sunday': {
              'start': _sundayStartController.text.trim(),
              'end': _sundayEndController.text.trim()
            },
          },
          if (_selectedLocation != null) 'location': _selectedLocation,
          if (!_isEditMode) ...{
            'creatorUid': _auth.currentUser?.uid,
            'createdAt': FieldValue.serverTimestamp()
          },
        };

        if (_isEditMode) {
          venueData.remove('createdAt');
          venueData.remove('creatorUid');
          venueData['updatedAt'] = FieldValue.serverTimestamp();
          // Use the state variable for the ID
          await _firestoreService.updateVenue(_currentVenueIdToEdit!, venueData);
          _showSnackBar('Venue updated successfully!', isError: false);
          
          // MODIFICATION: After successful edit, reset the form to "create" mode
          setState(() {
            _currentVenueIdToEdit = null;
          });
          _resetFormForNewEntry();

        } else {
          await _firestoreService.addVenue(venueData);
          _showSnackBar('Venue added successfully!', isError: false);
          _resetFormForNewEntry();
        }

      } catch (e) {
        debugPrint("Submit error: $e");
        if (!mounted) return;
        _showSnackBar(
            'Failed to save venue: ${e.toString().replaceFirst("Exception: ", "")}',
            isError: true);
      } finally {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    } else {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      String errorMessage = "Please fix errors in the form.";
      if (!isTextFormFieldsValid) {
        /* Errors shown by fields */
      } else if (!isImagePresent && !areSportsSelected) {
        errorMessage = "Please upload a venue image and add at least one sport.";
      } else if (!isImagePresent) {
        errorMessage = "Please upload a venue image.";
      } else if (!areSportsSelected) {
        errorMessage = "Please add at least one sport.";
      }
      _showSnackBar(errorMessage, isError: true);
    }
  }

  void _showSnackBar(String message,
      {required bool isError, int durationSeconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      duration: Duration(seconds: message == 'Uploading image...' ? 10 : durationSeconds),
    ));
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLoggedIn = _auth.currentUser != null;
    final appBarBackgroundColor =
        theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final actionsIconColor = theme.appBarTheme.actionsIconTheme?.color ??
        theme.appBarTheme.iconTheme?.color ??
        (kIsWeb
            ? (theme.brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87)
            : Colors.white);
    final titleTextStyle = theme.appBarTheme.titleTextStyle?.copyWith(
            color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white) ??
        TextStyle(
            color: kIsWeb ? theme.textTheme.titleLarge?.color : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500);

    return AppBar(
      toolbarHeight: 70.0,
      automaticallyImplyLeading: false,
      backgroundColor: kIsWeb ? theme.canvasColor : appBarBackgroundColor,
      elevation: kIsWeb ? 1.0 : theme.appBarTheme.elevation ?? 4.0,
      iconTheme: theme.iconTheme.copyWith(
          color: kIsWeb
              ? (theme.brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87)
              : Colors.white),
      actionsIconTheme: theme.iconTheme.copyWith(color: actionsIconColor),
      title: kIsWeb
          ? Row(children: [
              Text('Secrets Of Sports',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color ??
                          theme.primaryColor)),
              const SizedBox(width: 24),
              if (_isLoadingName && isLoggedIn)
                const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_userName != null && isLoggedIn)
                Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text('Hi, ${_userName!.split(' ')[0]}!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color),
                        overflow: TextOverflow.ellipsis)),
              const Spacer(),
            ])
          : Row(children: [
              if (isLoggedIn)
                GestureDetector(
                  onTap: () {
                    if (!context.mounted) return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        backgroundImage: _userProfilePicUrl != null &&
                                _userProfilePicUrl!.isNotEmpty
                            ? NetworkImage(_userProfilePicUrl!)
                            : null,
                        child: _userProfilePicUrl == null ||
                                _userProfilePicUrl!.isEmpty
                            ? Icon(Icons.person_outline,
                                size: 20, color: Colors.white.withOpacity(0.8))
                            : null),
                  ),
                ),
              if (_isLoadingName && isLoggedIn)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white70)))
              else if (_userName != null && isLoggedIn)
                Flexible(
                  child: Text('Hi, ${_userName!.split(' ')[0]}!',
                      style: titleTextStyle.copyWith(
                          fontSize: 18, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                )
              else
                Text('Secrets Of Sports', style: titleTextStyle),
            ]),
      centerTitle: false,
      actions: [
        if (isLoggedIn)
          IconButton(
            icon: Icon(Icons.person_outline_rounded, color: actionsIconColor),
            tooltip: 'My Profile',
            onPressed: () {
              if (!context.mounted) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()));
            },
          ),
        if (kIsWeb) const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool anyOperationInProgress = _isLoading ||
        _isFetchingLocation ||
        _isGeocoding ||
        _isUploadingImage ||
        _isCheckingVenueName;
    final String submitBtnTxt = _isEditMode ? "Update Venue" : "Save Venue";
    final IconData submitBtnIcon =
        _isEditMode ? Icons.edit_outlined : Icons.save_alt_outlined;
    final String pageTitle = _isEditMode ? 'Edit Venue' : 'Add New Venue';

    Widget nameSuffixIcon;
    if (_isCheckingVenueName) {
      nameSuffixIcon = const SizedBox(
          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (_hasRunUniquenessCheck) {
      nameSuffixIcon = _venueNameIsAvailable
          ? const Icon(Icons.check_circle_outline, color: Colors.green)
          : Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error);
    } else {
      nameSuffixIcon = const SizedBox.shrink();
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: AbsorbPointer(
                absorbing: anyOperationInProgress,
                child: Opacity(
                  opacity: anyOperationInProgress ? 0.7 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                          child: Text(
                            pageTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      _buildSectionHeader("Core Details"),
                      TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Venue Name*',
                            prefixIcon: const Icon(Icons.sports_soccer),
                            suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: nameSuffixIcon),
                            errorText: _venueNameErrorText,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            return null;
                          },
                          textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 15),
                      _buildSportsInputSection(),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.description_outlined),
                              alignLabelWithHint: true),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences),
                      const SizedBox(height: 20),
                      _buildSectionHeader("Venue Image*"),
                      _buildImageUploadSection(),
                      const SizedBox(height: 20),
                      _buildSectionHeader("Address & Location*"),
                      TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                              labelText: 'Address Line*',
                              prefixIcon: Icon(Icons.location_on_outlined)),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Required' : null,
                          textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(
                              labelText: 'Area / Locality*',
                              hintText: 'e.g., Borivali, Koramangala',
                              prefixIcon: Icon(Icons.explore_outlined)),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Required' : null,
                          textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 15),
                      Row(children: [
                        Expanded(
                          child: FormField<String>(
                            // Use a key to force rebuild when city changes externally
                            key: ValueKey(_selectedCity),
                            initialValue: _selectedCity,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'City is required';
                              }
                              return null;
                            },
                            builder: (FormFieldState<String> state) {
                              void handleTap() async {
                                if (anyOperationInProgress) return;
                                final result = await Navigator.push<String?>(
                                  context,
                                  MaterialPageRoute(builder: (context) => CitySelectionScreen(currentSelectedCity: state.value)),
                                );
                                
                                if (result != null) {
                                  state.didChange(result);
                                  setState(() {
                                    _selectedCity = result;
                                  });
                                  // Re-trigger the uniqueness check now that the city has changed.
                                  _onIdentityFieldsChanged();
                                }
                              }

                              return InkWell(
                                onTap: handleTap,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'City*',
                                    prefixIcon: const Icon(Icons.location_city),
                                    errorText: state.errorText,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 16.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          state.value ?? 'Tap to select city',
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: state.value == null
                                            ? TextStyle(color: Theme.of(context).hintColor, fontSize: 16)
                                            : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: TextFormField(
                                controller: _countryController,
                                decoration: const InputDecoration(
                                    labelText: 'Country*',
                                    prefixIcon: Icon(Icons.public)),
                                validator: (v) =>
                                    v!.trim().isEmpty ? 'Required' : null,
                                textCapitalization: TextCapitalization.words))
                      ]),
                      const SizedBox(height: 15),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                icon: _isFetchingLocation
                                    ? _buildButtonSpinner()
                                    : const Icon(Icons.my_location, size: 18),
                                label: const Text('Use Current'),
                                onPressed: anyOperationInProgress
                                    ? null
                                    : _fetchAndSetCurrentLocation,
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12)))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: OutlinedButton.icon(
                                icon: _isGeocoding
                                    ? _buildButtonSpinner()
                                    : const Icon(Icons.location_searching,
                                        size: 18),
                                label: const Text('Find Address'),
                                onPressed: anyOperationInProgress
                                    ? null
                                    : _geocodeAddress,
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12))))
                      ]),
                      Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                          child: Text(
                              _locationStatusMessage ??
                                  (_isEditMode && _selectedLocation != null
                                      ? 'Location previously set'
                                      : 'Location not set* (Required for new venues)'),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[700]),
                              textAlign: TextAlign.center)),
                      _buildSectionHeader("Venue on Google Maps*"),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Open Google Maps'),
                              onPressed:
                                  anyOperationInProgress ? null : _launchGoogleMaps,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _googleMapsUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Pasted Google Maps Link*',
                          hintText: 'e.g., https://maps.app.goo.gl/xxxx',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Google Maps link is required.';
                          }
                          final trimmedValue = value.trim();
                          final uri = Uri.tryParse(trimmedValue);
                          if (uri == null || !uri.isAbsolute) {
                            return 'Please enter a valid URL.';
                          }
                          final lowerTrimmedValue = trimmedValue.toLowerCase();
                          if (!lowerTrimmedValue.contains('maps.app.goo.gl') &&
                              !lowerTrimmedValue.contains('google.') &&
                              !lowerTrimmedValue.contains('goo.gl/maps')) {
                            return 'Please paste a valid Google Maps link (e.g., from Share button).';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.url,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, left: 4.0, right: 4.0, bottom: 5.0),
                        child: Text(
                          "1. Click 'Open Google Maps' above.\n"
                          "2. In Google Maps, find the exact venue.\n"
                          "3. Use the 'Share' option and 'Copy link'.\n"
                          "4. Paste the link in the field above.",
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).hintColor),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader("Operating Hours*"),
                      _buildOperatingHoursRow(
                          "Weekday", _weekdayStartController, _weekdayEndController),
                      const SizedBox(height: 12),
                      _buildOperatingHoursRow("Saturday", _saturdayStartController,
                          _saturdayEndController),
                      const SizedBox(height: 12),
                      _buildOperatingHoursRow(
                          "Sunday", _sundayStartController, _sundayEndController),
                      const SizedBox(height: 20),
                      _buildSectionHeader("Contact & Other Info"),
                      TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                              labelText: 'Phone*',
                              prefixIcon: Icon(Icons.phone_outlined)),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          }),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                              labelText: 'Email*',
                              prefixIcon: Icon(Icons.email_outlined)),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                .hasMatch(v.trim()))
                              return 'Please enter a valid email address';
                            return null;
                          }),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                              labelText: 'Website (Optional)',
                              prefixIcon: Icon(Icons.language_outlined)),
                          keyboardType: TextInputType.url,
                          validator: (v) {
                            if (v!.trim().isNotEmpty &&
                                (Uri.tryParse(v.trim())?.isAbsolute ?? false) ==
                                    false) return 'Invalid URL';
                            return null;
                          }),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: _facilitiesController,
                          decoration: const InputDecoration(
                              labelText: 'Facilities*',
                              hintText: 'e.g., Parking, Washroom, Cafe (Comma-separated)',
                              prefixIcon: Icon(Icons.local_offer_outlined)),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'At least one facility is required';
                            }
                            return null;
                          }),
                      const SizedBox(height: 20),
                      _buildSectionHeader("Status & Settings"),
                      SwitchListTile(
                          title: const Text('Booking Enabled?'),
                          subtitle: const Text(
                              'Can users make bookings for this venue?'),
                          value: _bookingEnabled,
                          onChanged: anyOperationInProgress
                              ? null
                              : (v) => setState(() => _bookingEnabled = v),
                          secondary: Icon(
                              _bookingEnabled
                                  ? Icons.event_available
                                  : Icons.event_busy,
                              color: _bookingEnabled
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey),
                          contentPadding: EdgeInsets.zero,
                          dense: true),
                      const SizedBox(height: 10),
                      SwitchListTile(
                          title: const Text('Venue is Active?'),
                          subtitle: const Text(
                              'Inactive venues won\'t appear in searches.'),
                          value: _isActive,
                          onChanged: anyOperationInProgress
                              ? null
                              : (v) => setState(() => _isActive = v),
                          secondary: Icon(
                              _isActive
                                  ? Icons.check_circle
                                  : Icons.cancel_outlined,
                              color: _isActive ? Colors.green : Colors.grey),
                          contentPadding: EdgeInsets.zero,
                          dense: true),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            child: ElevatedButton.icon(
                                icon: (anyOperationInProgress &&
                                        (_isLoading || _isUploadingImage))
                                    ? _buildButtonSpinner(
                                        size: 20, color: Colors.white)
                                    : Icon(submitBtnIcon),
                                label: Text((anyOperationInProgress &&
                                        (_isLoading || _isUploadingImage))
                                    ? 'Saving...'
                                    : submitBtnTxt),
                                onPressed:
                                    anyOperationInProgress ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    Widget imagePreview;
    const double previewSize = 150.0;

    if (_isUploadingImage && _selectedImageFile == null) {
      imagePreview = const Center(child: CircularProgressIndicator());
    } else if (_selectedImageFile != null) {
      imagePreview = kIsWeb
          ? Image.network(_selectedImageFile!.path,
              width: previewSize, height: previewSize, fit: BoxFit.cover)
          : Image.file(File(_selectedImageFile!.path),
              width: previewSize, height: previewSize, fit: BoxFit.cover);
    } else if (_imageUrlController.text.isNotEmpty) {
      imagePreview = Image.network(
        _imageUrlController.text,
        width: previewSize,
        height: previewSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 40, color: Colors.grey)),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
              child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null));
        },
      );
    } else {
      imagePreview = Center(
          child: Icon(Icons.add_a_photo_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Container(
                  height: previewSize,
                  width: previewSize,
                  margin: const EdgeInsets.only(bottom: 10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    border: Border.all(
                      color: _imageErrorText != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                      width: _imageErrorText != null ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imagePreview,
                        if (_isUploadingImage)
                          Container(
                            color: Colors.black.withOpacity(0.4),
                            child: const Center(
                                child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )),
                          ),
                        if (!_isUploadingImage &&
                            (_imageUrlController.text.isNotEmpty ||
                                _selectedImageFile != null))
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _isUploadingImage ? null : _clearImage,
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child:
                                      Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isUploadingImage)
                OutlinedButton.icon(
                  icon: Icon(
                      _imageUrlController.text.isNotEmpty ||
                              _selectedImageFile != null
                          ? Icons.edit_outlined
                          : Icons.add_photo_alternate_outlined,
                      size: 18),
                  label: Text(_imageUrlController.text.isNotEmpty ||
                          _selectedImageFile != null
                      ? 'Change Image'
                      : 'Select Image*'),
                  onPressed: _pickAndUploadImage,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10)),
                ),
            ],
          ),
        ),
        if (_isUploadingImage)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text("Uploading, please wait...",
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontStyle: FontStyle.italic)),
            ),
          ),
        if (_imageErrorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                _imageErrorText!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Visibility(
          visible: false,
          maintainState: true,
          child: TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
        ),
      ],
    );
  }

  Widget _buildSportsInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _sportInputController,
          focusNode: _sportInputFocusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g., Cricket, Football (Type & press Enter)*',
            prefixIcon: const Icon(Icons.fitness_center),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                  color: _sportsErrorText != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: _sportsErrorText != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor,
                  width: 1.5),
              borderRadius: BorderRadius.circular(4.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: _sportsErrorText != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline.withOpacity(0.8)),
              borderRadius: BorderRadius.circular(4.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error, width: 1.5),
              borderRadius: BorderRadius.circular(4.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error, width: 1.5),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          onFieldSubmitted: (_) => _addSportFromInput(),
        ),
        if (_selectedSports.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _selectedSports.map((sport) {
                  return InputChip(
                    label: Text(sport),
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.7),
                    deleteIconColor: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer
                        .withOpacity(0.7),
                    onDeleted: () => _removeSport(sport),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(6),
                  );
                }).toList(),
              ),
            ),
          ),
        if (_sportsErrorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              _sportsErrorText!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildButtonSpinner({double size = 16, Color? color}) {
    final resolvedColor = color ?? Theme.of(context).primaryColor;
    return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(resolvedColor)));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOperatingHoursRow(String dayLabel,
      TextEditingController startController, TextEditingController endController) {
    const double dayLabelColumnWidth = 90.0;
    const double gapBetweenLabelAndTimes = 8.0;
    const double preferredTimeFieldWidth = 105.0;
    const double horizontalPaddingForToText = 5.0;
    String? timeValidator(String? value) {
      if (value == null || value.trim().isEmpty) return 'Required';
      if (!RegExp(r"^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$")
          .hasMatch(value.trim())) return 'HH:MM';
      return null;
    }

    Widget buildCoreTimeInput(TextEditingController controller, String labelText) {
      return InkWell(
          onTap: () => _selectTime(context, controller),
          child: AbsorbPointer(
              child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      labelText: labelText,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 8.0),
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.access_time, size: 18)),
                  validator: timeValidator)));
    }

    Widget dayLabelWidget = SizedBox(
        width: dayLabelColumnWidth,
        child: Text(dayLabel,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            textAlign: TextAlign.start));
    if (kIsWeb) {
      Widget buildWebTimeInput(TextEditingController controller, String labelText) {
        return SizedBox(
            width: preferredTimeFieldWidth,
            child: buildCoreTimeInput(controller, labelText));
      }

      final TextPainter textPainter = TextPainter(
          text: const TextSpan(text: "to", style: TextStyle(fontSize: 14)),
          maxLines: 1,
          textDirection: TextDirection.ltr)
        ..layout(minWidth: 0, maxWidth: double.infinity);
      final double widthOfToTextWithPadding =
          textPainter.width + (2 * horizontalPaddingForToText);
      final double requiredWidthForTimeControlsGroupWeb =
          (2 * preferredTimeFieldWidth) + widthOfToTextWithPadding;
      return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        final double totalAvailableWidth = constraints.maxWidth;
        final double singleLineRequiredWidthWeb =
            dayLabelColumnWidth + gapBetweenLabelAndTimes + requiredWidthForTimeControlsGroupWeb;
        if (totalAvailableWidth >= singleLineRequiredWidthWeb) {
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            dayLabelWidget,
            const SizedBox(width: gapBetweenLabelAndTimes),
            Expanded(
                child: Row(children: [
              Flexible(child: buildWebTimeInput(startController, 'Start')),
              Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPaddingForToText),
                  child: Text("to", style: const TextStyle(fontSize: 14))),
              Flexible(child: buildWebTimeInput(endController, 'End')),
              const Spacer()
            ]))
          ]);
        } else {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dayLabelWidget,
                const SizedBox(height: 8.0),
                Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child:
                        Row(mainAxisSize: MainAxisSize.min, children: [
                      buildWebTimeInput(startController, 'Start'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: horizontalPaddingForToText),
                          child: Text("to", style: const TextStyle(fontSize: 14))),
                      buildWebTimeInput(endController, 'End')
                    ]))
              ]);
        }
      });
    } else {
      return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        dayLabelWidget,
        const SizedBox(width: gapBetweenLabelAndTimes),
        Expanded(child: buildCoreTimeInput(startController, 'Start')),
        Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: horizontalPaddingForToText),
            child: Text("to", style: const TextStyle(fontSize: 14))),
        Expanded(child: buildCoreTimeInput(endController, 'End'))
      ]);
    }
  }
}