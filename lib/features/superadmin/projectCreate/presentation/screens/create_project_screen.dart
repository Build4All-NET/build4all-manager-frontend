import 'package:build4all_manager/features/superadmin/tutorial/presentation/superadmin/bloc/tutorial_video_event.dart';
import 'package:build4all_manager/features/superadmin/tutorial/presentation/superadmin/widgets/tutorial_video_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../../tutorial/presentation/superadmin/bloc/tutorial_video_bloc.dart';
import '../../data/repositories/projects_repository_impl.dart';
import '../../data/services/projects_api.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../bloc/create_project_bloc.dart';
import '../bloc/create_project_event.dart';
import '../bloc/create_project_state.dart';

import '../../../tutorial/data/services/tutorial_api.dart';
import '../../../tutorial/data/repositories/tutorial_repository_impl.dart';
import '../../../tutorial/domain/usecases/get_owner_guide_video.dart';
import '../../../tutorial/domain/usecases/upload_owner_guide_video.dart';

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

  // Project types now come from backend, so this is dynamic.
  List<String> _availableTypes = [];
  String? _selectedType;
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    _loadProjectTypes();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _loadProjectTypes() async {
    final token = await widget.tokenProvider();

    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _availableTypes = [];
        _selectedType = null;
        _loadingTypes = false;
      });
      return;
    }

    try {
      final api = ProjectsApi(dio: widget.dio, baseUrl: widget.baseUrl);
      final types = await api.fetchProjectTypes(token: token);

      if (!mounted) return;
      setState(() {
        _availableTypes = types;
        _selectedType = types.isNotEmpty ? types.first : null;
        _loadingTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableTypes = [];
        _selectedType = null;
        _loadingTypes = false;
      });

      AppToast.error(context, 'Failed to load project types');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final api = ProjectsApi(dio: widget.dio, baseUrl: widget.baseUrl);
    final repo = ProjectsRepositoryImpl(api);
    final usecase = CreateProjectUseCase(repo);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CreateProjectBloc(
            usecase: usecase,
            tokenProvider: widget.tokenProvider,
          ),
        ),
        BlocProvider(
          create: (_) {
            final tutorialApi = TutorialApi(widget.dio);
            final tutorialRepo = TutorialRepositoryImpl(tutorialApi);
            final getGuide = GetOwnerGuideVideo(tutorialRepo);
            final uploadGuide = UploadOwnerGuideVideo(tutorialRepo);

            return TutorialVideoBloc(
              getOwnerGuide: getGuide,
              uploadOwnerGuide: uploadGuide,
              tokenProvider: widget.tokenProvider,
            )..add(const TutorialVideoStarted());
          },
        ),
      ],
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 6),
            Text(
              l10n.super_create_project_subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            TutorialVideoCard(dioBaseUrl: widget.dio.options.baseUrl),
            const SizedBox(height: 16),

            BlocConsumer<CreateProjectBloc, CreateProjectState>(
              listener: (context, state) {
                if (state is CreateProjectSuccess) {
                  AppToast.success(
                    context,
                    l10n.super_create_project_success(
                      state.project.projectName,
                    ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),

                    if (_loadingTypes)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableTypes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withOpacity(.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No project types available from backend',
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _availableTypes.map((type) {
                          final selected = _selectedType == type;

                          return ChoiceChip(
                            selected: selected,
                            onSelected: loading
                                ? null
                                : (_) => setState(() => _selectedType = type),
                            label: Text(type),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 12),

                    SwitchListTile(
                      value: _active,
                      onChanged:
                          loading ? null : (v) => setState(() => _active = v),
                      title: Text(l10n.super_project_active),
                      subtitle: Text(l10n.super_project_active_hint),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (loading || _loadingTypes)
                            ? null
                            : () => _submit(context),
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                              _selectedType = _availableTypes.isNotEmpty
                                  ? _availableTypes.first
                                  : null;
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
  }

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    final desc = _desc.text.trim();

    if (name.isEmpty) {
      AppToast.error(context, l10n.super_project_name_required);
      return;
    }

    if (_selectedType == null || _selectedType!.trim().isEmpty) {
      AppToast.error(context, 'Please select a project type');
      return;
    }

    context.read<CreateProjectBloc>().add(
          CreateProjectSubmitted(
            projectName: name,
            description: desc.isEmpty ? null : desc,
            active: _active,
            projectType: _selectedType!,
          ),
        );
  }

  String _prettyError(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
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