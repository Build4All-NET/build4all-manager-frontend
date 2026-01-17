import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../bloc/superadmin_ai_bloc.dart';
import '../bloc/superadmin_ai_event.dart';
import '../bloc/superadmin_ai_state.dart';

class OwnerAiToggleTile extends StatelessWidget {
  final int ownerId;

  const OwnerAiToggleTile({
    super.key,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocConsumer<SuperAdminAiBloc, SuperAdminAiState>(
      listener: (context, state) {
        // success / error toasts
        if (state.error != null && state.error!.trim().isNotEmpty) {
          AppToast.error(context, l10n.ai_update_failed);
        }
      },
      builder: (context, state) {
        final loading = state.loading;
        final updating = state.updating;

        final enabled = state.status?.aiEnabled ?? false;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ai_owner_setting_title,
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.ai_owner_setting_subtitle,
                      style: tt.bodySmall?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Switch(
                      value: enabled,
                      onChanged: updating
                          ? null
                          : (v) {
                              context.read<SuperAdminAiBloc>().add(
                                    SuperAdminAiToggled(
                                      ownerId: ownerId,
                                      enabled: v,
                                    ),
                                  );
                            },
                    ),
                    Text(
                      enabled ? l10n.ai_enabled : l10n.ai_disabled,
                      style: tt.bodySmall?.copyWith(
                        color: enabled ? cs.primary : cs.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
