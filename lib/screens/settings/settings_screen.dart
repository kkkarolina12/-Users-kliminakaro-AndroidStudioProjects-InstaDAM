import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/localization_service.dart';
import '../../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final String currentLang;
  final void Function(bool darkMode) onThemeChanged;
  final void Function(String lang) onLanguageChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
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
        Text('Una aplicación tipo Instagram mejorada para el proyecto InstaDAM.'),
      ],
    );
  }

  Future<void> _editProfile() async {
    final name = await _prefs.getProfileName('');
    final bio = await _prefs.getProfileBio();

    final nameCtrl = TextEditingController(text: name);
    final bioCtrl = TextEditingController(text: bio);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('edit_profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: t('name')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                decoration: InputDecoration(labelText: t('bio')),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop({
                'name': nameCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    bioCtrl.dispose();

    if (result == null) return;
    await _prefs.setProfile(
      name: result['name']?.trim() ?? '',
      bio: result['bio']?.trim() ?? '',
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final name = await _prefs.getProfileName('');
      final bio = await _prefs.getProfileBio();
      await _prefs.setProfile(name: name, bio: bio, photoPath: picked.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('profile_photo_updated'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('profile_photo_error'))),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(t('settings')),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              t('account'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(t('edit_profile')),
            onTap: _editProfile,
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(t('change_photo')),
            onTap: _changeProfilePhoto,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              t('preferences'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
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
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'ca', child: Text('Català')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _changeLanguage(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t('app_info')),
            onTap: _showAppInfo,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(t('logout'), style: const TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
