// lib/features/owner/ownerrequests/presentation/widgets/runtime_draft.dart
import 'dart:convert';

enum MenuType { bottom, hamburger }

class NavItemDraft {
  final String id; // internal key (HOME, EXPLORE...)
  final String label; // visible label
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
  final String id; // internal key
  final String type; // HEADER, SEARCH, BANNER, CATEGORY_CHIPS, ITEM_LIST
  final String layout; // HORIZONTAL/GRID/etc
  final int limit;
  final bool enabled;
  final String? feature;

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

  /// Set of enabled feature codes (ITEMS, BOOKING, REVIEWS, ORDERS, COUPONS, NOTIFICATIONS)
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

  RuntimeJsonOut toJsonOut() {
    // ✅ Only enabled nav items are exported -> affects preview bottom nav
    final nav = navItems
        .where((x) => x.enabled)
        .map((x) => {
              "id": x.id,
              "label": x.label,
              "icon": x.icon,
            })
        .toList();

    // ✅ Only enabled home sections are exported -> affects preview
    final home = homeSections
        .where((x) => x.enabled)
        .map((x) => {
              "type": x.type,
              "layout": x.layout,
              "limit": x.limit,
              if (x.feature != null) "feature": x.feature,
            })
        .toList();

    // ✅ Export enabled features list
    final features = enabledFeatures.toList()..sort();

    // ✅ BrandingJson is used by PhonePreview for menuType
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
        NavItemDraft(
            id: "EXPLORE", label: "Explore", icon: "search", enabled: true),
        NavItemDraft(id: "CART", label: "Cart", icon: "cart", enabled: true),
        NavItemDraft(
            id: "PROFILE", label: "Profile", icon: "profile", enabled: true),
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
    );
  }
}

extension MenuTypeUi on MenuType {
  String get uiLabel => this == MenuType.hamburger ? "Hamburger" : "Bottom";
}
