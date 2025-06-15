import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<void> saveThemeMode(ThemeMode themeMode) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('themeMode', themeMode.toString());
}

Future<ThemeMode> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString('themeMode') ?? 'ThemeMode.light';
  return ThemeMode.values.firstWhere(
    (mode) => mode.toString() == themeModeString,
    orElse: () => ThemeMode.light,
  );
}
