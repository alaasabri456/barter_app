import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/authentication/models/user_model.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _localeKey = 'selected_locale';

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      if (UserModel.currentUser != null) {
        UserModel.currentUser!.languageCode = languageCode;
      }
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;

    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);

    // Sync with Firestore if logged in
    final user = UserModel.currentUser;
    if (user != null) {
      user.languageCode = languageCode;
      await AuthRepository().updateUserLanguage(user.id, languageCode);
    }

    notifyListeners();
  }

  bool get isArabic => _currentLocale.languageCode == 'ar';
}
