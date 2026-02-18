import 'package:flutter/foundation.dart';

class OwnerMeStore {
  OwnerMeStore._();
  static final OwnerMeStore I = OwnerMeStore._();

  final ValueNotifier<String?> displayName = ValueNotifier<String?>(null);

  void setName(String? name) {
    final cleaned = (name ?? '').trim();
    final normalized = cleaned.isEmpty ? null : cleaned;

    if (displayName.value == normalized) return; // no pointless rebuild
    displayName.value = normalized;
  }

  void clear() => setName(null);
}
