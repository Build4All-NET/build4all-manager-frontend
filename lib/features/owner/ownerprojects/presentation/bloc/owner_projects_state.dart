import 'package:equatable/equatable.dart';
import '../../../common/domain/entities/owner_project.dart';

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
      final matchesText = q.isEmpty ||
          p.projectName.toLowerCase().contains(q) ||
          p.slug.toLowerCase().contains(q);
      final matchesReady = !onlyReady ||
          (p.androidBuildStatus == 'SUCCESS' || p.iosBuildStatus == 'SUCCESS');
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
