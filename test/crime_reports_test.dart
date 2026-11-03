import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/features/reports/report_repository.dart';
import 'package:harkai/features/reports/report_categories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'community cutoff includes exactly 72 hours and preserves history',
    () async {
      final cutoff = DateTime.utc(2026, 11, 1, 12);
      final repository = ReportRepository(
        ApiClient(
          transport: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'items': [
                  for (final hours in [-1, 0, 1])
                    {
                      'id': '$hours',
                      'type': 'fire',
                      'description': 'Reporte',
                      'status': 'active',
                      'latitude': -12,
                      'longitude': -77,
                      'verified': false,
                      'created_at': cutoff
                          .add(Duration(hours: hours))
                          .toIso8601String(),
                    },
                ],
                'next_cursor': 'next',
              }),
              200,
            ),
          ),
        ),
      );
      final recent = await repository.list(
        latitude: -12,
        longitude: -77,
        archive: true,
        createdAfter: cutoff,
      );
      expect(recent.items.map((item) => item.id), ['0', '1']);
      expect(recent.cursor, 'next');
      final history = await repository.list(
        latitude: -12,
        longitude: -77,
        history: true,
      );
      expect(history.items, hasLength(3));
    },
  );
  test(
    'crime includes all subtypes and only paginates unfinished categories',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final requested = <String>[];
      final repository = ReportRepository(
        ApiClient(
          transport: MockClient((request) async {
            final type = request.url.queryParameters['type']!;
            requested.add(type);
            final more = request.url.queryParameters['cursor'] != null;
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'id': '$type${more ? 2 : 1}',
                    'type': type,
                    'description': 'Reporte',
                    'status': 'active',
                    'latitude': -12,
                    'longitude': -77,
                    'verified': false,
                    'created_at': more
                        ? '2026-10-21T12:00:00Z'
                        : '2026-10-22T12:00:00Z',
                  },
                ],
                'next_cursor': type == 'theft' && !more ? 'next-theft' : null,
              }),
              200,
            );
          }),
        ),
      );
      final page = await repository.list(
        latitude: -12,
        longitude: -77,
        type: 'crime',
      );
      expect(requested.toSet(), crimeTypes.toSet());
      expect(page.items.map((item) => item.type).toSet(), crimeTypes.toSet());
      expect(page.cursor, isNotNull);
      requested.clear();
      final next = await repository.list(
        latitude: -12,
        longitude: -77,
        type: 'crime',
        cursor: page.cursor,
      );
      expect(requested, ['theft']);
      expect(next.items.single.id, 'theft2');
      expect(next.cursor, isNull);
    },
  );
}
