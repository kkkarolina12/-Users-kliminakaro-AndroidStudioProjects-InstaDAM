import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/preferences_service.dart';

class AuthScreen extends StatefulWidget {
  final void Function(String username) onAuthenticated;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Logo.png',
                width: 90,
                height: 90,
                semanticLabel: 'Logo de InstaDAM',
              ),
              const SizedBox(height: 8),
              Text(
                'InstaDAM',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F3864),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: _showLogin,
                      label: _showLogin
                          ? 'Iniciar sesión, seleccionado'
                          : 'Iniciar sesión',
                      child: TextButton(
                        onPressed: () => setState(() => _showLogin = true),
                        style: TextButton.styleFrom(
                          foregroundColor: _showLogin
                              ? const Color(0xFF1F3864)
                              : Colors.grey,
                          side: _showLogin
                              ? const BorderSide(
                            color: Color(0xFF1F3864),
                            width: 2,
                          )
                              : BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: !_showLogin,
                      label: !_showLogin
                          ? 'Crear cuenta, seleccionado'
                          : 'Crear cuenta',
                      child: TextButton(
                        onPressed: () => setState(() => _showLogin = false),
                        style: TextButton.styleFrom(
                          foregroundColor: !_showLogin
                              ? const Color(0xFF1F3864)
                              : Colors.grey,
                          side: !_showLogin
                              ? const BorderSide(
                            color: Color(0xFF1F3864),
                            width: 2,
                          )
                              : BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showLogin
                    ? LoginForm(
                  key: const ValueKey('login'),
                  onAuthenticated: widget.onAuthenticated,
                )
                    : RegisterForm(
                  key: const ValueKey('register'),
                  onAuthenticated: widget.onAuthenticated,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
            errorText != null ? Colors.red[700] : const Color(0xFF1F3864),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                errorText != null ? Colors.red : const Color(0xFFCCCCCC),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                errorText != null ? Colors.red : const Color(0xFF1F3864),
                width: 2,
              ),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  final void Function(String username) onAuthenticated;

  const LoginForm({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  final _db = DatabaseService.instance;
  final _prefs = PreferencesService();

  bool _rememberUser = false;
  bool _isLoading = false;
  bool _obscurePass = true;

  String? _userError;
  String? _passError;
  String? _globalError;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  String? _validateUser(String user) {
    if (user.trim().isEmpty) return 'El usuario es obligatorio';
    return null;
  }

  String? _validatePass(String pass) {
    if (pass.isEmpty) return 'La contraseña es obligatoria';
    if (pass.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _userError = _validateUser(_userCtrl.text);
      _passError = _validatePass(_passCtrl.text);
      _globalError = null;
    });

    if (_userError != null) {
      FocusScope.of(context).requestFocus(_userFocus);
      return;
    }
    if (_passError != null) {
      FocusScope.of(context).requestFocus(_passFocus);
      return;
    }

    setState(() => _isLoading = true);

    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final user = await _db.login(username, password);

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _globalError = 'Usuario o contraseña incorrectos.';
      });
      return;
    }

    if (_rememberUser) {
      await _prefs.rememberUsername(username);
    } else {
      await _prefs.clearRememberedUsername();
    }

    setState(() => _isLoading = false);
    widget.onAuthenticated(username);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Usuario',
          hint: 'Introduce tu usuario',
          controller: _userCtrl,
          focusNode: _userFocus,
          nextFocus: _passFocus,
          errorText: _userError,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Contraseña',
          hint: '••••••••',
          controller: _passCtrl,
          focusNode: _passFocus,
          errorText: _passError,
          obscureText: _obscurePass,
          textInputAction: TextInputAction.done,
          suffixIcon: Semantics(
            label: _obscurePass ? 'Mostrar contraseña' : 'Ocultar contraseña',
            button: true,
            child: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Semantics(
              label: 'Recordar usuario',
              toggled: _rememberUser,
              child: Switch(
                value: _rememberUser,
                activeColor: const Color(0xFF1F3864),
                onChanged: (val) => setState(() => _rememberUser = val),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _rememberUser = !_rememberUser),
              child: const Text(
                'Recordar usuario',
                style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _globalError != null ? null : 0,
            child: _globalError != null
                ? Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _globalError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: _isLoading ? 'Iniciando sesión, espera' : 'Iniciar sesión',
          button: true,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F3864),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : const Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class RegisterForm extends StatefulWidget {
  final void Function(String username) onAuthenticated;

  const RegisterForm({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final _db = DatabaseService.instance;
  final _prefs = PreferencesService();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  String? _usernameError;
  String? _passError;
  String? _confirmError;
  String? _globalError;
  String? _successMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _usernameFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _usernameError = _usernameCtrl.text.trim().isEmpty
          ? 'El nombre de usuario es obligatorio'
          : _usernameCtrl.text.trim().length < 3
          ? 'Mínimo 3 caracteres'
          : null;
      _passError = _passCtrl.text.length < 6
          ? 'La contraseña debe tener al menos 6 caracteres'
          : null;
      _confirmError = _passCtrl.text != _confirmCtrl.text
          ? 'Las contraseñas no coinciden'
          : null;
      _globalError = null;
      _successMessage = null;
    });

    if (_usernameError != null) {
      FocusScope.of(context).requestFocus(_usernameFocus);
      return;
    }
    if (_passError != null) {
      FocusScope.of(context).requestFocus(_passFocus);
      return;
    }
    if (_confirmError != null) {
      FocusScope.of(context).requestFocus(_confirmFocus);
      return;
    }
    if (!_acceptTerms) {
      setState(() => _globalError = 'Debes aceptar los términos y condiciones.');
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text.trim();

    try {
      await _db.registerUser(
        UserModel(username: username, password: password),
      );

      await _prefs.rememberUsername(username);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _successMessage = '¡Cuenta creada correctamente!';
      });

      widget.onAuthenticated(username);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _globalError = 'Ese usuario ya existe.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Nombre de usuario',
          hint: 'p. ej. maria_dam',
          controller: _usernameCtrl,
          focusNode: _usernameFocus,
          nextFocus: _passFocus,
          errorText: _usernameError,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Contraseña',
          hint: 'Mínimo 6 caracteres',
          controller: _passCtrl,
          focusNode: _passFocus,
          nextFocus: _confirmFocus,
          errorText: _passError,
          obscureText: _obscurePass,
          textInputAction: TextInputAction.next,
          suffixIcon: Semantics(
            label: _obscurePass ? 'Mostrar contraseña' : 'Ocultar contraseña',
            button: true,
            child: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Confirmar contraseña',
          hint: 'Repite tu contraseña',
          controller: _confirmCtrl,
          focusNode: _confirmFocus,
          errorText: _confirmError,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          suffixIcon: Semantics(
            label: _obscureConfirm
                ? 'Mostrar contraseña'
                : 'Ocultar contraseña',
            button: true,
            child: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(
                    () => _obscureConfirm = !_obscureConfirm,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Semantics(
              label: 'Acepto los términos y condiciones',
              toggled: _acceptTerms,
              child: Checkbox(
                value: _acceptTerms,
                activeColor: const Color(0xFF1F3864),
                onChanged: (val) =>
                    setState(() => _acceptTerms = val ?? false),
              ),
            ),
            const Expanded(
              child: Text(
                'Acepto los términos y condiciones',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Column(
            children: [
              if (_globalError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _globalError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Semantics(
          label: _isLoading ? 'Creando cuenta, espera' : 'Crear cuenta',
          button: true,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F3864),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : const Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}