import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onToggle;
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
      toggled: isLiked,
      label: 'Me gusta',
      value: isLiked ? 'Activado' : 'Desactivado',
      hint: isLiked
          ? 'Doble toque para quitar me gusta. $likeCount me gusta en total'
          : 'Doble toque para dar me gusta. $likeCount me gusta en total',
      onTapHint: isLiked ? 'Quitar me gusta' : 'Dar me gusta',
      child: OutlinedButton.icon(
        onPressed: enabled ? onToggle : null,
        icon: ExcludeSemantics(
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? const Color(0xFFE23D5B) : theme.iconTheme.color,
          ),
        ),
        label: ExcludeSemantics(child: Text(isLiked ? 'Te gusta' : 'Me gusta')),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: isLiked
              ? const Color(0xFFE23D5B)
              : theme.colorScheme.primary,
          backgroundColor: isLiked
              ? const Color(0xFFFFEEF2)
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
