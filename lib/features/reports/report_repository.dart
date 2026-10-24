import 'dart:typed_data';
import 'dart:convert';
import 'report_categories.dart';
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
    bool archive = false,
  }) async {
    if (type == 'crime') {
      final cursors = cursor == null
          ? null
          : jsonDecode(utf8.decode(base64Url.decode(cursor)))
                as Map<String, dynamic>;
      final types = cursors == null
          ? crimeTypes
          : crimeTypes.where(cursors.containsKey).toList();
      final pages = await Future.wait(
        types.map(
          (category) => list(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: category,
            cursor: cursors?[category] as String?,
            history: history,
            alerts: alerts,
            archive: archive,
          ),
        ),
      );
      final next = <String, String>{};
      final items = <Incident>[];
      for (var index = 0; index < pages.length; index++) {
        items.addAll(pages[index].items);
        if (pages[index].cursor != null) {
          next[types[index]] = pages[index].cursor!;
        }
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ReportPage(
        items,
        next.isEmpty ? null : base64Url.encode(utf8.encode(jsonEncode(next))),
      );
    }
    final query = Uri(
      queryParameters: {
        'lat': '$latitude',
        'lng': '$longitude',
        'radius_meters': '$radius',
        'limit': '50',
        if (type.isNotEmpty) 'type': type,
        'cursor': ?cursor,
      },
    ).query;
    return ReportPage.fromJson(
      await api.request(
        'GET',
        '${history
            ? 'me/incidents'
            : alerts
            ? 'alerts'
            : archive
            ? 'archive/incidents'
            : 'incidents'}?$query',
        authenticated: history || alerts,
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
          body: {'text': text, 'selected_type': ?type},
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
