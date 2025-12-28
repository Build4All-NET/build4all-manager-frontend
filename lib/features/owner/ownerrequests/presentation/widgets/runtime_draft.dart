import 'dart:convert';

enum MenuType { bottom, drawer }

class RuntimeDraft {
  final MenuType menuType;

  final List<NavItemDraft> navItems;
  final List<HomeSectionDraft> homeSections;
  final Set<String> enabledFeatures;

  final String splashMode; // "auto" | "light" | "dark"
  final bool showSearchOnExplore; // example of extra branding/runtime flags

  const RuntimeDraft({
    required this.menuType,
    required this.navItems,
    required this.homeSections,
    required this.enabledFeatures,
    required this.splashMode,
    required this.showSearchOnExplore,
  });

  RuntimeDraft copyWith({
    MenuType? menuType,
    List<NavItemDraft>? navItems,
    List<HomeSectionDraft>? homeSections,
    Set<String>? enabledFeatures,
    String? splashMode,
    bool? showSearchOnExplore,
  }) {
    return RuntimeDraft(
      menuType: menuType ?? this.menuType,
      navItems: navItems ?? this.navItems,
      homeSections: homeSections ?? this.homeSections,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      splashMode: splashMode ?? this.splashMode,
      showSearchOnExplore: showSearchOnExplore ?? this.showSearchOnExplore,
    );
  }

  /// ✅ Build the 4 JSON strings for backend
  RuntimeJsonOut toJsonOut() {
    final navJson = jsonEncode(navItems.map((e) => e.toJson()).toList());

    final homeJson = jsonEncode({
      "sections": homeSections.map((e) => e.toJson()).toList(),
    });

    final enabledJson = jsonEncode(enabledFeatures.toList()..sort());

    final brandingJson = jsonEncode({
      "splashColor": "#FFFFFF", // keep current behavior
      "menuType": menuType.name, // bottom/drawer
      "splashMode": splashMode,
      "showSearchOnExplore": showSearchOnExplore,
    });

    return RuntimeJsonOut(
      navJson: navJson,
      homeJson: homeJson,
      enabledFeaturesJson: enabledJson,
      brandingJson: brandingJson,
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

class NavItemDraft {
  final String id;
  final String label;
  final String icon;
  final bool enabled;

  const NavItemDraft({
    required this.id,
    required this.label,
    required this.icon,
    this.enabled = true,
  });

  NavItemDraft copyWith({bool? enabled}) {
    return NavItemDraft(
      id: id,
      label: label,
      icon: icon,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "label": label,
        "icon": icon,
      };
}

class HomeSectionDraft {
  final String id;
  final String type;
  final String layout;
  final int limit;
  final bool enabled;
  final String? feature;

  const HomeSectionDraft({
    required this.id,
    required this.type,
    required this.layout,
    required this.limit,
    this.enabled = true,
    this.feature,
  });

  HomeSectionDraft copyWith({bool? enabled, int? limit}) {
    return HomeSectionDraft(
      id: id,
      type: type,
      layout: layout,
      limit: limit ?? this.limit,
      enabled: enabled ?? this.enabled,
      feature: feature,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "layout": layout,
        "limit": limit,
        if (feature != null) "feature": feature,
      };
}

class RuntimeDefaults {
  static RuntimeDraft defaults() {
    return RuntimeDraft(
      menuType: MenuType.bottom,
      navItems: const [
        NavItemDraft(id: "home", label: "Home", icon: "home"),
        NavItemDraft(id: "explore", label: "Explore", icon: "search"),
        NavItemDraft(id: "cart", label: "Cart", icon: "shopping_cart"),
        NavItemDraft(id: "profile", label: "Profile", icon: "person"),
      ],
      homeSections: const [
        HomeSectionDraft(
            id: "header", type: "HEADER", layout: "full", limit: 1),
        HomeSectionDraft(
            id: "search", type: "SEARCH", layout: "full", limit: 1),
        HomeSectionDraft(
            id: "hero_banner", type: "BANNER", layout: "full", limit: 1),
        HomeSectionDraft(
          id: "categories",
          type: "CATEGORY_CHIPS",
          layout: "horizontal",
          limit: 10,
        ),
        HomeSectionDraft(
          id: "flash_sale",
          type: "ITEM_LIST",
          layout: "horizontal",
          limit: 10,
          feature: "ITEMS",
        ),
      ],
      enabledFeatures: {"ITEMS", "BOOKING", "REVIEWS", "ORDERS"},
      splashMode: "auto",
      showSearchOnExplore: true,
    );
  }
}
