import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/github_dispatch_service.dart';
import 'sprint_release_state.dart';

class SprintReleaseCubit extends Cubit<SprintReleaseState> {
  final GitHubDispatchService _service;
  static const _patKey = 'github_dispatch_pat';

  SprintReleaseCubit({GitHubDispatchService? service})
      : _service = service ?? GitHubDispatchService(),
        super(SprintReleaseIdle());

  Future<String> loadPat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patKey) ?? '';
  }

  Future<void> _savePat(String pat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patKey, pat);
  }

  Future<void> trigger({
    required String pat,
    required WorkflowJob job,
    required Map<String, String> inputs,
  }) async {
    if (pat.trim().isEmpty) {
      emit(SprintReleaseError('Enter your GitHub PAT first.'));
      return;
    }

    emit(SprintReleaseLoading());
    try {
      await _service.triggerWorkflow(
        pat: pat.trim(),
        job: job,
        inputs: inputs,
      );
      await _savePat(pat.trim());
      emit(SprintReleaseSuccess(job));
    } catch (e) {
      emit(SprintReleaseError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void reset() => emit(SprintReleaseIdle());
}
