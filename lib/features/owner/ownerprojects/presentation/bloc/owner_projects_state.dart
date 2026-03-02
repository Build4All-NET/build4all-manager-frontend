import 'package:equatable/equatable.dart';
import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';

class OwnerProjectsState extends Equatable {
  final bool loading;
  final List<OwnerProject> all;
  final String query;
  final bool onlyReady;
  final String? error;

  const OwnerProjectsState({
    this.loading = false,
    this.all = const [],
    this.query = '',
    this.onlyReady = false,
    this.error,
  });

  List<OwnerProject> get filtered {
    final q = query.trim().toLowerCase();

    return all.where((p) {
      final name = p.projectName.toLowerCase();
      final slug = p.slug.toLowerCase();
      final app = (p.appName ?? '').toLowerCase();

      final matchesText =
          q.isEmpty || name.contains(q) || slug.contains(q) || app.contains(q);

      final android = (p.androidBuildStatus ?? '').toUpperCase();
      final ios = (p.iosBuildStatus ?? '').toUpperCase();

      final matchesReady = !onlyReady || android == 'SUCCESS' || ios == 'SUCCESS';

      return matchesText && matchesReady;
    }).toList();
  }

  OwnerProjectsState copyWith({
    bool? loading,
    List<OwnerProject>? all,
    String? query,
    bool? onlyReady,
    String? error,
  }) {
    return OwnerProjectsState(
      loading: loading ?? this.loading,
      all: all ?? this.all,
      query: query ?? this.query,
      onlyReady: onlyReady ?? this.onlyReady,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, all, query, onlyReady, error];
}