import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  /// Fetches the current location of the user.
  /// Throws an exception if permissions are denied or service is disabled.
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  /// Reverse geocoding using Nominatim (OpenStreetMap)
  /// Returns a human-readable address string or null.
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1');

      final response = await http.get(url, headers: {
        'User-Agent': 'BarterApp/1.0', // Required by Nominatim policy
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address == null) return null;

        // Build a detailed address using available components
        List<String> parts = [];
        // Street name (road) and house number if available
        if (address['road'] != null) {
          String street = address['road'];
          if (address['house_number'] != null) {
            street = '${address['house_number']} $street';
          }
          parts.add(street);
        }
        // Neighborhood / district
        if (address['neighbourhood'] != null) {
          parts.add(address['neighbourhood']);
        } else if (address['suburb'] != null) {
          parts.add(address['suburb']);
        }
        // City / town / village
        if (address['city'] != null) {
          parts.add(address['city']);
        } else if (address['town'] != null) {
          parts.add(address['town']);
        } else if (address['village'] != null) {
          parts.add(address['village']);
        }
        // State / region
        if (address['state'] != null) {
          parts.add(address['state']);
        }
        // Country
        if (address['country'] != null) {
          parts.add(address['country']);
        }
        // Join parts with commas for a readable address
        return parts.join(', ');
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    return null;
  }

  /// Search for locations by text query using Nominatim
  static Future<List<Map<String, dynamic>>> searchLocations(
      String query) async {
    if (query.trim().length < 3) return [];
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');

      final response = await http.get(url, headers: {
        'User-Agent': 'BarterApp/1.0',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error searching locations: $e');
    }
    return [];
  }

  /// Calculates the distance between two points in kilometers.
  static double calculateDistance(
      double startLat, double startLong, double endLat, double endLong) {
    return Geolocator.distanceBetween(startLat, startLong, endLat, endLong) /
        1000;
  }
}
