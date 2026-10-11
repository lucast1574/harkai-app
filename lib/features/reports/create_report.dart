import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
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
  const CreateReport({super.key});
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
          draft.type ??= result.suggestedType;
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

  Future<bool> locate() async {
    try {
      final p = await currentLocation();
      if (!mounted) return false;
      setState(() {
        draft.latitude.text = '${p.latitude}';
        draft.longitude.text = '${p.longitude}';
        error = null;
      });
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
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
    final category = app.categories
        .where((c) => c.id == draft.type)
        .firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Volver',
                onPressed: busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const PageHeading(
              'Cuéntanos qué está pasando',
              'Publica desde un lugar seguro. Tu reporte comienza como no verificado.',
            ),
            Text(
              'PASO ${step + 1} DE 3 · ${['Qué ocurrió', 'Lugar y evidencia', 'Revisión'][step]}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 22),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step == 0)
                    ReportDescriptionStep(
                      draft: draft,
                      busy: busy,
                      categories: app.categories,
                      analysis: analysis,
                      analyze: analyze,
                      onType: (value) => setState(() => draft.type = value),
                    ),
                  if (step == 1)
                    ReportLocationStep(
                      draft: draft,
                      busy: busy,
                      onLocate: locate,
                      onPhoto: photo,
                      onPoint: (point) => setState(() {
                        draft.latitude.text = '${point.latitude}';
                        draft.longitude.text = '${point.longitude}';
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
                  if (error != null) MessageCard(error!, error: true),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (step > 0)
                        OutlinedButton(
                          onPressed: busy ? null : () => setState(() => step--),
                          child: const Text('Atrás'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: busy ? null : next,
                        child: Text(
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
