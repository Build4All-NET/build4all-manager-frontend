import 'package:flutter/foundation.dart';

class OwnerMeStore {
  OwnerMeStore._();

  static final OwnerMeStore I = OwnerMeStore._();

  final ValueNotifier<String?> displayName = ValueNotifier<String?>(null);

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  bool _looksLikeUsernameOrEmail(String value) {
    final s = value.trim();

    if (s.isEmpty) return true;
    if (_isEmail(s)) return true;
    if (s.startsWith('@')) return true;

    if (s.contains('_')) return true;
    if (s.contains('.')) return true;
    if (s.contains('-')) return true;
    if (RegExp(r'\d').hasMatch(s)) return true;

    final lower = s.toLowerCase();

    if (lower.contains('owner')) return true;
    if (lower.contains('admin')) return true;
    if (lower.contains('user')) return true;
    if (lower.contains('manager')) return true;
    if (lower.contains('build4all')) return true;

    return false;
  }

  String _firstNameOnly(String? raw) {
    final value = (raw ?? '').trim();

    if (value.isEmpty) return '';
    if (_looksLikeUsernameOrEmail(value)) return '';

    return value.split(RegExp(r'\s+')).first.trim();
  }

  void setName(String? name) {
    final safeFirstName = _firstNameOnly(name);
    final normalized = safeFirstName.isEmpty ? null : safeFirstName;

    if (displayName.value == normalized) return;

    displayName.value = normalized;
  }

  void clear() {
    setName(null);
  }
}