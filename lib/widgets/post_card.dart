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
    if (_toggling) return;
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
                height: 240,
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
