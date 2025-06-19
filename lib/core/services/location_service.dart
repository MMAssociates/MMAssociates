import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting current location: $e");
      return null;
    }
  }

  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
     return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000; // in KM
  }
}