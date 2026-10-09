import 'package:flutter/foundation.dart' hide Category;
import 'api_client.dart';
import 'api_error.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  final ApiClient api;
  Account? account;
  List<Category> categories = [];
  Map<String, dynamic> capabilities = {};
  bool loading = true;
  String? error;
  AppController(this.api);
  Future<bool> initialize() async {
    try {
      await api.restore();
      await loadMeta();
      if (api.hasSession) await reloadAccount();
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
    final meta = await api.request('GET', 'meta');
    categories = (meta['categories'] as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
    capabilities = meta['capabilities'] as Map<String, dynamic>;
    return categories;
  }

  Future<Account?> reloadAccount() async {
    try {
      account = Account.fromJson(await api.request('GET', 'me'));
    } on ApiException catch (e) {
      if (e.status != 401) rethrow;
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
      body: {
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      },
    );
    await api.save(session);
    account = Account.fromJson(session['user'] as Map<String, dynamic>);
    notifyListeners();
    return account!;
  }

  Future<Account> exchangeGoogle(String token) async {
    final session = await api.request(
      'POST',
      'auth/google',
      body: {'id_token': token},
    );
    await api.save(session);
    account = Account.fromJson(session['user'] as Map<String, dynamic>);
    notifyListeners();
    return account!;
  }

  Future<bool> logout() async {
    await api.logout();
    account = null;
    notifyListeners();
    return true;
  }

  String categoryLabel(String id) =>
      categories.where((c) => c.id == id).firstOrNull?.label ?? id;
}
