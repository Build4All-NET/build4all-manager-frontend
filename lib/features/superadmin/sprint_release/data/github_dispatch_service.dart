import 'dart:convert';
import 'package:http/http.dart' as http;

enum WorkflowJob {
  sprintRelease,
  androidBuild,
  iosBuild,
}

extension WorkflowJobX on WorkflowJob {
  String get fileName {
    switch (this) {
      case WorkflowJob.sprintRelease:
        return 'sprint-release.yml';
      case WorkflowJob.androidBuild:
        return 'android-playstore-build4allmanager.yml';
      case WorkflowJob.iosBuild:
        return 'ios_testflight.yml';
    }
  }

  String get label {
    switch (this) {
      case WorkflowJob.sprintRelease:
        return 'Sprint Release';
      case WorkflowJob.androidBuild:
        return 'Android - Play Store';
      case WorkflowJob.iosBuild:
        return 'iOS - TestFlight';
    }
  }
}

class GitHubDispatchService {
  static const _owner = 'Build4All-NET';
  static const _repo = 'build4all-manager-frontend';
  static const _apiBase = 'https://api.github.com';

  Future<void> triggerWorkflow({
    required String pat,
    required WorkflowJob job,
    required Map<String, String> inputs,
    String ref = 'main',
  }) async {
    final url = Uri.parse(
      '$_apiBase/repos/$_owner/$_repo/actions/workflows/${job.fileName}/dispatches',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $pat',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ref': ref,
        if (inputs.isNotEmpty) 'inputs': inputs,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Invalid token - check your GitHub PAT.');
    }
    if (response.statusCode == 404) {
      throw Exception('Workflow not found or repo is inaccessible.');
    }
    if (response.statusCode != 204) {
      String detail = '';
      try {
        detail = (jsonDecode(response.body) as Map)['message'] ?? response.body;
      } catch (_) {
        detail = response.body;
      }
      throw Exception('GitHub error ${response.statusCode}: $detail');
    }
  }
}
