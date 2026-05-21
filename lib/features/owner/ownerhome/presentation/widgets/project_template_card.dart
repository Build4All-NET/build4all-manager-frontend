import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import '../../domain/entities/backend_project.dart';
import 'package:build4all_manager/shared/themes/theme_palette.dart';

class ProjectTemplateCard extends StatelessWidget {
  final BackendProject project;
  final VoidCallback? onOpen;
  final bool isAvailable;

  const ProjectTemplateCard({
    super.key,
    required this.project,
    this.onOpen,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final tint = _resolveTint(project, cs);
    final title = project.displayTitle?.isNotEmpty == true
        ? project.displayTitle!
        : (project.name.isNotEmpty ? project.name : project.projectType ?? '');
    final desc = project.displayDescription?.isNotEmpty == true
        ? project.displayDescription!
        : project.description;

    final mutedFg = cs.onSurface.withOpacity(isAvailable ? .72 : .45);
    final borderColor = isAvailable
        ? cs.outlineVariant.withOpacity(.60)
        : cs.outlineVariant.withOpacity(.35);

    final ctaText =
        isAvailable ? l10n.owner_proj_open : l10n.owner_proj_comingSoon;

    return LayoutBuilder(
      builder: (context, c) {
        final cardW = c.maxWidth;
        final compact = cardW < 190;
        final comfy = cardW >= 230;
        final pad = compact ? 12.0 : (comfy ? 16.0 : 14.0);

        final titleStyle = (compact ? tt.titleSmall : tt.titleMedium)?.copyWith(
          fontWeight: FontWeight.w800,
          color: isAvailable ? cs.onSurface : cs.onSurface.withOpacity(.75),
          height: 1.1,
        );

        final descStyle = tt.bodySmall?.copyWith(
          color: mutedFg,
          height: compact ? 1.18 : 1.25,
        );

        final descLines = compact ? 2 : (comfy ? 4 : 3);

        return Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onOpen,
            child: Container(
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(
                    icon: _resolveIcon(project.iconName, project.projectType),
                    tint: tint,
                    dimmed: !isAvailable,
                  ),
                  SizedBox(height: compact ? 8 : 10),

                  AutoSizeText(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    minFontSize: compact ? 12 : 14,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: compact ? 6 : 8),

                  Flexible(
                    child: AutoSizeText(
                      desc,
                      style: descStyle,
                      maxLines: descLines,
                      minFontSize: compact ? 9 : 10.5,
                      stepGranularity: 0.5,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),

                  SizedBox(height: compact ? 10 : 12),

                  SizedBox(
                    width: double.infinity,
                    height: compact ? 40 : 44,
                    child: OutlinedButton(
                      onPressed: onOpen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isAvailable
                            ? tint
                            : cs.onSurface.withOpacity(.55),
                        side: BorderSide(
                          color: tint.withOpacity(isAvailable ? .35 : .18),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: (compact ? tt.bodySmall : tt.bodyMedium)
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: AutoSizeText(
                        '$ctaText →',
                        maxLines: 1,
                        minFontSize: compact ? 10 : 11.5,
                        stepGranularity: 0.5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _resolveTint(BackendProject p, ColorScheme cs) {
    // Backend-supplied hex takes highest priority
    final hex = p.cardColor;
    if (hex != null && hex.isNotEmpty) {
      final parsed = _parseHex(hex);
      if (parsed != null) return parsed;
    }
    return _pickTintForType(p.projectType, cs);
  }

  Color? _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
      if (clean.length == 8) return Color(int.parse(clean, radix: 16));
    } catch (_) {}
    return null;
  }

  Color _pickTintForType(String? type, ColorScheme cs) {
    switch ((type ?? '').toUpperCase()) {
      case 'ACTIVITIES':
      case 'ACTIVITY':
        return ProjectPalette.activities;
      case 'ECOMMERCE':
      case 'E_COMMERCE':
        return ProjectPalette.gym;
      case 'GYM':
      case 'FITNESS':
        return const Color(0xFFF59E0B);
      case 'SERVICES':
      case 'SERVICE':
        return ProjectPalette.services;
      case 'WHOLESALE':
      case 'WHOLE_SALE':
        return const Color(0xFF2563EB);
      case 'MUNICIPALITY':
      case 'MUNICIPAL':
        return const Color(0xFF7C3AED);
      default:
        return cs.primary;
    }
  }

  IconData _resolveIcon(String? iconName, String? projectType) {
    if (iconName != null && iconName.isNotEmpty) {
      final mapped = _iconMap[iconName.trim().toLowerCase()];
      if (mapped != null) return mapped;
    }
    return _defaultIconForType(projectType);
  }

  static const Map<String, IconData> _iconMap = {
    'shopping_bag_rounded': Icons.shopping_bag_rounded,
    'shopping_cart_rounded': Icons.shopping_cart_rounded,
    'store_rounded': Icons.store_rounded,
    'fitness_center_rounded': Icons.fitness_center_rounded,
    'sports_gymnastics': Icons.sports_gymnastics,
    'inventory_2_rounded': Icons.inventory_2_rounded,
    'warehouse_rounded': Icons.warehouse_rounded,
    'location_city_rounded': Icons.location_city_rounded,
    'account_balance_rounded': Icons.account_balance_rounded,
    'event_rounded': Icons.event_rounded,
    'local_activity_rounded': Icons.local_activity_rounded,
    'miscellaneous_services_rounded': Icons.miscellaneous_services_rounded,
    'construction_rounded': Icons.construction_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'medical_services_rounded': Icons.medical_services_rounded,
    'school_rounded': Icons.school_rounded,
    'apps_rounded': Icons.apps_rounded,
  };

  IconData _defaultIconForType(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'ECOMMERCE':
      case 'E_COMMERCE':
        return Icons.shopping_bag_rounded;
      case 'GYM':
      case 'FITNESS':
        return Icons.fitness_center_rounded;
      case 'WHOLESALE':
      case 'WHOLE_SALE':
        return Icons.inventory_2_rounded;
      case 'MUNICIPALITY':
      case 'MUNICIPAL':
        return Icons.location_city_rounded;
      case 'ACTIVITIES':
      case 'ACTIVITY':
        return Icons.local_activity_rounded;
      case 'SERVICES':
      case 'SERVICE':
        return Icons.miscellaneous_services_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final bool dimmed;

  const _IconBadge({
    required this.icon,
    required this.tint,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = tint.withOpacity(dimmed ? .06 : .12);
    final fg = dimmed ? tint.withOpacity(.45) : tint;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Icon(icon, size: 22, color: fg),
    );
  }
}
