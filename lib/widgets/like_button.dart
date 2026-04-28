import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onToggle;

  /// Por si quieres bloquear el tap mientras guardas en SQFlite
  final bool enabled;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: isLiked ? 'Me gusta activado' : 'Me gusta desactivado',
      value: '$likeCount likes',
      hint: isLiked ? 'Doble toque para quitar me gusta' : 'Doble toque para dar me gusta',
      child: InkWell(
        onTap: enabled ? onToggle : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : theme.iconTheme.color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '$likeCount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}