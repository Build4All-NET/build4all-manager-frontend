import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/models/super_admin_ios_internal_testing_request_model.dart';

class SuperAdminIosInternalTestingActionsSheet extends StatelessWidget {
  final SuperAdminIosInternalTestingRequestModel request;
  final VoidCallback onProcess;
  final VoidCallback onSync;

  const SuperAdminIosInternalTestingActionsSheet({
    super.key,
    required this.request,
    required this.onProcess,
    required this.onSync,
  });

  static Future<void> show(
    BuildContext context, {
    required SuperAdminIosInternalTestingRequestModel request,
    required VoidCallback onProcess,
    required VoidCallback onSync,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => SuperAdminIosInternalTestingActionsSheet(
        request: request,
        onProcess: onProcess,
        onSync: onSync,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.play_circle_outline_rounded,
                  color: cs.primary,
                ),
                title: Text(l10n.super_ios_internal_testing_process_request),
                onTap: () {
                  Navigator.pop(context);
                  onProcess();
                },
              ),
              ListTile(
                leading: Icon(Icons.sync_rounded, color: cs.primary),
                title: Text(l10n.super_ios_internal_testing_sync_request),
                onTap: () {
                  Navigator.pop(context);
                  onSync();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(l10n.super_ios_internal_testing_copy_apple_email),
                subtitle: Text(
                  request.appleEmail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: request.appleEmail),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tag_rounded),
                title: Text(l10n.super_ios_internal_testing_copy_request_id),
                subtitle: Text('#${request.id}'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: request.id.toString()),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.apps_rounded),
                title: Text(l10n.super_ios_internal_testing_copy_bundle_id),
                subtitle: Text(
                  request.bundleIdSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: request.bundleIdSnapshot),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}