import 'package:flutter/material.dart';

class CommentComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const CommentComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([focus, widget.controller]),
      builder: (context, _) => TextFieldTapRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tu comentario',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (focus.hasFocus)
                    TextButton.icon(
                      onPressed: focus.unfocus,
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
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: focus,
                    enabled: !widget.sending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onTapOutside: (_) => focus.unfocus(),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario…',
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: widget.sending ? 'Publicando…' : 'Enviar comentario',
                  onPressed:
                      widget.sending || widget.controller.text.trim().length < 2
                      ? null
                      : widget.onSend,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: widget.sending
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onSurfaceVariant,
                            semanticsLabel: 'Publicando comentario',
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.controller.text.characters.length}/1000',
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
