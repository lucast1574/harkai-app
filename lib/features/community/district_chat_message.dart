import 'package:flutter/material.dart';

/// Top-level message: replies are opened on a dedicated route.
class DistrictChatMessage extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onDelete, onOpen;
  const DistrictChatMessage({
    super.key,
    required this.message,
    this.onDelete,
    this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = DateTime.parse(message['created_at'] as String).toLocal();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Vecino anónimo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${MaterialLocalizations.of(context).formatShortDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message['body'] as String,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.45),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Ver hilo'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (message['can_delete'] == true)
                      IconButton(
                        tooltip: 'Retirar mensaje',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                      ),
                    IconButton(
                      tooltip: 'Abrir conversación',
                      onPressed: onOpen,
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
