import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/features/reports/report_repository.dart';

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
  test('crime uses the backend group and preserves its cursor', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final requested = <Uri>[];
    final repository = ReportRepository(
      ApiClient(
        transport: MockClient((request) async {
          requested.add(request.url);
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'new-subtype',
                  'type': 'public_drinking',
                  'description': 'Personas tomando en la calle',
                  'status': 'active',
                  'latitude': -12,
                  'longitude': -77,
                  'verified': false,
                  'created_at': '2026-10-22T12:00:00Z',
                },
              ],
              'next_cursor': 'server-cursor',
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
    expect(requested.single.queryParameters['type'], 'crime');
    expect(page.items.single.type, 'public_drinking');
    expect(page.cursor, 'server-cursor');
    await repository.list(
      latitude: -12,
      longitude: -77,
      type: 'crime',
      cursor: page.cursor,
    );
    expect(requested.last.queryParameters['cursor'], 'server-cursor');
  });
}
