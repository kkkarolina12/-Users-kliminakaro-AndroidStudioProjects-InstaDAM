import 'package:flutter/material.dart';
import 'services/preferences_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'theme/app_theme.dart';

class InstaDAMApp extends StatefulWidget {
  const InstaDAMApp({super.key});

  @override
  State<InstaDAMApp> createState() => _InstaDAMAppState();
}

class _InstaDAMAppState extends State<InstaDAMApp> {
  final _prefs = PreferencesService();

  ThemeMode _themeMode = ThemeMode.light;
  String _lang = 'es';
  bool _ready = false;
  String? _rememberedUser;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final darkMode = await _prefs.getDarkMode();
    final lang = await _prefs.getLanguage();
    final remembered = await _prefs.getRememberedUsername();

    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
      _lang = lang;
      _rememberedUser = remembered;
      _ready = true;
    });
  }

  void _setTheme(bool dark) async {
    await _prefs.setDarkMode(dark);
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  void _setLanguage(String lang) async {
    await _prefs.setLanguage(lang);
    setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    final start = (_rememberedUser != null && _rememberedUser!.isNotEmpty)
        ? FeedScreen(
            username: _rememberedUser!,
            onThemeChanged: _setTheme,
            onLanguageChanged: _setLanguage,
            currentLang: _lang,
            isDarkMode: _themeMode == ThemeMode.dark,
          )
        : LoginScreen(
            onLoggedIn: (user) async {
              // si el login decide recordar usuario, lo guarda él;
              // aquí solo navegamos.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => FeedScreen(
                    username: user,
                    onThemeChanged: _setTheme,
                    onLanguageChanged: _setLanguage,
                    currentLang: _lang,
                    isDarkMode: _themeMode == ThemeMode.dark,
                  ),
                ),
              );
            },
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InstaDAM',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: start,
    );
  }
}
