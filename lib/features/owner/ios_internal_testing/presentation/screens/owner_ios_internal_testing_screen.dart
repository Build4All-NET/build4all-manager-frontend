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
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();

    _bloc = IosInternalTestingManagerBloc(
      createRequestUc: widget.createUc,
      getSummaryUc: widget.summaryUc,
    )..add(
        IosInternalTestingManagerStarted(
          linkId: widget.project.linkId,
        ),
      );

    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _firstNameCtrl = TextEditingController(text: widget.initialFirstName);
    _lastNameCtrl = TextEditingController(text: widget.initialLastName);
  }

  @override
  void dispose() {
    _bloc.close();
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    _bloc.add(
      IosInternalTestingManagerSubmitted(
        linkId: widget.project.linkId,
        appleEmail: _emailCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      ),
    );
  }

  String _statusHelperText(
    AppLocalizations l10n,
    IosInternalTestingRequest request,
  ) {
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

  String? _validateEmail(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    final value = (v ?? '').trim();

    if (value.isEmpty) return l10n.iosInternalTestingEmailRequired;

    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (!ok) return l10n.errEmailInvalid;

    return null;
  }

  String? _validateFirstName(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    final value = (v ?? '').trim();

    if (value.isEmpty) return l10n.iosInternalTestingFirstNameRequired;
    if (value.length < 2) return l10n.iosInternalTestingFirstNameMin;
    if (value.length > 100) return l10n.iosInternalTestingFirstNameTooLong;

    return null;
  }

  String? _validateLastName(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    final value = (v ?? '').trim();

    if (value.isEmpty) return l10n.iosInternalTestingLastNameRequired;
    if (value.length < 2) return l10n.iosInternalTestingLastNameMin;
    if (value.length > 100) return l10n.iosInternalTestingLastNameTooLong;

    return null;
  }

  String _toastMessage(AppLocalizations l10n, String? rawMessage) {
    final msg = (rawMessage ?? '').trim();
    if (msg.isNotEmpty) return msg;
    return l10n.iosInternalTestingSubmittedMessage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appName = widget.project.appName.isNotEmpty
        ? widget.project.appName
        : widget.project.projectName;

    final bundleId = (widget.project.iosBundleId ?? '').trim();

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<IosInternalTestingManagerBloc,
          IosInternalTestingManagerState>(
        listener: (context, state) {
          if ((state.error ?? '').trim().isNotEmpty) {
            AppToast.error(
              context,
              state.error!.replaceFirst('Exception: ', ''),
            );
            context
                .read<IosInternalTestingManagerBloc>()
                .add(const IosInternalTestingManagerErrorCleared());
          }

          if ((state.message ?? '').trim().isNotEmpty) {
            AppToast.success(
              context,
              _toastMessage(l10n, state.message),
            );
            context
                .read<IosInternalTestingManagerBloc>()
                .add(const IosInternalTestingManagerMessageCleared());
          }
        },
        builder: (context, state) {
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
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(.65),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (bundleId.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          SelectableText(
                            bundleId,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.70),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cs.primary.withOpacity(.20),
                                ),
                              ),
                              child: Text(
                                '${state.usedSlots} / ${state.maxSlots} ${l10n.iosInternalTestingSlotsUsedLabel}',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (state.loading)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${l10n.iosInternalTestingRemainingSlotsLabel}: ${state.remainingSlots}',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(.72),
                          ),
                        ),
                        if (state.isFull) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.error.withOpacity(.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.error.withOpacity(.16),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: cs.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.iosInternalTestingCapacityReachedMessage,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.error,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(.65),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.iosInternalTestingAddTesterTitle,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.iosInternalTestingRequestSubtitle,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.72),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.iosInternalTestingAppleEmailLabel,
                              hintText: l10n.iosInternalTestingAppleEmailHint,
                              prefixIcon:
                                  const Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (v) => _validateEmail(context, v),
                            enabled: !state.isFull && !state.submitting,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameCtrl,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText:
                                        l10n.iosInternalTestingFirstNameLabel,
                                    hintText:
                                        l10n.iosInternalTestingFirstNameHint,
                                    prefixIcon:
                                        const Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (v) =>
                                      _validateFirstName(context, v),
                                  enabled: !state.isFull && !state.submitting,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameCtrl,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText:
                                        l10n.iosInternalTestingLastNameLabel,
                                    hintText:
                                        l10n.iosInternalTestingLastNameHint,
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) =>
                                      _validateLastName(context, v),
                                  enabled: !state.isFull && !state.submitting,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withOpacity(.45),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(.28),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.iosInternalTestingInfoText,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(.78),
                                      height: 1.35,
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
                              onPressed:
                                  state.submitting || state.isFull ? null : _submit,
                              icon: state.submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_rounded),
                              label: Text(
                                l10n.iosInternalTestingAddTesterButton,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.iosInternalTestingTesterListTitle,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!state.hasRequests && !state.loading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(.65),
                        ),
                      ),
                      child: Text(
                        l10n.iosInternalTestingNoTestersYet,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.72),
                        ),
                      ),
                    )
                  else
                    ...state.requests.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TesterCard(
                          request: request,
                          helperText: _statusHelperText(l10n, request),
                        ),
                      ),
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

class _TesterCard extends StatelessWidget {
  final IosInternalTestingRequest request;
  final String helperText;

  const _TesterCard({
    required this.request,
    required this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final email = request.appleEmail.trim();
    final fullName = '${request.firstName} ${request.lastName}'.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
                child: SelectableText(
                  email,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              IosInternalTestingStatusChip(
                status: request.status,
                compact: true,
              ),
            ],
          ),
          if (fullName.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              fullName,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(.74),
                height: 1.3,
              ),
            ),
          ],
          if (helperText.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              helperText,
              style: tt.bodySmall?.copyWith(
                color: request.isFailed
                    ? cs.error
                    : cs.onSurface.withOpacity(.72),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}