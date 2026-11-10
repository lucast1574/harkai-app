import 'package:flutter/material.dart';

class DistrictChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool inThread;
  final VoidCallback onSend, onChanged;
  const DistrictChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sending,
    this.inThread = false,
    required this.onSend,
    required this.onChanged,
  });
  @override
  State<DistrictChatComposer> createState() => _DistrictChatComposerState();
}

class _DistrictChatComposerState extends State<DistrictChatComposer>
    with WidgetsBindingObserver {
  bool keyboardVisible = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    keyboardVisible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final visible = View.of(context).viewInsets.bottom > 0;
    if (visible != keyboardVisible) setState(() => keyboardVisible = visible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = widget.focusNode;
    final controller = widget.controller;
    final sending = widget.sending;
    final inThread = widget.inThread;
    final onSend = widget.onSend;
    final onChanged = widget.onChanged;

    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) => TextFieldTapRegion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (!focusNode.hasFocus && !keyboardVisible)
                    Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: colors.primary,
                    ),
                  if (!focusNode.hasFocus && !keyboardVisible)
                    const SizedBox(width: 6),
                  Expanded(
                    child: focusNode.hasFocus || keyboardVisible
                        ? const SizedBox.shrink()
                        : Text(
                            inThread
                                ? 'Responder en este hilo'
                                : 'Nuevo mensaje al distrito',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  if (focusNode.hasFocus)
                    TextButton.icon(
                      onPressed: focusNode.unfocus,
                      icon: const Icon(Icons.keyboard_hide_outlined, size: 20),
                      label: const Text('Listo'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines:
                        (focusNode.hasFocus || keyboardVisible) &&
                            MediaQuery.textScalerOf(context).scale(16) > 24
                        ? 1
                        : 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLength: 1000,
                    enabled: !sending,
                    onTapOutside: (_) => focusNode.unfocus(),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      hintText: inThread
                          ? 'Escribe tu respuesta…'
                          : 'Comparte algo con tus vecinos…',
                      counterText: '',
                      filled: true,
                      fillColor: colors.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: sending ? 'Enviando mensaje' : 'Enviar',
                  onPressed: sending || controller.text.trim().length < 2
                      ? null
                      : onSend,
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 22),
                ),
              ],
            ),
            if (!focusNode.hasFocus && !keyboardVisible) ...[
              const SizedBox(height: 8),
              Text(
                'Chat público · Tu nombre y foto no se muestran.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
