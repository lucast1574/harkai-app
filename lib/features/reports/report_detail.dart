import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart';
import '../community/report_comments.dart';
import '../help/safety_report.dart';
import 'report_repository.dart';
import 'package:latlong2/latlong.dart';

class ReportDetail extends StatefulWidget {
  final String id;
  final LatLng? userPosition;
  final bool own;
  final bool embedded;
  final ScrollController? scrollController;
  final Widget? sheetHeader;
  final Incident? initialIncident;
  final ValueChanged<Incident>? onMap;
  const ReportDetail({
    super.key,
    required this.id,
    this.userPosition,
    this.own = false,
    this.embedded = false,
    this.scrollController,
    this.sheetHeader,
    this.initialIncident,
    this.onMap,
  });
  @override
  State<ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<ReportDetail> {
  Incident? incident;
  String? error;
  bool busy = false, initialized = false;
  @override
  void initState() {
    super.initState();
    incident = widget.initialIncident;
  }

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
    if (AppScope.of(context).account == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || AppScope.of(context).account == null) return false;
      final refreshed = await load();
      if (!mounted ||
          refreshed == null ||
          !refreshed.canConfirm ||
          refreshed.viewerIsAuthor) {
        return false;
      }
    }
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

  Future<bool> resolve([String status = 'resolved']) async {
    if (busy) return false;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ReportRepository(
        AppScope.of(context).api,
      ).status(widget.id, status);
      await load();
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
    final app = AppScope.of(context);
    final i = incident;
    final visual = i != null ? categoryVisual(i.type) : null;
    final body = SafeArea(
      top: !widget.embedded,
      bottom: !widget.embedded,
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(20, widget.embedded ? 8 : 20, 20, 40),
        children: [
          if (widget.sheetHeader != null) widget.sheetHeader!,
          if (i != null && visual != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: visual.color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: CategoryGlyph(
                              type: i.type,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.categoryLabel(i.type),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                i.district ?? i.city ?? 'Reporte comunitario',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xff64748b)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.userPosition != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Aprox. ${(const Distance()(widget.userPosition!, LatLng(i.latitude, i.longitude)) / 1000).toStringAsFixed(1)} km de ti',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        VerificationBadge(i.verified),
                        if (i.confirmations > 0)
                          Text(
                            '${i.confirmations} ${i.confirmations == 1 ? 'vecino confirmó' : 'vecinos confirmaron'}',
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffe2e8f0),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            'Estado: ${i.status == 'resolved'
                                ? 'Resuelto'
                                : i.mapActive
                                ? 'Activo'
                                : 'Inactivo'}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    SelectableText(
                      i.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Publicado: ${i.createdAt.toLocal().toString().substring(0, 16)} · En el mapa hasta 90 min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (i.observedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'El autor indicó que seguía ocurriendo: ${i.observedAt!.toLocal().toString().substring(0, 16)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'La confirmación es vecinal. Al salir del mapa, la publicación y sus comentarios se conservan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (i.contact != null && i.contact!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri(scheme: 'tel', path: i.contact!.trim()),
                        ),
                        icon: const Icon(Icons.phone_outlined, size: 17),
                        label: Text('Contacto: ${i.contact}'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (i.mediaId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    app.api.photoUrl(i.mediaId!),
                    headers: app.api.authHeaders,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const MessageCard('La evidencia no está disponible.'),
                  ),
                ),
              ),
            if (widget.onMap != null)
              OutlinedButton.icon(
                onPressed: () => widget.onMap!(i),
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Ver en el mapa'),
              ),
            const SizedBox(height: 16),
            if (app.categories
                    .where((c) => c.id == i.type)
                    .firstOrNull
                    ?.advice
                    .isNotEmpty ??
                false)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            color: visual.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recomendaciones ante esta alerta',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: visual.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...?app.categories
                          .where((c) => c.id == i.type)
                          .firstOrNull
                          ?.advice
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('• $a'),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: share,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Compartir'),
                  ),
                ),
                if (i.canConfirm && !(widget.own || i.viewerIsAuthor)) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: busy ? null : confirm,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: Text(
                        app.account == null
                            ? 'Ingresar para confirmar'
                            : 'Confirmo el hecho',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if ((widget.own || i.viewerIsAuthor) && i.mapActive) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : () => resolve('active'),
                icon: const Icon(Icons.update_rounded),
                label: const Text('Sigue ocurriendo'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => resolve(),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Marcar mi reporte como resuelto'),
                ),
              ),
            ],
            ReportComments(
              key: ValueKey('${i.id}:${app.account?.id ?? 'guest'}'),
              incidentId: i.id,
            ),
            SafetyReportButton(incidentId: i.id),
          ],
          if (error != null) MessageCard(error!, error: true, onRetry: load),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: green),
        ),
        title: Text(
          i != null ? app.categoryLabel(i.type) : 'Detalle del reporte',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (i != null)
            IconButton(
              tooltip: 'Compartir reporte',
              onPressed: share,
              icon: const Icon(Icons.share_outlined, color: green),
            ),
        ],
      ),
      body: body,
    );
  }
}
