import 'package:flutter/material.dart';
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
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    final posts = await _db.getAllPosts();
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  Future<void> _goCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(username: widget.username)),
    );
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed - @${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(username: widget.username)),
              );
              await _loadPosts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
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
                // volvemos al login por reinicio simple:
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goCreatePost,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (_, i) => PostCard(
                  post: _posts[i],
                  currentUser: widget.username,
                  onChanged: _loadPosts,
                ),
              ),
            ),
    );
  }
}
