import 'package:flutter/material.dart';
import 'comment_repository.dart';

class CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final Future<bool> Function(String) onRemove;
  final bool busy;
  const CommentTile({
    super.key,
    required this.comment,
    required this.onRemove,
    required this.busy,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 17, child: Text('V')),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.deleted ? 'Comentario retirado' : 'Vecino anónimo',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${comment.createdAt.toLocal()}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (!comment.deleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectableText(comment.body),
                ),
              if (comment.canDelete)
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('¿Retirar comentario?'),
                              content: const Text(
                                'El texto dejará de mostrarse públicamente.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Retirar'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) await onRemove(comment.id);
                        },
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Retirar comentario'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
