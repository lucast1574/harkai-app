import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import 'report_photo.dart';
import 'report_repository.dart';
import 'voice_input.dart';
import 'report_input_action.dart';
import 'report_categories.dart';
import 'report_classifier.dart';
import 'report_description_field.dart';
import 'report_type_field.dart';
import 'report_contact_field.dart';

class QuickReportSheet extends StatefulWidget {
  final String category;
  final Future<Position> Function() getLocation;
  const QuickReportSheet({
    super.key,
    required this.category,
    this.getLocation = currentLocation,
  });
  @override
  State<QuickReportSheet> createState() => _QuickReportSheetState();
}

class _QuickReportSheetState extends State<QuickReportSheet> {
  final text = TextEditingController(), contact = TextEditingController();
  final form = GlobalKey<FormState>();
  Position? position;
  String? mediaId, photoName, error;
  ReportClassifier? _classifier;
  bool busy = false, locating = true, share = false, voiceBusy = false;
  bool photoBusy = false;
  bool get pet => (_classifier?.type ?? widget.category) == 'pet';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_classifier == null) {
      _classifier = ReportClassifier(
        ReportRepository(AppScope.of(context).api),
      );
      // Publishing from pets is an explicit choice, even if the description
      // uses a name, a breed or wording the automatic rules do not recognize.
      if (widget.category == 'pet') _classifier!.selectType('pet');
      _classifier!.addListener(refreshClassification);
      text.addListener(descriptionChanged);
    }
  }

  void descriptionChanged() => _classifier!.updateText(text.text);

  void refreshClassification() {
    if (mounted) setState(() => error = null);
  }

  @override
  void initState() {
    super.initState();
    locate();
  }

  @override
  void dispose() {
    _classifier?.removeListener(refreshClassification);
    _classifier?.dispose();
    text.dispose();
    contact.dispose();
    super.dispose();
  }

  Future<bool> locate() async {
    if (mounted) {
      setState(() {
        locating = true;
        error = null;
      });
    }
    try {
      final value = await widget.getLocation();
      if (!mounted) return false;
      if (value.accuracy > 150) {
        throw Exception(
          'El GPS todavía no es preciso. Espera un momento y vuelve a localizarte.',
        );
      }
      setState(() => position = value);
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<bool> photo() async {
    setState(() {
      busy = true;
      photoBusy = true;
      error = null;
    });
    final api = AppScope.of(context).api;
    try {
      final image = await pickReportPhoto(api);
      if (mounted && image != null) {
        setState(() {
          mediaId = image.id;
          photoName = image.name;
        });
      }
      return image != null;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          photoBusy = false;
        });
      }
    }
  }

  Future<bool> publish() async {
    if (busy || voiceBusy || !form.currentState!.validate()) return false;
    final app = AppScope.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final owner = app.account?.id;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final description = text.text.trim();
      final classifier = _classifier!;
      await classifier.identifyNow();
      if (!mounted || app.account?.id != owner) return false;
      final type = classifier.type;
      if (type == null || type.isEmpty || type == 'place') {
        setState(
          () => error =
              'Elige el tipo de alerta para continuar. Tu descripción se conserva.',
        );
        return false;
      }
      if (pet && share) {
        final contactError = reportContactValidator(contact.text);
        if (contactError != null) {
          setState(() => error = contactError);
          return false;
        }
      }
      // Refresh the GPS only after the report is ready to publish.
      if (!await locate() || !mounted || app.account?.id != owner) return false;
      final report = await ReportRepository(app.api).create({
        'category': crimeTypes.contains(type) ? 'crime' : type,
        if (classifier.manualType != null) 'type': type,
        if (classifier.manualType != null) 'manual_type': true,
        'description': description,
        'latitude': position!.latitude,
        'longitude': position!.longitude,
        'country': 'PE',
        if (mediaId != null) 'media_id': mediaId,
        if (pet && share) 'contact_info': normalizedReportContact(contact.text),
        'share_contact': pet && share,
      });
      if (mounted && app.account?.id == owner) Navigator.pop(context, report);
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
    final colors = Theme.of(context).colorScheme;
    final visual = categoryVisual(_classifier!.type ?? widget.category);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: !busy && !voiceBusy,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Form(
                      key: form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(visual.icon, color: visual.color, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Reportar ${visual.shortLabel.toLowerCase()}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cerrar',
                                onPressed: busy || voiceBusy
                                    ? null
                                    : () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            pet
                                ? 'Cuenta si se perdió o lo encontraste, sus rasgos y cuándo lo viste.'
                                : 'Describe la situación para alertar a tu comunidad.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ReportDescriptionField(
                            controller: text,
                            enabled: !busy && !voiceBusy,
                            pet: pet,
                          ),
                          const SizedBox(height: 24),
                          ReportTypeField(
                            classifier: _classifier!,
                            categories: AppScope.of(context).categories,
                            enabled: !busy && !voiceBusy,
                          ),
                          const SizedBox(height: 24),
                          if (AppScope.of(context).capabilities['audio'] ==
                              true)
                            VoiceInput(
                              disabled: busy,
                              onBusyChanged: (value) {
                                if (mounted) setState(() => voiceBusy = value);
                              },
                              onTranscript: (value, _) =>
                                  setState(() => text.text = value),
                            ),
                          const SizedBox(height: 16),
                          ReportInputAction(
                            icon: mediaId == null
                                ? Icons.add_a_photo_rounded
                                : Icons.check_circle_outline_rounded,
                            title: photoBusy
                                ? 'Preparando foto…'
                                : mediaId == null
                                ? 'Añadir una foto'
                                : 'Foto adjunta',
                            subtitle: mediaId == null
                                ? pet
                                      ? 'Opcional · ayuda a reconocer al animal.'
                                      : 'Opcional · muestra lo que está pasando.'
                                : 'Lista para publicar. Toca para cambiarla.',
                            busy: photoBusy,
                            onTap: busy || voiceBusy
                                ? null
                                : () {
                                    photo();
                                  },
                            trailing: mediaId == null
                                ? null
                                : IconButton(
                                    tooltip: 'Quitar foto',
                                    onPressed: busy || voiceBusy
                                        ? null
                                        : () => setState(() {
                                            mediaId = null;
                                            photoName = null;
                                          }),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.onSurface.withValues(alpha: .04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.my_location_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    locating
                                        ? 'Buscando tu ubicación actual…'
                                        : position == null
                                        ? 'Se necesita tu ubicación para publicar.'
                                        : 'En tu ubicación actual · precisión aprox. ${position!.accuracy.round()} m',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                if (!locating && position == null)
                                  TextButton(
                                    onPressed: busy ? null : locate,
                                    child: const Text('Reintentar'),
                                  ),
                              ],
                            ),
                          ),
                          if (pet) ...[
                            const SizedBox(height: 24),
                            ReportContactField(
                              controller: contact,
                              share: share,
                              enabled: !busy && !voiceBusy,
                              onShare: (value) => setState(() {
                                share = value;
                                error = null;
                              }),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (error != null) MessageCard(error!, error: true),
                          const SizedBox(height: 16),
                          Text(
                            'Publica desde un lugar seguro. Tu reporte se mostrará como no verificado.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy || locating || voiceBusy
                                  ? null
                                  : publish,
                              icon: Icon(
                                busy
                                    ? Icons.hourglass_top_rounded
                                    : Icons.send_rounded,
                                size: 18,
                              ),
                              label: Text(
                                busy ? 'Publicando…' : 'Publicar reporte',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (keyboardVisible)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextButton.icon(
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      icon: const Icon(Icons.keyboard_hide_outlined, size: 20),
                      label: const Text('Listo'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
