import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../shared/app_choice_field.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import '../map/community_map.dart';
import '../reports/report_photo.dart';
import 'business_point.dart';
import 'business_submission.dart';

class BusinessEditor extends StatefulWidget {
  final BusinessPoint? point;
  const BusinessEditor({super.key, this.point});
  @override
  State<BusinessEditor> createState() => _BusinessEditorState();
}

class _BusinessEditorState extends State<BusinessEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  String kind = 'restaurant';
  String? media, error;
  LatLng? position;
  bool busy = false;
  int step = 0;
  final scroll = ScrollController();

  static const labels = {
    'name': 'Nombre del negocio',
    'subtype': 'Especialidad (opcional)',
    'description': 'Qué ofreces',
    'address': 'Dirección',
    'district': 'Distrito',
    'city': 'Ciudad',
    'phone': 'Teléfono (opcional)',
    'website': 'Sitio web (opcional)',
    'offer': 'Oferta para vecinos (opcional)',
    'discount_code': 'Código de descuento (opcional)',
  };
  @override
  void initState() {
    super.initState();
    final p = widget.point?.data;
    for (final key in labels.keys) {
      fields[key] = TextEditingController(text: p?[key] as String? ?? '');
    }
    if (p != null) {
      kind = p['kind'] as String;
      media = p['media_id'] as String?;
      position = LatLng(widget.point!.latitude, widget.point!.longitude);
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    setState(() => busy = true);
    try {
      final p = await currentLocation();
      if (mounted) setState(() => position = LatLng(p.latitude, p.longitude));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> choosePoint() async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _BusinessMapPicker(
          initial: position ?? const LatLng(-12.0464, -77.0428),
        ),
      ),
    );
    if (mounted && selected != null) setState(() => position = selected);
  }

  Future<void> photo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de mi galería'),
              subtitle: const Text('Fachada, logo o imagen de tu lugar'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    setState(() => busy = true);
    try {
      final p = await pickReportPhoto(AppScope.of(context).api, source: source);
      if (mounted && p != null) setState(() => media = p.id);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (position == null) {
      setState(() => error = 'Elige dónde está tu negocio en el mapa.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.of(context).api.request(
        widget.point == null ? 'POST' : 'PUT',
        'me/businesses${widget.point == null ? '' : '/${widget.point!.id}'}',
        body: {
          for (final e in fields.entries) e.key: e.value.text.trim(),
          'kind': kind,
          'latitude': position!.latitude,
          'longitude': position!.longitude,
          'radius_meters': 500,
          'discount_code': fields['discount_code']!.text.trim().toUpperCase(),
          if (media != null) 'media_id': media,
        },
      );
      if (mounted) {
        final name = fields['name']!.text.trim();
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BusinessSubmission(name: name)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == 0 && !busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy && step > 0) {
        setState(() {
          step--;
          error = null;
        });
        scroll.jumpTo(0);
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.point == null ? 'Ponte en el mapa' : 'Editar negocio',
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: busy
                    ? null
                    : () {
                        if (step == 2) {
                          save();
                          return;
                        }
                        if (!form.currentState!.validate()) return;
                        if (step == 1 && position == null) {
                          setState(
                            () => error =
                                'Elige la ubicación de tu negocio para continuar.',
                          );
                          return;
                        }
                        setState(() {
                          step++;
                          error = null;
                        });
                        scroll.jumpTo(0);
                      },
                child: Text(
                  busy
                      ? 'Guardando…'
                      : step == 2
                      ? 'Enviar a revisión gratis'
                      : 'Continuar',
                ),
              ),
              if (step > 0)
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            step--;
                            error = null;
                          });
                          scroll.jumpTo(0);
                        },
                  child: const Text('Volver'),
                ),
            ],
          ),
        ),
      ),
      body: Form(
        key: form,
        child: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  'Tu negocio',
                  'Dónde encontrarte',
                  'Todo listo para enviar',
                ][step],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gratis por ahora, sin tarjeta. Tras la revisión, tu negocio aparecerá en el mapa y podrá llegar a personas cercanas.',
              ),
              const SizedBox(height: 16),
              Text(
                'Paso ${step + 1} de 3 · ${['Negocio', 'Ubicación', 'Revisión'][step]}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (step + 1) / 3),
              const SizedBox(height: 24),
              if (step == 0) ...[
                for (final key in ['name', 'description'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: fields[key],
                      enabled: !busy,
                      maxLines: key == 'description' ? 3 : 1,
                      maxLength: key == 'description' ? 2000 : 100,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      decoration: InputDecoration(labelText: labels[key]),
                      validator: (v) =>
                          (v?.trim().length ?? 0) < (key == 'name' ? 2 : 5)
                          ? 'Completa este campo.'
                          : null,
                    ),
                  ),
                AppChoiceField(
                  label: 'Tipo de negocio',
                  value: kind,
                  options: businessKinds,
                  onChanged: busy ? null : (v) => setState(() => kind = v),
                ),
              ],
              if (step == 1) ...[
                const SizedBox(height: 16),
                Text(
                  position == null
                      ? 'Ubicación del negocio'
                      : 'Ubicación elegida',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : locate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi ubicación'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : choosePoint,
                  icon: const Icon(Icons.place_outlined),
                  label: Text(
                    position == null
                        ? 'Elegir punto en el mapa'
                        : 'Ajustar punto en el mapa',
                  ),
                ),
                if (position != null)
                  const MessageCard(
                    'Ubicación seleccionada. Comprueba que el punto esté en la entrada de tu negocio.',
                  ),
              ],
              if (step == 0) ...[
                OutlinedButton.icon(
                  onPressed: busy ? null : photo,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    media == null
                        ? 'Foto opcional · se revisará'
                        : 'Cambiar foto adjunta',
                  ),
                ),
                if (media != null)
                  TextButton(
                    onPressed: busy ? null : () => setState(() => media = null),
                    child: const Text('Quitar foto'),
                  ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Más detalles (opcional)'),
                  children: [
                    for (final key in [
                      'address',
                      'subtype',
                      'phone',
                      'website',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: fields[key],
                          enabled: !busy,
                          decoration: InputDecoration(labelText: labels[key]),
                          maxLength: key == 'phone'
                              ? 30
                              : key == 'subtype'
                              ? 80
                              : 300,
                          buildCounter:
                              (
                                _, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                          validator: (v) =>
                              key == 'website' &&
                                  v != null &&
                                  v.trim().isNotEmpty &&
                                  !(Uri.tryParse(v.trim())?.isScheme('https') ??
                                      false)
                              ? 'Usa una dirección https://'
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
              if (step == 2) ...[
                BusinessSummary(
                  name: fields['name']!.text.trim(),
                  description: fields['description']!.text.trim(),
                  kind: businessKinds[kind]!,
                  address: fields['address']!.text.trim(),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: fields['offer'],
                  enabled: !busy,
                  maxLength: 160,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Oferta (opcional)',
                    hintText: 'Por ejemplo: 15 % en tu primera visita',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fields['discount_code'],
                  enabled: !busy,
                  maxLength: 32,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código (opcional)',
                    hintText: 'VECINOS15',
                  ),
                  validator: (v) =>
                      v != null &&
                          v.trim().isNotEmpty &&
                          !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v.trim())
                      ? 'Usa letras, números o guiones.'
                      : null,
                ),
                const MessageCard(
                  'Revisaremos tus datos antes de publicarlos. Los avisos se muestran según la cercanía y los permisos de cada persona, separados de las alertas de seguridad.',
                ),
              ],
              const SizedBox(height: 12),
              if (error != null) MessageCard(error!, error: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BusinessMapPicker extends StatefulWidget {
  final LatLng initial;
  const _BusinessMapPicker({required this.initial});
  @override
  State<_BusinessMapPicker> createState() => _BusinessMapPickerState();
}

class _BusinessMapPickerState extends State<_BusinessMapPicker> {
  late LatLng point = widget.initial;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ubicación del negocio')),
    body: CommunityMap(
      fullScreen: true,
      center: point,
      target: point,
      initialZoom: 16,
      onPoint: (v) => setState(() => point = v),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => Navigator.pop(context, point),
          child: const Text('Usar este punto'),
        ),
      ),
    ),
  );
}
