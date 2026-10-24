import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../shared/app_choice_field.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import '../map/community_map.dart';
import '../reports/report_photo.dart';
import 'business_point.dart';

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
  int radius = 250;
  static const labels = {
    'name': 'Nombre del negocio',
    'subtype': 'Especialidad (opcional)',
    'description': 'Qué ofreces',
    'address': 'Dirección',
    'district': 'Distrito',
    'city': 'Ciudad',
    'phone': 'Teléfono (opcional)',
    'website': 'Sitio HTTPS (opcional)',
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
      radius = p['radius_meters'] as int;
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
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
    setState(() => busy = true);
    try {
      final p = await pickReportPhoto(AppScope.of(context).api);
      if (mounted && p != null) setState(() => media = p.id);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
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
          'radius_meters': radius,
          if (media != null) 'media_id': media,
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.point == null ? 'Registrar negocio' : 'Editar negocio',
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Un lugar fijo en tu comunidad',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los cambios pasan por revisión. Tu punto aparecerá cuando esté aprobado y tenga un pago vigente.',
          ),
          const SizedBox(height: 20),
          for (final e in labels.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: fields[e.key],
                enabled: !busy,
                maxLength: e.key == 'description'
                    ? 2000
                    : e.key == 'name'
                    ? 100
                    : e.key == 'subtype'
                    ? 80
                    : e.key == 'phone'
                    ? 30
                    : e.key == 'address' || e.key == 'website'
                    ? 300
                    : 100,
                maxLines: e.key == 'description' ? 4 : 1,
                decoration: InputDecoration(labelText: e.value),
                validator: (v) {
                  if (['name', 'description'].contains(e.key) &&
                      (v?.trim().length ?? 0) < (e.key == 'name' ? 2 : 5)) {
                    return 'Completa este campo.';
                  }
                  if (e.key == 'website' &&
                      v!.isNotEmpty &&
                      !(Uri.tryParse(v)?.isScheme('https') ?? false)) {
                    return 'Usa una dirección https://';
                  }
                  return null;
                },
              ),
            ),
          AppChoiceField(
            label: 'Tipo de negocio',
            value: kind,
            options: businessKinds,
            onChanged: busy ? null : (v) => setState(() => kind = v),
          ),
          const SizedBox(height: 12),
          AppChoiceField(
            label: 'Avisar al acercarse',
            value: '$radius',
            options: const {
              '100': '100 m',
              '250': '250 m',
              '500': '500 m',
              '1000': '1 km',
            },
            onChanged: busy
                ? null
                : (v) => setState(() => radius = int.parse(v)),
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
          if (error != null) MessageCard(error!, error: true),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Guardando…' : 'Guardar y enviar a revisión'),
          ),
        ],
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
