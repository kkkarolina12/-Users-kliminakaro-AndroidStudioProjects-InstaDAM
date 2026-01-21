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
    final liked = await _db.isLikedByUser(postId: widget.post.id!, username: widget.currentUser);
    final count = await _db.getCommentsCount(widget.post.id!);
    if (!mounted) return;
    setState(() {
      _liked = liked;
      _commentsCount = count;
    });
  }

  Future<void> _toggleLike() async {
    await _db.toggleLike(postId: widget.post.id!, username: widget.currentUser);
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${p.user}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Imagen placeholder (sin plugins)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black12,
              ),
              child: const Center(child: Icon(Icons.image, size: 60)),
            ),

            const SizedBox(height: 8),
            Text(p.description),
            const SizedBox(height: 6),
            Text(p.date, style: Theme.of(context).textTheme.bodySmall),

            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    await _toggleLike();
                    await _loadExtras();
                  },
                  icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
                ),
                Text('${p.likes}'),

                const SizedBox(width: 16),
                TextButton.icon(
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
              ],
            )
          ],
        ),
      ),
    );
  }
}
