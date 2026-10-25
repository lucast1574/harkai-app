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

class QuickReportSheet extends StatefulWidget {
  final String category;
  const QuickReportSheet({super.key, required this.category});
  @override
  State<QuickReportSheet> createState() => _QuickReportSheetState();
}

class _QuickReportSheetState extends State<QuickReportSheet> {
  final text = TextEditingController(), contact = TextEditingController();
  final form = GlobalKey<FormState>();
  Position? position;
  String? mediaId, photoName, error;
  bool busy = false, locating = true, share = false, voiceBusy = false;
  bool photoBusy = false;
  bool get pet => widget.category == 'pet';

  @override
  void initState() {
    super.initState();
    locate();
  }

  @override
  void dispose() {
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
      final value = await currentLocation();
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
    final owner = app.account?.id;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // Always refresh the GPS before publication; never use a map exploration point.
      if (!await locate() || !mounted) return false;
      final description = text.text.trim();
      final analysis = await ReportRepository(
        app.api,
      ).analyze(description, type: widget.category);
      if (!mounted || app.account?.id != owner) return false;
      if (analysis.suggestedType == null || analysis.suggestedType!.isEmpty) {
        setState(() => error = analysis.reason);
        return false;
      }
      final report = await ReportRepository(app.api).create({
        'category': widget.category,
        'description': description,
        'latitude': position!.latitude,
        'longitude': position!.longitude,
        'country': 'PE',
        if (mediaId != null) 'media_id': mediaId,
        if (pet) 'contact_info': contact.text.trim(),
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
    final visual = categoryVisual(widget.category);
    return PopScope(
      canPop: !busy && !voiceBusy,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
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
                    const SizedBox(height: 12),
                    if (widget.category == 'crime')
                      Text(
                        'Cuéntanos qué pasó. Identificaremos el tipo de crimen por tu descripción.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: text,
                      enabled: !busy && !voiceBusy,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: '¿Qué ocurrió?',
                        hintText: 'Describe lo que viste y hace cuánto pasó.',
                      ),
                      validator: (value) =>
                          (value?.trim().runes.length ?? 0) < 5
                          ? 'Describe brevemente lo ocurrido.'
                          : null,
                    ),
                    if (AppScope.of(context).capabilities['audio'] == true)
                      VoiceInput(
                        disabled: busy,
                        onBusyChanged: (value) {
                          if (mounted) setState(() => voiceBusy = value);
                        },
                        onTranscript: (value, _) =>
                            setState(() => text.text = value),
                      ),
                    const SizedBox(height: 12),
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
                          ? 'Opcional · muestra lo que está pasando.'
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
                              icon: const Icon(Icons.close_rounded, size: 19),
                            ),
                    ),
                    const SizedBox(height: 12),
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
                    ...[
                      const SizedBox(height: 12),
                      if (pet)
                        TextFormField(
                          controller: contact,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Contacto opcional para ayudar',
                          ),
                          validator: (value) =>
                              (value?.trim().isNotEmpty ?? false) &&
                                  (value?.trim().length ?? 0) < 6
                              ? 'Añade un contacto de al menos 6 caracteres.'
                              : null,
                        ),
                      if (pet)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: share,
                          onChanged: busy
                              ? null
                              : (value) =>
                                    setState(() => share = value ?? false),
                          title: const Text(
                            'Acepto mostrar este contacto en mi reporte',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
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
                        label: Text(busy ? 'Publicando…' : 'Publicar reporte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
