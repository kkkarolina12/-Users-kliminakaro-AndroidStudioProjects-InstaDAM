import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../services/database_service.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  final String currentUser;

  const CommentsScreen({super.key, required this.postId, required this.currentUser});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _db = DatabaseService.instance;
  final _ctrl = TextEditingController();
  List<CommentModel> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _db.getCommentsByPost(widget.postId);
    setState(() {
      _comments = list;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    await _db.addComment(CommentModel(
      postId: widget.postId,
      user: widget.currentUser,
      text: text,
      date: DateTime.now().toIso8601String(),
    ));

    _ctrl.clear();
    await _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (_, i) {
                      final c = _comments[i];
                      return ListTile(
                        title: Text(c.user),
                        subtitle: Text(c.text),
                        trailing: Text(c.date.split('T').first),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Añade un comentario...'),
                  ),
                ),
                IconButton(onPressed: _add, icon: const Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
