import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../notifications/device_permissions.dart';
import '../../core/api_client.dart';
import 'report_repository.dart';

Future<({String id, String name})?> pickReportPhoto(
  ApiClient api, {
  ImageSource source = ImageSource.camera,
  Future<XFile?> Function(ImageSource)? pick,
}) async {
  if (pick == null &&
      source == ImageSource.camera &&
      defaultTargetPlatform == TargetPlatform.android) {
    final allowed =
        await DevicePermissions.channel.invokeMethod<bool>('requestCamera') ??
        false;
    if (!allowed) {
      throw Exception(
        'Permite la cámara en Mi cuenta → Permisos del teléfono para tomar la foto.',
      );
    }
  }
  final file = pick != null
      ? await pick(source)
      : await ImagePicker().pickImage(
          source: source,
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
