import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../models/post_model.dart';
import '../services/database_service.dart';
import '../screens/feed/comments_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUser;
  final Future<void> Function() onChanged;

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

  bool _liked = false;
  int _commentsCount = 0;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likes;
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final liked = await _db.isLikedByUser(
      postId: widget.post.id!,
      username: widget.currentUser,
    );
    final commentsCount = await _db.getCommentsCount(widget.post.id!);
    if (!mounted) return;
    setState(() {
      _liked = liked;
      _commentsCount = commentsCount;
    });
  }

  String _safeDescription() {
    final description = widget.post.description.trim();
    return description.isEmpty ? 'Sin descripción' : description;
  }

  String _buildImageDescription() {
    if (widget.post.imagePath.isEmpty || widget.post.imagePath == 'placeholder') {
      return 'Publicación sin imagen';
    }
    return 'Imagen de la publicación de ${widget.post.user}. ${_safeDescription()}';
  }

  String _buildPostSummary() {
    return 'Publicación de ${widget.post.user}. '
        'Fecha ${widget.post.date}. '
        'Descripción: ${_safeDescription()}. '
        '$_likesCount me gusta y $_commentsCount comentarios.';
  }

  void _announceMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Semantics(
            liveRegion: true,
            child: Text(message),
          ),
        ),
      );
    SemanticsService.announce(message, Directionality.of(context));
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked;
    await _db.toggleLike(postId: widget.post.id!, username: widget.currentUser);
    if (!mounted) return;
    setState(() {
      _liked = !wasLiked;
      _likesCount = wasLiked ? _likesCount - 1 : _likesCount + 1;
    });
    _announceMessage(
      _liked
          ? 'Has dado me gusta. $_likesCount me gusta.'
          : 'Has quitado me gusta. $_likesCount me gusta.',
    );
    await widget.onChanged();
    await _loadExtras();
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
    await _loadExtras();
    await widget.onChanged();
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Semantics(
          label: 'Avatar del usuario ${widget.post.user}',
          child: CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: ExcludeSemantics(
              child: Text(
                widget.post.user.isNotEmpty ? widget.post.user[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.post.user}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.post.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
        const ExcludeSemantics(child: Icon(Icons.more_horiz)),
      ],
    );
  }

  Widget _buildImage(ThemeData theme) {
    if (widget.post.imagePath.isNotEmpty && widget.post.imagePath != 'placeholder') {
      return Semantics(
        image: true,
        label: _buildImageDescription(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(widget.post.imagePath),
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade300,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(Icons.broken_image_outlined, size: 56, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ExcludeSemantics(
                      child: Text(
                        'Error al cargar imagen',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label: 'Publicación sin imagen',
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.secondary.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: ExcludeSemantics(child: Icon(Icons.image_outlined, size: 60)),
        ),
      ),
    );
  }

  Widget _buildSummaryBlock(ThemeData theme) {
    return MergeSemantics(
      child: Semantics(
        readOnly: true,
        label: _buildPostSummary(),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 14),
              _buildImage(theme),
              const SizedBox(height: 14),
              Text(_safeDescription(), style: theme.textTheme.bodyLarge),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  // FIX: surfaceVariant → surfaceContainerHighest
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_outline, size: 18),
                      const SizedBox(width: 6),
                      Text('$_likesCount me gusta'),
                      const SizedBox(width: 16),
                      const Icon(Icons.mode_comment_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('$_commentsCount comentarios'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: _liked ? 'Me gusta activado' : 'Me gusta desactivado',
            value: '$_likesCount likes',
            hint: _liked ? 'Doble toque para quitar me gusta' : 'Doble toque para dar me gusta',
            child: OutlinedButton.icon(
              onPressed: _toggleLike,
              icon: ExcludeSemantics(
                child: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : null,
                ),
              ),
              label: ExcludeSemantics(child: Text(_liked ? 'Te gusta' : 'Me gusta')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Comentarios',
            value: '$_commentsCount comentarios',
            hint: 'Doble toque para abrir los comentarios',
            child: FilledButton.tonalIcon(
              onPressed: _openComments,
              icon: const ExcludeSemantics(child: Icon(Icons.comment_outlined)),
              label: const ExcludeSemantics(child: Text('Comentarios')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryBlock(theme),
            const SizedBox(height: 14),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }
}