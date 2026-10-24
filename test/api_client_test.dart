import 'dart:async';
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
    'interrupted refresh resumes the persisted rotation after app restart',
    () async {
      String? rotationID;
      var loseResponse = true;
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final persisted =
              jsonDecode(
                    (await const FlutterSecureStorage().read(
                      key: ApiClient.sessionKey,
                    ))!,
                  )
                  as Map<String, dynamic>;
          expect(persisted['pending_rotation_id'], body['rotation_id']);
          rotationID ??= body['rotation_id'] as String;
          expect(body['rotation_id'], rotationID);
          if (loseResponse) {
            loseResponse = false;
            throw http.ClientException('response lost after commit');
          }
          return http.Response(
            '{"access_token":"new","refresh_token":"next"}',
            200,
          );
        }
        if (request.headers['Authorization'] != 'Bearer new') {
          return http.Response('{"error":{"code":"unauthorized"}}', 401);
        }
        return http.Response('{"id":"account"}', 200);
      });
      final first = ApiClient(transport: transport);
      await first.save({'access_token': 'old', 'refresh_token': 'initial'});
      await expectLater(first.request('GET', 'me'), throwsException);
      final reopened = ApiClient(transport: transport);
      await reopened.restore();
      expect((await reopened.request('GET', 'me'))['id'], 'account');
      final stored = jsonDecode(
        (await const FlutterSecureStorage().read(key: ApiClient.sessionKey))!,
      );
      expect(stored['refresh_token'], 'next');
      expect(stored['pending_rotation_id'], isNull);
      transport.close();
    },
  );

  test('late unauthorized response reuses the already rotated token', () async {
    final late = Completer<void>();
    var oldRequests = 0, rotations = 0;
    final api = ApiClient(
      transport: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          rotations++;
          return http.Response(
            '{"access_token":"new","refresh_token":"next"}',
            200,
          );
        }
        if (request.headers['Authorization'] == 'Bearer old') {
          oldRequests++;
          if (oldRequests == 2) await late.future;
          return http.Response('{"error":{"code":"unauthorized"}}', 401);
        }
        return http.Response('{"id":"account"}', 200);
      }),
    );
    await api.save({'access_token': 'old', 'refresh_token': 'initial'});
    final first = api.request('GET', 'me');
    final second = api.request('GET', 'me');
    await first;
    late.complete();
    await second;
    expect(rotations, 1);
    expect(api.hasSession, true);
  });

  test(
    'refresh connection failure preserves session for next launch',
    () async {
      final api = ApiClient(
        transport: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            throw http.ClientException('offline');
          }
          return http.Response('{"error":{"code":"unauthorized"}}', 401);
        }),
      );
      await api.save({'access_token': 'old', 'refresh_token': 'initial'});
      await expectLater(api.request('GET', 'me'), throwsException);
      expect(api.hasSession, true);
      expect(await ApiClient().restore(), true);
    },
  );

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
