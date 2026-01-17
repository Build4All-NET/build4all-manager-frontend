import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_storage.dart';

class LocaleCubit extends Cubit<Locale?> {
  final LocaleStorage storage;

  LocaleCubit(this.storage) : super(null);

  Future<void> loadSavedLocale() async {
    final saved = await storage.load();
    emit(saved);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await storage.clear();
      emit(null);
      return;
    }

    // only allow ar/en/fr
    const allowed = ['ar', 'en', 'fr'];
    if (!allowed.contains(locale.languageCode)) return;

    await storage.save(locale);
    emit(locale);
  }
}
