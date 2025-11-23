
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager {
  static late SharedPreferences prefs;


  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static saveTheme(ThemeMode themeMode) {
    String savedTheme = themeMode == ThemeMode.light ? "Light" : "Dark";
    prefs.setString("savedTheme", savedTheme);
  }

  static ThemeMode? getSavedTheme() {
    String? savedTheme = prefs.getString("savedTheme");
    if (savedTheme == "Light") {
      return ThemeMode.light;
    }
    if (savedTheme == "Dark") {
      return ThemeMode.dark;
    }
    return null;
  }
}