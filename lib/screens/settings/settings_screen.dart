import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/database_service.dart';
import '../../services/localization_service.dart';
import '../../services/preferences_service.dart';
import '../../widgets/edit_profile_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final String currentLang;
  final void Function(bool darkMode) onThemeChanged;
  final void Function(String lang) onLanguageChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.currentLang,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  final _db = DatabaseService.instance;
  final _picker = ImagePicker();
  late bool _dark;
  late String _lang;
  bool _noti = true;

  String t(String key) => LocalizationService.translate(key, _lang);

  @override
  void initState() {
    super.initState();
    _dark = widget.isDarkMode;
    _lang = widget.currentLang;
    _loadNoti();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _dark = widget.isDarkMode;
    }
    if (oldWidget.currentLang != widget.currentLang) {
      _lang = widget.currentLang;
    }
  }

  Future<void> _loadNoti() async {
    final n = await _prefs.getNotifications();
    if (!mounted) return;
    setState(() => _noti = n);
  }

  Future<void> _logout() async {
    await _prefs.clearAll();
    widget.onLogout();
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationName: 'InstaDAM',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/Logo.png', width: 50, height: 50),
      children: const [
        Text('Una aplicacion tipo Instagram para el proyecto InstaDAM.'),
      ],
    );
  }

  Future<void> _editProfile() async {
    final profile = await _db.getUserProfile(widget.username);
    if (!mounted) return;

    final result = await showDialog<EditProfileResult>(
      context: context,
      builder: (_) => EditProfileDialog(
        title: t('edit_profile'),
        nameLabel: t('name'),
        bioLabel: t('bio'),
        cancelLabel: t('cancel'),
        saveLabel: t('save'),
        initialName: profile.name,
        initialBio: profile.bio,
      ),
    );

    if (!mounted || result == null) return;
    await _db.updateUserProfile(
      username: widget.username,
      name: result.name.trim(),
      bio: result.bio.trim(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        imageQuality: 60,
      );
      if (picked == null) return;

      final profile = await _db.getUserProfile(widget.username);
      await _db.updateUserProfile(
        username: widget.username,
        name: profile.name,
        bio: profile.bio,
        photoPath: picked.path,
      );

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

  Future<void> _changeLanguage(String lang) async {
    setState(() => _lang = lang);
    await _prefs.setLanguage(lang);
    widget.onLanguageChanged(lang);
  }

  Future<void> _changeTheme(bool value) async {
    setState(() => _dark = value);
    await _prefs.setDarkMode(value);
    widget.onThemeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t('settings')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingsSection(
            title: t('account'),
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(t('edit_profile')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editProfile,
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(t('change_photo')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changeProfilePhoto,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: t('preferences'),
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                value: _dark,
                title: Text(t('dark_mode')),
                onChanged: _changeTheme,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                value: _noti,
                title: Text(t('notifications')),
                onChanged: (v) async {
                  setState(() => _noti = v);
                  await _prefs.setNotifications(v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(t('language')),
                trailing: DropdownButton<String>(
                  value: _lang,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'es', child: Text('Espanol')),
                    DropdownMenuItem(value: 'ca', child: Text('Catala')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    _changeLanguage(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: 'InstaDAM',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(t('app_info')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAppInfo,
              ),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text(
                  t('logout'),
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
