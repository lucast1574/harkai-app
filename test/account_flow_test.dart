import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/account/profile_screen.dart';
import 'package:harkai/features/auth/login_screen.dart';

const user = {
  'id': 'user',
  'name': 'Lucas Santillan',
  'email': 'lucas@example.com',
  'role': 'neighbor',
  'preferences': {
    'notifications': 'all',
    'radius_meters': 500,
    'language': 'es',
    'theme': 'dark',
  },
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'relaunch restores cached identity even when metadata and network fail',
    () async {
      final saved = ApiClient();
      await saved.save({
        'access_token': 'old',
        'refresh_token': 'initial',
        'user': user,
      });
      final api = ApiClient(
        transport: MockClient(
          (_) async => throw http.ClientException('offline'),
        ),
      );
      final app = AppController(api);
      await app.restoreSession();
      expect(app.account?.id, 'user');
      expect(await app.initialize(), false);
      expect(app.account?.id, 'user');
      expect(api.hasSession, true);
    },
  );
  test('successful account lookup persists the latest profile', () async {
    final api = ApiClient(
      transport: MockClient(
        (request) async => http.Response(jsonEncode(user), 200),
      ),
    );
    await api.save({'access_token': 'token', 'refresh_token': 'refresh'});
    await AppController(api).reloadAccount();
    final reopened = ApiClient();
    await reopened.restore();
    expect(reopened.savedAccount?['name'], 'Lucas Santillan');
  });
  testWidgets('login replaces form with loading and recovers after an error', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final app = AppController(
      ApiClient(transport: MockClient((_) => pending.future)),
    );
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: appTheme(Brightness.dark),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'lucas@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Entrando a tu comunidad'), findsOneWidget);
    pending.complete(http.Response('{"error":{"code":"unauthorized"}}', 401));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'profile keeps personal details collapsed and compact settings visible',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = AppController(ApiClient())..account = Account.fromJson(user);
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: appTheme(Brightness.dark),
            home: RepaintBoundary(
              child: Scaffold(
                appBar: AppBar(title: const Text('Mi cuenta')),
                body: const ProfileScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Radio personalizado (100 a 10000 m)'), findsNothing);
      await tester.tap(find.text('Datos personales'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
