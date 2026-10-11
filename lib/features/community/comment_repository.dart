import '../../core/api_client.dart';

class CommunityComment {
  final String id, name, body;
  final DateTime createdAt;
  final bool deleted, canDelete;
  const CommunityComment({
    required this.id,
    required this.name,
    required this.body,
    required this.createdAt,
    required this.deleted,
    required this.canDelete,
  });
  factory CommunityComment.fromJson(Map<String, dynamic> value) =>
      CommunityComment(
        id: value['id'] as String,
        name: value['author_name'] as String? ?? '',
        body: value['body'] as String? ?? '',
        createdAt: DateTime.parse(value['created_at'] as String),
        deleted: value['deleted_at'] != null,
        canDelete: value['can_delete'] == true,
      );
}

class CommentPage {
  final List<CommunityComment> items;
  final String? cursor;
  const CommentPage(this.items, this.cursor);
  factory CommentPage.fromJson(Map<String, dynamic> value) => CommentPage(
    (value['items'] as List)
        .map((v) => CommunityComment.fromJson(v as Map<String, dynamic>))
        .toList(),
    value['next_cursor'] as String?,
  );
}

class CommentRepository {
  final ApiClient api;
  final String incidentId;
  const CommentRepository(this.api, this.incidentId);
  String get path => 'incidents/${Uri.encodeComponent(incidentId)}/comments';
  Future<CommentPage> list([String? cursor]) async => CommentPage.fromJson(
    await api.request(
      'GET',
      '$path${cursor == null ? '' : '?cursor=${Uri.encodeComponent(cursor)}'}',
    ),
  );
  Future<CommunityComment> add(String body) async => CommunityComment.fromJson(
    await api.request('POST', path, body: {'body': body}),
  );
  Future<bool> remove(String id) async {
    await api.request('DELETE', '$path/${Uri.encodeComponent(id)}');
    return true;
  }
}
