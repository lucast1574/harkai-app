import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import '../auth/login_screen.dart';
import '../map/map_target.dart';
import 'business_point.dart';
import 'business_editor.dart';

class BusinessDirectory extends StatefulWidget {
  final bool own;
  final ValueChanged<MapTarget>? onMap;
  const BusinessDirectory({super.key, this.own = false, this.onMap});
  @override
  State<BusinessDirectory> createState() => _BusinessDirectoryState();
}

class _BusinessDirectoryState extends State<BusinessDirectory> {
  List<BusinessPoint> items = [];
  String? error, cursor;
  bool busy = false, started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      Future.microtask(load);
    }
  }

  Future<void> load({bool more = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = AppScope.of(context).api;
      String path = 'me/businesses?limit=50';
      if (!widget.own) {
        final p = await currentLocation();
        path =
            'businesses?lat=${p.latitude}&lng=${p.longitude}&radius_meters=10000&limit=50';
      }
      if (more && cursor != null) path += '&cursor=$cursor';
      final page = await api.request('GET', path, authenticated: widget.own);
      if (mounted) {
        setState(() {
          final next = (page['items'] as List)
              .map((p) => BusinessPoint(p as Map<String, dynamic>))
              .toList();
          items = more ? [...items, ...next] : next;
          cursor = page['next_cursor'] as String?;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([BusinessPoint? point]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BusinessEditor(point: point)),
    );
    if (mounted) await load();
  }

  Future<void> manageBusiness() async {
    final app = AppScope.of(context);
    if (app.account == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
    if (!mounted || app.account == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Tu punto en el mapa')),
          body: const BusinessDirectory(own: true),
        ),
      ),
    );
    if (mounted) await load();
  }

  Future<void> toggle(BusinessPoint p) async {
    try {
      await AppScope.of(context).api.request(
        'PATCH',
        'me/businesses/${p.id}/enabled',
        body: {'enabled': !p.enabled},
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.own
              ? 'Tu negocio, cerca de los vecinos'
              : 'Tu lugar en la comunidad',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.own
              ? 'Prepara tu punto y envíalo a revisión. La publicación requiere un pago vigente. Los pagos con Stripe están pendientes de habilitar.'
              : 'Descubre negocios de tu zona o pon el tuyo en el mapa.',
        ),
        if (!widget.own)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const Icon(Icons.add_business_outlined),
                title: const Text('Pon tu negocio en el mapa'),
                subtitle: const Text('Crea y administra tu punto promocionado'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: manageBusiness,
              ),
            ),
          ),
        if (widget.own)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Registrar negocio'),
            ),
          ),
        if (error != null) MessageCard(error!, error: true, onRetry: load),
        if (busy) const LinearProgressIndicator(),
        for (final p in items)
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(p.name),
                  subtitle: Text(
                    widget.own
                        ? 'Revisión: ${businessStates[p.data['moderation']] ?? p.data['moderation']} · Pago: ${businessStates[p.data['billing_status']] ?? p.data['billing_status']}'
                        : '${businessKinds[p.data['kind']] ?? 'Negocio'} · Promocionado',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.own
                      ? edit(p)
                      : widget.onMap?.call(MapTarget.business(p)),
                ),
                if (widget.own)
                  SwitchListTile(
                    title: Text(
                      p.enabled ? 'Punto habilitado' : 'Punto pausado',
                    ),
                    subtitle: const Text(
                      'Solo se muestra con revisión aprobada y pago vigente.',
                    ),
                    value: p.enabled,
                    onChanged: busy ? null : (_) => toggle(p),
                  ),
              ],
            ),
          ),
        if (!busy && items.isEmpty && error == null)
          MessageCard(
            widget.own
                ? 'Todavía no registraste un negocio.'
                : 'No hay negocios promocionados en esta zona.',
          ),
        if (cursor != null)
          TextButton(
            onPressed: busy ? null : () => load(more: true),
            child: const Text('Ver más'),
          ),
      ],
    ),
  );
}
