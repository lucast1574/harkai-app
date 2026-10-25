import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/features/reports/report_photo.dart';

void main() {
  test(
    'Reports open the camera and cancellation never uploads a photo',
    () async {
      ImageSource? requested;
      final result = await pickReportPhoto(
        ApiClient(),
        pick: (source) async {
          requested = source;
          return null;
        },
      );
      expect(requested, ImageSource.camera);
      expect(result, isNull);
    },
  );
  test('Paid places may explicitly choose the gallery', () async {
    ImageSource? requested;
    await pickReportPhoto(
      ApiClient(),
      source: ImageSource.gallery,
      pick: (source) async {
        requested = source;
        return null;
      },
    );
    expect(requested, ImageSource.gallery);
  });
}
