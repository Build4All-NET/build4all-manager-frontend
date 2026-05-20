import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sprint_release_cubit.dart';
import '../cubit/sprint_release_state.dart';
import '../../data/github_dispatch_service.dart';

class SprintReleaseScreen extends StatefulWidget {
  const SprintReleaseScreen({super.key});

  @override
  State<SprintReleaseScreen> createState() => _SprintReleaseScreenState();
}

class _SprintReleaseScreenState extends State<SprintReleaseScreen> {
  final _patCtrl = TextEditingController();
  bool _patObscured = true;
  WorkflowJob _selectedJob = WorkflowJob.sprintRelease;

  final _sprintCtrl = TextEditingController();
  String _androidTrack = 'internal';
  String _androidStatus = 'draft';
  final _androidChangelogCtrl = TextEditingController(text: 'CI build');
  final _iosChangelogCtrl = TextEditingController(text: 'CI build');

  @override
  void initState() {
    super.initState();
    context.read<SprintReleaseCubit>().loadPat().then((pat) {
      if (mounted) _patCtrl.text = pat;
    });
  }

  @override
  void dispose() {
    _patCtrl.dispose();
    _sprintCtrl.dispose();
    _androidChangelogCtrl.dispose();
    _iosChangelogCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _buildInputs() {
    switch (_selectedJob) {
      case WorkflowJob.sprintRelease:
        return {'sprint_name': _sprintCtrl.text.trim()};
      case WorkflowJob.androidBuild:
        return {
          'track': _androidTrack,
          'release_status': _androidStatus,
          'changelog': _androidChangelogCtrl.text.trim(),
        };
      case WorkflowJob.iosBuild:
        return {'changelog': _iosChangelogCtrl.text.trim()};
    }
  }

  bool _inputsValid() {
    if (_selectedJob == WorkflowJob.sprintRelease) {
      return _sprintCtrl.text.trim().isNotEmpty;
    }
    return true;
  }

  void _trigger() {
    if (!_inputsValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all required fields.')),
      );
      return;
    }
    context.read<SprintReleaseCubit>().trigger(
          pat: _patCtrl.text,
          job: _selectedJob,
          inputs: _buildInputs(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<SprintReleaseCubit, SprintReleaseState>(
      listener: (context, state) {
        if (state is SprintReleaseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade700,
              content: Text('${state.job.label} triggered on GitHub.'),
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
              subtitle: 'Saved locally. Needs Actions: Write on this repo.',
              child: TextField(
                controller: _patCtrl,
                obscureText: _patObscured,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_patObscured
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _patObscured = !_patObscured),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Workflow',
              subtitle: 'Select which workflow to run.',
              child: Column(
                children: [
                  for (final job in WorkflowJob.values)
                    RadioListTile<WorkflowJob>(
                      value: job,
                      groupValue: _selectedJob,
                      title: Text(job.label),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedJob = v);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInputsCard(),
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
                        loading ? 'Triggering...' : 'Run ${_selectedJob.label}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputsCard() {
    switch (_selectedJob) {
      case WorkflowJob.sprintRelease:
        return _SectionCard(
          title: 'Inputs',
          subtitle: 'Opens a PR from UAT to Prod.',
          child: TextField(
            controller: _sprintCtrl,
            decoration: const InputDecoration(
              labelText: 'Sprint name *',
              hintText: 'sprint-25',
              border: OutlineInputBorder(),
            ),
          ),
        );
      case WorkflowJob.androidBuild:
        return _SectionCard(
          title: 'Inputs',
          subtitle: 'Builds AAB and uploads to Google Play.',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _androidTrack,
                decoration: const InputDecoration(
                    labelText: 'Track', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                  DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
                  DropdownMenuItem(value: 'beta', child: Text('Beta')),
                  DropdownMenuItem(
                      value: 'production', child: Text('Production')),
                ],
                onChanged: (v) =>
                    setState(() => _androidTrack = v ?? 'internal'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _androidStatus,
                decoration: const InputDecoration(
                    labelText: 'Release status',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                      value: 'inProgress', child: Text('In Progress')),
                  DropdownMenuItem(
                      value: 'completed', child: Text('Completed')),
                ],
                onChanged: (v) =>
                    setState(() => _androidStatus = v ?? 'draft'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _androidChangelogCtrl,
                decoration: const InputDecoration(
                  labelText: 'Changelog',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      case WorkflowJob.iosBuild:
        return _SectionCard(
          title: 'Inputs',
          subtitle: 'Builds IPA and uploads to TestFlight.',
          child: TextField(
            controller: _iosChangelogCtrl,
            decoration: const InputDecoration(
              labelText: 'Changelog',
              border: OutlineInputBorder(),
            ),
          ),
        );
    }
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
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
