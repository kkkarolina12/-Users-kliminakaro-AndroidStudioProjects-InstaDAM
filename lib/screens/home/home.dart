import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../search/search_screen.dart';
import '../../services/localization_service.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final void Function(bool darkMode) onThemeChanged;
  final void Function(String lang) onLanguageChanged;
  final String currentLang;
  final bool isDarkMode;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.username,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLang,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Usamos una lista de funciones para reconstruir las pantallas si es necesario,
  // o simplemente los widgets si son mayormente estáticos.
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _updateScreens();
  }

  // Actualizamos las pantallas cuando cambian las props
  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode || 
        oldWidget.currentLang != widget.currentLang ||
        oldWidget.username != widget.username) {
      _updateScreens();
    }
  }

  void _updateScreens() {
    _screens = [
      FeedScreen(
        username: widget.username,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
        currentLang: widget.currentLang,
        isDarkMode: widget.isDarkMode,
        onLogout: widget.onLogout,
      ),
      const SearchScreen(),
      CreatePostScreen(username: widget.username, currentLang: widget.currentLang),
      ProfileScreen(username: widget.username, currentLang: widget.currentLang),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        currentLang: widget.currentLang,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
        onLogout: widget.onLogout,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Asegura que se vean todos los items
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: LocalizationService.translate('home', widget.currentLang),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          activeIcon: const Icon(Icons.search_rounded),
          label: LocalizationService.translate('search', widget.currentLang),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.add_box_outlined),
          activeIcon: const Icon(Icons.add_box),
          label: LocalizationService.translate('create', widget.currentLang),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: LocalizationService.translate('profile', widget.currentLang),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: LocalizationService.translate('settings', widget.currentLang),
        ),
      ],
      ),
    );
  }
}
