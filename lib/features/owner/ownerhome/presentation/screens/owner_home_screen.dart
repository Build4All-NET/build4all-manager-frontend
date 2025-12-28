import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/shared/widgets/search_input.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart'; // ✅ NEW
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../common/data/repositories/owner_repository_impl.dart';
import '../../../common/data/services/owner_api.dart';
import '../../../common/domain/usecases/get_app_config_uc.dart';
import '../../../common/domain/usecases/get_my_requests_uc.dart';

import '../../domain/usecases/get_available_kinds_from_active_uc.dart';
import '../../data/services/owner_projects_api.dart';
import '../../data/repositories/owner_projects_repository_impl.dart';

import '../bloc/owner_home_bloc.dart';
import '../bloc/owner_home_event.dart';
import '../bloc/owner_home_state.dart';

import '../widgets/request_card.dart';
import '../../data/static_project_models.dart';
import '../widgets/project_template_card.dart';

class OwnerHomeScreen extends StatelessWidget {
  final int ownerId;
  final Dio dio;
  final String? ownerName;

  const OwnerHomeScreen({
    super.key,
    required this.ownerId,
    required this.dio,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final generalRepo = OwnerRepositoryImpl(OwnerApi(dio));

    final projectsRepo = OwnerProjectsRepositoryImpl(OwnerProjectsApi(dio));
    final getAvailableKinds = GetAvailableKindsFromActiveUc(projectsRepo);

    return BlocProvider(
      create: (_) => OwnerHomeBloc(
        getMyRequests: GetMyRequestsUc(generalRepo),
        getAppConfig: GetAppConfigUc(generalRepo),
        getAvailableKinds: getAvailableKinds,
      )..add(OwnerHomeStarted(ownerId)),
      child: _HomeScaffold(ownerName: ownerName),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  final String? ownerName;
  const _HomeScaffold({this.ownerName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: _HomeBody(ownerName: ownerName),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final String? ownerName;
  const _HomeBody({this.ownerName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    final w = MediaQuery.of(context).size.width;
    final pagePad = w >= 480
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
        : ux.pagePad;

    final greeting = (ownerName == null || ownerName!.trim().isEmpty)
        ? l10n.owner_home_hello
        : '${l10n.owner_home_hello} $ownerName';

    final ownerId =
        (context.findAncestorWidgetOfExactType<OwnerHomeScreen>()!).ownerId;

    return Padding(
      padding: pagePad,
      child: BlocConsumer<OwnerHomeBloc, OwnerHomeState>(
        listenWhen: (prev, curr) {
          // ✅ only react when error changes
          final prevErr = _errText(prev);
          final currErr = _errText(curr);
          return prevErr != currErr && (currErr?.isNotEmpty ?? false);
        },
        listener: (context, state) {
          final msg = _errText(state);
          if (msg != null && msg.trim().isNotEmpty) {
            AppToast.error(context, msg);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<OwnerHomeBloc>().add(OwnerHomeRefreshed(ownerId));
              // ✅ optional toast (small info)
              AppToast.info(context, l10n.refresh);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ----- Header -----
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                color: cs.onSurface.withOpacity(.55),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              greeting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.owner_home_subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ----- Search -----
                const SliverToBoxAdapter(
                  child: AppSearchInput(hintKey: 'owner_home_search_hint'),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ----- Choose your project -----
                SliverToBoxAdapter(
                  child: Text(
                    l10n.owner_home_chooseProject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ----- Projects grid (with toast) -----
                SliverPadding(
                  padding: EdgeInsets.only(bottom: ux.radiusMd),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final cross = constraints.crossAxisExtent;

                      // ✅ better responsiveness: choose columns based on width
                      final cols = cross >= 900 ? 4 : (cross >= 600 ? 3 : 2);
                      const spacing = 12.0;

                      final cardW = (cross - (spacing * (cols - 1))) / cols;
                      final aspect =
                          cardW < 190 ? 0.86 : (cardW < 230 ? 0.95 : 1.05);

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: aspect,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final tpl = projectTemplates[i];
                            final kind = tpl.kind.toLowerCase();

                            final isAvailable =
                                state.availableKinds.contains(kind);
                            final int? realProjectId =
                                state.kindToProjectId[kind];

                            return ProjectTemplateCard(
                              tpl: tpl,
                              isAvailable: isAvailable,
                              onOpen: () {
                                if (!isAvailable) {
                                  AppToast.info(
                                      context, l10n.owner_proj_comingSoon);
                                }

                                context.push(
                                  '/owner/project/${tpl.id}',
                                  extra: {
                                    'canRequest': isAvailable,
                                    'projectId': realProjectId, // ✅ nullable
                                  },
                                );
                              },
                            );
                          },
                          childCount: projectTemplates.length,
                        ),
                      );
                    },
                  ),
                ),

                // ----- Recent requests -----
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.owner_home_recentRequests,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // optional tiny toast
                          // AppToast.info(context, l10n.owner_home_openingRequests);
                          context.push('/owner/requests');
                        },
                        child: Text(l10n.owner_home_viewAll),
                      ),
                    ],
                  ),
                ),

                if (state.loading && state.recent.isEmpty)
                  const SliverToBoxAdapter(child: _LoadingList())
                else if (state.recent.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        l10n.owner_home_noRecent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: state.recent.length,
                    itemBuilder: (_, i) => RequestCard(req: state.recent[i]),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ supports multiple possible state shapes without breaking compile
  String? _errText(OwnerHomeState s) {
    try {
      final dynamic d = s;
      final e = d.error ?? d.errorMessage ?? d.message;
      if (e == null) return null;
      final t = e.toString();
      return t.trim().isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(3, (i) {
        return Container(
          height: 64,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.45),
            borderRadius: BorderRadius.circular(14),
          ),
        );
      }),
    );
  }
}
