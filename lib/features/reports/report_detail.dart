import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import '../map/community_map.dart';
import '../auth/login_screen.dart';
import 'report_repository.dart';

class ReportDetail extends StatefulWidget {
  final String id;
  final bool own;
  const ReportDetail({super.key, required this.id, this.own = false});
  @override
  State<ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<ReportDetail> {
  Incident? incident;
  String? error;
  bool busy = false, initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      Future.microtask(load);
    }
  }

  Future<Incident?> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await ReportRepository(
        AppScope.of(context).api,
      ).find(widget.id);
      if (mounted) setState(() => incident = next);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
    return incident;
  }

  Future<bool> confirm() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await ReportRepository(
        AppScope.of(context).api,
      ).confirm(widget.id);
      if (mounted) setState(() => incident = next);
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<ShareResult> share() => SharePlus.instance.share(
    ShareParams(
      text:
          'Reporte comunitario en Harkai. Revisa su estado y detalles: ${Uri(scheme: 'https', host: 'panel.harkai.lat', pathSegments: ['incidents', widget.id])}',
    ),
  );
  Future<bool> resolve() async {
    try {
      await ReportRepository(
        AppScope.of(context).api,
      ).status(widget.id, 'resolved');
      await load();
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final i = incident;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Volver',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            if (i != null) ...[
              PageHeading(
                app.categoryLabel(i.type),
                i.district ?? i.city ?? 'Reporte comunitario',
              ),
              VerificationBadge(i.verified),
              const SizedBox(height: 20),
              SelectableText(
                i.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Text(
                'Estado: ${i.status == 'resolved'
                    ? 'Resuelto'
                    : i.canConfirm || i.verified
                    ? 'Activo'
                    : 'Inactivo'}',
              ),
              Text('Publicado: ${i.createdAt.toLocal()}'),
              if (i.contact != null)
                SelectableText('Contacto compartido: ${i.contact}'),
              if (i.mediaId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      app.api.photoUrl(i.mediaId!),
                      headers: app.api.authHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) =>
                          const MessageCard('La evidencia no está disponible.'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: CommunityMap(
                  center: LatLng(i.latitude, i.longitude),
                  incidents: [i],
                ),
              ),
              const SizedBox(height: 18),
              ...?app.categories
                  .where((c) => c.id == i.type)
                  .firstOrNull
                  ?.advice
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('• $a'),
                    ),
                  ),
              const MessageCard(
                'Una aprobación de otra cuenta basta para confirmar lo observado. La confirmación es comunitaria.',
              ),
              OutlinedButton.icon(
                onPressed: share,
                icon: const Icon(Icons.share),
                label: const Text('Compartir reporte'),
              ),
              if (i.canConfirm && !(widget.own || i.viewerIsAuthor))
                FilledButton(
                  onPressed: busy
                      ? null
                      : app.account == null
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        )
                      : confirm,
                  child: Text(
                    app.account == null
                        ? 'Ingresar para confirmar'
                        : 'Confirmo que observé el hecho',
                  ),
                ),
              if ((widget.own || i.viewerIsAuthor) && i.status == 'active')
                TextButton(
                  onPressed: busy ? null : resolve,
                  child: const Text('Marcar como resuelto'),
                ),
            ],
            if (error != null) MessageCard(error!, error: true, onRetry: load),
            if (busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
