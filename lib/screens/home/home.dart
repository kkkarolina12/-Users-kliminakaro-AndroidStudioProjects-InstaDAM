import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final void Function(bool darkMode) onThemeChanged;
  final void Function(String lang) onLanguageChanged;
  final String currentLang;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.username,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLang,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InstaDAM'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Logo.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 20),
            Text(
              'Bienvenido, @$username',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Ir al Feed'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedScreen(
                        username: username,
                        onThemeChanged: onThemeChanged,
                        onLanguageChanged: onLanguageChanged,
                        currentLang: currentLang,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_box),
                label: const Text('Crear publicación'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(
                        username: username,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Perfil'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        username: username,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Configuración'),
                onPressed: () async {
                  final loggedOut = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        isDarkMode: isDarkMode,
                        currentLang: currentLang,
                        onThemeChanged: onThemeChanged,
                        onLanguageChanged: onLanguageChanged,
                      ),
                    ),
                  );

                  if (loggedOut == true && context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const InstaDAMHomeReset(),
                      ),
                          (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstaDAMHomeReset extends StatelessWidget {
  const InstaDAMHomeReset({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}