import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/save_owner_guide_url.dart';
import 'package:build4all_manager/features/superadmin/tutorial/presentation/superadmin/bloc/tutorial_video_event.dart';
import 'package:build4all_manager/features/superadmin/tutorial/presentation/superadmin/widgets/tutorial_video_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../../tutorial/data/repositories/tutorial_repository_impl.dart';
import '../../../tutorial/data/services/tutorial_api.dart';
import '../../../tutorial/domain/usecases/get_owner_guide_video.dart';
import '../../../tutorial/domain/usecases/upload_owner_guide_video.dart';
import '../../../tutorial/presentation/superadmin/bloc/tutorial_video_bloc.dart';
import '../../data/repositories/projects_repository_impl.dart';
import '../../data/services/projects_api.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../bloc/create_project_bloc.dart';
import '../bloc/create_project_event.dart';
import '../bloc/create_project_state.dart';

class _IconOption {
  final String key;
  final IconData icon;
  final String label;

  const _IconOption(this.key, this.icon, this.label);
}

const List<_IconOption> _kIcons = [
  _IconOption('apps_rounded', Icons.apps_rounded, 'Default'),
  _IconOption('shopping_bag_rounded', Icons.shopping_bag_rounded, 'Shopping Bag'),
  _IconOption('shopping_cart_rounded', Icons.shopping_cart_rounded, 'Shopping Cart'),
  _IconOption('store_rounded', Icons.store_rounded, 'Store'),
  _IconOption('restaurant_rounded', Icons.restaurant_rounded, 'Restaurant'),
  _IconOption('fitness_center_rounded', Icons.fitness_center_rounded, 'Fitness'),
  _IconOption('sports_gymnastics', Icons.sports_gymnastics, 'Sports'),
  _IconOption('inventory_2_rounded', Icons.inventory_2_rounded, 'Inventory'),
  _IconOption('warehouse_rounded', Icons.warehouse_rounded, 'Warehouse'),
  _IconOption('location_city_rounded', Icons.location_city_rounded, 'City'),
  _IconOption('account_balance_rounded', Icons.account_balance_rounded, 'Municipality'),
  _IconOption('event_rounded', Icons.event_rounded, 'Events'),
  _IconOption('local_activity_rounded', Icons.local_activity_rounded, 'Activities'),
  _IconOption('miscellaneous_services_rounded', Icons.miscellaneous_services_rounded, 'Services'),
  _IconOption('construction_rounded', Icons.construction_rounded, 'Construction'),
  _IconOption('medical_services_rounded', Icons.medical_services_rounded, 'Medical'),
  _IconOption('school_rounded', Icons.school_rounded, 'School'),
];

class _ColorOption {
  final String hex;
  final String label;

  const _ColorOption(this.hex, this.label);
}

const List<_ColorOption> _kColors = [
  _ColorOption('#2563EB', 'Blue'),
  _ColorOption('#16A34A', 'Green'),
  _ColorOption('#7C3AED', 'Purple'),
  _ColorOption('#EC4899', 'Pink'),
  _ColorOption('#F97316', 'Orange'),
  _ColorOption('#DC2626', 'Red'),
  _ColorOption('#0D9488', 'Teal'),
  _ColorOption('#475569', 'Slate'),
  _ColorOption('#D97706', 'Amber'),
  _ColorOption('#4F46E5', 'Indigo'),
];

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
  final _displayTitle = TextEditingController();
  final _displayDesc = TextEditingController();
  final _displayOrder = TextEditingController();

  bool _active = false;
  List<String> _availableTypes = [];
  String? _selectedType;
  String? _selectedIconName;
  String? _selectedColor;
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    _selectedIconName = _kIcons.first.key;
    _selectedColor = _kColors.first.hex;
    _loadProjectTypes();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _displayTitle.dispose();
    _displayDesc.dispose();
    _displayOrder.dispose();
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
      final api = ProjectsApi(
        dio: widget.dio,
        baseUrl: widget.baseUrl,
      );

      final types = await api.fetchProjectTypes(token: token);

      if (!mounted) return;

      setState(() {
        _availableTypes = types;
        _selectedType = types.isNotEmpty ? types.first : null;
        _loadingTypes = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _availableTypes = [];
        _selectedType = null;
        _loadingTypes = false;
      });

      AppToast.error(context, 'Failed to load project types');
    }
  }

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();

      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }

      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}

    return Colors.grey;
  }

  InputDecoration _fieldDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final api = ProjectsApi(
      dio: widget.dio,
      baseUrl: widget.baseUrl,
    );

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
final saveGuideUrl = SaveOwnerGuideUrl(tutorialRepo);

return TutorialVideoBloc(
  getOwnerGuide: getGuide,
  uploadOwnerGuide: uploadGuide,
  saveOwnerGuideUrl: saveGuideUrl,
  tokenProvider: widget.tokenProvider,
)..add(const TutorialVideoStarted());
      },
    ),
  ],
  child: Builder(
    builder: (blocContext) {
      return DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  l10n.super_create_project_subtitle,
                  style: Theme.of(blocContext).textTheme.bodyMedium,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(blocContext)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(.65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Theme.of(blocContext).colorScheme.surface,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.ondemand_video_rounded),
                        text: 'Tutorial',
                      ),
                      Tab(
                        icon: Icon(Icons.add_business_rounded),
                        text: 'Create Project',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  children: [
                    _TutorialTab(
                      dioBaseUrl: widget.dio.options.baseUrl,
                    ),
                    _CreateProjectFormTab(
                      loadingTypes: _loadingTypes,
                      availableTypes: _availableTypes,
                      selectedType: _selectedType,
                      selectedIconName: _selectedIconName,
                      selectedColor: _selectedColor,
                      active: _active,
                      name: _name,
                      desc: _desc,
                      displayTitle: _displayTitle,
                      displayDesc: _displayDesc,
                      displayOrder: _displayOrder,
                      fieldDecoration: _fieldDecoration,
                      hexToColor: _hexToColor,
                      onTypeChanged: (value) {
                        setState(() => _selectedType = value);
                      },
                      onIconChanged: (value) {
                        setState(() => _selectedIconName = value);
                      },
                      onColorChanged: (value) {
                        setState(() => _selectedColor = value);
                      },
                      onActiveChanged: (value) {
                        setState(() => _active = value);
                      },

                      // ✅ IMPORTANT FIX:
                      // use blocContext, not the parent context
                      onSubmit: () => _submit(blocContext),
                      onReset: () => _resetForm(blocContext),
                    ),
                  ],
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

  void _resetForm(BuildContext context) {
    context.read<CreateProjectBloc>().add(CreateProjectReset());

    _name.clear();
    _desc.clear();
    _displayTitle.clear();
    _displayDesc.clear();
    _displayOrder.clear();

    setState(() {
      _active = false;
      _selectedType = _availableTypes.isNotEmpty ? _availableTypes.first : null;
      _selectedIconName = _kIcons.first.key;
      _selectedColor = _kColors.first.hex;
    });
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

    String? clean(TextEditingController ctrl) {
      final value = ctrl.text.trim();
      return value.isEmpty ? null : value;
    }

    final orderRaw = _displayOrder.text.trim();
    final orderInt = orderRaw.isEmpty ? null : int.tryParse(orderRaw);

    context.read<CreateProjectBloc>().add(
          CreateProjectSubmitted(
            projectName: name,
            description: desc.isEmpty ? null : desc,
            active: _active,
            projectType: _selectedType!,
            displayTitle: clean(_displayTitle),
            displayDescription: clean(_displayDesc),
            iconName: _selectedIconName,
            cardColor: _selectedColor,
            displayOrder: orderInt,
          ),
        );
  }
}

class _TutorialTab extends StatelessWidget {
  final String dioBaseUrl;

  const _TutorialTab({
    required this.dioBaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TutorialVideoCard(
          dioBaseUrl: dioBaseUrl,
        ),
      ],
    );
  }
}

class _CreateProjectFormTab extends StatelessWidget {
  final bool loadingTypes;
  final List<String> availableTypes;
  final String? selectedType;
  final String? selectedIconName;
  final String? selectedColor;
  final bool active;

  final TextEditingController name;
  final TextEditingController desc;
  final TextEditingController displayTitle;
  final TextEditingController displayDesc;
  final TextEditingController displayOrder;

  final InputDecoration Function(BuildContext context) fieldDecoration;
  final Color Function(String hex) hexToColor;

  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onIconChanged;
  final ValueChanged<String?> onColorChanged;
  final ValueChanged<bool> onActiveChanged;

  final VoidCallback onSubmit;
  final VoidCallback onReset;

  const _CreateProjectFormTab({
    required this.loadingTypes,
    required this.availableTypes,
    required this.selectedType,
    required this.selectedIconName,
    required this.selectedColor,
    required this.active,
    required this.name,
    required this.desc,
    required this.displayTitle,
    required this.displayDesc,
    required this.displayOrder,
    required this.fieldDecoration,
    required this.hexToColor,
    required this.onTypeChanged,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.onActiveChanged,
    required this.onSubmit,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final sectionTitle = tt.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );

    final labelStyle = tt.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return BlocConsumer<CreateProjectBloc, CreateProjectState>(
      listener: (context, state) {
        if (state is CreateProjectSuccess) {
          AppToast.success(
            context,
            l10n.super_create_project_success(state.project.projectName),
          );
        }

        if (state is CreateProjectFailure) {
          AppToast.error(
            context,
            _prettyError(context, state.message),
          );
        }
      },
      builder: (context, state) {
        final loading = state is CreateProjectLoading;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

            Text(
              'Basic Information',
              style: sectionTitle,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: fieldDecoration(context).copyWith(
                labelText: l10n.super_project_name,
                hintText: l10n.super_project_name_hint,
                prefixIcon: const Icon(Icons.folder_rounded),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: desc,
              minLines: 3,
              maxLines: 5,
              decoration: fieldDecoration(context).copyWith(
                labelText: l10n.super_project_description,
                hintText: l10n.super_project_description_hint,
                prefixIcon: const Icon(Icons.description_rounded),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              l10n.super_project_type,
              style: labelStyle,
            ),

            const SizedBox(height: 6),

            if (loadingTypes)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (availableTypes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No project types available from backend'),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedType,
                isExpanded: true,
                decoration: fieldDecoration(context).copyWith(
                  hintText: 'Select project type',
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: availableTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: loading ? null : onTypeChanged,
              ),

            const SizedBox(height: 20),

            Divider(
              color: cs.outlineVariant.withOpacity(.55),
            ),

            const SizedBox(height: 12),

            Text(
              'Card Display',
              style: sectionTitle,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: displayTitle,
              decoration: fieldDecoration(context).copyWith(
                labelText: l10n.super_proj_display_title,
                hintText: l10n.super_proj_display_title_hint,
                prefixIcon: const Icon(Icons.title_rounded),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: displayDesc,
              minLines: 2,
              maxLines: 4,
              decoration: fieldDecoration(context).copyWith(
                labelText: l10n.super_proj_display_description,
                hintText: l10n.super_proj_display_description_hint,
                prefixIcon: const Icon(Icons.short_text_rounded),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              l10n.super_proj_icon_name,
              style: labelStyle,
            ),

            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: selectedIconName,
              isExpanded: true,
              decoration: fieldDecoration(context).copyWith(
                hintText: l10n.super_proj_icon_name_hint,
              ),
              items: _kIcons
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.key,
                      child: Row(
                        children: [
                          Icon(
                            opt.icon,
                            size: 20,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (_) {
                return _kIcons
                    .map(
                      (opt) => Row(
                        children: [
                          Icon(
                            opt.icon,
                            size: 20,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList();
              },
              onChanged: loading ? null : onIconChanged,
            ),

            const SizedBox(height: 16),

            Text(
              l10n.super_proj_card_color,
              style: labelStyle,
            ),

            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: selectedColor,
              isExpanded: true,
              decoration: fieldDecoration(context).copyWith(
                hintText: l10n.super_proj_card_color_hint,
              ),
              items: _kColors
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.hex,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: hexToColor(opt.hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.outlineVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${opt.label}  ${opt.hex}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (_) {
                return _kColors
                    .map(
                      (opt) => Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: hexToColor(opt.hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.outlineVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${opt.label}  ${opt.hex}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList();
              },
              onChanged: loading ? null : onColorChanged,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: displayOrder,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: fieldDecoration(context).copyWith(
                labelText: l10n.super_proj_display_order,
                hintText: l10n.super_proj_display_order_hint,
                prefixIcon: const Icon(Icons.sort_rounded),
              ),
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: active,
              onChanged: loading ? null : onActiveChanged,
              title: Text(l10n.super_project_active),
              subtitle: Text(l10n.super_project_active_hint),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (loading || loadingTypes) ? null : onSubmit,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
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
                  onPressed: onReset,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.super_create_another),
                ),
              ),
          ],
        );
      },
    );
  }

  String _prettyError(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    final s = raw.toLowerCase();

    if (s.contains('project name already exists')) {
      return l10n.super_project_name_exists;
    }

    if (s.contains('403') || s.contains('forbidden')) {
      return l10n.common_forbidden;
    }

    if (s.contains('401') || s.contains('unauthorized')) {
      return l10n.common_unauthorized;
    }

    return raw;
  }
}

enum _BannerKind {
  success,
  error,
}

class _InlineBanner extends StatelessWidget {
  final _BannerKind kind;
  final String text;

  const _InlineBanner({
    required this.kind,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = kind == _BannerKind.success
        ? cs.primaryContainer
        : cs.errorContainer;

    final fg = kind == _BannerKind.success
        ? cs.onPrimaryContainer
        : cs.onErrorContainer;

    final icon = kind == _BannerKind.success
        ? Icons.check_circle
        : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: fg,
          ),
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