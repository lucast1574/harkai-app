import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart';
import 'comment_repository.dart';
import 'comment_tile.dart';

class ReportComments extends StatefulWidget {
  final String incidentId;
  const ReportComments({super.key, required this.incidentId});
  @override
  State<ReportComments> createState() => _ReportCommentsState();
}

class _ReportCommentsState extends State<ReportComments> {
  final text = TextEditingController();
  final form = GlobalKey<FormState>();
  List<CommunityComment> items = [];
  String? cursor, error;
  bool initialized = false, loading = false, busy = false;
  int generation = 0;
  CommentRepository get repository =>
      CommentRepository(AppScope.of(context).api, widget.incidentId);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      Future.microtask(load);
    }
  }

  @override
  void dispose() {
    generation++;
    text.dispose();
    super.dispose();
  }

  Future<bool> load([bool more = false]) async {
    if (!mounted) return false;
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final page = await repository.list(more ? cursor : null);
      if (mounted && generation == version) {
        setState(() {
          items = more
              ? {
                  for (final c in [...items, ...page.items]) c.id: c,
                }.values.toList()
              : page.items;
          cursor = page.cursor;
        });
      }
      return true;
    } catch (e) {
      if (mounted && generation == version) {
        setState(() => error = e.toString());
      }
      return false;
    } finally {
      if (mounted && generation == version) setState(() => loading = false);
    }
  }

  Future<bool> publish() async {
    if (!(form.currentState?.validate() ?? false)) return false;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final created = await repository.add(text.text.trim());
      if (!mounted) return false;
      text.clear();
      setState(
        () => items = {
          ...{for (final c in items) c.id: c},
          created.id: created,
        }.values.toList(),
      );
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> remove(String id) async {
    setState(() => busy = true);
    try {
      await repository.remove(id);
      if (!mounted) return false;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'La conversación de este reporte',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('Aporta contexto, pregunta o comparte una actualización.'),
        const SizedBox(height: 12),
        ...items.map(
          (c) => CommentTile(comment: c, onRemove: remove, busy: busy),
        ),
        if (items.isEmpty && !loading && error == null)
          const MessageCard(
            'La conversación empieza aquí. Comparte información útil y respeta a las personas.',
          ),
        if (loading) const LinearProgressIndicator(),
        if (cursor != null)
          TextButton(
            onPressed: loading ? null : () => load(true),
            child: const Text('Ver más comentarios'),
          ),
        if (error != null) MessageCard(error!, error: true, onRetry: load),
        if (app.account == null)
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Ingresar para comentar'),
          )
        else
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: text,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Tu comentario',
                    hintText: '¿Qué información puedes aportar?',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Escribe al menos dos caracteres.'
                      : null,
                ),
                const Text(
                  'Participas como vecino anónimo. Evita insultos y datos que te identifiquen.',
                  style: TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://harkai.lat/normas-comunidad/'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Normas de la comunidad'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : publish,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(busy ? 'Publicando…' : 'Comentar'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
