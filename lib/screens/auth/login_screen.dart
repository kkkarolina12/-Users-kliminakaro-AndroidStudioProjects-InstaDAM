import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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
              // ✅ LOGO DESDE ASSETS
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
                    child: TextButton(
                      onPressed: () => setState(() => _showLogin = true),
                      child: const Text('Iniciar sesión'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showLogin = false),
                      child: const Text('Crear cuenta'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _showLogin ? const LoginForm() : const RegisterForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        TextField(decoration: InputDecoration(labelText: 'Email')),
        TextField(decoration: InputDecoration(labelText: 'Contraseña')),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: null,
          child: Text('Login'),
        ),
      ],
    );
  }
}

class RegisterForm extends StatelessWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        TextField(decoration: InputDecoration(labelText: 'Usuario')),
        TextField(decoration: InputDecoration(labelText: 'Email')),
        TextField(decoration: InputDecoration(labelText: 'Contraseña')),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: null,
          child: Text('Registrar'),
        ),
      ],
    );
  }
}