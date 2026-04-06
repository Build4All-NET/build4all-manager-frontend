import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RequestedAppsTableHeader extends StatelessWidget {
  final bool showVersion;
  final bool showRequested;

  const RequestedAppsTableHeader({
    super.key,
    required this.showVersion,
    required this.showRequested,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    TextStyle style() => Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
          color: cs.onSurface.withOpacity(.70),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            flex: 38,
            child: Text(l10n.publish_table_app, style: style()),
          ),
          Expanded(
            flex: 22,
            child: Text(l10n.publish_table_platforms, style: style()),
          ),
          if (showVersion)
            Expanded(
              flex: 18,
              child: Text(l10n.publish_table_version, style: style()),
            ),
          Expanded(
            flex: 16,
            child: Text(l10n.common_status, style: style()),
          ),
          if (showRequested)
            Expanded(
              flex: 24,
              child: Text(l10n.publish_table_requested_date, style: style()),
            ),
          SizedBox(
            width: 162,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(l10n.publish_table_actions, style: style()),
            ),
          ),
        ],
      ),
    );
  }
}