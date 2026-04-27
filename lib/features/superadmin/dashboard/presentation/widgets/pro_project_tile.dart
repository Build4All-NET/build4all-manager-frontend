import 'package:flutter/material.dart';

import '../../domain/entities/project_summary.dart';

class ProProjectTile extends StatelessWidget {
  final ProjectSummary project;
  final VoidCallback? onTap;
  final VoidCallback? onEnable;
  final VoidCallback? onDisable;
  final VoidCallback? onArchive;

  const ProProjectTile({
    super.key,
    required this.project,
    this.onTap,
    this.onEnable,
    this.onDisable,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final statusColor = project.active ? cs.primary : cs.outline;
    final statusLabel = project.active ? 'Active' : 'Inactive';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(.22)),
                ),
                child: Icon(
                  project.active
                      ? Icons.check_circle
                      : Icons.pause_circle_filled,
                  color: statusColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (project.description?.trim().isNotEmpty ?? false)
                          ? project.description!.trim()
                          : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(context, statusLabel, statusColor),
                        _chip(
                          context,
                          _fmt(project.updatedAt),
                          cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              PopupMenuButton<_ProjectAction>(
                tooltip: 'Project actions',
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case _ProjectAction.enable:
                      onEnable?.call();
                      break;
                    case _ProjectAction.disable:
                      onDisable?.call();
                      break;
                    case _ProjectAction.archive:
                      onArchive?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!project.active)
                    const PopupMenuItem(
                      value: _ProjectAction.enable,
                      child: _MenuRow(
                        icon: Icons.check_circle_outline,
                        label: 'Enable',
                      ),
                    ),
                  if (project.active)
                    const PopupMenuItem(
                      value: _ProjectAction.disable,
                      child: _MenuRow(
                        icon: Icons.pause_circle_outline,
                        label: 'Disable',
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _ProjectAction.archive,
                    child: _MenuRow(
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      danger: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

enum _ProjectAction {
  enable,
  disable,
  archive,
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? cs.error : cs.onSurface;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}