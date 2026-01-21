import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../services/database_service.dart';
import '../../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _prefs = PreferencesService();
  final _db = DatabaseService.instance;

  String _name = '';
  int _postsCount = 0;
  List<PostModel> _myPosts = [];
  bool _showOnlyMine = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _prefs.getProfileName(widget.username);
    final posts = await _db.getPostsByUser(widget.username);
    setState(() {
      _name = name;
      _myPosts = posts;
      _postsCount = posts.length;
    });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nombre de perfil'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      await _prefs.setProfile(name: res);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(_name.isEmpty ? widget.username : _name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${widget.username}'),
              trailing: IconButton(onPressed: _editName, icon: const Icon(Icons.edit)),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _showOnlyMine = !_showOnlyMine),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Posts: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$_postsCount'),
                  const SizedBox(width: 10),
                  Text(_showOnlyMine ? '(viendo solo los tuyos)' : '(pulsa para filtrar)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _showOnlyMine
                  ? ListView.builder(
                      itemCount: _myPosts.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(_myPosts[i].description),
                        subtitle: Text(_myPosts[i].date),
                      ),
                    )
                  : const Center(child: Text('Pulsa en Posts para ver tu feed filtrado')),
            ),
          ],
        ),
      ),
    );
  }
}
