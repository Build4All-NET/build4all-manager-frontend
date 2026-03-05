// lib/features/owner/ownerrequests/presentation/widgets/runtime_draft.dart
import 'dart:convert';

enum MenuType { bottom, hamburger }

class NavItemDraft {
  final String id; // HOME, EXPLORE, CART, PROFILE...
  final String label; // visible label (fallback)
  final String icon; // icon key string
  final bool enabled;

  const NavItemDraft({
    required this.id,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  NavItemDraft copyWith({
    String? id,
    String? label,
    String? icon,
    bool? enabled,
  }) {
    return NavItemDraft(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
    );
  }
}

class HomeSectionDraft {
  final String id;
  final String type; // HEADER, SEARCH, BANNER, CATEGORY_CHIPS, ITEM_LIST
  final String layout; // HORIZONTAL/GRID/etc
  final int limit;
  final bool enabled;
  final String? feature; // if set => requires that feature enabled

  const HomeSectionDraft({
    required this.id,
    required this.type,
    required this.layout,
    required this.limit,
    required this.enabled,
    this.feature,
  });

  HomeSectionDraft copyWith({
    String? id,
    String? type,
    String? layout,
    int? limit,
    bool? enabled,
    String? feature,
  }) {
    return HomeSectionDraft(
      id: id ?? this.id,
      type: type ?? this.type,
      layout: layout ?? this.layout,
      limit: limit ?? this.limit,
      enabled: enabled ?? this.enabled,
      feature: feature ?? this.feature,
    );
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

class RuntimeDraft {
  final MenuType menuType;

  /// Enabled features codes (ITEMS, BOOKING, REVIEWS, ORDERS, COUPONS, NOTIFICATIONS)
  final Set<String> enabledFeatures;

  /// Navigation config for preview + submit
  final List<NavItemDraft> navItems;

  /// Home sections config for preview + submit
  final List<HomeSectionDraft> homeSections;

  const RuntimeDraft({
    required this.menuType,
    required this.enabledFeatures,
    required this.navItems,
    required this.homeSections,
  });

  RuntimeDraft copyWith({
    MenuType? menuType,
    Set<String>? enabledFeatures,
    List<NavItemDraft>? navItems,
    List<HomeSectionDraft>? homeSections,
  }) {
    return RuntimeDraft(
      menuType: menuType ?? this.menuType,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      navItems: navItems ?? this.navItems,
      homeSections: homeSections ?? this.homeSections,
    );
  }

  /// ------------------------------------------------------------
  /// NAV / FEATURE RULES
  /// ------------------------------------------------------------
  static const String navHome = "HOME";
  static const String navExplore = "EXPLORE";
  static const String navCart = "CART";
  static const String navProfile = "PROFILE";

  /// Required nav tabs (as you requested):
  /// ✅ HOME + CART + PROFILE required
  /// ❌ EXPLORE optional
  static const Set<String> requiredNavIds = {navHome, navCart, navProfile};

  /// Bottom nav limits (you ship 4 items max; required already = 3)
  static const int bottomNavMax = 4;
  static const int bottomNavMin = 3; // since HOME+CART+PROFILE are required

  /// What nav item requires what features
  /// - EXPLORE requires ITEMS
  /// - CART requires ITEMS + ORDERS
  static const Map<String, List<String>> navRequires = {
    navExplore: ["ITEMS"],
    navCart: ["ITEMS", "ORDERS"],
    navHome: [],
    navProfile: [],
  };

  static bool navIsRequired(String navId) => requiredNavIds.contains(navId);

  static List<String> navMissingFeatures(String navId, Set<String> enabled) {
    final req = navRequires[navId] ?? const <String>[];
    return req.where((f) => !enabled.contains(f)).toList();
  }

  /// Union of features required by REQUIRED nav tabs.
  /// Since CART is required => ITEMS + ORDERS become locked.
  static Set<String> requiredFeaturesForRequiredNav() {
    final out = <String>{};
    for (final navId in requiredNavIds) {
      final req = navRequires[navId] ?? const <String>[];
      out.addAll(req.map((e) => e.toUpperCase()));
    }
    return out;
  }

  static bool featureIsLocked(String featureCode) {
    return requiredFeaturesForRequiredNav().contains(featureCode.toUpperCase());
  }

  bool canEnableNav(String navId, Set<String> enabled) {
    final missing = navMissingFeatures(navId, enabled);
    return missing.isEmpty;
  }

  /// ------------------------------------------------------------
  /// NORMALIZE (the magic that prevents nonsense configs)
  /// ------------------------------------------------------------
  RuntimeDraft normalized() {
    // Start with current features
    final features = <String>{...enabledFeatures.map((e) => e.toUpperCase())};

    // 1) Force required features ON (because required nav tabs depend on them)
    features.addAll(requiredFeaturesForRequiredNav());

    // 2) NAV: force required tabs enabled
    List<NavItemDraft> nav = navItems.map((x) {
      if (navIsRequired(x.id)) return x.copyWith(enabled: true);
      return x;
    }).toList();

    // 3) NAV: disable OPTIONAL tabs if deps missing
    nav = nav.map((x) {
      if (navIsRequired(x.id)) return x;
      final missing = navMissingFeatures(x.id, features);
      if (missing.isNotEmpty) return x.copyWith(enabled: false);
      return x;
    }).toList();

    // 4) HOME SECTIONS: disable sections whose required feature is OFF
    List<HomeSectionDraft> home = homeSections.map((s) {
      final f = s.feature?.trim();
      if (f == null || f.isEmpty) return s;
      final ok = features.contains(f.toUpperCase());
      return ok ? s : s.copyWith(enabled: false);
    }).toList();

    // 5) Bottom nav min/max enforcement
    if (menuType == MenuType.bottom) {
      final enabled = nav.where((n) => n.enabled).toList();

      // Max: disable extra OPTIONAL items from end
      if (enabled.length > bottomNavMax) {
        int toDisable = enabled.length - bottomNavMax;
        for (int i = nav.length - 1; i >= 0 && toDisable > 0; i--) {
          final n = nav[i];
          if (!n.enabled) continue;
          if (navIsRequired(n.id)) continue;
          nav[i] = n.copyWith(enabled: false);
          toDisable--;
        }
      }

      // Min: ensure required count (should already be true, but keep safety)
      final enabled2 = nav.where((n) => n.enabled).toList();
      if (enabled2.length < bottomNavMin) {
        for (int i = 0; i < nav.length; i++) {
          final n = nav[i];
          if (n.enabled) continue;
          if (navIsRequired(n.id)) {
            nav[i] = n.copyWith(enabled: true);
          }
        }
      }
    }

    return copyWith(
      enabledFeatures: features,
      navItems: nav,
      homeSections: home,
    );
  }

  /// ------------------------------------------------------------
  /// EXPORT (preview + submit payload)
  /// ------------------------------------------------------------
  RuntimeJsonOut toJsonOut() {
    // Export ONLY enabled nav items
    final nav = navItems
        .where((x) => x.enabled)
        .map((x) => {
              "id": x.id,
              "label": x.label, // fallback; client should localize by id
              "icon": x.icon,
            })
        .toList();

    // Export ONLY enabled home sections
    final home = homeSections
        .where((x) => x.enabled)
        .map((x) => {
              "type": x.type,
              "layout": x.layout,
              "limit": x.limit,
              if (x.feature != null) "feature": x.feature,
            })
        .toList();

    // Export enabled features list
    final features = enabledFeatures.toList()..sort();

    final branding = {
      "menuType": menuType == MenuType.hamburger ? "hamburger" : "bottom",
    };

    return RuntimeJsonOut(
      navJson: jsonEncode(nav),
      homeJson: jsonEncode(home),
      enabledFeaturesJson: jsonEncode(features),
      brandingJson: jsonEncode(branding),
    );
  }
}

class RuntimeDefaults {
  static RuntimeDraft defaults() {
    // Default config is already valid.
    // normalized() will lock ITEMS+ORDERS ON because CART is required.
    return RuntimeDraft(
      menuType: MenuType.bottom,
      enabledFeatures: {
        "ITEMS",
        "BOOKING",
        "REVIEWS",
        "ORDERS",
        "COUPONS",
        "NOTIFICATIONS",
      },
      navItems: const [
        NavItemDraft(id: "HOME", label: "Home", icon: "home", enabled: true),
        NavItemDraft(id: "EXPLORE", label: "Explore", icon: "search", enabled: true),
        NavItemDraft(id: "CART", label: "Cart", icon: "cart", enabled: true),
        NavItemDraft(id: "PROFILE", label: "Profile", icon: "profile", enabled: true),
      ],
      homeSections: const [
        HomeSectionDraft(
          id: "HEADER",
          type: "HEADER",
          layout: "FULL",
          limit: 1,
          enabled: true,
        ),
        HomeSectionDraft(
          id: "SEARCH",
          type: "SEARCH",
          layout: "FULL",
          limit: 1,
          enabled: true,
        ),
        HomeSectionDraft(
          id: "BANNER",
          type: "BANNER",
          layout: "FULL",
          limit: 1,
          enabled: true,
        ),
        HomeSectionDraft(
          id: "CATEGORY_CHIPS",
          type: "CATEGORY_CHIPS",
          layout: "HORIZONTAL",
          limit: 8,
          enabled: true,
        ),
        HomeSectionDraft(
          id: "ITEM_LIST",
          type: "ITEM_LIST",
          layout: "HORIZONTAL",
          limit: 10,
          enabled: true,
          feature: "ITEMS",
        ),
      ],
    ).normalized(); // ✅ ensure locks applied from day 1
  }
}

extension MenuTypeUi on MenuType {
  String get uiLabel => this == MenuType.hamburger ? "Hamburger" : "Bottom";
}