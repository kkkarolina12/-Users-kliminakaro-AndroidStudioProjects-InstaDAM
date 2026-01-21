import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final String currentLang;
  final void Function(bool darkMode) onThemeChanged;
  final void Function(String lang) onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.currentLang,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  bool _dark = false;
  bool _noti = true;
  String _lang = 'es';

  @override
  void initState() {
    super.initState();
    _dark = widget.isDarkMode;
    _lang = widget.currentLang;
    _loadNoti();
  }

  Future<void> _loadNoti() async {
    final n = await _prefs.getNotifications();
    setState(() => _noti = n);
  }

  Future<void> _logout() async {
    await _prefs.clearAll();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          SwitchListTile(
            value: _dark,
            title: const Text('Tema oscuro'),
            onChanged: (v) async {
              setState(() => _dark = v);
              widget.onThemeChanged(v);
            },
          ),
          SwitchListTile(
            value: _noti,
            title: const Text('Notificaciones (simulación)'),
            onChanged: (v) async {
              setState(() => _noti = v);
              await _prefs.setNotifications(v);
            },
          ),
          ListTile(
            title: const Text('Idioma'),
            subtitle: Text(_lang),
            trailing: DropdownButton<String>(
              value: _lang,
              items: const [
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'ca', child: Text('Català')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _lang = v);
                widget.onLanguageChanged(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Cerrar sesión'),
            leading: const Icon(Icons.logout),
            onTap: _logout,
          )
        ],
      ),
    );
  }
}
