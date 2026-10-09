import 'dart:typed_data';
import '../../core/api_client.dart';
import '../../core/models.dart';

class ReportRepository {
  final ApiClient api;
  const ReportRepository(this.api);
  Future<ReportPage> list({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String type = '',
    String? cursor,
    bool history = false,
    bool alerts = false,
  }) async {
    final query = Uri(
      queryParameters: {
        'lat': '$latitude',
        'lng': '$longitude',
        'radius_meters': '$radius',
        'limit': '50',
        if (type.isNotEmpty) 'type': type,
        if (cursor != null) 'cursor': cursor,
      },
    ).query;
    return ReportPage.fromJson(
      await api.request(
        'GET',
        '${history
            ? 'me/incidents'
            : alerts
            ? 'alerts'
            : 'incidents'}?$query',
      ),
    );
  }

  Future<Incident> find(String id) async => Incident.fromJson(
    await api.request('GET', 'incidents/${Uri.encodeComponent(id)}'),
  );
  Future<Incident> confirm(String id) async => Incident.fromJson(
    await api.request('POST', 'incidents/${Uri.encodeComponent(id)}/confirm'),
  );
  Future<Incident> status(String id, String status) async => Incident.fromJson(
    await api.request(
      'PATCH',
      'incidents/${Uri.encodeComponent(id)}/status',
      body: {'status': status},
    ),
  );
  Future<Incident> create(Map<String, dynamic> input) async =>
      Incident.fromJson(await api.request('POST', 'incidents', body: input));
  Future<Analysis> analyze(String text, {String? type}) async =>
      Analysis.fromJson(
        await api.request(
          'POST',
          'analysis/text',
          body: {'text': text, if (type != null) 'selected_type': type},
        ),
      );
  Future<String> upload(Uint8List bytes, String contentType) async {
    final result = await api.request(
      'POST',
      'media',
      bytes: bytes,
      contentType: contentType,
    );
    return result['id'] as String;
  }
}
