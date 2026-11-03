import 'package:flutter/material.dart';

class DistrictChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final String? replyBody;
  final VoidCallback? onCancelReply;
  final VoidCallback onSend, onChanged;
  const DistrictChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onChanged,
    this.replyBody,
    this.onCancelReply,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyBody != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.reply_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Respondiendo a un vecino',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        replyBody!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar respuesta',
                  onPressed: onCancelReply,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Como vecino anónimo',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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
                maxLines: 4,
                maxLength: 1000,
                enabled: !sending,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: replyBody == null
                      ? 'Escribe a tu barrio…'
                      : 'Escribe tu respuesta…',
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
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
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
        const SizedBox(height: 8),
        Text(
          'Chat público · Tu nombre y foto no se muestran.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
