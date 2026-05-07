import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _prefs.getProfileName(widget.username);
    final posts = await _db.getPostsByUser(widget.username);
    if (!mounted) return;
    setState(() {
      _name = name.isEmpty ? widget.username : name;
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
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header: Perfil y Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            widget.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32, 
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn('Publicaciones', _postsCount.toString()),
                              _buildStatColumn('Seguidores', '120'), // Simulado
                              _buildStatColumn('Seguidos', '150'),   // Simulado
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('Estudiante de DAM. Amante de la fotografía y el desarrollo móvil. 🚀'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _editName,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Selector de vista (Grid / List)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  indicatorColor: theme.colorScheme.onSurface,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 1,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.assignment_ind_outlined)),
                  ],
                ),
              ),
            ),

            // Grid de publicaciones
            _myPosts.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No tienes publicaciones aún.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _myPosts[index];
                        final hasImage = post.imagePath.isNotEmpty && post.imagePath != 'placeholder';
                        return InkWell(
                          onTap: () {
                            // Aquí se podría abrir el post en detalle
                          },
                          child: Hero(
                            tag: 'post_${post.id}',
                            child: hasImage
                                ? Image.file(File(post.imagePath), fit: BoxFit.cover)
                                : Container(
                                    color: theme.colorScheme.surfaceVariant,
                                    child: const Icon(Icons.photo, color: Colors.grey),
                                  ),
                          ),
                        );
                      },
                      childCount: _myPosts.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
