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

    TextStyle style() => Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
          color: cs.onSurface.withOpacity(.70),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(flex: 38, child: Text('APP', style: style())),
          Expanded(flex: 22, child: Text('PLATFORMS', style: style())),
          if (showVersion)
            Expanded(flex: 18, child: Text('VERSION', style: style())),
          Expanded(flex: 16, child: Text('STATUS', style: style())),
          if (showRequested)
            Expanded(flex: 24, child: Text('REQUESTED DATE', style: style())),
          SizedBox(
              width: 162,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('ACTIONS', style: style()))),
        ],
      ),
    );
  }
}
