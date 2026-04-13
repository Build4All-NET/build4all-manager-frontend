import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/themes/theme_palette.dart';

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

  final String stat1Title;
  final String stat1Hint;
  final String stat2Title;
  final String stat2Hint;
  final String stat3Title;
  final String stat3Hint;

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

ThemedProjectDetailsSpec themedSpecFor(
  BuildContext context,
  String projectIdRaw,
) {
  final cs = Theme.of(context).colorScheme;
  final id = projectIdRaw.toLowerCase();

  Color roleAccent(String pid) {
    switch (pid) {
      case 'ecommerce':
        return ProjectPalette.gym; // keep ecommerce forced to gym green
      case 'gym':
        return ProjectPalette.gym;
      case 'services':
        return ProjectPalette.services;
      case 'wholesale':
        return const Color(0xFF2563EB);
      case 'municipality':
        return const Color(0xFF7C3AED);
      case 'activities':
        return ProjectPalette.activities;
      default:
        return cs.primary;
    }
  }

  Color chipBg(Color c) => c.withOpacity(.12);

  Color headerEnd(Color accent) =>
      Color.alphaBlend(Colors.white.withOpacity(.30), accent);

  Color createEnd(Color accent) => HSLColor.fromColor(accent)
      .withLightness(
        (HSLColor.fromColor(accent).lightness + .18).clamp(.0, 1.0),
      )
      .toColor();

  final accent = roleAccent(id);
  final chipBgColor = chipBg(accent);
  final headerEndColor = headerEnd(accent);
  final createEndColor = createEnd(accent);

  const s1Title = '4.8';
  const s1Hint = 'stat_reviews_hint';
  const s2Hint = 'stat_active_hint';
  const s3Hint = 'stat_days_hint';

  if (id == 'ecommerce') {
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
        l.owner_proj_details_ecom_h5,
        l.owner_proj_details_ecom_h6,
        l.owner_proj_details_ecom_h7,
        l.owner_proj_details_ecom_h8,
      ],
      screens: (l) => [
        MiniScreen(
          l.owner_proj_details_ecom_sf1_title,
          l.owner_proj_details_ecom_sf1_sub,
          chipBg(accent),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf2_title,
          l.owner_proj_details_ecom_sf2_sub,
          chipBg(cs.primary),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf3_title,
          l.owner_proj_details_ecom_sf3_sub,
          chipBg(cs.tertiaryContainer),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf4_title,
          l.owner_proj_details_ecom_sf4_sub,
          chipBg(cs.secondaryContainer),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf5_title,
          l.owner_proj_details_ecom_sf5_sub,
          chipBg(accent),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf6_title,
          l.owner_proj_details_ecom_sf6_sub,
          chipBg(cs.primary),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf7_title,
          l.owner_proj_details_ecom_sf7_sub,
          chipBg(cs.tertiaryContainer),
        ),
        MiniScreen(
          l.owner_proj_details_ecom_sf8_title,
          l.owner_proj_details_ecom_sf8_sub,
          chipBg(cs.secondaryContainer),
        ),
      ],
      modules: (l) => [
        l.owner_proj_details_ecom_m1,
        l.owner_proj_details_ecom_m2,
        l.owner_proj_details_ecom_m3,
        l.owner_proj_details_ecom_m4,
        l.owner_proj_details_ecom_m5,
        l.owner_proj_details_ecom_m6,
        l.owner_proj_details_ecom_m7,
        l.owner_proj_details_ecom_m8,
        l.owner_proj_details_ecom_m9,
        l.owner_proj_details_ecom_m10,
      ],
      insights: (l) => [
        InsightLine('💳', l.owner_proj_details_ecom_i1),
        InsightLine('🔁', l.owner_proj_details_ecom_i2),
      ],
    );
  }

  if (id == 'gym') {
    return ThemedProjectDetailsSpec(
      id: 'gym',
      emoji: '🏋️',
      accent: accent,
      headerStart: accent,
      headerEnd: headerEndColor,
      chipBg: chipBgColor,
      createEnd: createEndColor,
      stat1Title: s1Title,
      stat1Hint: s1Hint,
      stat2Title: '2.7k',
      stat2Hint: s2Hint,
      stat3Title: '6',
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
        MiniScreen(
          l.owner_proj_details_gym_s1_title,
          l.owner_proj_details_gym_s1_sub,
          chipBg(accent),
        ),
        MiniScreen(
          l.owner_proj_details_gym_s2_title,
          l.owner_proj_details_gym_s2_sub,
          chipBg(cs.primary),
        ),
      ],
      modules: (l) => [
        l.owner_proj_details_gym_m1,
        l.owner_proj_details_gym_m2,
        l.owner_proj_details_gym_m3,
      ],
      insights: (l) => [
        InsightLine('📈', l.owner_proj_details_gym_i1),
        InsightLine('💬', l.owner_proj_details_gym_i2),
      ],
    );
  }

  if (id == 'wholesale') {
    return ThemedProjectDetailsSpec(
      id: 'wholesale',
      emoji: '📦',
      accent: accent,
      headerStart: accent,
      headerEnd: headerEndColor,
      chipBg: chipBgColor,
      createEnd: createEndColor,
      stat1Title: s1Title,
      stat1Hint: s1Hint,
      stat2Title: '1.9k',
      stat2Hint: s2Hint,
      stat3Title: '7',
      stat3Hint: s3Hint,
      headline: (l) => l.owner_proj_details_headline_wholesale,
      subhead: (l) => l.owner_proj_details_subhead_wholesale,
      i18nHighlights: (l) => l.owner_proj_details_highlights,
      i18nScreens: (l) => l.owner_proj_details_screens,
      i18nModules: (l) => l.owner_proj_details_modules,
      i18nWhy: (l) => l.owner_proj_details_why,
      i18nPrimaryCta: (l) => l.owner_proj_details_primaryCta,
      i18nSecondaryCta: (l) => l.owner_proj_details_secondaryCta,
      i18nCreateTitle: (l) => l.owner_proj_details_create_title,
      i18nCreateSubtitle: (l) => l.owner_proj_details_create_subtitle,
      highlights: (l) => [
        l.owner_proj_details_wholesale_h1,
        l.owner_proj_details_wholesale_h2,
        l.owner_proj_details_wholesale_h3,
        l.owner_proj_details_wholesale_h4,
      ],
      screens: (l) => [
        MiniScreen(
          l.owner_proj_details_wholesale_s1_title,
          l.owner_proj_details_wholesale_s1_sub,
          chipBg(accent),
        ),
        MiniScreen(
          l.owner_proj_details_wholesale_s2_title,
          l.owner_proj_details_wholesale_s2_sub,
          chipBg(cs.primary),
        ),
      ],
      modules: (l) => [
        l.owner_proj_details_wholesale_m1,
        l.owner_proj_details_wholesale_m2,
        l.owner_proj_details_wholesale_m3,
      ],
      insights: (l) => [
        InsightLine('📊', l.owner_proj_details_wholesale_i1),
        InsightLine('🚚', l.owner_proj_details_wholesale_i2),
      ],
    );
  }

  if (id == 'municipality') {
    return ThemedProjectDetailsSpec(
      id: 'municipality',
      emoji: '🏛️',
      accent: accent,
      headerStart: accent,
      headerEnd: headerEndColor,
      chipBg: chipBgColor,
      createEnd: createEndColor,
      stat1Title: s1Title,
      stat1Hint: s1Hint,
      stat2Title: '3.4k',
      stat2Hint: s2Hint,
      stat3Title: '9',
      stat3Hint: s3Hint,
      headline: (l) => l.owner_proj_details_headline_municipality,
      subhead: (l) => l.owner_proj_details_subhead_municipality,
      i18nHighlights: (l) => l.owner_proj_details_highlights,
      i18nScreens: (l) => l.owner_proj_details_screens,
      i18nModules: (l) => l.owner_proj_details_modules,
      i18nWhy: (l) => l.owner_proj_details_why,
      i18nPrimaryCta: (l) => l.owner_proj_details_primaryCta,
      i18nSecondaryCta: (l) => l.owner_proj_details_secondaryCta,
      i18nCreateTitle: (l) => l.owner_proj_details_create_title,
      i18nCreateSubtitle: (l) => l.owner_proj_details_create_subtitle,
      highlights: (l) => [
        l.owner_proj_details_municipality_h1,
        l.owner_proj_details_municipality_h2,
        l.owner_proj_details_municipality_h3,
        l.owner_proj_details_municipality_h4,
      ],
      screens: (l) => [
        MiniScreen(
          l.owner_proj_details_municipality_s1_title,
          l.owner_proj_details_municipality_s1_sub,
          chipBg(accent),
        ),
        MiniScreen(
          l.owner_proj_details_municipality_s2_title,
          l.owner_proj_details_municipality_s2_sub,
          chipBg(cs.primary),
        ),
      ],
      modules: (l) => [
        l.owner_proj_details_municipality_m1,
        l.owner_proj_details_municipality_m2,
        l.owner_proj_details_municipality_m3,
      ],
      insights: (l) => [
        InsightLine('📝', l.owner_proj_details_municipality_i1),
        InsightLine('📣', l.owner_proj_details_municipality_i2),
      ],
    );
  }

  return ThemedProjectDetailsSpec(
    id: id,
    emoji: '✨',
    accent: accent,
    headerStart: accent,
    headerEnd: headerEndColor,
    chipBg: chipBgColor,
    createEnd: createEndColor,
    stat1Title: s1Title,
    stat1Hint: s1Hint,
    stat2Title: '—',
    stat2Hint: s2Hint,
    stat3Title: '—',
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
    highlights: (l) => [],
    screens: (l) => [],
    modules: (l) => [],
    insights: (l) => [],
  );
}