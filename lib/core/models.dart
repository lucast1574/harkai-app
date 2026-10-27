class Preferences {
  final String notifications, language, theme;
  final int radius;
  final bool businessNotifications;
  const Preferences({
    this.notifications = 'all',
    this.businessNotifications = false,
    this.radius = 500,
    this.language = 'es',
    this.theme = 'system',
  });
  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
    notifications: json['notifications'] as String,
    businessNotifications: json['business_notifications'] == true,
    radius: json['radius_meters'] as int,
    language: json['language'] as String,
    theme: json['theme'] as String,
  );
  Map<String, dynamic> toJson() => {
    'notifications': notifications,
    'business_notifications': businessNotifications,
    'radius_meters': radius,
    'language': language,
    'theme': theme,
  };
}

class Account {
  final String? photoUrl;
  final String id, name, email, role;
  final Preferences preferences;
  const Account(
    this.id,
    this.name,
    this.email,
    this.role,
    this.preferences, {
    this.photoUrl,
  });
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    json['id'] as String,
    json['name'] as String,
    json['email'] as String,
    json['role'] as String,
    Preferences.fromJson(json['preferences'] as Map<String, dynamic>),
    photoUrl: json['photo_url'] as String?,
  );
  Account withPhoto(String? url) =>
      Account(id, name, email, role, preferences, photoUrl: url);
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
  final bool verified, viewerIsAuthor, viewerHasConfirmed;
  final int confirmations;
  final DateTime? observedAt;
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
    this.viewerHasConfirmed = false,
    this.confirmations = 0,
    this.observedAt,
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
    viewerHasConfirmed: json['viewer_has_confirmed'] == true,
    confirmations:
        (json['confirmations'] as num?)?.toInt() ??
        (json['verified'] == true ? 1 : 0),
    observedAt: DateTime.tryParse(json['observed_at'] as String? ?? ''),
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.parse(json['expires_at'] as String),
    mediaId: json['media_id'] as String?,
    contact: json['contact_info'] as String?,
    district: json['district'] as String?,
    city: json['city'] as String?,
  );
  bool get mapActive =>
      status == 'active' &&
      !createdAt.isAfter(DateTime.now()) &&
      DateTime.now().difference(createdAt) < const Duration(minutes: 90) &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  bool get canConfirm => !viewerHasConfirmed && mapActive;
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
