import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import '../../data/static_project_models.dart';
import 'package:build4all_manager/shared/themes/theme_palette.dart';

class ProjectTemplateCard extends StatelessWidget {
  final ProjectTemplate tpl;
  final VoidCallback? onOpen;
  final bool isAvailable;

  const ProjectTemplateCard({
    super.key,
    required this.tpl,
    this.onOpen,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ✅ FORCE ECOMMERCE TO GYM GREEN (even if tpl.tint exists)
    final tint = (tpl.kind.toLowerCase() == 'ecommerce')
        ? ProjectPalette.gym
        : (tpl.tint ?? _pickTintFor(tpl.kind, cs));

    final mutedFg = cs.onSurface.withOpacity(isAvailable ? .72 : .45);
    final borderColor = isAvailable
        ? cs.outlineVariant.withOpacity(.60)
        : cs.outlineVariant.withOpacity(.35);

    final ctaText =
        isAvailable ? _tr(l10n, tpl.ctaKey) : l10n.owner_proj_comingSoon;

    return LayoutBuilder(
      builder: (context, c) {
        final cardW = c.maxWidth;

        // ✅ card-based responsiveness (better than screen width)
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
            onTap: onOpen, // always open details
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
                  _IconBadge(icon: tpl.icon, tint: tint, dimmed: !isAvailable),

                  SizedBox(height: compact ? 8 : 10),

                  // ✅ Title (auto-shrinks)
                  AutoSizeText(
                    _tr(l10n, tpl.titleKey),
                    style: titleStyle,
                    maxLines: 1,
                    minFontSize: compact ? 12 : 14,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: compact ? 6 : 8),

                  // ✅ Description (auto-shrinks across languages)
                  Flexible(
                    child: AutoSizeText(
                      _tr(l10n, tpl.descKey),
                      style: descStyle,
                      maxLines: descLines,
                      minFontSize: compact ? 9 : 10.5,
                      stepGranularity: 0.5,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),

                  SizedBox(height: compact ? 10 : 12),

                  // ✅ CTA button (fixed height, auto-shrinks text)
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 40 : 44,
                    child: OutlinedButton(
                      onPressed: onOpen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isAvailable ? tint : cs.onSurface.withOpacity(.55),
                        side: BorderSide(
                          color: tint.withOpacity(isAvailable ? .35 : .18),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
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

  Color _pickTintFor(String id, ColorScheme cs) {
    switch (id) {
      case 'activities':
        return ProjectPalette.activities;
      case 'ecommerce':
        return ProjectPalette.gym; // ✅ ecommerce follows gym green
      case 'gym':
        return ProjectPalette.gym;
      case 'services':
        return ProjectPalette.services;
      default:
        return cs.primary;
    }
  }

  String _tr(AppLocalizations l10n, String key) {
    switch (key) {
      case 'owner_proj_activities_title':
        return l10n.owner_proj_activities_title;
      case 'owner_proj_activities_desc':
        return l10n.owner_proj_activities_desc;

      case 'owner_proj_ecom_title':
        return l10n.owner_proj_ecom_title;
      case 'owner_proj_ecom_desc':
        return l10n.owner_proj_ecom_desc;

      case 'owner_proj_gym_title':
        return l10n.owner_proj_gym_title;
      case 'owner_proj_gym_desc':
        return l10n.owner_proj_gym_desc;

      case 'owner_proj_services_title':
        return l10n.owner_proj_services_title;
      case 'owner_proj_services_desc':
        return l10n.owner_proj_services_desc;

      case 'owner_proj_open':
        return l10n.owner_proj_open;

      default:
        return key;
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
