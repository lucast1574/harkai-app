import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

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
  final VoidCallback? onClose;
  const BusinessDetails({super.key, required this.point, this.onClose});
  @override
  Widget build(BuildContext context) {
    final p = point.data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Negocio local',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Cerrar negocio',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          if (p['media_id'] is String && (p['media_id'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ColoredBox(
                    color: navy,
                    child: Image.network(
                      AppScope.of(
                        context,
                      ).api.photoUrl(p['media_id'] as String),
                      fit: BoxFit.contain,
                      semanticLabel: 'Foto de ${point.name}',
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (_, e, s) => const Center(
                        child: Icon(
                          Icons.storefront_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Text(
            point.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            [
              businessKinds[p['kind']] ?? 'Negocio',
              p['subtype'] ?? '',
            ].where((s) => s.isNotEmpty).join(' · '),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          const SizedBox(height: 16),
          if (p['offer'] is String && (p['offer'] as String).isNotEmpty)
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Theme.of(context).colorScheme.secondaryContainer,
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
