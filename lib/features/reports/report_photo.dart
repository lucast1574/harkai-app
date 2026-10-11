import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import 'report_repository.dart';

Future<({String id, String name})?> pickReportPhoto(ApiClient api) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2048,
    maxHeight: 2048,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > 5 * 1024 * 1024) {
    throw Exception('Elige una foto de hasta 5 MB.');
  }
  final mime = file.name.toLowerCase().endsWith('.png')
      ? 'image/png'
      : 'image/jpeg';
  final id = await ReportRepository(api).upload(bytes, mime);
  return (id: id, name: file.name);
}
