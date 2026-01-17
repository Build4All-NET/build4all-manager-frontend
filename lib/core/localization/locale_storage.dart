import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleStorage {
  static const _key = 'app_locale_code';

  Future<Locale?> load() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_key);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> save(Locale locale) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, locale.languageCode);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
