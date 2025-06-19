import 'dart:async';
import 'dart:convert'; 
import 'dart:typed_data'; 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mm_associates/features/user/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String? currentPhone;
  final String? currentProfilePicUrl; // Expects a Cloudinary URL or null
  final String? currentBio;
  final DateTime? currentDateOfBirth;
  final String? currentGender;
  final String? currentAddressStreet;
  final String? currentAddressCity;
  final String? currentAddressState;
  final String? currentAddressZipCode;
  final String? currentAddressCountry;
  final String? currentSocialMediaLink;

  const EditProfileScreen({
    required this.currentName,
    required this.currentEmail,
    this.currentPhone,
    this.currentProfilePicUrl,
    this.currentBio,
    this.currentDateOfBirth,
    this.currentGender,
    this.currentAddressStreet,
    this.currentAddressCity,
    this.currentAddressState,
    this.currentAddressZipCode,
    this.currentAddressCountry,
    this.currentSocialMediaLink,
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  late TextEditingController _addressStreetController;
  late TextEditingController _addressCityController;
  late TextEditingController _addressStateController;
  late TextEditingController _addressZipController;
  late TextEditingController _addressCountryController;
  late TextEditingController _socialMediaController;

  XFile? _selectedXFile;
  Uint8List? _newlyPickedImageBytes; // For preview of newly picked image

  String? _localProfilePicUrl; // Holds current Cloudinary URL (or old data URI)
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  String? _errorMessage;

  String _initialPhoneNumber = '';
  String _initialBio = '';
  String _initialAddressStreet = '';
  String _initialAddressCity = '';
  String _initialAddressState = '';
  String _initialAddressZip = '';
  String _initialAddressCountry = '';
  String _initialSocialMediaLink = '';
  DateTime? _initialDateOfBirth;
  String? _initialGender;
  String? _initialProfilePicUrl;

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _addressStreetFocusNode = FocusNode();
  final FocusNode _addressCityFocusNode = FocusNode();
  final FocusNode _addressStateFocusNode = FocusNode();
  final FocusNode _addressZipFocusNode = FocusNode();
  final FocusNode _addressCountryFocusNode = FocusNode();
  final FocusNode _socialMediaFocusNode = FocusNode();

  final List<String> _addressValidationTips = [
    'Street Address', 'City', 'State/Province', 'Zip/Postal Code', 'Country'
  ];
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const double _inputPaddingHorizontal = 0;
  static const EdgeInsets _fieldPadding = EdgeInsets.symmetric(vertical: 10.0);
  static const double _buttonBorderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _localProfilePicUrl = widget.currentProfilePicUrl;
    _initialProfilePicUrl = widget.currentProfilePicUrl;

    _phoneController = TextEditingController(text: widget.currentPhone ?? '');
    _initialPhoneNumber = widget.currentPhone ?? '';

    _bioController = TextEditingController(text: widget.currentBio ?? '');
    _initialBio = widget.currentBio ?? '';

    _selectedDate = widget.currentDateOfBirth;
    _initialDateOfBirth = widget.currentDateOfBirth;
    _dobController = TextEditingController(
        text: _selectedDate != null ? DateFormat('dd MMMM yyyy').format(_selectedDate!) : '');

    _selectedGender = (widget.currentGender != null && _genderOptions.contains(widget.currentGender!))
        ? widget.currentGender!
        : null;
    _initialGender = _selectedGender;

    _addressStreetController = TextEditingController(text: widget.currentAddressStreet ?? '');
    _initialAddressStreet = widget.currentAddressStreet ?? '';
    _addressCityController = TextEditingController(text: widget.currentAddressCity ?? '');
    _initialAddressCity = widget.currentAddressCity ?? '';
    _addressStateController = TextEditingController(text: widget.currentAddressState ?? '');
    _initialAddressState = widget.currentAddressState ?? '';
    _addressZipController = TextEditingController(text: widget.currentAddressZipCode ?? '');
    _initialAddressZip = widget.currentAddressZipCode ?? '';
    _addressCountryController = TextEditingController(text: widget.currentAddressCountry ?? '');
    _initialAddressCountry = widget.currentAddressCountry ?? '';
    _socialMediaController = TextEditingController(text: widget.currentSocialMediaLink ?? '');
    _initialSocialMediaLink = widget.currentSocialMediaLink ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _addressStreetController.dispose();
    _addressCityController.dispose();
    _addressStateController.dispose();
    _addressZipController.dispose();
    _addressCountryController.dispose();
    _socialMediaController.dispose();

    _phoneFocusNode.dispose();
    _bioFocusNode.dispose();
    _dobFocusNode.dispose();
    _genderFocusNode.dispose();
    _addressStreetFocusNode.dispose();
    _addressCityFocusNode.dispose();
    _addressStateFocusNode.dispose();
    _addressZipFocusNode.dispose();
    _addressCountryFocusNode.dispose();
    _socialMediaFocusNode.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    if (_isLoading) return false;
    if (_selectedXFile != null) return true;
    if (_localProfilePicUrl == null && _initialProfilePicUrl != null) return true; // Image removed
    // This case covers if a URL changed NOT due to _selectedXFile (e.g. pasting a URL directly, if that feature existed)
    // For now, XFile handles explicit new images.
    // if (_localProfilePicUrl != _initialProfilePicUrl && _selectedXFile == null) return true;


    if (_phoneController.text.trim() != _initialPhoneNumber.trim()) return true;
    if (_bioController.text.trim() != _initialBio.trim()) return true;
    if (_addressStreetController.text.trim() != _initialAddressStreet.trim()) return true;
    if (_addressCityController.text.trim() != _initialAddressCity.trim()) return true;
    if (_addressStateController.text.trim() != _initialAddressState.trim()) return true;
    if (_addressZipController.text.trim() != _initialAddressZip.trim()) return true;
    if (_addressCountryController.text.trim() != _initialAddressCountry.trim()) return true;
    if (_socialMediaController.text.trim() != _initialSocialMediaLink.trim()) return true;
    if (_selectedDate != _initialDateOfBirth) return true;
    if (_selectedGender != _initialGender) return true;
    return false;
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges()) {
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            actions: <Widget>[
              TextButton(
                child: Text('Discard', style: TextStyle(color: theme.colorScheme.error)),
                onPressed: () => Navigator.of(dialogContext).pop('discard'),
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop('cancel'),
              ),
              // MODIFIED: Changed ElevatedButton to TextButton for "Save Changes"
              TextButton(
                child: Text('Save Changes', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(dialogContext).pop('save');
                }
              ),
            ],
          );
        },
      );
      if (result == 'save') {
        await _saveChanges(); // This will handle popping if successful
        return false; // Don't pop immediately, let _saveChanges handle it
      } else if (result == 'discard') {
        return true; // Allow pop
      } else { // cancel or null
        return false; // Don't pop
      }
    }
    return true; // No unsaved changes, allow pop
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 1024, maxHeight: 1024,
      );
      if (pickedFile != null && mounted) {
        Uint8List imageBytes = await pickedFile.readAsBytes();
        if (imageBytes.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Picked image appears to be empty."), backgroundColor: Colors.orange),
          );
          return;
        }
        setState(() {
          _selectedXFile = pickedFile;
          _newlyPickedImageBytes = imageBytes;
          _localProfilePicUrl = null; // Clear any existing URL if new image is picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow future date for flexibility if needed
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd MMMM yyyy').format(_selectedDate!);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix the errors in the form."), backgroundColor: Colors.orange),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMessage = null; });

    Map<String, dynamic> dataToUpdate = {};
    String? finalCloudinaryUrlToStoreInFirestore = _localProfilePicUrl; // Start with current, possibly null

    // 1. Handle Profile Picture
    if (_selectedXFile != null) { // A new image was picked
      try {
        finalCloudinaryUrlToStoreInFirestore = await _userService.uploadProfilePicture(_selectedXFile!);
        dataToUpdate['profilePictureUrl'] = finalCloudinaryUrlToStoreInFirestore;
      } catch (uploadError) {
        if (mounted) {
          setState(() {
            _errorMessage = "Image upload failed: ${uploadError.toString().replaceFirst("Exception: ", "")}";
            _isLoading = false;
          });
        }
        return;
      }
    } else if (_localProfilePicUrl == null && _initialProfilePicUrl != null) {
      // Image was explicitly removed (local URL is null, but there was an initial URL)
      finalCloudinaryUrlToStoreInFirestore = null;
      dataToUpdate['profilePictureUrl'] = FieldValue.delete(); // Or null, depending on Firestore preference
    }
    // If _selectedXFile is null AND _localProfilePicUrl is NOT null, and _localProfilePicUrl is same as initial,
    // then no image change is intended from the user's direct action via picker/remove.
    // If _localProfilePicUrl IS NOT NULL and DIFFERENT from _initialProfilePicUrl BUT _selectedXFile is null,
    // this state shouldn't typically occur with current UI (localProfilePicUrl only becomes null via removal, or non-null via picker).
    // This logic prioritizes _selectedXFile.

    // 2. Handle Text Fields and Other Data
    _updateFieldIfNeeded(dataToUpdate, 'phoneNumber', _phoneController.text, _initialPhoneNumber);
    _updateFieldIfNeeded(dataToUpdate, 'bio', _bioController.text, _initialBio);
    _updateFieldIfNeeded(dataToUpdate, 'addressStreet', _addressStreetController.text, _initialAddressStreet);
    _updateFieldIfNeeded(dataToUpdate, 'addressCity', _addressCityController.text, _initialAddressCity);
    _updateFieldIfNeeded(dataToUpdate, 'addressState', _addressStateController.text, _initialAddressState);
    _updateFieldIfNeeded(dataToUpdate, 'addressZipCode', _addressZipController.text, _initialAddressZip);
    _updateFieldIfNeeded(dataToUpdate, 'addressCountry', _addressCountryController.text, _initialAddressCountry);
    _updateFieldIfNeeded(dataToUpdate, 'socialMediaLink', _socialMediaController.text, _initialSocialMediaLink);

    if (_selectedGender != _initialGender) {
      dataToUpdate['gender'] = _selectedGender; // Can be null if "Prefer not to say" or deselected
    }
    if (_selectedDate != _initialDateOfBirth) {
      dataToUpdate['dateOfBirth'] = _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null;
    }
    
    // Check if actual data to update, including specific handling for profilePictureUrl if it was just set by upload
    // but its value is the same as initial (though this is less likely if upload provides a new unique URL).
    // The main check is if dataToUpdate map has entries.
    bool actualUpdateOccurred = dataToUpdate.isNotEmpty;

    try {
      if (actualUpdateOccurred) {
        await _userService.updateUserProfileData(dataToUpdate);

        // Update initial values to current ones after successful save
        _initialPhoneNumber = _phoneController.text.trim();
        _initialBio = _bioController.text.trim();
        _initialAddressStreet = _addressStreetController.text.trim();
        _initialAddressCity = _addressCityController.text.trim();
        _initialAddressState = _addressStateController.text.trim();
        _initialAddressZip = _addressZipController.text.trim();
        _initialAddressCountry = _addressCountryController.text.trim();
        _initialSocialMediaLink = _socialMediaController.text.trim();
        _initialDateOfBirth = _selectedDate;
        _initialGender = _selectedGender;
        _initialProfilePicUrl = finalCloudinaryUrlToStoreInFirestore;


        if (mounted) {
          setState(() {
             // Update UI state based on what was saved
            _localProfilePicUrl = finalCloudinaryUrlToStoreInFirestore; // This should be the URL now in Firestore
            _selectedXFile = null; // Clear picked file
            _newlyPickedImageBytes = null; // Clear preview bytes
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
          );
          if (Navigator.canPop(context)) Navigator.pop(context, true); // Indicate success
        }
      } else {
         if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No changes detected to save.")));
          if (Navigator.canPop(context)) Navigator.pop(context, false); // Indicate no changes made
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _errorMessage = "Profile update failed: ${e.toString().replaceFirst("Exception: ", "")}";
           _isLoading = false;
        });
      }
    }
    // This finally block was redundant as _isLoading=false is handled in success/no-change/catch.
    // finally {
    //   if (mounted) setState(() => _isLoading = false);
    // }
  }

  void _updateFieldIfNeeded(Map<String, dynamic> data, String key, String newValue, String? oldValue) {
    final String trimmedNew = newValue.trim();
    final String currentOld = oldValue?.trim() ?? '';
    if (trimmedNew != currentOld) {
      data[key] = trimmedNew.isEmpty ? FieldValue.delete() : trimmedNew; // Use FieldValue.delete() to remove field or set to null
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: IgnorePointer(
        ignoring: _isLoading,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Edit Profile"),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0.5,
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))),
                ),
              // MODIFIED: Removed save icon from AppBar
              // IconButton(
              //   icon: Icon(Icons.save_outlined, color: theme.colorScheme.primary),
              //   tooltip: 'Save Changes',
              //   onPressed: (_isLoading || !_hasUnsavedChanges()) ? null : _saveChanges,
              // ),
            ],
          ),
          body: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildInfoTile(ThemeData theme, {required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: _inputPaddingHorizontal, vertical: 4.0),
    );
  }

  Widget _buildBody(ThemeData theme) {
    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfilePictureSection(theme),
          const SizedBox(height: 20.0),
          _buildInfoTile(theme, icon: Icons.badge_outlined, title: widget.currentName, subtitle: "Name"),
          _buildInfoTile(theme, icon: Icons.alternate_email_outlined, title: widget.currentEmail, subtitle: "Email"),
          const SizedBox(height: 24.0),
          _buildPhoneField(theme),
          const SizedBox(height: 16.0),
          _buildBioField(theme),
          const SizedBox(height: 16.0),
          _buildDateField(theme),
          const SizedBox(height: 16.0),
          _buildGenderField(theme),
          const SizedBox(height: 16.0),
          _buildAddressFields(theme),
          const SizedBox(height: 16.0),
          _buildSocialMediaField(theme),
          const SizedBox(height: 32.0),
          _buildSaveButton(theme),
          const SizedBox(height: 16.0),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
              ),
            ),
        ],
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 550,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1.0),
            boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12.0, offset: const Offset(0, 4)), ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: formContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme) {
    ImageProvider? displayImage;

    if (_newlyPickedImageBytes != null) { // Highest priority: a newly picked image
      displayImage = MemoryImage(_newlyPickedImageBytes!);
    } else if (_localProfilePicUrl != null && _localProfilePicUrl!.isNotEmpty) {
      if (_localProfilePicUrl!.startsWith('http')) { // Cloudinary URL
          displayImage = NetworkImage(_localProfilePicUrl!);
      } else if (_localProfilePicUrl!.startsWith('data:image')) { // Old base64 data URI (for backward compatibility)
         try {
            final parts = _localProfilePicUrl!.split(',');
            if (parts.length == 2) {
              displayImage = MemoryImage(base64Decode(parts[1]));
            }
          } catch (e) { debugPrint("Error decoding old base64 data for preview: $e");}
      }
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundImage: displayImage,
            onForegroundImageError: displayImage != null
              ? (exception, stackTrace) {
                  debugPrint('Error loading profile picture into CircleAvatar: $exception');
                }
              : null,
            child: (displayImage == null)
                ? Icon(Icons.person_outline, size: 60, color: theme.colorScheme.onSurfaceVariant)
                : null,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: () => _showImageSourceSheet(theme),
              child: CircleAvatar(radius: 20, backgroundColor: theme.colorScheme.primary,
                  child: Icon(Icons.camera_alt_outlined, size: 20, color: theme.colorScheme.onPrimary)),
            ),
          ),
          if (_newlyPickedImageBytes != null || (_localProfilePicUrl != null && _localProfilePicUrl!.isNotEmpty))
            Positioned(
              bottom: 0, left: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedXFile = null;
                    _newlyPickedImageBytes = null;
                    _localProfilePicUrl = null; // This flags for removal on save if _initialProfilePicUrl was not null
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile picture will be removed on save.")),
                    );
                  }
                },
                child: CircleAvatar(radius: 20, backgroundColor: Colors.red[400],
                    child: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.onPrimary)),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(children: <Widget>[
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: theme.colorScheme.primary),
            title: const Text('Photo Library'),
            onTap: () { Navigator.pop(bottomSheetContext); _pickImage(ImageSource.gallery); },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
            title: const Text('Camera'),
            onTap: () { Navigator.pop(bottomSheetContext); _pickImage(ImageSource.camera); },
          ),
        ]),
      ),
    );
  }

  Widget _buildPhoneField(ThemeData theme) {
    return _buildTextField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      labelText: 'Phone Number',
      hintText: 'Enter your phone number (e.g., +1234567890)',
      theme: theme,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_bioFocusNode),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final phoneRegExp = RegExp(r'^\+?[0-9\s-]{7,15}$');
        if (!phoneRegExp.hasMatch(value.trim())) return 'Please enter a valid phone number';
        return null;
      },
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
      onChanged: (_) => setState(() {}), // MODIFIED: Added for save button state update
    );
  }

  Widget _buildBioField(ThemeData theme) {
    return _buildTextField(
      controller: _bioController,
      focusNode: _bioFocusNode,
      labelText: 'Bio',
      hintText: 'Tell us about yourself...',
      theme: theme,
      minLines: 1, maxLines: 4,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline, // Use newline for multiline bio
      validator: (value) => null,
      onChanged: (_) => setState(() {}), // MODIFIED: Added for save button state update
    );
  }

  Widget _buildDateField(ThemeData theme) {
    return _buildTextField(
      controller: _dobController,
      focusNode: _dobFocusNode,
      labelText: 'Date of Birth',
      hintText: 'Select your date of birth',
      theme: theme,
      readOnly: true,
      onTap: _selectDate, // setState is handled within _selectDate
      suffixIcon: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
      validator: (value) => null,
    );
  }

  Widget _buildGenderField(ThemeData theme) {
    return Padding(
      padding: _fieldPadding,
      child: DropdownButtonFormField<String>(
        focusNode: _genderFocusNode,
        decoration: _inputDecoration(labelText: 'Gender', hintText: 'Select your gender', theme: theme),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select your gender', style: TextStyle(color: theme.hintColor))),
          ..._genderOptions.map((String gender) => DropdownMenuItem<String>(value: gender, child: Text(gender))),
        ],
        value: _selectedGender,
        onChanged: (String? newValue) {
          setState(() => _selectedGender = newValue); // This setState handles update for _hasUnsavedChanges
          FocusScope.of(context).requestFocus(_addressStreetFocusNode);
        },
        validator: (value) => null,
        style: theme.textTheme.bodyMedium,
        icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
        elevation: 2,
        dropdownColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildAddressFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0.0, left: _inputPaddingHorizontal),
          child: Text("Address", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        _buildTextField(
            controller: _addressStreetController, focusNode: _addressStreetFocusNode,
            labelText: _addressValidationTips[0], theme: theme, keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_addressCityFocusNode),
            validator: (v) => null, onChanged: (_) => setState(() {})), // MODIFIED
        _buildTextField(
            controller: _addressCityController, focusNode: _addressCityFocusNode,
            labelText: _addressValidationTips[1], theme: theme, keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_addressStateFocusNode),
            validator: (v) => null, onChanged: (_) => setState(() {})), // MODIFIED
        _buildTextField(
            controller: _addressStateController, focusNode: _addressStateFocusNode,
            labelText: _addressValidationTips[2], theme: theme, keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_addressZipFocusNode),
            validator: (v) => null, onChanged: (_) => setState(() {})), // MODIFIED
        _buildTextField(
            controller: _addressZipController, focusNode: _addressZipFocusNode,
            labelText: _addressValidationTips[3], theme: theme, keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_addressCountryFocusNode),
            validator: (v) => null, onChanged: (_) => setState(() {})), // MODIFIED
        _buildTextField(
            controller: _addressCountryController, focusNode: _addressCountryFocusNode,
            labelText: _addressValidationTips[4], theme: theme, keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_socialMediaFocusNode),
            validator: (v) => null, onChanged: (_) => setState(() {})), // MODIFIED
      ],
    );
  }

  Widget _buildSocialMediaField(ThemeData theme) {
    return _buildTextField(
      controller: _socialMediaController,
      focusNode: _socialMediaFocusNode,
      labelText: 'Social Media Link',
      hintText: 'e.g., https://linkedin.com/in/yourprofile',
      theme: theme,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveChanges(),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final Uri? uri = Uri.tryParse(value.trim());
          if (uri == null || !uri.isAbsolute || (uri.scheme != 'http' && uri.scheme != 'https')) {
            return 'Please enter a valid URL (e.g., http://...)';
          }
        }
        return null;
      },
      suffixIcon: Icon(Icons.link_outlined, color: theme.colorScheme.primary),
      onChanged: (_) => setState(() {}), // MODIFIED: Added for save button state update
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String labelText,
    String? hintText,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
    int? minLines,
    int? maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    ValueChanged<String>? onChanged, // Added onChanged parameter
  }) {
    return Padding(
      padding: _fieldPadding,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: _inputDecoration(labelText: labelText, hintText: hintText, theme: theme, suffixIcon: suffixIcon),
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: (keyboardType == TextInputType.multiline && (maxLines ?? 1) > 1 ) ? maxLines : 1,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: theme.textTheme.bodyMedium,
        cursorColor: theme.colorScheme.primary,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: onChanged, // MODIFIED: Used here
        textCapitalization: (keyboardType == TextInputType.name ||
                             keyboardType == TextInputType.streetAddress ||
                            (keyboardType == TextInputType.text &&
                             (labelText.toLowerCase().contains('city') ||
                              labelText.toLowerCase().contains('state') ||
                              labelText.toLowerCase().contains('country'))))
                            ? TextCapitalization.words
                            : (keyboardType == TextInputType.multiline)
                                ? TextCapitalization.sentences
                                : TextCapitalization.none,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    required ThemeData theme,
    Widget? suffixIcon,
  }) {
    final borderSide = BorderSide(color: theme.dividerColor.withOpacity(0.7), width: 1.0);
    final focusedBorderSide = BorderSide(color: theme.colorScheme.primary, width: 1.5);
    final errorBorderSide = BorderSide(color: theme.colorScheme.error, width: 1.0);
    final focusedErrorBorderSide = BorderSide(color: theme.colorScheme.error, width: 1.5);

    return InputDecoration(
      labelText: labelText,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor.withOpacity(0.9)),
      hintText: hintText,
      hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.7)),
      border: UnderlineInputBorder(borderSide: borderSide),
      enabledBorder: UnderlineInputBorder(borderSide: borderSide),
      focusedBorder: UnderlineInputBorder(borderSide: focusedBorderSide),
      errorBorder: UnderlineInputBorder(borderSide: errorBorderSide),
      focusedErrorBorder: UnderlineInputBorder(borderSide: focusedErrorBorderSide),
      contentPadding: const EdgeInsets.symmetric(horizontal: _inputPaddingHorizontal, vertical: 12.0),
      filled: false,
      suffixIcon: suffixIcon,
      isDense: true,
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    bool canSave = _hasUnsavedChanges();
    return ElevatedButton(
      onPressed: (_isLoading || !canSave) ? null : _saveChanges, // Updated condition
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonBorderRadius)),
        minimumSize: const Size.fromHeight(50),
        disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.4),
        disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.7),
      ),
      child: _isLoading
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.onPrimary))
          : Text('Save Changes', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
    );
  }
}