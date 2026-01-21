import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/preferences_service.dart';
import '../../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String username) onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _remember = true;
  bool _loading = false;

  final _db = DatabaseService.instance;
  final _prefs = PreferencesService();

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) return;

    setState(() => _loading = true);
    final user = await _db.login(u, p);
    setState(() => _loading = false);

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login incorrecto')));
      return;
    }

    if (_remember) {
      await _prefs.rememberUsername(u);
    } else {
      await _prefs.clearRememberedUsername();
    }

    widget.onLoggedIn(u);
  }

  Future<void> _register() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _db.registerUser(UserModel(username: u, password: p));
      if (_remember) await _prefs.rememberUsername(u);
      if (!mounted) return;
      widget.onLoggedIn(u);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario ya existe')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InstaDAM - Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Usuario')),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? true)),
                const Text('Recordar usuario'),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: _login, child: const Text('Entrar'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: _register, child: const Text('Registro'))),
                ],
              )
          ],
        ),
      ),
    );
  }
}
