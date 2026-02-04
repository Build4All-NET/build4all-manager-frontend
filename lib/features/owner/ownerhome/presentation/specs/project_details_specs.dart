/// lib/features/owner/ownerhome/presentation/specs/project_details_specs.dart
library;
import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

class MiniScreen {
  final String title;
  final String subtitle;
  final Color bg;
  MiniScreen(this.title, this.subtitle, this.bg);
}

class InsightLine {
  final String emoji;
  final String text;
  InsightLine(this.emoji, this.text);
}

typedef Txt = String Function(AppLocalizations);

class ThemedProjectDetailsSpec {
  final String id;
  final String emoji;
  final Color accent;
  final Color headerStart;
  final Color headerEnd;
  final Color chipBg;
  final Color createEnd;

  // Stats text
  final String stat1Title; // rating number only, e.g. "4.8"
  final String stat1Hint; // 'stat_reviews_hint' -> localized later
  final String stat2Title;
  final String stat2Hint;
  final String stat3Title;
  final String stat3Hint;

  // i18n titles
  final Txt headline;
  final Txt subhead;
  final Txt i18nHighlights;
  final Txt i18nScreens;
  final Txt i18nModules;
  final Txt i18nWhy;
  final Txt i18nPrimaryCta;
  final Txt i18nSecondaryCta;
  final Txt i18nCreateTitle;
  final Txt i18nCreateSubtitle;

  // content
  final List<String> Function(AppLocalizations) highlights;
  final List<MiniScreen> Function(AppLocalizations) screens;
  final List<String> Function(AppLocalizations) modules;
  final List<InsightLine> Function(AppLocalizations) insights;

  const ThemedProjectDetailsSpec({
    required this.id,
    required this.emoji,
    required this.accent,
    required this.headerStart,
    required this.headerEnd,
    required this.chipBg,
    required this.createEnd,
    required this.stat1Title,
    required this.stat1Hint,
    required this.stat2Title,
    required this.stat2Hint,
    required this.stat3Title,
    required this.stat3Hint,
    required this.headline,
    required this.subhead,
    required this.i18nHighlights,
    required this.i18nScreens,
    required this.i18nModules,
    required this.i18nWhy,
    required this.i18nPrimaryCta,
    required this.i18nSecondaryCta,
    required this.i18nCreateTitle,
    required this.i18nCreateSubtitle,
    required this.highlights,
    required this.screens,
    required this.modules,
    required this.insights,
  });
}

/// Factory that builds “theme-aware” specs per project id.
ThemedProjectDetailsSpec themedSpecFor(BuildContext context, String projectId) {
  final cs = Theme.of(context).colorScheme;

  Color roleAccent(String id) => switch (id) {
        //'activities' => cs.primary,
        'ecommerce' => cs.secondaryContainer,
       // 'gym' => cs.secondaryContainer,
       // 'services' => cs.secondary,
        _ => cs.primary,
      };

  Color _chipBg(Color c) => c.withOpacity(.12);

  Color _headerEnd(Color accent) =>
      Color.alphaBlend(Colors.white.withOpacity(.3), accent);

  Color _createEnd(Color accent) => HSLColor.fromColor(accent)
      .withLightness(
        (HSLColor.fromColor(accent).lightness + .18).clamp(.0, 1.0),
      )
      .toColor();

  // ✅ computed colors (different names)
  final Color accent = roleAccent(projectId);
  final Color chipBgColor = _chipBg(accent);
  final Color headerEndColor = _headerEnd(accent);
  final Color createEndColor = _createEnd(accent);


  // Common stats (localized later):
  const s1Title = '4.8'; // ⭐ handled in UI, keep number only
  const s1Hint = 'stat_reviews_hint';
  const s2Hint = 'stat_active_hint';
  const s3Hint = 'stat_days_hint';

  switch (projectId) {
    case 'ecommerce':
      return ThemedProjectDetailsSpec(
        id: 'ecommerce',
        emoji: '🛍️',
        accent: accent,
        headerStart: accent,
        headerEnd: headerEndColor, 
        chipBg: chipBgColor, 
        createEnd: createEndColor,
        stat1Title: s1Title,
        stat1Hint: s1Hint,
        stat2Title: '5.1k',
        stat2Hint: s2Hint,
        stat3Title: '8',
        stat3Hint: s3Hint,
        headline: (l) => l.owner_proj_details_headline_ecommerce,
        subhead: (l) => l.owner_proj_details_subhead_ecommerce,
        i18nHighlights: (l) => l.owner_proj_details_highlights,
        i18nScreens: (l) => l.owner_proj_details_screens,
        i18nModules: (l) => l.owner_proj_details_modules,
        i18nWhy: (l) => l.owner_proj_details_why,
        i18nPrimaryCta: (l) => l.owner_proj_details_primaryCta,
        i18nSecondaryCta: (l) => l.owner_proj_details_secondaryCta,
        i18nCreateTitle: (l) => l.owner_proj_details_create_title,
        i18nCreateSubtitle: (l) => l.owner_proj_details_create_subtitle,
        highlights: (l) => [
          l.owner_proj_details_ecom_h1,
          l.owner_proj_details_ecom_h2,
          l.owner_proj_details_ecom_h3,
          l.owner_proj_details_ecom_h4,
        ],
          screens: (l) => [
          MiniScreen(
            l.owner_proj_details_ecom_s1_title,
            l.owner_proj_details_ecom_s1_sub,
            _chipBg(cs.surfaceTint), // ✅ use helper for different colors
          ),
          MiniScreen(
            l.owner_proj_details_ecom_s2_title,
            l.owner_proj_details_ecom_s2_sub,
            _chipBg(cs.primary),
          ),
        ],
        modules: (l) => [
          l.owner_proj_details_ecom_m1,
          l.owner_proj_details_ecom_m2,
          l.owner_proj_details_ecom_m3,
        ],
        insights: (l) => [
          InsightLine('💳', l.owner_proj_details_ecom_i1),
          InsightLine('🔁', l.owner_proj_details_ecom_i2),
        ],
      );

    /* case 'gym':
      return ThemedProjectDetailsSpec(
        id: 'gym',
        emoji: '🏋️',
        accent: accent,
        headerStart: accent,
        headerEnd: _headerEnd,
        chipBg: _chipBg,
        createEnd: _createEnd,
        stat1Title: s1Title,
        stat1Hint: s1Hint,
        stat2Title: '2.9k',
        stat2Hint: s2Hint,
        stat3Title: '9',
        stat3Hint: s3Hint,
        headline: (l) => l.owner_proj_details_headline_gym,
        subhead: (l) => l.owner_proj_details_subhead_gym,
        i18nHighlights: (l) => l.owner_proj_details_highlights,
        i18nScreens: (l) => l.owner_proj_details_screens,
        i18nModules: (l) => l.owner_proj_details_modules,
        i18nWhy: (l) => l.owner_proj_details_why,
        i18nPrimaryCta: (l) => l.owner_proj_details_primaryCta,
        i18nSecondaryCta: (l) => l.owner_proj_details_secondaryCta,
        i18nCreateTitle: (l) => l.owner_proj_details_create_title,
        i18nCreateSubtitle: (l) => l.owner_proj_details_create_subtitle,
        highlights: (l) => [
          l.owner_proj_details_gym_h1,
          l.owner_proj_details_gym_h2,
          l.owner_proj_details_gym_h3,
          l.owner_proj_details_gym_h4,
        ],
        screens: (l) => [
          MiniScreen(l.owner_proj_details_gym_s1_title,
              l.owner_proj_details_gym_s1_sub, chipBg(cs.secondary)),
          MiniScreen(l.owner_proj_details_gym_s2_title,
              l.owner_proj_details_gym_s2_sub, chipBg(cs.primary)),
        ],
        modules: (l) => [
          l.owner_proj_details_gym_m1,
          l.owner_proj_details_gym_m2,
          l.owner_proj_details_gym_m3,
        ],
        insights: (l) => [
          InsightLine('🔥', l.owner_proj_details_gym_i1),
          InsightLine('🧑‍🤝‍🧑', l.owner_proj_details_gym_i2),
        ],
      );

    case 'services':
      return ThemedProjectDetailsSpec(
        id: 'services',
        emoji: '🛠️',
        accent: accent,
        headerStart: accent,
        headerEnd: _headerEnd,
        chipBg: _chipBg,
        createEnd: _createEnd,
        stat1Title: s1Title,
        stat1Hint: s1Hint,
        stat2Title: '4.4k',
        stat2Hint: s2Hint,
        stat3Title: '11',
        stat3Hint: s3Hint,
        headline: (l) => l.owner_proj_details_headline_services,
        subhead: (l) => l.owner_proj_details_subhead_services,
        i18nHighlights: (l) => l.owner_proj_details_highlights,
        i18nScreens: (l) => l.owner_proj_details_screens,
        i18nModules: (l) => l.owner_proj_details_modules,
        i18nWhy: (l) => l.owner_proj_details_why,
        i18nPrimaryCta: (l) => l.owner_proj_details_primaryCta,
        i18nSecondaryCta: (l) => l.owner_proj_details_secondaryCta,
        i18nCreateTitle: (l) => l.owner_proj_details_create_title,
        i18nCreateSubtitle: (l) => l.owner_proj_details_create_subtitle,
        highlights: (l) => [
          l.owner_proj_details_services_h1,
          l.owner_proj_details_services_h2,
          l.owner_proj_details_services_h3,
          l.owner_proj_details_services_h4,
        ],
        screens: (l) => [
          MiniScreen(l.owner_proj_details_services_s1_title,
              l.owner_proj_details_services_s1_sub, chipBg(cs.secondary)),
          MiniScreen(l.owner_proj_details_services_s2_title,
              l.owner_proj_details_services_s2_sub, chipBg(cs.primary)),
        ],
        modules: (l) => [
          l.owner_proj_details_services_m1,
          l.owner_proj_details_services_m2,
          l.owner_proj_details_services_m3,
        ],
        insights: (l) => [
          InsightLine('🚀', l.owner_proj_details_services_i1),
          InsightLine('💼', l.owner_proj_details_services_i2),
        ],
      );

    case 'activities':
    default:
      return ThemedProjectDetailsSpec(
        id: 'activities',
        emoji: '🎯',
        accent: accent,
        headerStart: accent,
        headerEnd: _headerEnd,
        chipBg: _chipBg,
        createEnd: _createEnd,
        stat1Title: s1Title,
        stat1Hint: s1Hint,
        stat2Title: '3.6k',
        stat2Hint: s2Hint,
        stat3Title: '10',
        stat3Hint: s3Hint,
        headline: (l) => l.owner_proj_details_headline_activities,
        subhead: (l) => l.owner_proj_details_subhead_activities,
        i18nHighlights: (l) => l.owner_proj_details_highlights,
        i18nScreens: (l) => l.owner_proj_details_screens,
        i18nModules: (l) => l.owner_proj_details_modules,
        i18nWhy: (l) => l.owner_proj_details_why,
        i18nPrimaryCta: (l) => l.owner_proj_details_primaryCta,
        i18nSecondaryCta: (l) => l.owner_proj_details_secondaryCta,
        i18nCreateTitle: (l) => l.owner_proj_details_create_title,
        i18nCreateSubtitle: (l) => l.owner_proj_details_create_subtitle,
        highlights: (l) => [
          l.owner_proj_details_act_h1,
          l.owner_proj_details_act_h2,
          l.owner_proj_details_act_h3,
          l.owner_proj_details_act_h4,
        ],
        screens: (l) => [
          MiniScreen(l.owner_proj_details_act_s1_title,
              l.owner_proj_details_act_s1_sub, chipBg(cs.primary)),
          MiniScreen(l.owner_proj_details_act_s2_title,
              l.owner_proj_details_act_s2_sub, chipBg(cs.tertiaryContainer)),
        ],
        modules: (l) => [
          l.owner_proj_details_act_m1,
          l.owner_proj_details_act_m2,
          l.owner_proj_details_act_m3,
        ],
        insights: (l) => [
          InsightLine('⭐️', l.owner_proj_details_act_i1),
          InsightLine('📈', l.owner_proj_details_act_i2),
        ],
      ); */
    default:
      throw Exception('Unknown projectId: $projectId');
  }
}
