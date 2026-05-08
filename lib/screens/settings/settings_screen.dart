import 'package:flutter/material.dart';
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
  late bool _dark;
  late String _lang;
  bool _noti = true;

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
      setState(() => _dark = widget.isDarkMode);
    }
    if (oldWidget.currentLang != widget.currentLang) {
      setState(() => _lang = widget.currentLang);
    }
  }

  Future<void> _loadNoti() async {
    final n = await _prefs.getNotifications();
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
      children: [
        const Text('Una aplicación tipo Instagram mejorada para el proyecto InstaDAM.'),
      ],
    );
  }

  Future<void> _editProfile() async {
    final name = await _prefs.getProfileName('');
    final bio = await _prefs.getProfileBio();
    
    final nameCtrl = TextEditingController(text: name);
    final bioCtrl = TextEditingController(text: bio);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Biografía'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _prefs.setProfile(name: nameCtrl.text.trim(), bio: bioCtrl.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    setState(() {});
  }

  Future<void> _changeUsername() async {
    final current = await _prefs.getRememberedUsername() ?? '';
    final ctrl = TextEditingController(text: current);
    
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nombre de usuario'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nuevo nombre de usuario'),
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
      await _prefs.rememberUsername(res);
      setState(() {});
      // Note: This might require a full app refresh or passing the new username up
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Cuenta',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Editar perfil'),
            onTap: _editProfile,
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Cambiar nombre de usuario'),
            onTap: _changeUsername,
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Cambiar foto de perfil'),
            onTap: () {
              // Simulación de cambio de foto
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de cámara no implementada en este entorno')),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Preferencias',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            value: _dark,
            title: const Text('Tema oscuro'),
            onChanged: (v) {
              setState(() => _dark = v);
              widget.onThemeChanged(v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            value: _noti,
            title: const Text('Notificaciones'),
            onChanged: (v) async {
              setState(() => _noti = v);
              await _prefs.setNotifications(v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Idioma'),
            trailing: DropdownButton<String>(
              value: _lang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'ca', child: Text('Català')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _lang = v);
                widget.onLanguageChanged(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Información de la app'),
            onTap: _showAppInfo,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          )
        ],
      ),
    );
  }
}
