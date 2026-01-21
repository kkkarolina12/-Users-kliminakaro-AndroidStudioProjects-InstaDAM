import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/database_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String username;
  const CreatePostScreen({super.key, required this.username});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _db = DatabaseService.instance;
  final _descCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;

    setState(() => _saving = true);

    await _db.createPost(PostModel(
      user: widget.username,
      imagePath: 'placeholder',
      description: desc,
      date: DateTime.now().toIso8601String(),
      likes: 0,
    ));

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black12),
              child: const Center(child: Icon(Icons.image, size: 60)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _saving
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _save, child: const Text('Publicar')),
                  ),
          ],
        ),
      ),
    );
  }
}
