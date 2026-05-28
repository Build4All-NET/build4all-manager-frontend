import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/data/services/firebase_pool_remote_ds.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/domain/entities/firebase_project_account.dart';
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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _focusNode = FocusNode();
    _loadAccounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _loadAccounts() async {
    try {
      final ds = FirebasePoolRemoteDs(dio: DioClient.ensure());
      final models = await ds.getAll();
      if (mounted) {
        setState(() {
          _accounts = models
              .map((m) => m.toEntity())
              .where((a) => a.isActive)
              .toList();
          _loadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load Firebase accounts';
          _loadingAccounts = false;
        });
      }
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
      (notes: notes, firebaseProjectAccountId: _selectedAccountId),
    );
  }

  void _cancel() => Navigator.of(context).pop<ApproveResult?>(null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final insets = MediaQuery.of(context).viewInsets;

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
              border:
                  Border.all(color: cs.outlineVariant.withOpacity(.35)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      labelText: 'Notes (optional)',
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
                          child: Text(widget.cancelLabel),
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
                          child: Text(widget.confirmLabel),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIREBASE PROJECT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingAccounts)
          Container(
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
          )
        else if (_loadError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded,
                    size: 16, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$_loadError – AUTO selection will be used',
                    style: TextStyle(
                        fontSize: 12, color: cs.onErrorContainer),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<int?>(
            value: _selectedAccountId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 16, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Text(
                      'AUTO – best available account',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              ..._accounts.map(
                (a) => DropdownMenuItem<int?>(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 16,
                        color: a.isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${a.remainingAndroid} Android / ${a.remainingIos} iOS remaining',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (a.isDefault) ...
                        [
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _selectedAccountId = v),
          ),
      ],
    );
  }
}
