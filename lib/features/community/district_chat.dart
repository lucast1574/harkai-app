import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart';
import '../location/location_service.dart';
import 'chat_district_picker.dart';
import 'district_chat_message.dart';

class DistrictChat extends StatefulWidget {
  const DistrictChat({super.key});
  @override
  State<DistrictChat> createState() => _DistrictChatState();
}

class _DistrictChatState extends State<DistrictChat>
    with WidgetsBindingObserver {
  final text = TextEditingController();
  List<Map<String, dynamic>> catalog = [], messages = [];
  Map<String, dynamic>? district;
  String? error, cursor;
  bool initialized = false, loading = false, sending = false, locating = false;
  int generation = 0, locationGeneration = 0;
  Timer? timer;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      WidgetsBinding.instance.addObserver(this);
      Future.microtask(initialize);
      startPolling();
    }
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!loading && !sending && district != null) load(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startPolling();
      load(silent: true);
    } else {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    generation++;
    locationGeneration++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    text.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      final data = await AppScope.of(context).api.request('GET', 'geo/catalog');
      if (!mounted) return;
      setState(
        () => catalog = (data['items'] as List).cast<Map<String, dynamic>>(),
      );
      await locate();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> locate() async {
    final version = ++locationGeneration;
    setState(() {
      locating = true;
      error = null;
    });
    final api = AppScope.of(context).api;
    try {
      final p = await currentLocation();
      final data = await api.request(
        'GET',
        'geo/district?lat=${p.latitude}&lng=${p.longitude}',
      );
      if (!mounted || version != locationGeneration) return;
      select(data['district'] as Map<String, dynamic>);
    } catch (_) {
      if (mounted && version == locationGeneration) {
        setState(
          () => error =
              'No pudimos ubicarte. Elige un distrito para abrir su chat.',
        );
      }
    } finally {
      if (mounted && version == locationGeneration) {
        setState(() => locating = false);
      }
    }
  }

  void select(Map<String, dynamic> value) {
    locationGeneration++;
    setState(() {
      district = value;
      messages = [];
      cursor = null;
      error = null;
      locating = false;
    });
    load();
  }

  Future<void> choose() async {
    if (catalog.isEmpty) {
      await initialize();
      if (!mounted || catalog.isEmpty) return;
    }
    if (!mounted) return;
    final value = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChatDistrictPicker(
        catalog: catalog,
        currentId: district?['id'] as String?,
      ),
    );
    if (value != null && mounted) select(value);
  }

  Future<void> load({bool more = false, bool silent = false}) async {
    if (district == null || !mounted || (silent && loading)) return;
    final version = ++generation;
    final id = district!['id'];
    setState(() {
      loading = true;
      if (!silent) error = null;
    });
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'forum?ubigeo=$id&scope=district${more && cursor != null ? '&cursor=$cursor' : ''}',
      );
      if (!mounted || version != generation) return;
      final fresh = (data['items'] as List).cast<Map<String, dynamic>>();
      setState(() {
        final older = silent && data['next_cursor'] != null && fresh.isNotEmpty
            ? messages
                  .where(
                    (m) =>
                        (m['id'] as String).compareTo(
                          fresh.last['id'] as String,
                        ) <
                        0,
                  )
                  .toList()
            : <Map<String, dynamic>>[];
        messages = more
            ? {
                for (final m in [...messages, ...fresh]) m['id']: m,
              }.values.toList()
            : [...fresh, ...older];
        if (!silent || older.isEmpty) cursor = data['next_cursor'] as String?;
        error = null;
      });
    } catch (e) {
      if (mounted && version == generation) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && version == generation) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (sending || district == null || text.text.trim().length < 2) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final created = await AppScope.of(context).api.request(
        'POST',
        'forum',
        body: {'district_id': district!['id'], 'body': text.text.trim()},
      );
      if (!mounted) return;
      generation++;
      text.clear();
      setState(() {
        messages = [created, ...messages];
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> remove(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Retirar mensaje?'),
        content: const Text(
          'El mensaje y sus respuestas dejarán de ser públicos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppScope.of(
        context,
      ).api.request('DELETE', 'forum/${message['id']}');
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = AppScope.of(context).account;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'El chat de tu distrito',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lee cualquier zona. Tu nombre y foto no se muestran.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sending ? null : choose,
                      icon: const Icon(Icons.place_outlined),
                      label: Text(
                        district?['name'] as String? ?? 'Elegir distrito',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mi ubicación',
                    onPressed: locating || sending ? null : locate,
                    icon: const Icon(Icons.my_location_outlined),
                  ),
                ],
              ),
              if (locating) const LinearProgressIndicator(),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (error != null)
                  MessageCard(
                    error!,
                    error: true,
                    onRetry: district == null ? initialize : load,
                  ),
                if (loading && messages.isEmpty)
                  const LinearProgressIndicator(),
                if (district != null &&
                    messages.isEmpty &&
                    !loading &&
                    error == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.forum_outlined, size: 32),
                        SizedBox(height: 12),
                        Text(
                          'La conversación empieza contigo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Comparte una novedad o pregunta a tus vecinos.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (messages.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final d = district!;
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                'https://panel.harkai.lat/distritos/chat-${d['id']}',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enlace público copiado.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Compartir chat'),
                    ),
                  ),
                ...messages.map(
                  (m) => DistrictChatMessage(
                    key: ValueKey('${m['id']}:${account?.id}'),
                    message: m,
                    onDelete: () => remove(m),
                  ),
                ),
                if (cursor != null)
                  TextButton(
                    onPressed: loading ? null : () => load(more: true),
                    child: const Text('Mensajes anteriores'),
                  ),
              ],
            ),
          ),
        ),
        if (district != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: account == null
                ? SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        if (mounted) load();
                      },
                      child: const Text('Ingresar para conversar'),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: text,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 1000,
                        enabled: !sending,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Mensaje anónimo',
                          hintText: '¿Qué pasa en tu barrio?',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Chat público. Evita datos personales.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          FilledButton(
                            onPressed: sending || text.text.trim().length < 2
                                ? null
                                : send,
                            child: Text(sending ? 'Enviando…' : 'Enviar'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}
