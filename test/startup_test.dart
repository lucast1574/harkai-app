import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/features/map/community_map.dart';
import 'package:harkai/features/navigation/app_shell.dart';
import 'package:harkai/features/splash/launch_experience.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'expired session cannot prevent loading public startup metadata',
    () async {
      var publicRequests = 0;
      final api = ApiClient(
        transport: MockClient((request) async {
          if (request.url.path.endsWith('/meta')) {
            expect(request.headers['Authorization'], isNull);
            publicRequests++;
            return http.Response('{"categories":[],"capabilities":{}}', 200);
          }
          return http.Response('{"error":{"code":"unauthorized"}}', 401);
        }),
      );
      await api.save({'access_token': 'expired', 'refresh_token': 'expired'});
      final controller = AppController(api);
      expect(await controller.initialize(), true);
      expect(publicRequests, 1);
      expect(controller.error, isNull);
      expect(controller.account, isNull);
      expect(api.hasSession, false);
    },
  );

  testWidgets('map remains the base while startup loads or fails', (
    tester,
  ) async {
    final api = ApiClient(
      transport: MockClient(
        (request) async => http.Response(
          jsonEncode({'items': [], 'categories': [], 'capabilities': {}}),
          200,
        ),
      ),
    );
    final controller = AppController(api)..error = 'Sin conexión';
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const MaterialApp(home: AppShell()),
      ),
    );
    expect(find.byType(CommunityMap), findsOneWidget);
    expect(find.text('Conectemos tu comunidad'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'splash dismisses independently of startup and respects reduced motion',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: LaunchExperience(child: Scaffold(body: Text('Mapa'))),
          ),
        ),
      );
      expect(find.text('harkai'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text('harkai'), findsNothing);
      expect(find.text('Mapa'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
