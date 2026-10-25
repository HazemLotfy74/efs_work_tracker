import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' show Geocoding, Placemark;
import 'package:http/http.dart' as http;

class AddressService {
  /// [httpClient] is only passed in tests.
  const AddressService({this._httpClient});

  final http.Client? _httpClient;

  static const _timeout = Duration(seconds: 10);

  /// Asks the phone's geocoder first, then OpenStreetMap (emulators and
  /// phones without Google Play have no working phone geocoder).
  Future<String?> getAddress(
    double latitude,
    double longitude, {
    String languageCode = 'en',
  }) async {
    return await _fromDevice(latitude, longitude, languageCode) ??
        await _fromOpenStreetMap(latitude, longitude, languageCode);
  }

  Future<String?> _fromDevice(double lat, double lng, String language) async {
    try {
      final geocoding = Geocoding(locale: Locale(language));
      if (!await geocoding.isPresent()) return null;

      final places = await geocoding
          .placemarkFromCoordinates(lat, lng)
          .timeout(_timeout);
      return places.isEmpty ? null : formatPlacemark(places.first);
    } catch (error) {
      debugPrint('Address: device geocoder failed: $error');
      return null;
    }
  }

  /// OpenStreetMap Nominatim: free, max 1 request per second, needs a
  /// User-Agent. Fine for one lookup per check-in; use a paid provider for
  /// heavy production traffic.
  Future<String?> _fromOpenStreetMap(
    double lat,
    double lng,
    String language,
  ) async {
    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'accept-language': language,
      });
      final get = _httpClient?.get ?? http.get;
      final response = await get(
        url,
        headers: {'User-Agent': 'efs_work_tracker/1.0'},
      ).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return formatOpenStreetMap(Map<String, dynamic>.from(json['address']));
    } catch (error) {
      debugPrint('Address: OpenStreetMap failed: $error');
      return null;
    }
  }

  /// On Android `placemark.street` is the whole address line, so the street
  /// name comes from `thoroughfare`.
  static String? formatPlacemark(Placemark place) {
    return joinParts([
      place.thoroughfare,
      place.subLocality,
      place.locality ?? place.administrativeArea,
    ]);
  }

  static String? formatOpenStreetMap(Map<String, dynamic> address) {
    return joinParts([
      address['road'] ?? address['pedestrian'],
      address['suburb'] ?? address['neighbourhood'],
      address['city'] ??
          address['town'] ??
          address['village'] ??
          address['state'],
    ]);
  }

  /// "a, b, c" without empty or repeated parts.
  static String? joinParts(List<Object?> parts) {
    final clean = parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet();
    return clean.isEmpty ? null : clean.join(', ');
  }
}
