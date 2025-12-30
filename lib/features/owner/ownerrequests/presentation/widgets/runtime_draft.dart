import 'dart:convert';

enum MenuType { bottom, hamburger }

class NavItemDraft {
  final String id;
  final String label;
  final String icon; // "home" | "search" | "cart" | "profile" | ...
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
  final String id; // internal only (we will hide in UI)
  final String type; // HEADER/BANNER/ITEM_LIST...
  final String layout; // carousel/grid/hero...
  final String? feature; // optional: ITEMS/BOOKING...
  final int limit;
  final bool enabled;

  const HomeSectionDraft({
    required this.id,
    required this.type,
    required this.layout,
    this.feature,
    required this.limit,
    required this.enabled,
  });

  HomeSectionDraft copyWith({
    String? id,
    String? type,
    String? layout,
    String? feature,
    int? limit,
    bool? enabled,
  }) {
    return HomeSectionDraft(
      id: id ?? this.id,
      type: type ?? this.type,
      layout: layout ?? this.layout,
      feature: feature ?? this.feature,
      limit: limit ?? this.limit,
      enabled: enabled ?? this.enabled,
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

  // Branding flags (still in payload even if preview doesn't use them)
  final String splashMode;
  final bool showSearchOnExplore;

  final Set<String> enabledFeatures;
  final List<NavItemDraft> navItems;
  final List<HomeSectionDraft> homeSections;

  const RuntimeDraft({
    required this.menuType,
    required this.splashMode,
    required this.showSearchOnExplore,
    required this.enabledFeatures,
    required this.navItems,
    required this.homeSections,
  });

  RuntimeDraft copyWith({
    MenuType? menuType,
    String? splashMode,
    bool? showSearchOnExplore,
    Set<String>? enabledFeatures,
    List<NavItemDraft>? navItems,
    List<HomeSectionDraft>? homeSections,
  }) {
    return RuntimeDraft(
      menuType: menuType ?? this.menuType,
      splashMode: splashMode ?? this.splashMode,
      showSearchOnExplore: showSearchOnExplore ?? this.showSearchOnExplore,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      navItems: navItems ?? this.navItems,
      homeSections: homeSections ?? this.homeSections,
    );
  }

  /// ✅ IMPORTANT:
  /// - navJson will contain ONLY enabled items so that uncheck => disappears from preview menu.
  /// - brandingJson will output menuType as "bottom" or "hamburger"
  RuntimeJsonOut toJsonOut() {
    final enabledNav = navItems.where((e) => e.enabled).toList();

    final navJson = jsonEncode(
      enabledNav
          .map((e) => {
                "id": e.id,
                "label": e.label,
                "icon": e.icon,
              })
          .toList(),
    );

    final brandingJson = jsonEncode({
      "menuType": menuType == MenuType.bottom ? "bottom" : "hamburger",
      "splashMode": splashMode,
      "showSearchOnExplore": showSearchOnExplore,
    });

    final enabledFeaturesJson = jsonEncode(enabledFeatures.toList());

    final enabledHome = homeSections.where((s) => s.enabled).toList();
    final homeJson = jsonEncode({
      "sections": enabledHome
          .map((s) => {
                "type": s.type,
                "layout": s.layout,
                "feature": s.feature,
                "limit": s.limit,
              })
          .toList()
    });

    return RuntimeJsonOut(
      navJson: navJson,
      homeJson: homeJson,
      enabledFeaturesJson: enabledFeaturesJson,
      brandingJson: brandingJson,
    );
  }
}

class RuntimeDefaults {
  static RuntimeDraft defaults() {
    return RuntimeDraft(
      menuType: MenuType.bottom,
      splashMode: "auto",
      showSearchOnExplore: true,
      enabledFeatures: {"ITEMS", "BOOKING", "REVIEWS", "ORDERS"},
      navItems: const [
        NavItemDraft(
          id: "HOME",
          label: "Home",
          icon: "home",
          enabled: true,
        ),
        NavItemDraft(
          id: "EXPLORE",
          label: "Explore",
          icon: "search",
          enabled: true,
        ),
        NavItemDraft(
          id: "CART",
          label: "Cart",
          icon: "cart",
          enabled: true,
        ),
        NavItemDraft(
          id: "PROFILE",
          label: "Profile",
          icon: "profile",
          enabled: true,
        ),
      ],
      homeSections: const [
        HomeSectionDraft(
          id: "S1",
          type: "BANNER",
          layout: "hero",
          feature: null,
          limit: 3,
          enabled: true,
        ),
        HomeSectionDraft(
          id: "S2",
          type: "ITEM_LIST",
          layout: "carousel",
          feature: "ITEMS",
          limit: 10,
          enabled: true,
        ),
        HomeSectionDraft(
          id: "S3",
          type: "CATEGORY_CHIPS",
          layout: "chips",
          feature: null,
          limit: 8,
          enabled: true,
        ),
      ],
    );
  }
}
