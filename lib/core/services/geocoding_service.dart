import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';


class LocationIQService {

  Future<GeoPoint?> getCoordsFromAddress(String fullAddress) async {
    final String key = dotenv.env['LOCATIONIQ_API_KEY'] ?? '';
    final String apiKey = utf8.decode(base64.decode(key));

    if (apiKey.isEmpty) {
        debugPrint("ERROR: LOCATIONIQ_API_KEY not found in .env or not loaded.");
        throw Exception("API Key Not Configured");
    }

    if (fullAddress.isEmpty) {
       throw Exception("Address cannot be empty");
    }

    final Uri apiUrl = Uri.parse(
      'https://us1.locationiq.com/v1/search.php?key=$apiKey&q=$fullAddress&format=json'
    );

    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 15));

      debugPrint("LocationIQ Response [${apiUrl.path}?q=...]: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        if (responseBody.isNotEmpty) {
          final Map<String, dynamic> firstResult = responseBody[0];
          final String? latString = firstResult['lat'];
          final String? lonString = firstResult['lon'];

          if (latString != null && lonString != null) {
            final double? lat = double.tryParse(latString);
            final double? lon = double.tryParse(lonString);
            if (lat != null && lon != null) {
              return GeoPoint(lat, lon);
            } else {
               debugPrint("LocationIQ couldn't parse lat/lon strings: '$latString', '$lonString'");
               throw Exception("Invalid Coordinate Format");
            }
          } else {
            debugPrint("LocationIQ response missing lat/lon keys.");
            throw Exception("Invalid Response Format");
          }
        } else {
          debugPrint("LocationIQ returned empty results array.");
          throw Exception("Address Not Found");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint("LocationIQ API Key invalid or unauthorized.");
          throw Exception("Invalid API Key");
      } else if (response.statusCode == 404 || response.statusCode == 400) {
         debugPrint("LocationIQ returned 400/404.");
         throw Exception("Address Not Found/Invalid");
      }
       else {
         debugPrint("LocationIQ returned error status: ${response.statusCode}");
         throw Exception("Service Error (${response.statusCode})");
      }

    } on TimeoutException catch (_) {
      debugPrint("LocationIQ request timed out for '$fullAddress'");
      throw Exception("Request Timeout");
    } catch (e) {
      debugPrint("Error during LocationIQ service call for '$fullAddress': $e");
      if (e is Exception) {
         rethrow;
      } else {
         throw Exception("Geocoding Failed");
      }
    }
  }
}