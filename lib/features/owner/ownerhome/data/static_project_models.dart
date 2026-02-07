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

/// Local-only static list (no backend).
const projectTemplates = <ProjectTemplate>[
  ProjectTemplate(
    id: 2,
    kind: 'ecommerce',
    titleKey: 'owner_proj_ecom_title',
    descKey: 'owner_proj_ecom_desc',
    ctaKey: 'owner_proj_open',
    route: '/owner/projects',
    icon: Icons.shopping_bag_rounded,
    tint: ProjectPalette.gym, // ✅ FORCE ecommerce = gym green everywhere
  ),
];
