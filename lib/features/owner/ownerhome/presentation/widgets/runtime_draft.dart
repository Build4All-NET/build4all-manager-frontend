import 'dart:convert';

/// ===============================================================
/// RuntimeDraft
///
/// What the owner configures under "Runtime Config".
///
/// ✅ Update:
/// - Menu Type is now:
///   - bottom       => bottom navigation
///   - hamburger    => hamburger menu (instead of "drawer")
///
/// Note:
/// - We keep backward compatibility:
///   - if old JSON contains "drawer", we treat it as "hamburger".
/// ===============================================================

enum MenuType {
  bottom,
  hamburger,
}

extension MenuTypeX on MenuType {
  String get code => switch (this) {
        MenuType.bottom => 'bottom',
        MenuType.hamburger => 'hamburger',
      };

  String get uiLabel => switch (this) {
        MenuType.bottom => 'Bottom Navigation',
        MenuType.hamburger => 'Hamburger menu',
      };

  static MenuType fromAny(dynamic v) {
    final s = (v ?? '').toString().toLowerCase().trim();
    if (s == 'hamburger') return MenuType.hamburger;

    // ✅ backward compatible
    if (s == 'drawer') return MenuType.hamburger;

    return MenuType.bottom;
  }
}

class RuntimeDraft {
  final MenuType menuType;

  /// You may already have more runtime flags/fields.
  /// Keep adding them here as needed without changing the backend contract.

  const RuntimeDraft({
    required this.menuType,
  });

  RuntimeDraft copyWith({
    MenuType? menuType,
  }) {
    return RuntimeDraft(
      menuType: menuType ?? this.menuType,
    );
  }

  /// Output container used by OwnerRequestScreen to send strings to backend
  RuntimeJsonOut toJsonOut() {
    // navJson/homeJson/enabledFeaturesJson can remain your existing logic.
    // Here we keep them minimal and stable.
    final navJson = jsonEncode([
      {"label": "Home", "icon": "home"},
      {"label": "Explore", "icon": "search"},
      {"label": "Cart", "icon": "shopping_cart"},
      {"label": "Profile", "icon": "person"},
    ]);

    final homeJson = jsonEncode({
      "sections": [
        {"code": "flash_sale"},
        {"code": "best_sellers"},
        {"code": "new_arrivals"},
      ]
    });

    final enabledFeaturesJson = jsonEncode([
      "catalog",
      "cart",
      "orders",
      "profile",
    ]);

    // ✅ IMPORTANT: brandingJson now uses "hamburger"
    // instead of "drawer".
    final brandingJson = jsonEncode({
      "menuType": menuType.code, // bottom | hamburger
    });

    return RuntimeJsonOut(
      navJson: navJson,
      homeJson: homeJson,
      enabledFeaturesJson: enabledFeaturesJson,
      brandingJson: brandingJson,
    );
  }

  /// Optional: parse from existing json if you ever load saved runtime config
  static RuntimeDraft fromBrandingJson(String brandingJson) {
    try {
      final d = jsonDecode(brandingJson);
      if (d is Map) {
        return RuntimeDraft(menuType: MenuTypeX.fromAny(d['menuType']));
      }
    } catch (_) {}
    return RuntimeDefaults.defaults();
  }
}

class RuntimeJsonOut {
  final String navJson;
  final String homeJson;
  final String enabledFeaturesJson;
  final String brandingJson;

  const RuntimeJsonOut({
    required this.navJson,
    required this.homeJson,
    required this.enabledFeaturesJson,
    required this.brandingJson,
  });
}

/// Defaults holder
class RuntimeDefaults {
  static RuntimeDraft defaults() {
    return const RuntimeDraft(
      menuType: MenuType.bottom,
    );
  }
}
