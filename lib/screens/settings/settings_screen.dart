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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Semantics(
              label: 'Cancelar y volver a ajustes',
              button: true,
              child: Text('Cancelar'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
            child: const Semantics(
              label: 'Confirmar cerrar sesión',
              button: true,
              child: Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _prefs.clearAll();
      if (!mounted) return;
      _announce('Sesión cerrada correctamente');
      Navigator.pop(context, true);
    }
  }

  void _announce(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Text(message),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          Semantics(
            label: 'Tema oscuro',
            toggled: _dark,
            child: SwitchListTile(
              value: _dark,
              title: Row(
                children: [
                  Icon(_dark ? Icons.dark_mode : Icons.light_mode),
                  const SizedBox(width: 12),
                  const Text('Tema oscuro'),
                ],
              ),
              onChanged: (v) async {
                setState(() => _dark = v);
                widget.onThemeChanged(v);
                _announce(v ? 'Modo oscuro activado' : 'Modo claro activado');
              },
            ),
          ),
          SwitchListTile(
            value: _noti,
            title: const Text('Notificaciones (simulación)'),
            onChanged: (v) async {
              setState(() => _noti = v);
              await _prefs.setNotifications(v);
              _announce(v ? 'Notificaciones activadas' : 'Notificaciones desactivadas');
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Idioma',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Seleccionar idioma',
                  hint: 'Actualmente seleccionado: ${_lang == 'es' ? 'Español' : 'Catalán'}',
                  child: DropdownButtonFormField<String>(
                    value: _lang,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                      DropdownMenuItem(value: 'ca', child: Text('Català')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _lang = v);
                      widget.onLanguageChanged(v);
                      _announce('Idioma cambiado a ${v == 'es' ? 'Español' : 'Catalán'}');
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Semantics(
            button: true,
            label: 'Cerrar sesión',
            child: ListTile(
              title: const Text('Cerrar sesión'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: _logout,
            ),
          )
        ],
      ),
    );
  }
}
