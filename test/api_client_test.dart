import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'concurrent expired requests rotate once and retry with new token',
    () async {
      var rotations = 0;
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          rotations++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return http.Response(
            jsonEncode({'access_token': 'new', 'refresh_token': 'next'}),
            200,
          );
        }
        if (request.headers['Authorization'] != 'Bearer new') {
          return http.Response('{"error":{"code":"unauthorized"}}', 401);
        }
        return http.Response('{"id":"account"}', 200);
      });
      final api = ApiClient(transport: transport);
      await api.save({'access_token': 'expired', 'refresh_token': 'initial'});
      final results = await Future.wait([
        api.request('GET', 'me'),
        api.request('GET', 'me'),
      ]);
      expect(rotations, 1);
      expect(results.every((r) => r['id'] == 'account'), true);
      expect(await ApiClient().restore(), true);
      transport.close();
    },
  );
  test(
    'clearing a session prevents an in-flight refresh restoring it',
    () async {
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return http.Response(
            '{"access_token":"new","refresh_token":"next"}',
            200,
          );
        }
        return http.Response('{"error":{"code":"unauthorized"}}', 401);
      });
      final api = ApiClient(transport: transport);
      await api.save({'access_token': 'expired', 'refresh_token': 'initial'});
      final response = api.request('GET', 'me');
      final expectation = expectLater(response, throwsException);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await api.clear();
      await expectation;
      expect(api.hasSession, false);
      expect(await ApiClient().restore(), false);
      transport.close();
    },
  );
}
