import 'package:flutter/material.dart';
import 'package:build4all_manager/shared/themes/theme_palette.dart';

class ProjectTemplate {
  final int id;
  final String kind;
  final String titleKey;
  final String descKey;
  final String ctaKey;
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

/// Static platform project templates shown in Owner Home.
/// These are UI templates only. The real backend projectId is resolved dynamically
/// from the platform projects API and mapped by kind.
const projectTemplates = <ProjectTemplate>[
  ProjectTemplate(
    id: 2,
    kind: 'ecommerce',
    titleKey: 'owner_proj_ecom_title',
    descKey: 'owner_proj_ecom_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.shopping_bag_rounded,
    tint: ProjectPalette.gym,
  ),
 ProjectTemplate(
  id: 3,
  kind: 'gym',
  titleKey: 'owner_proj_gym_title',
  descKey: 'owner_proj_gym_desc',
  ctaKey: 'owner_proj_open',
  route: '/owner/projects',
  icon: Icons.fitness_center_rounded,
  tint: const Color(0xFFF59E0B),
),
  ProjectTemplate(
    id: 4,
    kind: 'wholesale',
    titleKey: 'owner_proj_wholesale_title',
    descKey: 'owner_proj_wholesale_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.inventory_2_rounded,
    tint: Color(0xFF2563EB),
  ),
  ProjectTemplate(
    id: 5,
    kind: 'municipality',
    titleKey: 'owner_proj_municipality_title',
    descKey: 'owner_proj_municipality_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.location_city_rounded,
    tint: Color(0xFF7C3AED),
  ),
];