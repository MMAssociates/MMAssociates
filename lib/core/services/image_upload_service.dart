// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart' show debugPrint;
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'dart:convert'; // For jsonDecode

// class ImageUploadService {
//   final String _cloudName = 'dvcyhagv0'; // Get this from your Cloudinary Dashboard
//   final String _uploadPreset = 'mm_associates_profile_pics'; // The unsigned preset you created

//   static final ImageUploadService _instance = ImageUploadService._internal();
//   factory ImageUploadService() => _instance;
//   ImageUploadService._internal();

//   Future<String?> uploadImageToCloudinary(XFile imageXFile, {String? folder}) async {
//     final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
//     var request = http.MultipartRequest('POST', uri);

//     request.fields['upload_preset'] = _uploadPreset;
//     if (folder != null && folder.isNotEmpty) {
//       request.fields['folder'] = folder; // e.g., 'profile_pictures'
//     }
//     // You can add tags if needed:
//     // request.fields['tags'] = 'profile,user_generated';

//     try {
//       debugPrint("ImageUploadService: Reading bytes from XFile: ${imageXFile.name}");
//       final Uint8List imageBytes = await imageXFile.readAsBytes();
//       debugPrint("ImageUploadService: Image bytes read: ${imageBytes.length}");

//       request.files.add(http.MultipartFile.fromBytes(
//         'file', // This 'file' field name is standard for Cloudinary API
//         imageBytes,
//         filename: imageXFile.name,
//         // contentType: MediaType.parse(imageXFile.mimeType ?? 'image/jpeg'), // Optional
//       ));

//       debugPrint("ImageUploadService: Uploading to Cloudinary...");
//       var response = await request.send().timeout(const Duration(seconds: 60)); // Added timeout
//       var responseBody = await response.stream.bytesToString();

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         var decoded = jsonDecode(responseBody);
//         String? secureUrl = decoded['secure_url'] as String?;
//         if (secureUrl != null) {
//           debugPrint("ImageUploadService: Cloudinary Upload Success. URL: $secureUrl");
//           return secureUrl;
//         } else {
//           debugPrint("ImageUploadService: Cloudinary response missing 'secure_url'. Response: $decoded");
//           throw Exception('Cloudinary response missing secure_url.');
//         }
//       } else {
//         debugPrint("ImageUploadService: Cloudinary Upload Error - Status: ${response.statusCode}, Body: $responseBody");
//         throw Exception('Failed to upload image: ${response.reasonPhrase} (Status ${response.statusCode})');
//       }
//     } on TimeoutException catch (e) {
//         debugPrint("ImageUploadService: Upload to Cloudinary timed out: $e");
//         throw Exception("Image upload timed out. Please check your connection.");
//     } catch (e) {
//       debugPrint("ImageUploadService: Error during Cloudinary upload process: $e");
//       // Rethrow a generic error or the specific one
//       throw Exception("Image upload failed. Please try again. ($e)");
//     }
//   }
// }

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // For jsonDecode
// import 'package:http_parser/http_parser.dart'; // Only needed if contentType is uncommented and used

class ImageUploadService {
  final String _cloudName = 'dvcyhagv0'; // Get this from your Cloudinary Dashboard
  // --- REMOVED: Hardcoded upload preset ---
  // final String _uploadPreset = 'mm_associates_profile_pics';

  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  Future<String?> uploadImageToCloudinary(
    XFile imageXFile, {
    // --- MODIFIED: Make uploadPreset a required named parameter ---
    required String uploadPreset,
    String? folder,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);

    // --- MODIFIED: Use the passed uploadPreset ---
    request.fields['upload_preset'] = uploadPreset;

    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder; // e.g., 'profile_pictures', 'venue_images'
    }
    // You can add tags if needed:
    // request.fields['tags'] = 'profile,user_generated';

    try {
      debugPrint("ImageUploadService: Reading bytes from XFile: ${imageXFile.name}");
      final Uint8List imageBytes = await imageXFile.readAsBytes();
      debugPrint("ImageUploadService: Image bytes read: ${imageBytes.length}");

      request.files.add(http.MultipartFile.fromBytes(
        'file', // This 'file' field name is standard for Cloudinary API
        imageBytes,
        filename: imageXFile.name,
        // contentType: MediaType.parse(imageXFile.mimeType ?? 'image/jpeg'), // Optional
      ));

      debugPrint("ImageUploadService: Uploading to Cloudinary with preset: $uploadPreset, folder: $folder...");
      var response = await request.send().timeout(const Duration(seconds: 60));
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var decoded = jsonDecode(responseBody);
        String? secureUrl = decoded['secure_url'] as String?;
        if (secureUrl != null) {
          debugPrint("ImageUploadService: Cloudinary Upload Success. URL: $secureUrl");
          return secureUrl;
        } else {
          debugPrint("ImageUploadService: Cloudinary response missing 'secure_url'. Response: $decoded");
          throw Exception('Cloudinary response missing secure_url.');
        }
      } else {
        debugPrint("ImageUploadService: Cloudinary Upload Error - Status: ${response.statusCode}, Body: $responseBody");
        throw Exception('Failed to upload image: ${response.reasonPhrase} (Status ${response.statusCode})');
      }
    } on TimeoutException catch (e) {
        debugPrint("ImageUploadService: Upload to Cloudinary timed out: $e");
        throw Exception("Image upload timed out. Please check your connection.");
    } catch (e) {
      debugPrint("ImageUploadService: Error during Cloudinary upload process: $e");
      throw Exception("Image upload failed. Please try again. ($e)");
    }
  }
}