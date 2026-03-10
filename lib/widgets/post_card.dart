import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final liked = await _db.isLikedByUser(
      postId: widget.post.id!,
      username: widget.currentUser,
    );
    final count = await _db.getCommentsCount(widget.post.id!);

    if (!mounted) return;

    setState(() {
      _liked = liked;
      _commentsCount = count;
    });
  }

  Future<void> _toggleLike() async {
    await _db.toggleLike(
      postId: widget.post.id!,
      username: widget.currentUser,
    );
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    return Semantics(
      container: true,
      label:
      'Publicación de ${p.user}. '
          'Descripción: ${p.description}. '
          'Fecha: ${p.date}. '
          '${p.likes} me gusta y $_commentsCount comentarios.',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${p.user}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (p.imagePath.isNotEmpty && p.imagePath != 'placeholder')
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(p.imagePath),
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: 'Imagen de la publicación de ${p.user}',
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[300],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Semantics(
                  label: 'Publicación sin imagen',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 60),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              Text(p.description),
              const SizedBox(height: 6),
              Text(
                p.date,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: _liked
                        ? 'Quitar me gusta. ${p.likes} me gusta'
                        : 'Dar me gusta. ${p.likes} me gusta',
                    child: IconButton(
                      tooltip: _liked ? 'Quitar me gusta' : 'Dar me gusta',
                      onPressed: () async {
                        await _toggleLike();
                        await _loadExtras();
                      },
                      icon: Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked ? Colors.red : null,
                      ),
                    ),
                  ),
                  Text('${p.likes}'),
                  const SizedBox(width: 16),
                  Semantics(
                    button: true,
                    label: 'Ver comentarios. $_commentsCount comentarios',
                    child: TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentsScreen(
                              postId: p.id!,
                              currentUser: widget.currentUser,
                            ),
                          ),
                        );
                        await _loadExtras();
                        await widget.onChanged();
                      },
                      icon: const Icon(Icons.comment),
                      label: Text('Ver comentarios ($_commentsCount)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}