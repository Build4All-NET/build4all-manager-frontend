import 'dart:convert';
import 'package:http/http.dart' as http;

class GithubActionsService {
  static const _owner = 'Build4All-NET';
  static const _repo = 'build4all-manager-frontend';

  Future<void> triggerSprintRelease({
    required String pat,
    required String sprintName,
    String ref = 'main',
  }) async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$_owner/$_repo/actions/workflows/sprint-release.yml/dispatches',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $pat',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ref': ref,
        'inputs': {'sprint_name': sprintName},
      }),
    );

    if (response.statusCode != 204) {
      String message = 'GitHub API error (HTTP ${response.statusCode})';
      try {
        final json = jsonDecode(response.body) as Map;
        message = (json['message'] as String?) ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }
}
