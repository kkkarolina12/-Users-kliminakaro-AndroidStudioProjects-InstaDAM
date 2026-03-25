import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/post_model.dart';
import '../../services/database_service.dart';
import '../../widgets/post_card.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class FeedScreen extends StatefulWidget {
  final String username;
  final void Function(bool darkMode) onThemeChanged;
  final void Function(String lang) onLanguageChanged;
  final String currentLang;
  final bool isDarkMode;

  const FeedScreen({
    super.key,
    required this.username,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLang,
    required this.isDarkMode,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _db = DatabaseService.instance;
  List<PostModel> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts(initialLoad: true);
  }

  Future<void> _loadPosts({bool initialLoad = false}) async {
    setState(() => _loading = true);

    final posts = await _db.getAllPosts();

    if (!mounted) return;

    setState(() {
      _posts = posts;
      _loading = false;
    });

    if (!initialLoad) {
      SemanticsService.announce(
        'Feed actualizado. ${_posts.length} publicaciones disponibles.',
        Directionality.of(context),
      );
    }
  }

  Future<void> _goCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(username: widget.username),
      ),
    );
    await _loadPosts();
  }

  Future<void> _goProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(username: widget.username),
      ),
    );
    await _loadPosts();
  }

  Future<void> _goSettings() async {
    final loggedOut = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          isDarkMode: widget.isDarkMode,
          currentLang: widget.currentLang,
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    if (loggedOut == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Semantics(
          header: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('InstaDAM'),
              Text(
                '@${widget.username}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Abrir perfil de ${widget.username}',
            hint: 'Abre la pantalla de perfil',
            child: IconButton(
              tooltip: 'Perfil',
              icon: const Icon(Icons.person_outline),
              onPressed: _goProfile,
            ),
          ),
          Semantics(
            button: true,
            label: 'Abrir ajustes',
            hint: 'Abre la configuración de la aplicación',
            child: IconButton(
              tooltip: 'Ajustes',
              icon: const Icon(Icons.settings_outlined),
              onPressed: _goSettings,
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Crear nueva publicación',
        hint: 'Abre la pantalla para crear una publicación',
        child: FloatingActionButton.extended(
          tooltip: 'Crear publicación',
          onPressed: _goCreatePost,
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        ),
      ),
      body: _loading
          ? Center(
        child: Semantics(
          label: 'Cargando publicaciones',
          child: const CircularProgressIndicator(),
        ),
      )
          : _posts.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'No hay publicaciones en el feed',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Todavía no hay publicaciones',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea la primera publicación para empezar.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      )
          : Semantics(
        container: true,
        label:
        'Feed principal con ${_posts.length} publicaciones. Desliza hacia arriba o abajo para navegar.',
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: _posts.length,
            itemBuilder: (_, i) {
              return Semantics(
                sortKey: OrdinalSortKey(i.toDouble()),
                child: PostCard(
                  post: _posts[i],
                  currentUser: widget.username,
                  onChanged: _loadPosts,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}