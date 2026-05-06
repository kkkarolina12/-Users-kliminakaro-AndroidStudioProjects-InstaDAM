import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../services/database_service.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';

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
    final theme = Theme.of(context);
    final profileName = _name.isEmpty ? widget.username : _name;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Capçalera del perfil
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: 'Foto de perfil de $profileName',
                        image: true,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            profileName.isNotEmpty ? profileName[0].toUpperCase() : '?',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileName,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '@${widget.username}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Text('Bio: Amante de la fotografía y el código.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Estadístiques agrupades
                  MergeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Posts', _postsCount.toString()),
                        _buildStatColumn('Seguidores', '120'),
                        _buildStatColumn('Siguiendo', '85'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 3. Botó "Editar perfil"
                  Semantics(
                    button: true,
                    label: 'Editar perfil',
                    child: SizedBox(
                      width: double.infinity,
                      height: 48, // Mida mínima 48dp
                      child: OutlinedButton(
                        onPressed: _editName,
                        child: const Text('Editar perfil'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Selector de vista
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: () => setState(() => _showOnlyMine = false),
                    icon: Icon(Icons.grid_on, color: !_showOnlyMine ? theme.colorScheme.primary : null),
                    tooltip: 'Vista de cuadrícula',
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: () => setState(() => _showOnlyMine = true),
                    icon: Icon(Icons.list, color: _showOnlyMine ? theme.colorScheme.primary : null),
                    tooltip: 'Vista de feed',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Contenido (Grid o Feed)
            _showOnlyMine ? _buildFeedView() : _buildGridView(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, i) {
        final post = _myPosts[i];
        final desc = post.description.isEmpty ? 'Sense descripció' : post.description;
        return Semantics(
          label: 'Post ${i + 1} de ${_myPosts.length}. $desc. ${post.likes} likes.',
          button: true,
          hint: 'Doble toque para abrir el post',
          child: InkWell(
            onTap: () {
              // Simular apertura
            },
            child: Container(
              color: Colors.grey.shade200,
              child: post.imagePath.isNotEmpty && post.imagePath != 'placeholder'
                  ? Image.file(File(post.imagePath), fit: BoxFit.cover)
                  : const Icon(Icons.image),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedView() {
    if (_myPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text('No hay publicaciones todavía.')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myPosts.length,
      itemBuilder: (context, i) {
        return PostCard(
          post: _myPosts[i],
          currentUser: widget.username,
          onChanged: _load,
        );
      },
    );
  }
}
