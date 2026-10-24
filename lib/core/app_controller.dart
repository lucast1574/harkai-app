import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'api_client.dart';
import 'dart:convert';
import '../features/help/support_place.dart';
import '../features/notifications/notification_service.dart';
import 'api_error.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  final ApiClient api;
  Account? account;
  String? appearance;
  Future<void> _appearanceWrites = Future.value();
  int _appearanceGeneration = 0;
  String? pendingReport, pendingBusiness;
  SupportPlace? pendingSupport;
  late final notifications = NotificationService(api, () => account?.id, (id) {
    if (id.startsWith('business:')) {
      pendingBusiness = id.substring(9);
    } else if (id.startsWith('support:')) {
      try {
        pendingSupport = SupportPlace.fromJson(
          jsonDecode(id.substring(8)) as Map<String, dynamic>,
        );
      } catch (_) {
        return false;
      }
    } else {
      pendingReport = id;
    }
    notifyListeners();
    return true;
  });
  List<Category> categories = [];
  Map<String, dynamic> capabilities = {};
  bool loading = true;
  String? error;
  Future<bool>? _initializing;
  Future<bool>? _restoringSession;
  AppController(this.api);
  Future<bool> restoreSession() => _restoringSession ??= _restoreSession();

  Future<bool> _restoreSession() async {
    appearance = await api.storage.read(key: "harkai_appearance_v1");
    await api.restore();
    final saved = api.savedAccount;
    if (saved != null) {
      try {
        account = Account.fromJson(saved);
        await restorePhoto();
        notifyListeners();
      } on TypeError {
        // A malformed cached profile must not invalidate the saved tokens.
      }
    }
    return api.hasSession;
  }

  Future<bool> initialize() => _initializing ??= _initialize().whenComplete(() {
    _initializing = null;
  });

  Future<bool> _initialize() async {
    try {
      await restoreSession();
      // Metadata connectivity must not prevent restoring the account.
      await Future.wait([loadMeta(), if (api.hasSession) reloadAccount()]);
      if (account != null && capabilities['push_notifications'] == true) {
        await notifications.restore();
      }
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
    return error == null;
  }

  Future<List<Category>> loadMeta() async {
    final meta = await api.request('GET', 'meta', authenticated: false);
    categories = (meta['categories'] as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
    capabilities = meta['capabilities'] as Map<String, dynamic>;
    return categories;
  }

  Future<void> changeAppearance(String value) async {
    if (!['system', 'light', 'dark'].contains(value)) return;
    appearance = value;
    notifyListeners();
    final owner = account?.id;
    final prefs = account?.preferences;
    final version = ++_appearanceGeneration;
    _appearanceWrites = _appearanceWrites.catchError((Object _) {}).then((
      _,
    ) async {
      await api.storage.write(key: 'harkai_appearance_v1', value: value);
      if (owner == null || account?.id != owner || prefs == null) return;
      final data = await api.request(
        'PUT',
        'me/preferences',
        body: {...prefs.toJson(), 'theme': value},
      );
      if (account?.id == owner && version == _appearanceGeneration) {
        account = Account.fromJson(data).withPhoto(account?.photoUrl);
        await api.cacheAccount(data);
        notifyListeners();
      }
    });
    await _appearanceWrites;
  }

  Future<Account?> reloadAccount() async {
    try {
      final user = await api.request('GET', 'me');
      account = Account.fromJson(user);
      await api.cacheAccount(user);
      await restorePhoto();
    } on ApiException catch (e) {
      if (e.status != 401) rethrow;
      await api.clear();
      account = null;
    }
    notifyListeners();
    return account;
  }

  Future<Account> login({
    required String email,
    required String password,
    String? name,
  }) async {
    final session = await api.request(
      'POST',
      name == null ? 'auth/login' : 'auth/register',
      body: {'email': email, 'password': password, 'name': ?name},
    );
    await api.save(session);
    account = Account.fromJson(session['user'] as Map<String, dynamic>);
    await restorePhoto();
    error = null;
    notifyListeners();
    if (capabilities['push_notifications'] == true) {
      unawaited(notifications.restore());
    }
    return account!;
  }

  Future<Account> exchangeGoogle(String token, {String? photoUrl}) async {
    final session = await api.request(
      'POST',
      'auth/google',
      body: {'id_token': token},
    );
    await api.save(session);
    account = Account.fromJson(session['user'] as Map<String, dynamic>);
    final photo = Uri.tryParse(photoUrl ?? '');
    if (photo?.scheme == 'https' &&
        photo!.host.endsWith('.googleusercontent.com')) {
      await api.storage.write(
        key: 'harkai_photo_${account!.id}',
        value: photoUrl,
      );
    }
    await restorePhoto();
    error = null;
    notifyListeners();
    if (capabilities['push_notifications'] == true) {
      unawaited(notifications.restore());
    }
    return account!;
  }

  Future<bool> logout() async {
    await api.logout();
    await notifications.stop();
    pendingReport = null;
    pendingBusiness = null;
    pendingSupport = null;
    account = null;
    notifyListeners();
    return true;
  }

  String categoryLabel(String id) =>
      categories.where((c) => c.id == id).firstOrNull?.label ?? id;

  Future<bool> restorePhoto() async {
    final user = account;
    if (user == null) return false;
    final photo =
        user.photoUrl ?? await api.storage.read(key: 'harkai_photo_${user.id}');
    if (account?.id == user.id) account = user.withPhoto(photo);
    return photo != null;
  }
}
