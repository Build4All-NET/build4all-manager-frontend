// lib/features/owner/ownerrequests/presentation/widgets/preview_phone.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/currency_model.dart';
import 'palette_builder.dart';

class PhonePreview extends StatelessWidget {
  final String appName;
  final ThemeDraft draft;
  final File? logoFile;
  final CurrencyModel? currency;

  final String navJson;
  final String homeJson;
  final String enabledFeaturesJson;
  final String brandingJson;

  const PhonePreview({
    super.key,
    required this.appName,
    required this.draft,
    required this.logoFile,
    required this.currency,
    required this.navJson,
    required this.homeJson,
    required this.enabledFeaturesJson,
    required this.brandingJson,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final navItems = _tryParseNav(navJson);
    final menuType = _tryBrandingMenuType(brandingJson); // bottom | hamburger
    final features = _tryParseFeatures(enabledFeaturesJson);
    final sections = _tryParseHome(homeJson);

    return Container(
      width: 310,
      height: 620,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(.05),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: cs.outlineVariant.withOpacity(.8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: const Color(0xFF0B1220),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: draft.background,
              child: Column(
                children: [
                  // Status bar
                  Container(
                    height: 22,
                    color: _headerBlue(draft.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(
                          "9:41",
                          style: TextStyle(
                            color: _on(_headerBlue(draft.primary)),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.signal_cellular_4_bar,
                            size: 14, color: _on(_headerBlue(draft.primary))),
                        const SizedBox(width: 6),
                        Icon(Icons.wifi,
                            size: 14, color: _on(_headerBlue(draft.primary))),
                        const SizedBox(width: 6),
                        Icon(Icons.battery_full,
                            size: 14, color: _on(_headerBlue(draft.primary))),
                      ],
                    ),
                  ),

                  // Header
                  _Header(
                    appName: appName,
                    headerColor: _headerBlue(draft.primary),
                    menuType: menuType,
                  ),

                  // Body (dynamic sections + feature row)
                  Expanded(
                    child: _Body(
                      draft: draft,
                      currency: currency,
                      features: features,
                      sections: sections,
                    ),
                  ),

                  // Bottom nav only if menuType == bottom
                  if (menuType == 'bottom')
                    _BottomNav(
                      draft: draft,
                      items: navItems.isEmpty
                          ? const [
                              _NavItem(label: 'Home', icon: Icons.home_rounded),
                              _NavItem(
                                  label: 'Explore',
                                  icon: Icons.search_rounded),
                              _NavItem(
                                  label: 'Cart',
                                  icon: Icons.shopping_cart_rounded),
                              _NavItem(
                                  label: 'Profile',
                                  icon: Icons.person_rounded),
                            ]
                          : navItems,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // Parsing helpers
  // --------------------------------------------------------------
  List<_NavItem> _tryParseNav(String navJson) {
    try {
      final d = jsonDecode(navJson);
      if (d is List) {
        return d.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          final label = (m['label'] ?? '').toString();
          final icon = (m['icon'] ?? '').toString();
          return _NavItem(
            label: label.isEmpty ? 'Tab' : label,
            icon: _icon(icon),
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  List<String> _tryParseFeatures(String enabledFeaturesJson) {
    try {
      final d = jsonDecode(enabledFeaturesJson);
      if (d is List) {
        return d.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  List<_HomeSection> _tryParseHome(String homeJson) {
    try {
      final d = jsonDecode(homeJson);
      if (d is List) {
        return d.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return _HomeSection(
            type: (m['type'] ?? '').toString(),
            layout: (m['layout'] ?? '').toString(),
            limit: int.tryParse('${m['limit']}') ?? 6,
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Returns: "bottom" or "hamburger"
  String _tryBrandingMenuType(String brandingJson) {
    try {
      final m = jsonDecode(brandingJson);
      if (m is Map) {
        final v = (m['menuType'] ?? '').toString().toLowerCase().trim();
        if (v == 'hamburger') return 'hamburger';
        if (v == 'drawer') return 'hamburger'; // backward compat
        return 'bottom';
      }
    } catch (_) {}
    return 'bottom';
  }

  IconData _icon(String raw) {
    switch (raw.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'search':
      case 'explore':
        return Icons.search_rounded;
      case 'shopping_cart':
      case 'cart':
        return Icons.shopping_cart_rounded;
      case 'person':
      case 'profile':
        return Icons.person_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  static Color _on(Color bg) =>
      bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;

  static Color _headerBlue(Color primary) {
    final lum = primary.computeLuminance();
    if (lum < 0.35) return primary;
    return const Color(0xFF0B6EA8);
  }
}

/// ===============================================================
/// Header (hamburger supported)
/// ===============================================================
class _Header extends StatelessWidget {
  final String appName;
  final Color headerColor;
  final String menuType;

  const _Header({
    required this.appName,
    required this.headerColor,
    required this.menuType,
  });

  @override
  Widget build(BuildContext context) {
    final onHeader = PhonePreview._on(headerColor);
    final isHamburger = menuType == 'hamburger';

    return Container(
      color: headerColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              if (isHamburger) ...[
                Icon(Icons.menu_rounded, color: onHeader, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onHeader,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.search_rounded, color: onHeader, size: 20),
              const SizedBox(width: 10),
              Icon(Icons.shopping_cart_outlined, color: onHeader, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.14)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    size: 18, color: onHeader.withOpacity(.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Search products...",
                    style: TextStyle(
                      color: onHeader.withOpacity(.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// Body (renders features + home sections)
/// ===============================================================
class _Body extends StatelessWidget {
  final ThemeDraft draft;
  final CurrencyModel? currency;
  final List<String> features;
  final List<_HomeSection> sections;

  const _Body({
    required this.draft,
    required this.currency,
    required this.features,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF3FAFF);
    final on = draft.onBackground;

    final money = (currency?.symbol.trim().isNotEmpty == true)
        ? currency!.symbol.trim()
        : "\$";

    final list = sections.isEmpty
        ? const [
            _HomeSection(type: 'HEADER', layout: 'FULL', limit: 1),
            _HomeSection(type: 'SEARCH', layout: 'FULL', limit: 1),
            _HomeSection(type: 'BANNER', layout: 'FULL', limit: 1),
            _HomeSection(type: 'ITEM_LIST', layout: 'HORIZONTAL', limit: 6),
          ]
        : sections;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ✅ Features row affects preview
          if (features.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in features.take(6))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: draft.primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: draft.primary.withOpacity(.35)),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: draft.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ✅ Render home sections in order
          for (final s in list) ..._renderSection(context, s, on, money),
        ],
      ),
    );
  }

  List<Widget> _renderSection(
      BuildContext context, _HomeSection s, Color on, String money) {
    switch (s.type.toUpperCase()) {
      case 'HEADER':
        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: draft.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.bolt_rounded, color: draft.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Welcome",
                    style: TextStyle(
                      color: on,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ];

      case 'SEARCH':
        return [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    size: 18, color: on.withOpacity(.6)),
                const SizedBox(width: 8),
                Text(
                  "Search...",
                  style: TextStyle(
                    color: on.withOpacity(.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ];

      case 'BANNER':
        return [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: draft.primary.withOpacity(.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: draft.primary.withOpacity(.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              "Hero Banner",
              style: TextStyle(
                color: draft.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ];

      case 'ITEM_LIST':
      default:
        return [
          Row(
            children: [
              Expanded(child: _ProductCard(draft: draft, money: money)),
              const SizedBox(width: 10),
              Expanded(child: _ProductCard(draft: draft, money: money)),
            ],
          ),
          const SizedBox(height: 12),
        ];
    }
  }
}

class _ProductCard extends StatelessWidget {
  final ThemeDraft draft;
  final String money;

  const _ProductCard({
    required this.draft,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final on = draft.onBackground;

    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 26),
              ),
            ),
          ),
          Container(height: 1, color: Colors.black.withOpacity(.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Product\nName",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: on,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${money}99.99",
                  style: TextStyle(
                    color: on.withOpacity(.85),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: draft.primary,
                      foregroundColor: PhonePreview._on(draft.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Text(
                      "Add to Cart",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom nav
class _BottomNav extends StatelessWidget {
  final ThemeDraft draft;
  final List<_NavItem> items;

  const _BottomNav({
    required this.draft,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final border = Colors.black.withOpacity(.08);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length.clamp(0, 5); i++)
            Expanded(
              child: _NavButton(
                draft: draft,
                item: items[i],
                active: i == 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final ThemeDraft draft;
  final _NavItem item;
  final bool active;

  const _NavButton({
    required this.draft,
    required this.item,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? draft.primary : Colors.black.withOpacity(.55);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(item.icon, color: fg, size: 22),
        const SizedBox(height: 4),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

class _HomeSection {
  final String type;
  final String layout;
  final int limit;

  const _HomeSection({
    required this.type,
    required this.layout,
    required this.limit,
  });
}
