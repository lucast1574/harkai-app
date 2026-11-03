import 'package:flutter/material.dart';

class BusinessSummary extends StatelessWidget {
  final String name, description, kind, address;
  const BusinessSummary({
    super.key,
    required this.name,
    required this.description,
    required this.kind,
    required this.address,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así te conocerán',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          Text(kind),
          const SizedBox(height: 12),
          Text(description),
          if (address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(address),
            ),
        ],
      ),
    ),
  );
}

class BusinessSubmission extends StatelessWidget {
  final String name;
  const BusinessSubmission({super.key, required this.name});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Negocio enviado')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.check_circle_outline, size: 56),
          ),
          const SizedBox(height: 24),
          Text(
            'Ya recibimos tu negocio',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '$name está en revisión. No tienes que pagar ni añadir una tarjeta.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Cuando lo aprobemos, aparecerá en el mapa. Las personas que se acerquen podrán recibir avisos según sus permisos de ubicación y notificaciones.',
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver a mis negocios'),
          ),
        ],
      ),
    ),
  );
}
