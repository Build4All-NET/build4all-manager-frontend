import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../data/repositories/projects_repository_impl.dart';
import '../../data/services/projects_api.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../bloc/create_project_bloc.dart';
import '../bloc/create_project_event.dart';
import '../bloc/create_project_state.dart';
import '../widgets/project_type_chip.dart';

class CreateProjectScreen extends StatefulWidget {
  final Dio dio;
  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  const CreateProjectScreen({
    super.key,
    required this.dio,
    required this.baseUrl,
    required this.tokenProvider,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _active = true;
  ProjectType _type = ProjectType.ECOMMERCE;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final api = ProjectsApi(dio: widget.dio, baseUrl: widget.baseUrl);
    final repo = ProjectsRepositoryImpl(api);
    final usecase = CreateProjectUseCase(repo);

    return BlocProvider(
      create: (_) => CreateProjectBloc(
        usecase: usecase,
        tokenProvider: widget.tokenProvider,
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 6),
                  Text(
                    l10n.super_create_project_subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  BlocConsumer<CreateProjectBloc, CreateProjectState>(
                    listener: (context, state) {
                      if (state is CreateProjectSuccess) {
                        AppToast.success(
                          context,
                          l10n.super_create_project_success(
                              state.project.projectName),
                        );
                      }
                      if (state is CreateProjectFailure) {
                        AppToast.error(context, state.message);
                      }
                    },
                    builder: (context, state) {
                      final loading = state is CreateProjectLoading;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state is CreateProjectFailure)
                            _InlineBanner(
                              kind: _BannerKind.error,
                              text: _prettyError(context, state.message),
                            ),
                          if (state is CreateProjectSuccess)
                            _InlineBanner(
                              kind: _BannerKind.success,
                              text: l10n.super_create_project_created_id(
                                state.project.id.toString(),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.super_project_name,
                              hintText: l10n.super_project_name_hint,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _desc,
                            minLines: 3,
                            maxLines: 6,
                            decoration: InputDecoration(
                              labelText: l10n.super_project_description,
                              hintText: l10n.super_project_description_hint,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.super_project_type,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ProjectTypeChip(
                                type: ProjectType.ECOMMERCE,
                                selected: _type == ProjectType.ECOMMERCE,
                                label: l10n.project_type_ecommerce,
                                onTap: () => setState(
                                    () => _type = ProjectType.ECOMMERCE),
                              ),
                              ProjectTypeChip(
                                type: ProjectType.SERVICES,
                                selected: _type == ProjectType.SERVICES,
                                label: l10n.project_type_services,
                                onTap: () => setState(
                                    () => _type = ProjectType.SERVICES),
                              ),
                              ProjectTypeChip(
                                type: ProjectType.ACTIVITIES,
                                selected: _type == ProjectType.ACTIVITIES,
                                label: l10n.project_type_activities,
                                onTap: () => setState(
                                    () => _type = ProjectType.ACTIVITIES),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: _active,
                            onChanged: loading
                                ? null
                                : (v) => setState(() => _active = v),
                            title: Text(l10n.super_project_active),
                            subtitle: Text(l10n.super_project_active_hint),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  loading ? null : () => _submit(context),
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                loading
                                    ? l10n.common_loading
                                    : l10n.super_create_project_btn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (state is CreateProjectSuccess)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context
                                      .read<CreateProjectBloc>()
                                      .add(CreateProjectReset());
                                  _name.clear();
                                  _desc.clear();
                                  setState(() {
                                    _active = true;
                                    _type = ProjectType.ECOMMERCE;
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: Text(l10n.super_create_another),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    final desc = _desc.text.trim();

    if (name.isEmpty) {
      AppToast.error(context, l10n.super_project_name_required);
      return;
    }

    context.read<CreateProjectBloc>().add(
          CreateProjectSubmitted(
            projectName: name,
            description: desc.isEmpty ? null : desc,
            active: _active,
            projectType: _type,
          ),
        );
  }

  String _prettyError(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;

    // If backend returns {"error":"..."} Dio prints a lot of junk sometimes.
    final s = raw.toLowerCase();

    if (s.contains("project name already exists")) {
      return l10n.super_project_name_exists;
    }
    if (s.contains("403") || s.contains("forbidden")) {
      return l10n.common_forbidden;
    }
    if (s.contains("401") || s.contains("unauthorized")) {
      return l10n.common_unauthorized;
    }
    return raw;
  }
}

enum _BannerKind { success, error }

class _InlineBanner extends StatelessWidget {
  final _BannerKind kind;
  final String text;

  const _InlineBanner({required this.kind, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg =
        kind == _BannerKind.success ? cs.primaryContainer : cs.errorContainer;
    final fg = kind == _BannerKind.success
        ? cs.onPrimaryContainer
        : cs.onErrorContainer;
    final icon =
        kind == _BannerKind.success ? Icons.check_circle : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
