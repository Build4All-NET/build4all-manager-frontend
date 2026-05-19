import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubDispatchService {
  static const _owner = 'Build4All-NET';
  static const _repo = 'build4all-manager-frontend';
  static const _apiBase = 'https://api.github.com';

  Future<void> triggerSprintRelease({
    required String pat,
    required String sprintName,
  }) async {
    final url = Uri.parse(
      '$_apiBase/repos/$_owner/$_repo/actions/workflows/sprint-release.yml/dispatches',
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
        'ref': 'main',
        'inputs': {'sprint_name': sprintName},
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Invalid token — check your GitHub PAT.');
    }
    if (response.statusCode == 404) {
      throw Exception('Repo or workflow not found. Make sure the repo is accessible by this token.');
    }
    if (response.statusCode != 204) {
      String detail = '';
      try {
        final body = jsonDecode(response.body);
        detail = body['message'] ?? response.body;
      } catch (_) {
        detail = response.body;
      }
      throw Exception('GitHub error ${response.statusCode}: $detail');
    }
  }
}
