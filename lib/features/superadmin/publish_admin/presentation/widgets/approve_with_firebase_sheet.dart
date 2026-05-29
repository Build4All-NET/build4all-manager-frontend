import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/data/services/firebase_pool_remote_ds.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/domain/entities/firebase_project_account.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

typedef ApproveResult = ({String notes, int? firebaseProjectAccountId});

class ApproveWithFirebaseSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String hint;
  final String cancelLabel;

  const ApproveWithFirebaseSheet({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.hint,
    required this.cancelLabel,
  });

  static Future<ApproveResult?> open(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required String hint,
    required String cancelLabel,
  }) {
    return showModalBottomSheet<ApproveResult?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApproveWithFirebaseSheet(
        title: title,
        confirmLabel: confirmLabel,
        hint: hint,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  State<ApproveWithFirebaseSheet> createState() =>
      _ApproveWithFirebaseSheetState();
}

class _ApproveWithFirebaseSheetState extends State<ApproveWithFirebaseSheet> {
  late final TextEditingController _notesController;
  late final FocusNode _focusNode;

  int? _selectedAccountId; // null = AUTO
  List<FirebaseProjectAccount> _accounts = [];

  bool _loadingAccounts = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController();
    _focusNode = FocusNode();

    // Safe: no AppLocalizations.of(context) inside this method.
    _loadAccounts();

    // Important:
    // Do NOT auto-focus. Auto-focus opens keyboard directly and makes the sheet cramped.
  }

  Future<void> _loadAccounts() async {
    try {
      final ds = FirebasePoolRemoteDs(dio: DioClient.ensure());
      final models = await ds.getAll();

      if (!mounted) return;

      setState(() {
        _accounts = models
            .map((model) => model.toEntity())
            .where((account) => account.isActive)
            .toList();

        _loadingAccounts = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _accounts = [];
        _loadingAccounts = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final notes = _notesController.text.trim();

    Navigator.of(context).pop<ApproveResult?>(
      (
        notes: notes,
        firebaseProjectAccountId: _selectedAccountId,
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop<ApproveResult?>(null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final insets = MediaQuery.of(context).viewInsets;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(.35),
              ),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildFirebaseSelector(context, cs),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 2,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      labelText: l10n.publish_sheet_notes_optional,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancel,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.cancelLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.confirmLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirebaseSelector(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.publish_firebase_project_label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingAccounts)
          _FirebaseLoadingBox(cs: cs)
        else if (_loadFailed)
          _FirebaseErrorBox(
            cs: cs,
            message: l10n.publish_firebase_load_error_auto(
              l10n.publish_firebase_load_failed,
            ),
          )
        else
          DropdownButtonFormField<int?>(
            value: _selectedAccountId,
            isExpanded: true,
            menuMaxHeight: 320,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            selectedItemBuilder: (context) {
              return [
                _AutoFirebaseItem(
                  label: l10n.publish_firebase_auto_short,
                ),
                ..._accounts.map(
                  (account) => _FirebaseAccountItem(
                    account: account,
                    cs: cs,
                    compact: true,
                    defaultLabel: l10n.publish_firebase_default_short,
                    remainingLabel: l10n.publish_firebase_remaining(
                      account.remainingAndroid,
                      account.remainingIos,
                    ),
                  ),
                ),
              ];
            },
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: _AutoFirebaseItem(
                  label: l10n.publish_firebase_auto_full,
                ),
              ),
              ..._accounts.map(
                (account) => DropdownMenuItem<int?>(
                  value: account.id,
                  child: _FirebaseAccountItem(
                    account: account,
                    cs: cs,
                    compact: false,
                    defaultLabel: l10n.publish_firebase_default_full,
                    remainingLabel: l10n.publish_firebase_remaining(
                      account.remainingAndroid,
                      account.remainingIos,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAccountId = value;
              });
            },
          ),
      ],
    );
  }
}

class _FirebaseLoadingBox extends StatelessWidget {
  final ColorScheme cs;

  const _FirebaseLoadingBox({
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FirebaseErrorBox extends StatelessWidget {
  final ColorScheme cs;
  final String message;

  const _FirebaseErrorBox({
    required this.cs,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            size: 16,
            color: cs.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoFirebaseItem extends StatelessWidget {
  final String label;

  const _AutoFirebaseItem({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          size: 16,
          color: Color(0xFF7C3AED),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _FirebaseAccountItem extends StatelessWidget {
  final FirebaseProjectAccount account;
  final ColorScheme cs;
  final bool compact;
  final String defaultLabel;
  final String remainingLabel;

  const _FirebaseAccountItem({
    required this.account,
    required this.cs,
    required this.compact,
    required this.defaultLabel,
    required this.remainingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.storage_rounded,
          size: 16,
          color: account.isActive
              ? const Color(0xFF16A34A)
              : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (!compact)
                Text(
                  remainingLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withOpacity(.6),
                  ),
                ),
            ],
          ),
        ),
        if (account.isDefault) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              defaultLabel,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}