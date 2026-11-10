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
import 'business_editor_field.dart';

class BusinessEditor extends StatefulWidget {
  final BusinessPoint point;
  final Future<({String id, String name})?> Function(ImageSource)? photoPicker;
  const BusinessEditor({super.key, required this.point, this.photoPicker});
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
  bool detailsIncluded = true;
  static const optionalDetails = [
    'address',
    'subtype',
    'phone',
    'website',
    'offer',
    'discount_code',
  ];

  String value(String key) => !detailsIncluded && optionalDetails.contains(key)
      ? widget.point.data[key] as String? ?? ''
      : fields[key]!.text.trim();

  void moveTo(int next, {bool? includeDetails}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      step = next;
      error = null;
      if (includeDetails != null) detailsIncluded = includeDetails;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  static const labels = {
    'name': 'Nombre del negocio',
    'subtype': 'Especialidad (opcional)',
    'description': 'Qué ofreces',
    'address': 'Dirección (opcional)',
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
    final p = widget.point.data;
    for (final key in labels.keys) {
      fields[key] = TextEditingController(text: p[key] as String? ?? '');
    }
    kind = p['kind'] as String;
    media = p['media_id'] as String?;
    position = LatLng(widget.point.latitude, widget.point.longitude);
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
    FocusManager.instance.primaryFocus?.unfocus();
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
      final p =
          await (widget.photoPicker?.call(source) ??
              pickReportPhoto(AppScope.of(context).api, source: source));
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
        'PUT',
        'me/businesses/${widget.point.id}',
        body: {
          for (final key in fields.keys) key: value(key),
          'kind': kind,
          'latitude': position!.latitude,
          'longitude': position!.longitude,
          'radius_meters': 500,
          'discount_code': value('discount_code').toUpperCase(),
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
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: step == 0 && !busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy && step > 0) moveTo(step - 1);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Editar negocio')),
        bottomNavigationBar: keyboardVisible
            ? null
            : SafeArea(
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
                                if (step == 3) {
                                  save();
                                  return;
                                }
                                if (!form.currentState!.validate()) return;
                                if (step == 2 && position == null) {
                                  setState(
                                    () => error =
                                        'Elige la ubicación de tu negocio para continuar.',
                                  );
                                  return;
                                }
                                moveTo(
                                  step + 1,
                                  includeDetails: step == 1 ? true : null,
                                );
                              },
                        child: Text(
                          busy
                              ? 'Guardando…'
                              : step == 3
                              ? 'Guardar cambios'
                              : 'Continuar',
                        ),
                      ),
                      if (step == 1)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => moveTo(2, includeDetails: false),
                          child: const Text('Omitir este paso'),
                        ),
                      if (step > 0)
                        TextButton(
                          onPressed: busy ? null : () => moveTo(step - 1),
                          child: const Text('Volver'),
                        ),
                    ],
                  ),
                ),
              ),
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: form,
                child: SingleChildScrollView(
                  controller: scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        [
                          'Tu negocio',
                          'Más detalles',
                          'Dónde encontrarte',
                          'Todo listo para enviar',
                        ][step],
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step == 1
                            ? 'Este paso es opcional. Puedes añadir más información o continuar sin completarlo.'
                            : 'Edita tu negocio sin un nuevo cobro. Revisaremos los cambios antes de mostrarlos en el mapa.',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Paso ${step + 1} de 4 · ${['Negocio', 'Detalles opcionales', 'Ubicación', 'Revisión'][step]}',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: (step + 1) / 4),
                      const SizedBox(height: 32),
                      if (step == 0) ...[
                        for (final key in ['name', 'description'])
                          BusinessEditorField(
                            name: key,
                            label: labels[key]!,
                            controller: fields[key]!,
                            enabled: !busy,
                          ),
                        AppChoiceField(
                          label: 'Tipo de negocio',
                          value: kind,
                          options: businessKinds,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => kind = v),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: busy ? null : photo,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            media == null
                                ? 'Añadir foto (opcional)'
                                : 'Cambiar foto adjunta',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Elige una imagen de tu galería o toma una foto. La revisaremos antes de publicarla.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (media != null)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() => media = null),
                            child: const Text('Quitar foto'),
                          ),
                      ],
                      if (step == 1)
                        for (final key in optionalDetails)
                          BusinessEditorField(
                            name: key,
                            label: labels[key]!,
                            controller: fields[key]!,
                            enabled: !busy,
                          ),
                      if (step == 2) ...[
                        Text(
                          position == null
                              ? 'Ubicación del negocio'
                              : 'Ubicación elegida',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: busy ? null : locate,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Usar mi ubicación'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: busy ? null : choosePoint,
                          icon: const Icon(Icons.place_outlined),
                          label: Text(
                            position == null
                                ? 'Elegir punto en el mapa'
                                : 'Ajustar punto en el mapa',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (position != null)
                          const MessageCard(
                            'Ubicación seleccionada. Comprueba que el punto esté en la entrada de tu negocio.',
                          ),
                      ],
                      if (step == 3) ...[
                        BusinessSummary(
                          name: value('name'),
                          description: value('description'),
                          kind: businessKinds[kind]!,
                          address: value('address'),
                        ),
                        if (value('offer').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Oferta para vecinos: ${value('offer')}',
                            ),
                          ),
                        const SizedBox(height: 24),
                        const MessageCard(
                          'Revisaremos tus datos antes de publicarlos. Los avisos se muestran según la cercanía y los permisos de cada persona, separados de las alertas de seguridad.',
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        MessageCard(error!, error: true),
                      ],
                      const SizedBox(height: 24),
                    ],
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
    );
  }
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
