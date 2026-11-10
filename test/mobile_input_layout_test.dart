import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/business/business_editor.dart';
import 'package:harkai/features/business/business_point.dart';
import 'package:harkai/features/community/district_chat_composer.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'small-screen inputs remain reachable with large text: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final text = TextEditingController();
        final focus = FocusNode();
        Widget app(Widget home) => MaterialApp(
          theme: appTheme(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: home,
        );
        await tester.pumpWidget(
          app(
            Scaffold(
              appBar: AppBar(title: const Text('Conversación')),
              body: Column(
                children: [
                  const Expanded(
                    child: SingleChildScrollView(
                      child: Text('Mensaje original'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DistrictChatComposer(
                      controller: text,
                      focusNode: focus,
                      sending: false,
                      onSend: () {},
                      onChanged: () {},
                      inThread: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextField),
          'Primera línea\nSegunda línea\nTercera línea\nCuarta línea',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Listo'));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.pumpWidget(
          app(
            BusinessEditor(
              point: const BusinessPoint({
                'id': '123456789012345678901234',
                'name': '',
                'description': '',
                'kind': 'restaurant',
                'latitude': -12.0,
                'longitude': -77.0,
                'payment_mode': 'one_time',
                'billing_status': 'active',
                'paid_at': '2026-11-01T00:00:00Z',
              }),
            ),
          ),
        );
        await tester.enterText(
          find.byKey(const ValueKey('business-name')),
          'Mi negocio',
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Listo'));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        text.dispose();
        focus.dispose();
      },
    );
  }
}
