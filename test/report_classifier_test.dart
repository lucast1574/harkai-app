import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/features/reports/report_classifier.dart';
import 'package:harkai/features/reports/report_repository.dart';

http.Response result(String? type) => http.Response(
  jsonEncode({
    'suggested_type': ?type,
    'reason': 'Revisa el tipo',
    'advice': <String>[],
  }),
  200,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'automatic detection is global, cached and changes with the description',
    () async {
      final payloads = <Map<String, dynamic>>[];
      final classifier = ReportClassifier(
        ReportRepository(
          ApiClient(
            transport: MockClient((r) async {
              final body = jsonDecode(r.body) as Map<String, dynamic>;
              payloads.add(body);
              return result(body['text'] == 'Incendio' ? 'fire' : 'pet');
            }),
          ),
        ),
      );
      addTearDown(classifier.dispose);
      classifier.updateText('Incendio');
      await classifier.identifyNow();
      await classifier.identifyNow();
      expect(classifier.type, 'fire');
      expect(payloads, [
        {'text': 'Incendio'},
      ]);
      classifier.updateText('Se perdió mi perro');
      expect(classifier.type, isNull);
      await classifier.identifyNow();
      expect(classifier.type, 'pet');
    },
  );

  test(
    'late responses cannot overwrite newer text or a manual choice',
    () async {
      final responses = <Completer<http.Response>>[];
      final classifier = ReportClassifier(
        ReportRepository(
          ApiClient(
            transport: MockClient((r) {
              final pending = Completer<http.Response>();
              responses.add(pending);
              return pending.future;
            }),
          ),
        ),
      );
      addTearDown(classifier.dispose);
      classifier.updateText('Incendio');
      final old = classifier.identifyNow();
      await Future<void>.delayed(Duration.zero);
      classifier.updateText('Se perdió mi perro');
      final current = classifier.identifyNow();
      await Future<void>.delayed(Duration.zero);
      responses[1].complete(result('pet'));
      await current;
      responses[0].complete(result('fire'));
      await old;
      expect(classifier.type, 'pet');
      classifier.updateText('Otro incendio');
      final automatic = classifier.identifyNow();
      await Future<void>.delayed(Duration.zero);
      classifier.selectType('crash');
      responses[2].complete(result('fire'));
      await automatic;
      expect(classifier.type, 'crash');
      expect(classifier.analyzing, isFalse);
    },
  );

  test('ambiguity and network errors preserve manual recovery', () async {
    var fail = false;
    final classifier = ReportClassifier(
      ReportRepository(
        ApiClient(
          transport: MockClient((_) async {
            if (fail) throw const FormatException('Unavailable');
            return result(null);
          }),
        ),
      ),
    );
    addTearDown(classifier.dispose);
    classifier.updateText('Hay varias cosas pasando');
    await classifier.identifyNow();
    expect(classifier.type, isNull);
    fail = true;
    classifier.updateText('No entiendo qué pasó aquí');
    await classifier.identifyNow();
    expect(classifier.error, isNotNull);
    classifier.selectType('public_disorder');
    expect(classifier.type, 'public_disorder');
    expect(classifier.error, isNull);
  });
}
