import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import 'business_point.dart';

class BusinessPromotion extends StatefulWidget {
  final BusinessPoint point;
  const BusinessPromotion({super.key, required this.point});
  @override
  State<BusinessPromotion> createState() => _BusinessPromotionState();
}

class _BusinessPromotionState extends State<BusinessPromotion> {
  final form = GlobalKey<FormState>();
  late final offer = TextEditingController(
    text: widget.point.data['offer'] as String? ?? '',
  );
  late final code = TextEditingController(
    text: widget.point.data['discount_code'] as String? ?? '',
  );
  bool busy = false;
  String? error;
  @override
  void dispose() {
    offer.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final data = widget.point.data;
      await AppScope.of(context).api.request(
        'PUT',
        'me/businesses/${widget.point.id}',
        body: {
          for (final key in [
            'name',
            'kind',
            'subtype',
            'description',
            'address',
            'city',
            'district',
            'latitude',
            'longitude',
            'phone',
            'website',
            'media_id',
          ])
            if (data[key] != null) key: data[key],
          'radius_meters': 500,
          'offer': offer.text.trim(),
          'discount_code': code.text.trim().toUpperCase(),
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
    appBar: AppBar(title: const Text('Una oferta para tu zona')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.local_offer_outlined, size: 44),
          const SizedBox(height: 18),
          Text(
            'Dales un motivo para acercarse',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'Puedes añadir una oferta o un código opcional. Se mostrará en tu punto y en los avisos a los vecinos que se acerquen.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: offer,
            enabled: !busy,
            maxLength: 160,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Oferta (opcional)',
              hintText: 'Por ejemplo: 15 % en tu primera visita',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: code,
            enabled: !busy,
            maxLength: 32,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código de descuento (opcional)',
              hintText: 'Por ejemplo: VECINOS15',
            ),
            validator: (v) =>
                v != null &&
                    v.trim().isNotEmpty &&
                    !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v.trim())
                ? 'Usa letras, números, guiones o guion bajo.'
                : null,
          ),
          const SizedBox(height: 20),
          const MessageCard(
            'Un pago único por punto. Puedes crear varios puntos y administrar cada oferta por separado. Los pagos con Stripe todavía no están habilitados; tu punto quedará preparado y en revisión.',
          ),
          if (error != null) MessageCard(error!, error: true),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Guardando…' : 'Guardar oferta'),
          ),
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Continuar sin cambios'),
          ),
        ],
      ),
    ),
  );
}
