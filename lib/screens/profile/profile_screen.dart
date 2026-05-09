import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/post_model.dart';
import '../../services/database_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/edit_profile_dialog.dart';
import '../../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String currentLang;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.currentLang,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final ImagePicker _picker = ImagePicker();

  String _name = '';
  String _bio = '';
  String? _photoPath;
  int _postsCount = 0;
  List<PostModel> _myPosts = [];

  String t(String key) =>
      LocalizationService.translate(key, widget.currentLang);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _db.getUserProfile(widget.username);
    final posts = await _db.getPostsByUser(widget.username);

    if (!mounted) return;

    setState(() {
      _name = profile.name.isEmpty ? widget.username : profile.name;
      _bio = profile.bio;
      _photoPath = profile.photoUrl;
      _myPosts = posts;
      _postsCount = posts.length;
    });
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      await _db.updateUserProfile(
        username: widget.username,
        name: _name.isEmpty ? widget.username : _name,
        bio: _bio,
        photoPath: picked.path,
      );
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('profile_photo_updated'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('profile_photo_error'))));
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog<EditProfileResult>(
      context: context,
      builder: (_) => EditProfileDialog(
        title: t('edit_profile'),
        nameLabel: t('name'),
        bioLabel: t('bio'),
        cancelLabel: t('cancel'),
        saveLabel: t('save'),
        initialName: _name,
        initialBio: _bio,
      ),
    );

    if (!mounted || result == null) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final newName = result.name.trim();
    final newBio = result.bio.trim();

    await _db.updateUserProfile(
      username: widget.username,
      name: newName.isEmpty ? widget.username : newName,
      bio: newBio,
      photoPath: _photoPath,
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openPost(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(t('post'))),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              PostCard(
                post: post,
                currentUser: widget.username,
                onChanged: () {
                  _load();
                },
              ),
            ],
          ),
        ),
      ),
    );
    await _load();
  }

  ImageProvider? _profileImageProvider() {
    final path = _photoPath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  bool _isRemoteImage(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = _profileImageProvider();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickProfilePhoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                backgroundImage: photo,
                                child: photo == null
                                    ? Text(
                                        widget.username.isNotEmpty
                                            ? widget.username[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      )
                                    : null,
                              ),
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: theme.colorScheme.primary,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 15,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                context,
                                t('posts'),
                                _postsCount.toString(),
                              ),
                              _buildStatColumn(context, t('followers'), '120'),
                              _buildStatColumn(context, t('following'), '150'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(_bio),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _editProfile,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          t('edit_profile'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickProfilePhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(t('change_photo')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _myPosts.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t('no_posts'),
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = _myPosts[index];
                        final hasImage =
                            post.imagePath.isNotEmpty &&
                            post.imagePath != 'placeholder' &&
                            (_isRemoteImage(post.imagePath) ||
                                File(post.imagePath).existsSync());

                        return InkWell(
                          onTap: () => _openPost(post),
                          child: hasImage
                              ? _isRemoteImage(post.imagePath)
                                    ? Image.network(
                                        post.imagePath,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(post.imagePath),
                                        fit: BoxFit.cover,
                                      )
                              : Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.photo,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        );
                      }, childCount: _myPosts.length),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
