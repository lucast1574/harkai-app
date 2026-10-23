import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import 'report_repository.dart';
import 'report_photo.dart';
import 'report_draft.dart';
import 'report_location_step.dart';
import 'report_detail.dart';
import 'report_description_step.dart';
import 'report_review_step.dart';

class CreateReport extends StatefulWidget {
  final String? initialType;
  final LatLng? initialPoint;
  const CreateReport({super.key, this.initialType, this.initialPoint});
  @override
  State<CreateReport> createState() => _CreateReportState();
}

class _CreateReportState extends State<CreateReport> {
  final draft = ReportDraft();
  final form = GlobalKey<FormState>();
  int step = 0;
  bool busy = false;
  String? error;
  Analysis? analysis;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null &&
        widget.initialType!.isNotEmpty &&
        widget.initialType != 'place') {
      draft.type = widget.initialType;
    }
    final pt = widget.initialPoint ?? const LatLng(-12.0464, -77.0428);
    draft.latitude.text = pt.latitude.toStringAsFixed(6);
    draft.longitude.text = pt.longitude.toStringAsFixed(6);
    if (widget.initialPoint == null) {
      Future.microtask(() => unawaited(locate(silent: true)));
    }
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  Future<bool> analyze() async {
    if (draft.description.text.trim().length < 5) return false;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ReportRepository(
        AppScope.of(context).api,
      ).analyze(draft.description.text, type: draft.type);
      if (mounted) {
        setState(() {
          analysis = result;
          if (result.suggestedType != 'place') {
            draft.type ??= result.suggestedType;
          }
        });
      }
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> locate({bool silent = false}) async {
    try {
      final p = await currentLocation();
      if (!mounted) return false;
      setState(() {
        draft.latitude.text = p.latitude.toStringAsFixed(6);
        draft.longitude.text = p.longitude.toStringAsFixed(6);
        if (!silent) error = null;
      });
      return true;
    } catch (e) {
      if (mounted && !silent) setState(() => error = e.toString());
      return false;
    }
  }

  Future<bool> photo() async {
    if (busy) return false;
    final api = AppScope.of(context).api;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await pickReportPhoto(api);
      if (result == null || !mounted) return false;
      setState(() {
        draft.mediaId = result.id;
        draft.photoName = result.name;
      });
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> next() async {
    if (!form.currentState!.validate()) return false;
    if (step == 1 && draft.needsPhoto && draft.mediaId == null) {
      setState(
        () => error = 'Se necesita una foto aprobada para este reporte.',
      );
      return false;
    }
    if (step < 2) {
      setState(() {
        step++;
        error = null;
      });
      return true;
    }
    if (!draft.reviewed) {
      setState(
        () => error = 'Revisa el reporte y confirma antes de publicarlo.',
      );
      return false;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final report = await ReportRepository(
        AppScope.of(context).api,
      ).create(draft.toJson());
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetail(id: report.id, own: true),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final reportableCategories = app.categories
        .where((c) => c.id != 'place')
        .toList();
    final category = reportableCategories
        .where((c) => c.id == draft.type)
        .firstOrNull;
    final stepTitles = ['Qué ocurrió', 'Lugar y evidencia', 'Confirmar envío'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: green),
        ),
        title: const Text(
          'Nuevo reporte comunitario',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PASO ${step + 1} DE 3',
                          style: const TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stepTitles[step],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: Container(
                          height: 5,
                          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: index <= step
                                ? green
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Publica desde un lugar seguro. Tu reporte alerta a los vecinos de tu zona.',
                    style: TextStyle(color: Color(0xffb5c7d6), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step == 0)
                    ReportDescriptionStep(
                      draft: draft,
                      busy: busy,
                      categories: reportableCategories,
                      analysis: analysis,
                      analyze: analyze,
                      onType: (value) => setState(() => draft.type = value),
                    ),
                  if (step == 1)
                    ReportLocationStep(
                      draft: draft,
                      busy: busy,
                      onLocate: () => locate(silent: false),
                      onPhoto: photo,
                      onPoint: (point) => setState(() {
                        draft.latitude.text = point.latitude.toStringAsFixed(6);
                        draft.longitude.text = point.longitude.toStringAsFixed(
                          6,
                        );
                      }),
                      onShare: (v) => setState(() => draft.shareContact = v),
                    ),
                  if (step == 2)
                    ReportReviewStep(
                      draft: draft,
                      category: category,
                      busy: busy,
                      onReviewed: (value) =>
                          setState(() => draft.reviewed = value),
                    ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    MessageCard(error!, error: true),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (step > 0)
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => setState(() => step--),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Atrás'),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: busy ? null : next,
                        icon: Icon(
                          step == 2
                              ? Icons.send_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label: Text(
                          busy
                              ? 'Un momento…'
                              : step == 2
                              ? 'Publicar reporte'
                              : 'Continuar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
