import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/reports/map_report_sheet.dart';

void main() {
  testWidgets('sheet handles a short viewport and subsequent resize', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 160);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MapReportSheet(
              onReport: (_) {},
              onEmergency: () {},
              children: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(400, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿Qué está pasando?'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CustomScrollView)).height,
      greaterThan(300),
    );
  });

  testWidgets('category sheet keeps a full width emergency action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var emergencyOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.blue)),
              Align(
                alignment: Alignment.bottomCenter,
                child: MapReportSheet(
                  onReport: (_) {},
                  onEmergency: () => emergencyOpens++,
                  children: const [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = find.byType(CustomScrollView);
    expect(tester.getSize(scroll).height, lessThan(150));
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.drag(find.text('¿Qué está pasando?'), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.getSize(scroll).height, greaterThan(300));
      await tester.drag(find.text('¿Qué está pasando?'), const Offset(0, 650));
      await tester.pumpAndSettle();
      expect(tester.getSize(scroll).height, lessThan(150));
    }
    await tester.drag(scroll, const Offset(0, -700));
    await tester.pumpAndSettle();
    final initialHeight = tester.getSize(scroll).height;
    expect(initialHeight, greaterThan(300));
    expect(initialHeight, lessThan(600));
    await tester.drag(scroll, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.getSize(scroll).height, closeTo(initialHeight, 1));
    final unusedSpace =
        tester.getBottomLeft(scroll).dy -
        tester.getBottomLeft(find.text('Llamadas de emergencia')).dy;
    expect(unusedSpace, lessThan(85));
    expect(find.text('Harki'), findsNothing);
    expect(tester.getSize(find.byType(FilledButton)).width, greaterThan(330));
    await tester.tap(find.text('Llamadas de emergencia'));
    expect(emergencyOpens, 1);
    await tester.drag(scroll, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(tester.getSize(scroll).height, lessThan(150));
    // The content fits at maximum: dragging down must still be accepted.
    await tester.tap(find.text('¿Qué está pasando?'));
    await tester.pumpAndSettle();
    expect(tester.getSize(scroll).height, greaterThan(300));
    await tester.drag(find.text('¿Qué está pasando?'), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(tester.getSize(scroll).height, lessThan(150));
    await tester.pumpWidget(const SizedBox());
  });
}
