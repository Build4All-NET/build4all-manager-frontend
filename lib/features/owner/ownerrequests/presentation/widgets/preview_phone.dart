import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/currency_model.dart';
import 'palette_builder.dart';

/// ===============================================================
/// PhonePreview (Figma-exact)
///
/// ✅ Update:
/// - Menu Type:
///   - bottom     => bottom navigation visible
///   - hamburger  => show hamburger icon in header + hide bottom nav
///
/// Backward compatibility:
/// - If brandingJson has menuType="drawer", we treat it as hamburger.
/// ===============================================================
class PhonePreview extends StatefulWidget {
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
  State<PhonePreview> createState() => _PhonePreviewState();

  static Color _on(Color bg) =>
      bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;

  static Color _headerBlue(Color primary) {
    final lum = primary.computeLuminance();
    if (lum < 0.35) return primary;
    return const Color(0xFF0B6EA8);
  }
}

class _PhonePreviewState extends State<PhonePreview> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final navItems = _tryParseNav(widget.navJson);
    final menuType = _tryBrandingMenuType(widget.brandingJson); // bottom | hamburger

    // safety: if nav count changes because you disabled items
    final items = navItems.isEmpty
        ? const [
            _NavItem(label: 'Home', icon: Icons.home_rounded),
            _NavItem(label: 'Explore', icon: Icons.search_rounded),
            _NavItem(label: 'Cart', icon: Icons.shopping_cart_rounded),
            _NavItem(label: 'Profile', icon: Icons.person_rounded),
          ]
        : navItems;

    if (_index >= items.length) _index = 0;

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
              color: widget.draft.background,
              child: Column(
                children: [
                  // Status bar
                  Container(
                    height: 22,
                    color: PhonePreview._headerBlue(widget.draft.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(
                          "9:41",
                          style: TextStyle(
                            color: PhonePreview._on(
                                PhonePreview._headerBlue(widget.draft.primary)),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.signal_cellular_4_bar,
                            size: 14,
                            color: PhonePreview._on(
                                PhonePreview._headerBlue(widget.draft.primary))),
                        const SizedBox(width: 6),
                        Icon(Icons.wifi,
                            size: 14,
                            color: PhonePreview._on(
                                PhonePreview._headerBlue(widget.draft.primary))),
                        const SizedBox(width: 6),
                        Icon(Icons.battery_full,
                            size: 14,
                            color: PhonePreview._on(
                                PhonePreview._headerBlue(widget.draft.primary))),
                      ],
                    ),
                  ),

                  // Header (App name + icons + search) + ✅ hamburger icon support
                  _Header(
                    appName: widget.appName,
                    headerColor: PhonePreview._headerBlue(widget.draft.primary),
                    menuType: menuType,
                  ),

                  // Content
                  Expanded(
                    child: _Body(
                      draft: widget.draft,
                      currency: widget.currency,
                    ),
                  ),

                  // Bottom nav only if menuType == bottom
                  if (menuType == 'bottom')
                    _BottomNav(
                      draft: widget.draft,
                      items: items,
                      index: _index,
                      onTap: (i) => setState(() => _index = i),
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

  /// Returns: "bottom" or "hamburger"
  String _tryBrandingMenuType(String brandingJson) {
    try {
      final m = jsonDecode(brandingJson);
      if (m is Map) {
        final v = (m['menuType'] ?? '').toString().toLowerCase().trim();

        if (v == 'hamburger') return 'hamburger';
        if (v == 'drawer') return 'hamburger'; // backward compatible

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
}

/// ===============================================================
/// Header (App name + icons + search)
/// - If menuType == hamburger => show hamburger icon
/// ===============================================================
class _Header extends StatelessWidget {
  final String appName;
  final Color headerColor;
  final String menuType; // bottom | hamburger

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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.shopping_cart_outlined, color: onHeader, size: 20),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        "1",
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
/// Body (same as before)
/// ===============================================================
class _Body extends StatelessWidget {
  final ThemeDraft draft;
  final CurrencyModel? currency;

  const _Body({
    required this.draft,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF3FAFF);
    final on = draft.onBackground;

    final money = (currency?.symbol?.trim().isNotEmpty == true)
        ? currency!.symbol.trim()
        : "\$";

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Flash Sale",
                        style: TextStyle(
                          color: on,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Up to 50% Off",
                        style: TextStyle(
                          color: on.withOpacity(.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Ends in",
                      style: TextStyle(
                        color: on.withOpacity(.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "24:53:30",
                      style: TextStyle(
                        color: draft.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SectionRow(
            title: "Best Sellers",
            onTapText: "View All",
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 10),
          const _SectionRow(
            title: "New Arrivals",
            onTapText: "View All",
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ProductCard(draft: draft, money: money)),
              const SizedBox(width: 10),
              Expanded(child: _ProductCard(draft: draft, money: money)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(.06)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TrustItem(icon: Icons.local_shipping_outlined, text: "Free Ship"),
                _TrustItem(icon: Icons.verified_user_outlined, text: "Secure"),
                _TrustItem(icon: Icons.history_rounded, text: "30-Day Return"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final String onTapText;
  final IconData icon;

  const _SectionRow({
    required this.title,
    required this.onTapText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        Text(
          onTapText,
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
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
            child: Stack(
              children: [
                Center(
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
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      "Low Stock",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
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

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
        ),
      ],
    );
  }
}

/// ===============================================================
/// Bottom Navigation (interactive)
/// ===============================================================
class _BottomNav extends StatelessWidget {
  final ThemeDraft draft;
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.draft,
    required this.items,
    required this.index,
    required this.onTap,
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
              child: InkWell(
                onTap: () => onTap(i),
                child: _NavButton(
                  draft: draft,
                  item: items[i],
                  active: i == index,
                ),
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
