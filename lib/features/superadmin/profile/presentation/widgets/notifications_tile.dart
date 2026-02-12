import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

class NotificationsTile extends StatefulWidget {
  final bool notifyItems;
  final bool notifyFeedback;
  final void Function(bool items, bool feedback) onSave;
  final bool busy;

  const NotificationsTile({
    super.key,
    required this.notifyItems,
    required this.notifyFeedback,
    required this.onSave,
    this.busy = false,
  });

  @override
  State<NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<NotificationsTile> {
  late bool _items = widget.notifyItems;
  late bool _fb = widget.notifyFeedback;

  @override
  void didUpdateWidget(covariant NotificationsTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifyItems != widget.notifyItems)
      _items = widget.notifyItems;
    if (oldWidget.notifyFeedback != widget.notifyFeedback) {
      _fb = widget.notifyFeedback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.profile_notify_items),
              subtitle: Text(l10n.profile_notify_items_sub),
              value: _items,
              onChanged: widget.busy ? null : (v) => setState(() => _items = v),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.profile_notify_feedback),
              subtitle: Text(l10n.profile_notify_feedback_sub),
              value: _fb,
              onChanged: widget.busy ? null : (v) => setState(() => _fb = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    widget.busy ? null : () => widget.onSave(_items, _fb),
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.profile_update_notifications),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
