import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/reports/report_draft.dart';

void main() {
  test('rejects malformed, infinite and out of range coordinates', () {
    for (final value in ['', 'abc', 'NaN', 'Infinity', '91', '-91']) {
      expect(coordinateValidator(value, -90, 90), isNotNull);
    }
    expect(coordinateValidator('-12.0464', -90, 90), isNull);
    expect(coordinateValidator('-77.0428', -180, 180), isNull);
    expect(coordinateValidator('181', -180, 180), isNotNull);
  });
  test('contact sharing is explicit and verification is server owned', () {
    final draft = ReportDraft()
      ..type = 'fire'
      ..description.text = '  Hay humo en la calle  '
      ..latitude.text = '-12.0464'
      ..longitude.text = '-77.0428'
      ..contact.text = ' 999888777 ';
    addTearDown(draft.dispose);
    final input = draft.toJson();
    expect(input['share_contact'], false);
    expect(input.containsKey('verified'), false);
    expect(input.containsKey('user_id'), false);
    expect(input['description'], 'Hay humo en la calle');
    expect(input.containsKey('media_id'), false);
    draft.shareContact = true;
    draft.mediaId = 'approved-photo';
    expect(draft.toJson()['share_contact'], true);
    expect(draft.toJson()['media_id'], 'approved-photo');
    draft.type = 'pet';
    expect(draft.needsPhoto, true);
    draft.type = 'place';
    expect(draft.needsPhoto, true);
  });
}
