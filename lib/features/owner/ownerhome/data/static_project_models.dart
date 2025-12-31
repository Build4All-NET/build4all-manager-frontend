import 'package:flutter/material.dart';
// If you want to force tint here too later, uncomment this import.
// import 'package:build4all_manager/shared/themes/theme_palette.dart';

class ProjectTemplate {
  final int id; // numeric id used by backend & dropdown
  final String kind; // 'activities' | 'ecommerce' | 'gym' | 'services'
  final String titleKey; // l10n key
  final String descKey; // l10n key
  final String ctaKey; // l10n key
  final String route;
  final IconData icon;
  final Color? tint;

  const ProjectTemplate({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.descKey,
    required this.ctaKey,
    required this.route,
    required this.icon,
    this.tint,
  });
}

/// Local-only static list (no backend).
const projectTemplates = <ProjectTemplate>[
  // ✅ ONLY SHOW E-COMMERCE NOW:
  ProjectTemplate(
    id: 2,
    kind: 'ecommerce',
    titleKey: 'owner_proj_ecom_title',
    descKey: 'owner_proj_ecom_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.shopping_bag_rounded,
    // ✅ Optional: force tint right here too (uncomment import above)
    // tint: ProjectPalette.gym,
  ),

  /* ---------------------------------------------------------
   * ⛔ Disabled for now (DON'T DELETE)
   * Uncomment later when you want them back
   * ---------------------------------------------------------

  ProjectTemplate(
    id: 1,
    kind: 'activities',
    titleKey: 'owner_proj_activities_title',
    descKey: 'owner_proj_activities_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.event_available_rounded,
  ),
  ProjectTemplate(
    id: 3,
    kind: 'gym',
    titleKey: 'owner_proj_gym_title',
    descKey: 'owner_proj_gym_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.fitness_center_rounded,
  ),
  ProjectTemplate(
    id: 4,
    kind: 'services',
    titleKey: 'owner_proj_services_title',
    descKey: 'owner_proj_services_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.home_repair_service_rounded,
  ),

  --------------------------------------------------------- */
];
