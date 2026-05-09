import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/comment_model.dart';
import '../../services/database_service.dart';
import '../../widgets/comment_tile.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String currentUser;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.currentUser,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _ctrl = TextEditingController();

  List<CommentModel> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
    });

    final list = await _db.getCommentsByPost(widget.postId);

    if (!mounted) return;

    setState(() {
      _comments = list;
      _loading = false;
    });
  }

  void _showAccessibleMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );

    SemanticsService.announce(
      message,
      Directionality.of(context),
      assertiveness: Assertiveness.assertive,
    );
  }

  Future<void> _addComment() async {
    final text = _ctrl.text.trim();

    if (text.isEmpty) {
      _showAccessibleMessage('Escribe un comentario antes de enviar');
      return;
    }

    final newComment = CommentModel(
      postId: widget.postId,
      user: widget.currentUser,
      text: text,
      date: DateTime.now().toIso8601String(),
    );

    await _db.addComment(newComment);

    _ctrl.clear();
    await _loadComments();

    if (!mounted) return;
    _showAccessibleMessage('Comentario añadido correctamente');
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar comentario'),
        content: const Text(
          '¿Estás seguro de que quieres borrar este comentario?',
        ),
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
      await _db.deleteComment(widget.postId, commentId);
      await _loadComments();
      if (!mounted) return;
      _showAccessibleMessage('Comentario borrado');
    }
  }

  DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsCount = _comments.length;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: ExcludeSemantics(child: Text('Comentarios ($commentsCount)')),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Semantics(
                      liveRegion: true,
                      child: const Text('Todavía no hay comentarios'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      return CommentTile(
                        username: c.user,
                        text: c.text,
                        createdAt: _parseDate(c.date),
                        isOwner: c.user == widget.currentUser,
                        onDelete: c.id != null
                            ? () => _deleteComment(c.id!)
                            : null,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                    decoration: const InputDecoration(
                      labelText: 'Escribe un comentario',
                      hintText: 'Añade tu comentario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      button: true,
                      label: 'Enviar comentario',
                      hint: 'Doble toque para publicar el comentario',
                      child: FilledButton.icon(
                        onPressed: _addComment,
                        icon: const ExcludeSemantics(child: Icon(Icons.send)),
                        label: const ExcludeSemantics(child: Text('Enviar')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
