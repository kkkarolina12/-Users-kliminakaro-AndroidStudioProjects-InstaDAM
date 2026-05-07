import 'dart:io';

import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/database_service.dart';
import '../screens/feed/comments_screen.dart';
import 'like_button.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUser;
  final VoidCallback onChanged;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUser,
    required this.onChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _db = DatabaseService.instance;

  bool _isLiked = false;
  bool _toggling = false;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    if (widget.post.id == null) return;
    
    final liked = await _db.isLikedByUser(
      postId: widget.post.id!,
      username: widget.currentUser,
    );
    final count = await _db.getCommentsCount(widget.post.id!);
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _commentsCount = count;
    });
  }

  Future<void> _toggleLike() async {
    if (_toggling || widget.post.id == null) return;
    setState(() => _toggling = true);
    await _db.toggleLike(
      postId: widget.post.id!,
      username: widget.currentUser,
    );
    await _loadState();
    setState(() => _toggling = false);
    widget.onChanged();
  }

  Future<void> _openComments() async {
    if (widget.post.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          postId: widget.post.id!,
          currentUser: widget.currentUser,
        ),
      ),
    );
    await _loadState();
  }

  Future<void> _showEditDialog() async {
    final controller = TextEditingController(text: widget.post.description);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar publicación'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Descripción'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _db.updatePost(widget.post.id!, controller.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (updated == true) {
      widget.onChanged();
    }
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar publicación'),
        content: const Text('¿Estás seguro de que quieres borrar esta publicación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deletePost(widget.post.id!);
      widget.onChanged();
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final hasImage =
        post.imagePath.isNotEmpty && post.imagePath != 'placeholder';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(
                    post.user.isNotEmpty ? post.user[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${post.user}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _formatDate(post.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (post.user == widget.currentUser)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditDialog();
                      } else if (val == 'delete') {
                        _showDeleteConfirm();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Borrar', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Image
          if (hasImage)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.zero),
              child: Image.file(
                File(post.imagePath),
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 48)),
                ),
              ),
            ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              post.description,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${post.likes} me gusta',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          const Divider(height: 16, indent: 12, endIndent: 12),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: LikeButton(
                    isLiked: _isLiked,
                    likeCount: post.likes,
                    onToggle: _toggleLike,
                    enabled: !_toggling,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Ver comentarios. $_commentsCount comentarios',
                    hint: 'Doble toque para abrir los comentarios',
                    child: OutlinedButton.icon(
                      onPressed: _openComments,
                      icon: const ExcludeSemantics(
                          child: Icon(Icons.comment_outlined)),
                      label: ExcludeSemantics(
                          child: Text('$_commentsCount comentarios')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
