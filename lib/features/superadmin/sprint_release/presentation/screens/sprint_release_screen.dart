import 'package:build4all_manager/features/superadmin/sprint_release/presentation/bloc/sprint_release_bloc.dart';
import 'package:build4all_manager/features/superadmin/sprint_release/presentation/bloc/sprint_release_event.dart';
import 'package:build4all_manager/features/superadmin/sprint_release/presentation/bloc/sprint_release_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SprintReleaseScreen extends StatelessWidget {
  const SprintReleaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SprintReleaseBloc()..add(SprintReleaseLoadPat()),
      child: const _SprintReleaseView(),
    );
  }
}

class _SprintReleaseView extends StatefulWidget {
  const _SprintReleaseView();

  @override
  State<_SprintReleaseView> createState() => _SprintReleaseViewState();
}

class _SprintReleaseViewState extends State<_SprintReleaseView> {
  final _sprintNameCtrl = TextEditingController();
  final _patCtrl = TextEditingController();
  bool _patVisible = false;
  bool _patExpanded = false;

  @override
  void dispose() {
    _sprintNameCtrl.dispose();
    _patCtrl.dispose();
    super.dispose();
  }

  void _trigger(BuildContext context, SprintReleaseState state) {
    final sprint = _sprintNameCtrl.text.trim();
    if (sprint.isEmpty) {
      _snack(context, 'Please enter a sprint name');
      return;
    }
    final pat = state.savedPat ?? '';
    if (pat.isEmpty) {
      _snack(context, 'Please configure a GitHub PAT first');
      setState(() => _patExpanded = true);
      return;
    }
    context
        .read<SprintReleaseBloc>()
        .add(SprintReleaseTrigger(pat: pat, sprintName: sprint));
  }

  void _snack(BuildContext context, String msg, {Color? color}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<SprintReleaseBloc, SprintReleaseState>(
      listener: (context, state) {
        if (state.status == SprintReleaseStatus.success) {
          _snack(context, 'Workflow triggered — check GitHub Actions',
              color: Colors.green);
          _sprintNameCtrl.clear();
        } else if (state.status == SprintReleaseStatus.failure) {
          _snack(context, state.error ?? 'Failed to trigger workflow',
              color: cs.error);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: 20),
              _PatSection(
                expanded: _patExpanded,
                hasSavedPat: state.savedPat != null,
                ctrl: _patCtrl,
                visible: _patVisible,
                onToggleExpand: () =>
                    setState(() => _patExpanded = !_patExpanded),
                onToggleVisibility: () =>
                    setState(() => _patVisible = !_patVisible),
                onSave: () {
                  final pat = _patCtrl.text.trim();
                  if (pat.isEmpty) return;
                  context
                      .read<SprintReleaseBloc>()
                      .add(SprintReleaseSavePat(pat));
                  _patCtrl.clear();
                  setState(() => _patExpanded = false);
                  _snack(context, 'PAT saved to device keychain');
                },
                onClear: () {
                  context
                      .read<SprintReleaseBloc>()
                      .add(SprintReleaseClearPat());
                  _snack(context, 'PAT removed');
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Sprint Name',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sprintNameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. sprint-25',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _trigger(context, state),
              ),
              const SizedBox(height: 6),
              Text(
                'Lowercase letters, numbers, and hyphens only (used as a git branch name).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      state.status == SprintReleaseStatus.loading
                          ? null
                          : () => _trigger(context, state),
                  icon: state.status == SprintReleaseStatus.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_outlined),
                  label: Text(
                    state.status == SprintReleaseStatus.loading
                        ? 'Triggering…'
                        : 'Trigger Sprint Release',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _WhatHappensCard(),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.rocket_launch_outlined,
              color: cs.onPrimaryContainer, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sprint Release',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Triggers sprint-release.yml on build4all-manager-frontend',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatSection extends StatelessWidget {
  final bool expanded;
  final bool hasSavedPat;
  final TextEditingController ctrl;
  final bool visible;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const _PatSection({
    required this.expanded,
    required this.hasSavedPat,
    required this.ctrl,
    required this.visible,
    required this.onToggleExpand,
    required this.onToggleVisibility,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasSavedPat
              ? cs.primary.withOpacity(.4)
              : cs.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.key_outlined,
                    color: hasSavedPat
                        ? cs.primary
                        : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GitHub PAT',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          hasSavedPat
                              ? 'Configured ✔'
                              : 'Not configured — tap to add',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: hasSavedPat
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ..._expandedContent(context, cs),
        ],
      ),
    );
  }

  List<Widget> _expandedContent(
      BuildContext context, ColorScheme cs) {
    return [
      Divider(height: 1, color: cs.outlineVariant),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stored securely in the device keychain. '
              'Required GitHub permissions: Actions → Read & Write.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: !visible,
              decoration: InputDecoration(
                hintText: 'github_pat_…',
                prefixIcon:
                    const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: onToggleVisibility,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onSave,
                    child: const Text('Save Token'),
                  ),
                ),
                if (hasSavedPat) ...[    
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onClear,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class _WhatHappensCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What this triggers',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final step in [
            (
              '1',
              'UAT main is pushed to build4all-manager-frontend-prod as a release branch'
            ),
            (
              '2',
              'Prod-specific files are preserved: Firebase configs, bundle IDs, hostIp'
            ),
            (
              '3',
              'A pull request is opened on the prod repo for review and merge'
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      step.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: Theme.of(context).textTheme.bodySmall,
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
