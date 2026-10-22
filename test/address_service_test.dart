import 'dart:convert';

import 'package:efs_work_tracker/core/services/address_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' show Placemark;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // Tests have no phone geocoder, so getAddress always reaches the
  // OpenStreetMap fallback, served here by a fake HTTP client.
  test('OpenStreetMap fallback, in the requested language', () async {
    late Uri sentUrl;
    final service = AddressService(
      httpClient: MockClient((request) async {
        sentUrl = request.url;
        final body = {
          'address': {
            'road': 'شارع التسعين',
            'suburb': 'التجمع الخامس',
            'city': 'القاهرة',
          },
        };
        return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
      }),
    );

    final address = await service.getAddress(30, 31, languageCode: 'ar');

    expect(address, 'شارع التسعين, التجمع الخامس, القاهرة');
    expect(sentUrl.queryParameters['accept-language'], 'ar');
  });

  test('server error -> no address, no crash', () async {
    final service = AddressService(
      httpClient: MockClient((_) async => http.Response('busy', 429)),
    );

    expect(await service.getAddress(30, 31), isNull);
  });

  test('no network -> no address, no crash', () async {
    final service = AddressService(
      httpClient: MockClient((_) async => throw http.ClientException('off')),
    );

    expect(await service.getAddress(30, 31), isNull);
  });

  test('phone geocoder result uses the street name, not the full line', () {
    const place = Placemark(
      street: '12 90th St, New Cairo 1, Cairo, Egypt',
      thoroughfare: '90th Street',
      subLocality: 'New Cairo 1',
      locality: 'Cairo',
    );

    expect(
      AddressService.formatPlacemark(place),
      '90th Street, New Cairo 1, Cairo',
    );
  });

  test('joinParts skips empty and repeated parts', () {
    expect(AddressService.joinParts([' ', 'Giza', null, 'Giza']), 'Giza');
    expect(AddressService.joinParts([null, '']), isNull);
  });
}
