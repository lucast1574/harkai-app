import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import 'package:flutter/services.dart';

const businessStates = {
  'pending': 'pendiente',
  'approved': 'aprobado',
  'rejected': 'rechazado',
  'active': 'vigente',
  'past_due': 'vencido',
  'canceled': 'cancelado',
  'refunded': 'reembolsado',
  'expired': 'vencido',
};
const businessKinds = {
  'restaurant': 'Restaurante',
  'health': 'Salud y odontología',
  'shop': 'Tienda',
  'service': 'Servicios',
  'other': 'Otro negocio',
};

class BusinessPoint {
  final Map<String, dynamic> data;
  const BusinessPoint(this.data);
  String get id => data['id'] as String;
  String get name => data['name'] as String;
  double get latitude => (data['latitude'] as num).toDouble();
  double get longitude => (data['longitude'] as num).toDouble();
  bool get enabled => data['enabled'] == true;
}

class BusinessDetails extends StatelessWidget {
  final BusinessPoint point;
  const BusinessDetails({super.key, required this.point});
  @override
  Widget build(BuildContext context) {
    final p = point.data;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Chip(
            label: Text('Espacio promocionado · No es una alerta'),
            avatar: Icon(Icons.storefront_outlined, size: 18),
          ),
          Text(point.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            [
              businessKinds[p['kind']] ?? 'Negocio',
              p['subtype'] ?? '',
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
          if (p['media_id'] is String && (p['media_id'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  AppScope.of(context).api.photoUrl(p['media_id'] as String),
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(p['description'] as String),
          ),
          Text(
            [
              p['address'],
              p['district'],
              p['city'],
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
          if (p['offer'] is String && (p['offer'] as String).isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Oferta para vecinos',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(p['offer'] as String),
                  ],
                ),
              ),
            ),
          if (p['discount_code'] is String &&
              (p['discount_code'] as String).isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_offer_outlined),
              title: SelectableText(p['discount_code'] as String),
              subtitle: const Text('Consulta las condiciones con el negocio'),
              trailing: IconButton(
                tooltip: 'Copiar código',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: p['discount_code'] as String),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado.')),
                  );
                },
              ),
            ),
          if (p['phone'] is String && (p['phone'] as String).isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: p['phone'] as String)),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Llamar'),
            ),
          if (p['website'] is String &&
              (p['website'] as String).startsWith('https://'))
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(p['website'] as String),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Visitar sitio web'),
            ),
        ],
      ),
    );
  }
}
