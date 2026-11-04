import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart';
import 'comment_repository.dart';
import 'comment_tile.dart';
import 'district_chat_composer.dart';

class DistrictThread extends StatefulWidget {
  final Map<String, dynamic> message;
  const DistrictThread({super.key, required this.message});
  @override
  State<DistrictThread> createState() => _DistrictThreadState();
}

class _DistrictThreadState extends State<DistrictThread>
    with WidgetsBindingObserver {
  final text = TextEditingController();
  final focus = FocusNode();
  List<CommunityComment> items = [];
  String? cursor, error;
  bool initialized = false, loading = false, sending = false, removing = false;
  int generation = 0;
  Timer? timer;
  CommentRepository get repository => CommentRepository(
    AppScope.of(context).api,
    widget.message['id'] as String,
    namespace: 'forum',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(load);
    startPolling();
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!loading &&
          !sending &&
          !removing &&
          ModalRoute.of(context)?.isCurrent != false) {
        load(silent: true);
      }
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

  Future<void> load({bool more = false, bool silent = false}) async {
    if (!mounted) return;
    final revision = ++generation;
    setState(() {
      loading = true;
      if (!silent) error = null;
    });
    try {
      final page = await repository.list(more ? cursor : null);
      if (!mounted || revision != generation) return;
      setState(() {
        final merged = more || silent
            ? {for (final item in items) item.id: item}
            : <String, CommunityComment>{};
        for (final item in page.items) {
          merged[item.id] = item;
        }
        items = merged.values.toList()..sort((a, b) => a.id.compareTo(b.id));
        if (!silent || cursor == null && items.length <= page.items.length) {
          cursor = page.cursor;
        }
        error = null;
      });
    } catch (e) {
      if (mounted && revision == generation) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && revision == generation) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (sending || removing || text.text.trim().length < 2) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final created = await repository.add(text.text.trim());
      if (!mounted) return;
      generation++;
      text.clear();
      setState(() {
        items = {
          for (final item in [...items, created]) item.id: item,
        }.values.toList()..sort((a, b) => a.id.compareTo(b.id));
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<bool> remove(String id) async {
    if (removing || sending) return false;
    setState(() => removing = true);
    try {
      await repository.remove(id);
      if (mounted) await load();
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => removing = false);
    }
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final account = AppScope.of(context).account;
    final date = DateTime.parse(
      widget.message['created_at'] as String,
    ).toLocal();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversación',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.message['district'] as String? ?? 'Chat del distrito',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensaje original',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Vecino anónimo · ${MaterialLocalizations.of(context).formatShortDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            widget.message['body'] as String,
                            style: const TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Respuestas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (loading && items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: LinearProgressIndicator(),
                      ),
                    if (!loading && items.isEmpty && error == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Sé el primero en responder a este mensaje.',
                        ),
                      ),
                    ...items.map(
                      (item) => CommentTile(
                        key: ValueKey(item.id),
                        comment: item,
                        leading: Icon(
                          Icons.person_outline_rounded,
                          size: 22,
                          color: colors.onSurfaceVariant,
                        ),
                        onRemove: remove,
                        busy: sending || removing,
                      ),
                    ),
                    if (error != null)
                      MessageCard(error!, error: true, onRetry: load),
                    if (cursor != null)
                      TextButton(
                        onPressed: loading ? null : () => load(more: true),
                        child: const Text('Ver más respuestas'),
                      ),
                  ],
                ),
              ),
            ),
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
                          if (mounted) await load();
                        },
                        child: const Text('Ingresar para responder'),
                      ),
                    )
                  : DistrictChatComposer(
                      controller: text,
                      focusNode: focus,
                      sending: sending || removing,
                      inThread: true,
                      onSend: send,
                      onChanged: () => setState(() {}),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
