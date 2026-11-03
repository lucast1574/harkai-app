import 'package:flutter/material.dart';
import 'report_comments.dart';

class DistrictChatMessage extends StatefulWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onDelete;
  const DistrictChatMessage({super.key, required this.message, this.onDelete});
  @override
  State<DistrictChatMessage> createState() => _DistrictChatMessageState();
}

class _DistrictChatMessageState extends State<DistrictChatMessage> {
  bool replies = false;
  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vecino anónimo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (m['can_delete'] == true)
                  IconButton(
                    tooltip: 'Retirar mensaje',
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
              ],
            ),
            Text(
              '${MaterialLocalizations.of(context).formatShortDate(DateTime.parse(m['created_at'] as String).toLocal())} · ${TimeOfDay.fromDateTime(DateTime.parse(m['created_at'] as String).toLocal()).format(context)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SelectableText(m['body'] as String),
            TextButton.icon(
              onPressed: () => setState(() => replies = !replies),
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: Text(replies ? 'Ocultar respuestas' : 'Responder'),
            ),
            if (replies)
              ReportComments(incidentId: m['id'] as String, namespace: 'forum'),
          ],
        ),
      ),
    );
  }
}
