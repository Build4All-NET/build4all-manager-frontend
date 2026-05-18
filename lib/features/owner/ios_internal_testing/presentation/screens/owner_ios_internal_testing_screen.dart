import 'dart:async';

import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/domain/entities/ios_internal_testing_request.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/domain/usecases/create_ios_internal_testing_request_uc.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/domain/usecases/get_ios_internal_testing_app_summary_uc.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/bloc/ios_internal_testing_manager_bloc.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/bloc/ios_internal_testing_manager_event.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/bloc/ios_internal_testing_manager_state.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/widgets/ios_internal_testing_status_chip.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Status filter ────────────────────────────────────────────────────────────

enum _StatusFilter { all, pending, invited, accepted, failed, cancelled }

extension _StatusFilterExt on _StatusFilter {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _StatusFilter.all:
        return 'All';
      case _StatusFilter.pending:
        return 'Pending';
      case _StatusFilter.invited:
        return 'Invited';
      case _StatusFilter.accepted:
        return l10n.iosInternalTestingStatusReady;
      case _StatusFilter.failed:
        return l10n.iosInternalTestingStatusFailed;
      case _StatusFilter.cancelled:
        return l10n.iosInternalTestingStatusCancelled;
    }
  }

  bool matches(String status) {
    final s = status.trim().toUpperCase();
    switch (this) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.pending:
        return s == 'REQUESTED' ||
            s == 'PROCESSING' ||
            s == 'ADDING_TO_INTERNAL_TESTING';
      case _StatusFilter.invited:
        return s == 'INVITED_TO_APPLE_TEAM' ||
            s == 'WAITING_OWNER_ACCEPTANCE' ||
            s == 'WAITING_APPLE_USER_SYNC';
      case _StatusFilter.accepted:
        return s == 'READY';
      case _StatusFilter.failed:
        return s == 'FAILED' || s == 'MANUAL_REVIEW_REQUIRED';
      case _StatusFilter.cancelled:
        return s == 'CANCELLED';
    }
  }
}

// ── Main screen ──────────────────────────────────────────────────────────────

class OwnerIosInternalTestingScreen extends StatefulWidget {
  final OwnerProject project;
  final CreateIosInternalTestingRequestUc createUc;
  final GetIosInternalTestingAppSummaryUc summaryUc;
  final String initialEmail;
  final String initialFirstName;
  final String initialLastName;

  const OwnerIosInternalTestingScreen({
    super.key,
    required this.project,
    required this.createUc,
    required this.summaryUc,
    this.initialEmail = '',
    this.initialFirstName = '',
    this.initialLastName = '',
  });

  @override
  State<OwnerIosInternalTestingScreen> createState() =>
      _OwnerIosInternalTestingScreenState();
}

class _OwnerIosInternalTestingScreenState
    extends State<OwnerIosInternalTestingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final IosInternalTestingManagerBloc _bloc;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  _StatusFilter _statusFilter = _StatusFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bloc = IosInternalTestingManagerBloc(
      createRequestUc: widget.createUc,
      getSummaryUc: widget.summaryUc,
    )..add(IosInternalTestingManagerStarted(linkId: widget.project.linkId));

    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _firstNameCtrl = TextEditingController(text: widget.initialFirstName);
    _lastNameCtrl = TextEditingController(text: widget.initialLastName);
    _searchCtrl.addListener(
      () => setState(
        () => _searchQuery = _searchCtrl.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<IosInternalTestingRequest> _filtered(
    List<IosInternalTestingRequest> all,
  ) {
    return all.where((r) {
      if (!_statusFilter.matches(r.status)) return false;
      if (_searchQuery.isEmpty) return true;
      final email = r.appleEmail.toLowerCase();
      final name = '${r.firstName} ${r.lastName}'.toLowerCase();
      return email.contains(_searchQuery) || name.contains(_searchQuery);
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _statusFilter != _StatusFilter.all;

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _statusFilter = _StatusFilter.all;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _bloc.add(
      IosInternalTestingManagerSubmitted(
        linkId: widget.project.linkId,
        appleEmail: _emailCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      ),
    );
  }

  void _retryRequest(IosInternalTestingRequest r) {
    _bloc.add(
      IosInternalTestingManagerSubmitted(
        linkId: widget.project.linkId,
        appleEmail: r.appleEmail.trim(),
        firstName: r.firstName.trim(),
        lastName: r.lastName.trim(),
      ),
    );
  }

  void _openAddTesterSheet(BuildContext ctx, bool isFull) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _bloc,
        child: _AddTesterSheet(
          formKey: _formKey,
          emailCtrl: _emailCtrl,
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          isFull: isFull,
          bloc: _bloc,
          onSubmit: _submit,
          validateEmail: (v) => _validateEmail(ctx, v),
          validateFirstName: (v) => _validateFirstName(ctx, v),
          validateLastName: (v) => _validateLastName(ctx, v),
        ),
      ),
    );
  }

  void _openDetail(BuildContext ctx, IosInternalTestingRequest request) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _bloc,
          child: _TesterDetailPage(
            request: request,
            onRetry: () => _retryRequest(request),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(BuildContext ctx, String? v) {
    final l10n = AppLocalizations.of(ctx)!;
    final val = (v ?? '').trim();
    if (val.isEmpty) return l10n.iosInternalTestingEmailRequired;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val)) {
      return l10n.errEmailInvalid;
    }
    return null;
  }

  String? _validateFirstName(BuildContext ctx, String? v) {
    final l10n = AppLocalizations.of(ctx)!;
    final val = (v ?? '').trim();
    if (val.isEmpty) return l10n.iosInternalTestingFirstNameRequired;
    if (val.length < 2) return l10n.iosInternalTestingFirstNameMin;
    if (val.length > 100) return l10n.iosInternalTestingFirstNameTooLong;
    return null;
  }

  String? _validateLastName(BuildContext ctx, String? v) {
    final l10n = AppLocalizations.of(ctx)!;
    final val = (v ?? '').trim();
    if (val.isEmpty) return l10n.iosInternalTestingLastNameRequired;
    if (val.length < 2) return l10n.iosInternalTestingLastNameMin;
    if (val.length > 100) return l10n.iosInternalTestingLastNameTooLong;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<IosInternalTestingManagerBloc,
          IosInternalTestingManagerState>(
        listener: (ctx, state) {
          if ((state.error ?? '').trim().isNotEmpty) {
            AppToast.error(
              ctx,
              state.error!.replaceFirst('Exception: ', ''),
            );
            _bloc.add(const IosInternalTestingManagerErrorCleared());
          }
          if ((state.message ?? '').trim().isNotEmpty) {
            AppToast.success(
              ctx,
              state.message!.trim().isNotEmpty
                  ? state.message!
                  : l10n.iosInternalTestingSubmittedMessage,
            );
            _bloc.add(const IosInternalTestingManagerMessageCleared());
          }
        },
        builder: (ctx, state) {
          final isInitialLoad = state.loading && !state.hasRequests;
          final visibleTesters = _filtered(state.requests);

          return Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              title: Text(l10n.iosInternalTestingPageTitle),
              actions: [
                IconButton(
                  tooltip: l10n.common_refresh,
                  onPressed: state.loading
                      ? null
                      : () => _bloc.add(
                            IosInternalTestingManagerRefreshed(
                              linkId: widget.project.linkId,
                            ),
                          ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                _bloc.add(
                  IosInternalTestingManagerRefreshed(
                    linkId: widget.project.linkId,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 250));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                children: [
                  _PageHeader(
                    appName: widget.project.appName.isNotEmpty
                        ? widget.project.appName
                        : widget.project.projectName,
                    bundleId: (widget.project.iosBundleId ?? '').trim(),
                    usedSlots: state.usedSlots,
                    maxSlots: state.maxSlots,
                    loading: isInitialLoad,
                    isFull: state.isFull,
                    onAddTester: () => _openAddTesterSheet(ctx, state.isFull),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 10),
                  if (state.hasRequests) ...[
                    _FilterBar(
                      searchCtrl: _searchCtrl,
                      selected: _statusFilter,
                      hasActive: _hasActiveFilters,
                      onChanged: (f) => setState(() => _statusFilter = f),
                      onReset: _resetFilters,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (isInitialLoad)
                    const _SkeletonList()
                  else if (!state.hasRequests)
                    _EmptyState(
                      onAddTester: () => _openAddTesterSheet(ctx, state.isFull),
                      l10n: l10n,
                    )
                  else if (visibleTesters.isEmpty)
                    _FilteredEmpty(onReset: _resetFilters, l10n: l10n)
                  else
                    Column(
                      children: visibleTesters
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CompactTesterCard(
                                request: r,
                                onTap: () => _openDetail(ctx, r),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String appName;
  final String bundleId;
  final int usedSlots;
  final int maxSlots;
  final bool loading;
  final bool isFull;
  final VoidCallback onAddTester;
  final AppLocalizations l10n;

  const _PageHeader({
    required this.appName,
    required this.bundleId,
    required this.usedSlots,
    required this.maxSlots,
    required this.loading,
    required this.isFull,
    required this.onAddTester,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.iosInternalTestingPageTitle,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.05),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.iosInternalTestingSectionSubtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.62),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isFull ? null : onAddTester,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(l10n.iosInternalTestingAddTesterButton),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 9),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(
                icon: Icons.apps_rounded,
                label: appName,
                cs: cs,
                tt: tt,
                bold: true,
              ),
              if (bundleId.isNotEmpty)
                _MetaChip(
                  icon: Icons.tag_rounded,
                  label: bundleId,
                  cs: cs,
                  tt: tt,
                  mono: true,
                ),
              _SlotBadge(
                used: usedSlots,
                max: maxSlots,
                loading: loading,
                cs: cs,
                tt: tt,
                l10n: l10n,
              ),
            ],
          ),
          if (isFull) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withOpacity(.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.iosInternalTestingCapacityReachedMessage,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.error, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;
  final bool bold;
  final bool mono;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
    this.bold = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurface.withOpacity(.45)),
        const SizedBox(width: 4),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(.72),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _SlotBadge extends StatelessWidget {
  final int used;
  final int max;
  final bool loading;
  final ColorScheme cs;
  final TextTheme tt;
  final AppLocalizations l10n;

  const _SlotBadge({
    required this.used,
    required this.max,
    required this.loading,
    required this.cs,
    required this.tt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final full = max > 0 && used >= max;
    final color = full ? cs.error : cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(Icons.group_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$used / $max ${l10n.iosInternalTestingSlotsUsedLabel}',
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final _StatusFilter selected;
  final bool hasActive;
  final ValueChanged<_StatusFilter> onChanged;
  final VoidCallback onReset;
  final AppLocalizations l10n;

  const _FilterBar({
    required this.searchCtrl,
    required this.selected,
    required this.hasActive,
    required this.onChanged,
    required this.onReset,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cs.outlineVariant.withOpacity(.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchCtrl,
            style: tt.bodySmall?.copyWith(fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.common_search_hint,
              hintStyle: TextStyle(
                color: cs.onSurface.withOpacity(.38),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: cs.onSurface.withOpacity(.38),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchCtrl,
                builder: (_, v, __) => v.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: cs.onSurface.withOpacity(.50),
                        ),
                        onPressed: searchCtrl.clear,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )
                    : const SizedBox.shrink(),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 7),
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withOpacity(.40),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withOpacity(.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 7),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._StatusFilter.values.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onChanged(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: f == selected
                              ? cs.primary
                              : cs.surfaceContainerHighest.withOpacity(.45),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: f == selected
                                ? cs.primary
                                : cs.outlineVariant.withOpacity(.35),
                          ),
                        ),
                        child: Text(
                          f.label(l10n),
                          style: tt.labelSmall?.copyWith(
                            fontSize: 10.5,
                            color: f == selected
                                ? cs.onPrimary
                                : cs.onSurface.withOpacity(.70),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasActive)
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 14),
                    label: Text(l10n.common_clear),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact list card ────────────────────────────────────────────────────────

class _CompactTesterCard extends StatelessWidget {
  final IosInternalTestingRequest request;
  final VoidCallback onTap;

  const _CompactTesterCard({
    required this.request,
    required this.onTap,
  });

  String _initials() {
    final f = request.firstName.trim();
    final l = request.lastName.trim();
    if (f.isEmpty && l.isEmpty) {
      return request.appleEmail.isNotEmpty
          ? request.appleEmail[0].toUpperCase()
          : '?';
    }
    return '${f.isNotEmpty ? f[0].toUpperCase() : ''}'
        '${l.isNotEmpty ? l[0].toUpperCase() : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fullName = '${request.firstName} ${request.lastName}'.trim();

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withOpacity(.12),
                child: Text(
                  _initials(),
                  style: tt.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fullName.isNotEmpty)
                      Text(
                        fullName,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      request.appleEmail,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(
                          fullName.isNotEmpty ? .60 : .88,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IosInternalTestingStatusChip(
                status: request.status,
                compact: true,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withOpacity(.30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tester detail page ───────────────────────────────────────────────────────

class _TesterDetailPage extends StatelessWidget {
  final IosInternalTestingRequest request;
  final VoidCallback onRetry;

  const _TesterDetailPage({
    required this.request,
    required this.onRetry,
  });

  bool get _canRetry {
    final s = request.status.trim().toUpperCase();
    switch (s) {
      case 'READY':
      case 'REQUESTED':
      case 'PROCESSING':
      case 'ADDING_TO_INTERNAL_TESTING':
      case 'CANCELLED':
        return false;
      default:
        return true;
    }
  }

  String _helperText(AppLocalizations l10n) {
    final best = request.bestMessage.trim();
    if (best.isNotEmpty) return best;
    final status = request.status.trim().toUpperCase();
    switch (status) {
      case 'READY':
        return l10n.iosInternalTestingReadyHint;
      case 'WAITING_OWNER_ACCEPTANCE':
        return l10n.iosInternalTestingWaitingHint;
      case 'FAILED':
        final err = (request.lastError ?? '').trim();
        return err.isNotEmpty ? err : l10n.iosInternalTestingFailedHint;
      case 'PROCESSING':
        return l10n.iosInternalTestingStatusProcessing;
      case 'REQUESTED':
        return l10n.iosInternalTestingStatusRequested;
      case 'INVITED_TO_APPLE_TEAM':
        return l10n.iosInternalTestingStatusInvitationSent;
      default:
        return '';
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min';
  }

  String _initials() {
    final f = request.firstName.trim();
    final l = request.lastName.trim();
    if (f.isEmpty && l.isEmpty) {
      return request.appleEmail.isNotEmpty
          ? request.appleEmail[0].toUpperCase()
          : '?';
    }
    return '${f.isNotEmpty ? f[0].toUpperCase() : ''}'
        '${l.isNotEmpty ? l[0].toUpperCase() : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fullName = '${request.firstName} ${request.lastName}'.trim();
    final helperText = _helperText(l10n);

    return BlocBuilder<IosInternalTestingManagerBloc,
        IosInternalTestingManagerState>(
      builder: (context, state) {
        final isRetrying = state.submitting &&
            (state.submittingEmail?.trim().toLowerCase() ==
                request.appleEmail.trim().toLowerCase());

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: Text(
              fullName.isNotEmpty ? fullName : request.appleEmail,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: [
              // ── Identity card ──────────────────────────────────────────────
              _DetailSection(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.primary.withOpacity(.12),
                      child: Text(
                        _initials(),
                        style: tt.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fullName.isNotEmpty)
                            Text(
                              fullName,
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(text: request.appleEmail),
                              );
                              AppToast.success(
                                context,
                                'Email copied',
                              );
                            },
                            child: Text(
                              request.appleEmail,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(.68),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          IosInternalTestingStatusChip(
                            status: request.status,
                            compact: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Status message ─────────────────────────────────────────────
              if (helperText.isNotEmpty) ...[
                _DetailSection(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        request.isFailed
                            ? Icons.error_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color:
                            request.isFailed ? cs.error : cs.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          helperText,
                          style: tt.bodyMedium?.copyWith(
                            color: request.isFailed
                                ? cs.error
                                : cs.onSurface.withOpacity(.78),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── App / build snapshot ───────────────────────────────────────
              _DetailSection(
                title: 'App Info',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.apps_rounded,
                      label: 'App name',
                      value: request.appNameSnapshot,
                      cs: cs,
                      tt: tt,
                    ),
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Bundle ID',
                      value: request.bundleIdSnapshot,
                      cs: cs,
                      tt: tt,
                      mono: true,
                      copyable: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Dates ──────────────────────────────────────────────────────
              _DetailSection(
                title: 'Timeline',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Requested',
                      value: _formatDate(request.requestedAt ?? request.createdAt),
                      cs: cs,
                      tt: tt,
                    ),
                    if (request.processedAt != null)
                      _DetailRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Processed',
                        value: _formatDate(request.processedAt),
                        cs: cs,
                        tt: tt,
                      ),
                    if (request.acceptedAt != null)
                      _DetailRow(
                        icon: Icons.verified_outlined,
                        label: 'Accepted',
                        value: _formatDate(request.acceptedAt),
                        cs: cs,
                        tt: tt,
                      ),
                    if (request.readyAt != null)
                      _DetailRow(
                        icon: Icons.rocket_launch_outlined,
                        label: 'Ready',
                        value: _formatDate(request.readyAt),
                        cs: cs,
                        tt: tt,
                      ),
                    if (request.updatedAt != null)
                      _DetailRow(
                        icon: Icons.update_rounded,
                        label: 'Last updated',
                        value: _formatDate(request.updatedAt),
                        cs: cs,
                        tt: tt,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Technical IDs (collapsed by default) ───────────────────────
              if ((request.appleUserId ?? '').isNotEmpty ||
                  (request.appleInvitationId ?? '').isNotEmpty)
                _ExpandableSection(
                  title: 'Technical details',
                  cs: cs,
                  tt: tt,
                  children: [
                    if ((request.appleUserId ?? '').isNotEmpty)
                      _DetailRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Apple User ID',
                        value: request.appleUserId!,
                        cs: cs,
                        tt: tt,
                        mono: true,
                        copyable: true,
                      ),
                    if ((request.appleInvitationId ?? '').isNotEmpty)
                      _DetailRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Invitation ID',
                        value: request.appleInvitationId!,
                        cs: cs,
                        tt: tt,
                        mono: true,
                        copyable: true,
                      ),
                  ],
                ),
              if ((request.appleUserId ?? '').isNotEmpty ||
                  (request.appleInvitationId ?? '').isNotEmpty)
                const SizedBox(height: 12),

              // ── Action ─────────────────────────────────────────────────────
              if (_canRetry)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isRetrying ? null : onRetry,
                    icon: isRetrying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(l10n.common_tryAgain),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Detail section wrapper ───────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String? title;
  final Widget child;

  const _DetailSection({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurface.withOpacity(.50),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;
  final bool mono;
  final bool copyable;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
    this.mono = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(.40)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.48),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                GestureDetector(
                  onLongPress: copyable
                      ? () {
                          Clipboard.setData(ClipboardData(text: value));
                          AppToast.success(context, 'Copied');
                        }
                      : null,
                  child: Text(
                    value,
                    style: tt.bodyMedium?.copyWith(
                      fontFamily: mono ? 'monospace' : null,
                      color: cs.onSurface.withOpacity(.84),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final ColorScheme cs;
  final TextTheme tt;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.cs,
    required this.tt,
    required this.children,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.60)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.code_rounded,
                    size: 16,
                    color: cs.onSurface.withOpacity(.45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.55),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: cs.onSurface.withOpacity(.40),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
                height: 1, color: cs.outlineVariant.withOpacity(.40)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(children: widget.children),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty states ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTester;
  final AppLocalizations l10n;

  const _EmptyState({required this.onAddTester, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_rounded,
              size: 44,
              color: cs.primary.withOpacity(.65),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.iosInternalTestingNoTestersYet,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.iosInternalTestingSectionSubtitle,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(.58),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAddTester,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(l10n.iosInternalTestingAddTesterButton),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmpty extends StatelessWidget {
  final VoidCallback onReset;
  final AppLocalizations l10n;

  const _FilteredEmpty({required this.onReset, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: cs.onSurface.withOpacity(.28),
          ),
          const SizedBox(height: 12),
          Text(
            'No testers match your filters',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.65),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
            label: Text(l10n.common_clear),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final base = cs.surfaceContainerHighest
            .withOpacity(0.45 + 0.20 * _anim.value);
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(.40)),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: base),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 100, height: 13, base: base),
                    const SizedBox(height: 6),
                    _Bone(
                      width: 160,
                      height: 11,
                      base: base.withOpacity(base.opacity * 0.75),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Bone(width: 64, height: 22, base: base, radius: 999),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final Color base;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    required this.base,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Add Tester bottom sheet ───────────────────────────────────────────────────

class _AddTesterSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final bool isFull;
  final IosInternalTestingManagerBloc bloc;
  final VoidCallback onSubmit;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validateFirstName;
  final String? Function(String?) validateLastName;

  const _AddTesterSheet({
    required this.formKey,
    required this.emailCtrl,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.isFull,
    required this.bloc,
    required this.onSubmit,
    required this.validateEmail,
    required this.validateFirstName,
    required this.validateLastName,
  });

  @override
  State<_AddTesterSheet> createState() => _AddTesterSheetState();
}

class _AddTesterSheetState extends State<_AddTesterSheet> {
  StreamSubscription<IosInternalTestingManagerState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.bloc.stream.listen((state) {
      if ((state.message ?? '').trim().isNotEmpty && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    return BlocBuilder<IosInternalTestingManagerBloc,
        IosInternalTestingManagerState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final submitting = state.submitting;

        return Container(
          margin: EdgeInsets.only(top: mq.size.height * 0.12),
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant.withOpacity(.50),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.iosInternalTestingAddTesterTitle,
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.iosInternalTestingRequestSubtitle,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              cs.surfaceContainerHighest.withOpacity(.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: widget.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: widget.emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.iosInternalTestingAppleEmailLabel,
                            hintText: l10n.iosInternalTestingAppleEmailHint,
                            prefixIcon:
                                const Icon(Icons.alternate_email_rounded),
                          ),
                          validator: widget.validateEmail,
                          enabled: !widget.isFull && !submitting,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: widget.firstNameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.iosInternalTestingFirstNameLabel,
                                  hintText:
                                      l10n.iosInternalTestingFirstNameHint,
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: widget.validateFirstName,
                                enabled: !widget.isFull && !submitting,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: widget.lastNameCtrl,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.iosInternalTestingLastNameLabel,
                                  hintText:
                                      l10n.iosInternalTestingLastNameHint,
                                  prefixIcon:
                                      const Icon(Icons.badge_outlined),
                                ),
                                validator: widget.validateLastName,
                                enabled: !widget.isFull && !submitting,
                                onFieldSubmitted: (_) => widget.onSubmit(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                cs.surfaceContainerHighest.withOpacity(.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withOpacity(.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.iosInternalTestingInfoText,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withOpacity(.72),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: (submitting || widget.isFull)
                                ? null
                                : widget.onSubmit,
                            icon: submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_rounded),
                            label:
                                Text(l10n.iosInternalTestingAddTesterButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
