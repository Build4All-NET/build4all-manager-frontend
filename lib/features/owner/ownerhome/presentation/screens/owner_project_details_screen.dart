import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/shared/themes/theme_palette.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../data/static_project_models.dart';
import '../specs/project_details_specs.dart';

class OwnerProjectDetailsScreen extends StatelessWidget {
  final ProjectTemplate tpl;
  final int ownerId;

  const OwnerProjectDetailsScreen({
    super.key,
    required this.tpl,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ux = Theme.of(context).extension<UiTokens>()!;
    final width = MediaQuery.of(context).size.width;

    final kind = tpl.kind.toLowerCase();
    final spec = themedSpecFor(context, kind);

    // ✅ Force ecommerce => gym green everywhere
    final tint =
        (kind == 'ecommerce') ? ProjectPalette.gym : (tpl.tint ?? spec.accent);

    final projectTitle = _projectTitle(tpl, l10n);

    final pagePad = width >= 480
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
        : ux.pagePad;

    final radiusLg = ux.radiusLg;
    final radiusMd = ux.radiusMd;

    final String? initialAppName = _prefillName(kind);

    final extra = GoRouterState.of(context).extra;

    final bool canRequest = (extra is Map && extra['canRequest'] is bool)
        ? extra['canRequest'] as bool
        : false;

    final int? initialProjectId = (extra is Map && extra['projectId'] is int)
        ? extra['projectId'] as int
        : null;

    final isSmall = width < 380;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _AutoShrinkText(
          projectTitle,
          maxLines: 1,
          minFontSize: 14,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  pagePad.horizontal / 2,
                  pagePad.vertical,
                  pagePad.horizontal / 2,
                  0,
                ),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tint, tint.withOpacity(.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(radiusLg + 4),
                  boxShadow: ux.cardShadow,
                ),
                child: DefaultTextStyle(
                  style: GoogleFonts.inter(color: Colors.white, height: 1.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          spec.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ✅ NO MORE "..." — shrink instead
                      _AutoShrinkText(
                        spec.headline(l10n),
                        maxLines: 3,
                        minFontSize: 16,
                        style: GoogleFonts.inter(
                          fontSize: isSmall ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _AutoShrinkText(
                        spec.subhead(l10n),
                        maxLines: 4,
                        minFontSize: 11,
                        style: GoogleFonts.inter(
                          fontSize: isSmall ? 13 : 14,
                          color: Colors.white.withOpacity(.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Stats row removed (COMMENTED OUT as requested)
            /*
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.horizontal / 2,
                  14,
                  pagePad.horizontal / 2,
                  0,
                ),
                child: _StatsRow(spec: spec, radius: radiusLg),
              ),
            ),
            */

            // CTA
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.horizontal / 2,
                  14,
                  pagePad.horizontal / 2,
                  0,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(radiusLg),
                  onTap: () {
                    if (!canRequest ||
                        initialProjectId == null ||
                        initialProjectId <= 0) {
                      AppToast.info(context, l10n.owner_proj_comingSoon);
                      return;
                    }

                    AppToast.success(context, l10n.owner_proj_open);

                    context.push(
                      '/owner/requests',
                      extra: {
                        'projectId': initialProjectId,
                        'appName': initialAppName,
                      },
                    );
                  },
                  child: _CreateCtaCard(
                    spec: spec,
                    radius: radiusLg,
                    tint: tint,
                  ),
                ),
              ),
            ),

            // Highlights
            // ✅ Highlights (compact horizontal scroll)
            _SectionTitle(
              padH: pagePad.horizontal / 2,
              title: spec.i18nHighlights(l10n),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44, // ✅ compact
                child: ListView.separated(
                  padding:
                      EdgeInsets.symmetric(horizontal: pagePad.horizontal / 2),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: spec.highlights(l10n).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final txt = spec.highlights(l10n)[i];
                    return _ChipPill(
                      text: txt,
                      bg: tint.withOpacity(.10),
                      fg: tint,
                    );
                  },
                ),
              ),
            ),

            // ✅ Screens & flows (horizontal scroll, 2 visible, tap opens details)
            _SectionTitle(
              padH: pagePad.horizontal / 2,
              title: spec.i18nScreens(l10n),
            ),
            _ScreensFlowCarousel(
              items: spec.screens(l10n),
              padH: pagePad.horizontal / 2,
              radius: radiusMd + 2,
              tint: tint,
            ),

            // Modules
            // ✅ Modules (show 3 only + View all bottom sheet)
            _SectionTitle(
              padH: pagePad.horizontal / 2,
              title: spec.i18nModules(l10n),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.horizontal / 2,
                  0,
                  pagePad.horizontal / 2,
                  0,
                ),
                child: _ModulesPreview(
                  modules: spec.modules(l10n),
                  radius: radiusMd,
                  tint: tint,
                  viewAllLabel: l10n.owner_home_viewAll, // ✅ reuse existing key
                ),
              ),
            ),

            // Insights
            _SectionTitle(
              padH: pagePad.horizontal / 2,
              title: spec.i18nWhy(l10n),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.horizontal / 2,
                  0,
                  pagePad.horizontal / 2,
                  20,
                ),
                child: Column(
                  children: spec.insights(l10n).map((i) {
                    return _InsightCard(
                      emoji: i.emoji,
                      text: i.text,
                      bubble: tint,
                      radius: radiusMd,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Screens & flows carousel ---------------- */

class _ScreensFlowCarousel extends StatelessWidget {
  final List<MiniScreen> items;
  final double padH;
  final double radius;
  final Color tint;

  const _ScreensFlowCarousel({
    required this.items,
    required this.padH,
    required this.radius,
    required this.tint,
  });

  void _open(BuildContext context, MiniScreen s) {
    final cs = Theme.of(context).colorScheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ux.radiusLg + 6),
        ),
      ),
      builder: (_) => _FlowDetailsSheet(
        screen: s,
        tint: tint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 150,
        child: LayoutBuilder(
          builder: (ctx, c) {
            const spacing = 12.0;

            // ✅ 2 cards visible at a time
            final available = c.maxWidth - (padH * 2) - spacing;
            final cardW = (available / 2).clamp(140.0, 9999.0);

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: padH),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: spacing),
              itemBuilder: (_, i) {
                final s = items[i];

                return SizedBox(
                  width: cardW,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius),
                    onTap: () => _open(context, s),
                    child: _MiniScreenCard(
                      title: s.title,
                      subtitle: s.subtitle,
                      bg: s.bg,
                      radius: radius,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FlowDetailsSheet extends StatelessWidget {
  final MiniScreen screen;
  final Color tint;

  const _FlowDetailsSheet({
    required this.screen,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ux.pagePad.horizontal / 2,
        10,
        ux.pagePad.horizontal / 2,
        20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.layers_rounded, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  screen.title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            screen.subtitle,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(.80),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- helpers ---------------- */

String? _prefillName(String id) {
  switch (id) {
    case 'activities':
      return 'My Activities App';
    case 'ecommerce':
      return 'My Shop';
    case 'gym':
      return 'My Gym App';
    case 'services':
      return 'My Services App';
    default:
      return null;
  }
}

String _projectTitle(ProjectTemplate tpl, AppLocalizations l10n) {
  switch (tpl.titleKey) {
    case 'owner_proj_activities_title':
      return l10n.owner_proj_activities_title;
    case 'owner_proj_ecom_title':
      return l10n.owner_proj_ecom_title;
    case 'owner_proj_gym_title':
      return l10n.owner_proj_gym_title;
    case 'owner_proj_services_title':
      return l10n.owner_proj_services_title;
    default:
      return tpl.titleKey;
  }
}

/* ---------------- auto shrink text ---------------- */

class _AutoShrinkText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final double minFontSize;

  const _AutoShrinkText(
    this.text, {
    required this.style,
    required this.maxLines,
    required this.minFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.maxWidth;
        final dir = Directionality.of(ctx);

        double fontSize = style.fontSize ?? 14;
        TextStyle s = style;

        for (int i = 0; i < 30; i++) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: s),
            maxLines: maxLines,
            textDirection: dir,
          )..layout(maxWidth: maxWidth);

          if (!tp.didExceedMaxLines) break;

          if (fontSize <= minFontSize) {
            fontSize = minFontSize;
            s = style.copyWith(fontSize: fontSize);
            break;
          }

          fontSize = (fontSize - 0.8).clamp(minFontSize, 999);
          s = style.copyWith(fontSize: fontSize);
        }

        return Text(
          text,
          style: s,
          maxLines: maxLines,
          softWrap: true,
          overflow: TextOverflow.clip, // ✅ no "..."
        );
      },
    );
  }
}

/* ---------------- UI bits ---------------- */

class _SectionTitle extends StatelessWidget {
  final double padH;
  final String title;
  const _SectionTitle({required this.padH, required this.title});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(padH, 18, padH, 10),
        child: _AutoShrinkText(
          title,
          maxLines: 1,
          minFontSize: 13,
          style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ) ??
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ThemedProjectDetailsSpec spec;
  final double radius;
  const _StatsRow({required this.spec, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ux = Theme.of(context).extension<UiTokens>()!;

    String hint(String key) => switch (key) {
          'stat_reviews_hint' => l10n.owner_proj_details_stat_reviews_hint,
          'stat_active_hint' => l10n.owner_proj_details_stat_active_hint,
          'stat_days_hint' => l10n.owner_proj_details_stat_days_hint,
          _ => key,
        };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ux.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              top: spec.stat1Title,
              hint: hint(spec.stat1Hint),
              suffixStar: true,
            ),
          ),
          Expanded(
            child: _MetricItem(
              top: spec.stat2Title,
              hint: hint(spec.stat2Hint),
            ),
          ),
          Expanded(
            child: _MetricItem(
              top: '${spec.stat3Title} ',
              hint: hint(spec.stat3Hint),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String top;
  final String hint;
  final bool suffixStar;

  const _MetricItem({
    required this.top,
    required this.hint,
    this.suffixStar = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                top,
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
              if (suffixStar) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ],
    );
  }
}

class _CreateCtaCard extends StatelessWidget {
  final ThemedProjectDetailsSpec spec;
  final double radius;
  final Color tint;

  const _CreateCtaCard({
    required this.spec,
    required this.radius,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tint, tint.withOpacity(.88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tint.withOpacity(.28),
            blurRadius: 26,
            offset: const Offset(0, 16),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const _Badge(text: '✨'),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AutoShrinkText(
                    l10n.owner_proj_details_create_title,
                    maxLines: 1,
                    minFontSize: 12,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _AutoShrinkText(
                    l10n.owner_proj_details_create_subtitle,
                    maxLines: 2,
                    minFontSize: 10,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(.86),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _Badge(text: '➜', size: 32, fontSize: 18, opacity: .16),
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _ChipPill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7), // ✅ smaller
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12), // ✅ tighter
      ),
      child: _AutoShrinkText(
        text,
        maxLines: 1, // ✅ keeps height small
        minFontSize: 9,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniScreenCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bg;
  final double radius;
  const _MiniScreenCard({
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: DefaultTextStyle(
        style: tt.bodySmall!.copyWith(color: cs.onSurface.withOpacity(.85)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AutoShrinkText(
              title,
              maxLines: 2,
              minFontSize: 12,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800) ??
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _AutoShrinkText(
              subtitle,
              maxLines: 4,
              minFontSize: 10,
              style: tt.bodySmall ??
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final String text;
  final double radius;
  final bool dense;

  const _ListTileCard({
    required this.text,
    required this.radius,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: dense ? 8 : 10),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: dense ? 10 : 14, // ✅ smaller height
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ux.cardShadow,
      ),
      child: _AutoShrinkText(
        text,
        maxLines: 1, // ✅ keeps it short
        minFontSize: 10,
        style: TextStyle(
          color: cs.onSurface.withOpacity(.92),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String emoji;
  final String text;
  final Color bubble;
  final double radius;
  const _InsightCard({
    required this.emoji,
    required this.text,
    required this.bubble,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ux = Theme.of(context).extension<UiTokens>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ux.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bubble,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final double fontSize;
  final double opacity;
  const _Badge({
    required this.text,
    this.size = 50,
    this.fontSize = 22,
    this.opacity = .16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, color: Colors.white),
      ),
    );
  }
}

class _ModulesPreview extends StatelessWidget {
  final List<String> modules;
  final double radius;
  final Color tint;
  final String viewAllLabel;

  const _ModulesPreview({
    required this.modules,
    required this.radius,
    required this.tint,
    required this.viewAllLabel,
  });

  void _openAll(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ux.radiusLg + 6),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ux.pagePad.horizontal / 2,
              8,
              ux.pagePad.horizontal / 2,
              16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modules included',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: modules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ListTileCard(
                        text: modules[i],
                        radius: radius,
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

  @override
  Widget build(BuildContext context) {
    final previewCount = modules.length > 3 ? 3 : modules.length;
    final preview = modules.take(previewCount).toList();

    return Column(
      children: [
        ...preview.map(
          (m) => _ListTileCard(
            text: m,
            radius: radius,
          ),
        ),
        if (modules.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openAll(context),
              child: Text(viewAllLabel),
            ),
          ),
      ],
    );
  }
}
