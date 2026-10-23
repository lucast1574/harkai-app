import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/reports/map_report_sheet.dart';

void main() {
  testWidgets(
    'category sheet stops at its content and keeps Harki actionable',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var helpOpens = 0;
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
                    onEmergency: () {},
                    onHelp: () => helpOpens++,
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
      final initialHeight = tester.getSize(scroll).height;
      expect(initialHeight, lessThan(600));
      await tester.drag(scroll, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.getSize(scroll).height, closeTo(initialHeight, 1));
      final unusedSpace =
          tester.getBottomLeft(scroll).dy -
          tester.getBottomLeft(find.text('Ayuda')).dy;
      expect(unusedSpace, lessThan(85));
      await tester.tap(find.text('Harki'));
      expect(helpOpens, 1);
      await tester.drag(scroll, const Offset(0, 700));
      await tester.pumpAndSettle();
      expect(tester.getSize(scroll).height, lessThan(150));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
