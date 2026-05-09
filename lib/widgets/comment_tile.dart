import 'package:flutter/material.dart';

class CommentTile extends StatelessWidget {
  final String username;
  final String text;
  final DateTime createdAt;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete; // Added
  final bool isOwner; // Added

  const CommentTile({
    super.key,
    required this.username,
    required this.text,
    required this.createdAt,
    this.onLongPress,
    this.onDelete,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MergeSemantics(
      child: Semantics(
        readOnly: true,
        label:
            'Comentario de $username. Texto: $text. Fecha ${_formatDate(createdAt)}',
        child: ListTile(
          dense: true,
          onLongPress: onLongPress,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: ExcludeSemantics(
            child: CircleAvatar(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: Text(
                  _formatDate(createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          subtitle: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text),
            ),
          ),
          trailing: isOwner && onDelete != null
              ? IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                )
              : null,
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
