class Preferences {
  final String notifications, language, theme;
  final int radius;
  const Preferences({
    this.notifications = 'all',
    this.radius = 500,
    this.language = 'es',
    this.theme = 'system',
  });
  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
    notifications: json['notifications'] as String,
    radius: json['radius_meters'] as int,
    language: json['language'] as String,
    theme: json['theme'] as String,
  );
  Map<String, dynamic> toJson() => {
    'notifications': notifications,
    'radius_meters': radius,
    'language': language,
    'theme': theme,
  };
}

class Account {
  final String id, name, email, role;
  final Preferences preferences;
  const Account(this.id, this.name, this.email, this.role, this.preferences);
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    json['id'] as String,
    json['name'] as String,
    json['email'] as String,
    json['role'] as String,
    Preferences.fromJson(json['preferences'] as Map<String, dynamic>),
  );
}

class Category {
  final String id, label;
  final bool critical;
  final List<String> advice;
  const Category(this.id, this.label, this.critical, this.advice);
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    json['id'] as String,
    json['label'] as String,
    json['critical'] as bool,
    List<String>.from(json['advice'] as List),
  );
}

class Incident {
  final String id, type, description, status;
  final double latitude, longitude;
  final bool verified, viewerIsAuthor;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? mediaId, contact, district, city;
  const Incident({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.verified,
    this.viewerIsAuthor = false,
    required this.createdAt,
    this.expiresAt,
    this.mediaId,
    this.contact,
    this.district,
    this.city,
  });
  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: json['id'] as String,
    type: json['type'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    verified: json['verified'] as bool,
    viewerIsAuthor: json['viewer_is_author'] == true,
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.parse(json['expires_at'] as String),
    mediaId: json['media_id'] as String?,
    contact: json['contact_info'] as String?,
    district: json['district'] as String?,
    city: json['city'] as String?,
  );
  bool get canConfirm =>
      !verified &&
      status == 'active' &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  String get verificationLabel =>
      verified ? 'Confirmado por la comunidad' : 'No verificado';
}

class ReportPage {
  final List<Incident> items;
  final String? cursor;
  const ReportPage(this.items, this.cursor);
  factory ReportPage.fromJson(Map<String, dynamic> json) => ReportPage(
    (json['items'] as List)
        .map((item) => Incident.fromJson(item as Map<String, dynamic>))
        .toList(),
    json['next_cursor'] as String?,
  );
}

class Analysis {
  final String? suggestedType;
  final String reason;
  final List<String> advice;
  const Analysis(this.suggestedType, this.reason, this.advice);
  factory Analysis.fromJson(Map<String, dynamic> json) => Analysis(
    json['suggested_type'] as String?,
    json['reason'] as String,
    List<String>.from(json['advice'] as List),
  );
}
