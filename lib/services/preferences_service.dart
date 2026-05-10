import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _kRememberedUser = 'remembered_username';
  static const _kDarkMode = 'dark_mode';
  static const _kLanguage = 'language';
  static const _kNotifications = 'notifications';
  static const _kProfileName = 'profile_name';
  static const _kProfilePhoto = 'profile_photo';
  static const _kProfileBio = 'profile_bio';

  Future<void> rememberUsername(String username) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRememberedUser, username);
  }

  Future<String?> getRememberedUsername() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRememberedUser);
  }

  Future<void> clearRememberedUsername() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRememberedUser);
  }

  Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDarkMode, value);
  }

  Future<bool> getDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDarkMode) ?? false;
  }

  Future<void> setLanguage(String lang) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLanguage, lang);
  }

  Future<String> getLanguage() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLanguage) ?? 'es';
  }

  Future<void> setNotifications(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifications, value);
  }

  Future<bool> getNotifications() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotifications) ?? true;
  }

  Future<void> setProfile({
    required String name,
    String? photoPath,
    String? bio,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kProfileName, name);
    if (photoPath != null) await p.setString(_kProfilePhoto, photoPath);
    if (bio != null) await p.setString(_kProfileBio, bio);
  }

  Future<String> getProfileName(String fallback) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kProfileName) ?? fallback;
  }

  Future<String?> getProfilePhoto() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kProfilePhoto);
  }

  Future<String> getProfileBio() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kProfileBio) ??
        'Estudiante de DAM. Amante de la fotografía y el desarrollo móvil. 🚀';
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
