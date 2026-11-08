import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/models.dart';
import 'report_repository.dart';

/// Debounces requests and discards results for old text or a manual selection.
class ReportClassifier extends ChangeNotifier {
  final ReportRepository repository;
  ReportClassifier(this.repository);

  Analysis? analysis;
  String? manualType, error;
  bool analyzing = false;
  String _text = '';
  String? _analyzedText;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  Future<Analysis?>? _pending;

  String? get type => manualType ?? analysis?.suggestedType;

  void updateText(String value) {
    final next = value.trim();
    if (next == _text) return;
    _text = next;
    _invalidate();
    analysis = null;
    error = null;
    if (manualType == null && next.runes.length >= 5) {
      _timer = Timer(const Duration(milliseconds: 1100), identifyNow);
    }
    notifyListeners();
  }

  void selectType(String value) {
    _invalidate();
    manualType = value.isEmpty ? null : value;
    analysis = null;
    error = null;
    notifyListeners();
    if (manualType == null && _text.runes.length >= 5) {
      unawaited(identifyNow());
    }
  }

  Future<Analysis?> identifyNow() {
    _timer?.cancel();
    if (_disposed || manualType != null || _text.runes.length < 5) {
      return Future.value(null);
    }
    if (_pending != null) return _pending!;
    if (_analyzedText == _text && analysis != null) {
      return Future.value(analysis);
    }
    final generation = _generation;
    final description = _text;
    analyzing = true;
    error = null;
    notifyListeners();
    final pending = _identify(description, generation);
    _pending = pending;
    return pending;
  }

  Future<Analysis?> _identify(String description, int generation) async {
    try {
      // No entry-category constraint: a fire can be described from any shortcut.
      final result = await repository.analyze(description);
      if (_disposed || generation != _generation) return null;
      analysis = result;
      _analyzedText = description;
      return result;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        error = 'No pudimos identificarlo. Puedes elegir el tipo de alerta.';
      }
      return null;
    } finally {
      if (!_disposed && generation == _generation) {
        analyzing = false;
        _pending = null;
        notifyListeners();
      }
    }
  }

  void _invalidate() {
    _generation++;
    _timer?.cancel();
    _pending = null;
    _analyzedText = null;
    analyzing = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidate();
    super.dispose();
  }
}
