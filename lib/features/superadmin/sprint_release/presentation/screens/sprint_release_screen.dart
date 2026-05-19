import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sprint_release_cubit.dart';
import '../cubit/sprint_release_state.dart';

class SprintReleaseScreen extends StatefulWidget {
  const SprintReleaseScreen({super.key});

  @override
  State<SprintReleaseScreen> createState() => _SprintReleaseScreenState();
}

class _SprintReleaseScreenState extends State<SprintReleaseScreen> {
  final _sprintCtrl = TextEditingController();
  final _patCtrl = TextEditingController();
  bool _patObscured = true;

  @override
  void initState() {
    super.initState();
    context.read<SprintReleaseCubit>().loadPat().then((pat) {
      if (mounted) _patCtrl.text = pat;
    });
  }

  @override
  void dispose() {
    _sprintCtrl.dispose();
    _patCtrl.dispose();
    super.dispose();
  }

  void _trigger() {
    context.read<SprintReleaseCubit>().trigger(
          pat: _patCtrl.text,
          sprintName: _sprintCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<SprintReleaseCubit, SprintReleaseState>(
      listener: (context, state) {
        if (state is SprintReleaseSuccess) {
          _sprintCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade700,
              content: Text(
                '"${state.sprintName}" release triggered successfully.',
              ),
            ),
          );
          context.read<SprintReleaseCubit>().reset();
        }
        if (state is SprintReleaseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: cs.error,
              content: Text(state.message),
            ),
          );
          context.read<SprintReleaseCubit>().reset();
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'GitHub PAT',
              subtitle: 'Saved locally. Required to trigger workflows on the private repo.',
              child: TextField(
                controller: _patCtrl,
                obscureText: _patObscured,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _patObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _patObscured = !_patObscured),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Sprint Release',
              subtitle: 'Triggers the sprint-release workflow and opens a PR on the prod repo.',
              child: Column(
                children: [
                  TextField(
                    controller: _sprintCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sprint name',
                      hintText: 'sprint-25',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<SprintReleaseCubit, SprintReleaseState>(
                    builder: (context, state) {
                      final loading = state is SprintReleaseLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loading ? null : _trigger,
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.rocket_launch_rounded),
                          label: Text(
                            loading ? 'Triggering...' : 'Trigger Sprint Release',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The PAT needs Actions: Read & Write + Contents: Read on the build4all-manager-frontend repo.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
