import 'package:flutter/material.dart';
import '../../domain/entities/project.dart';

class ProjectTypeChip extends StatelessWidget {
  final ProjectType type;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  const ProjectTypeChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
    );
  }
}
