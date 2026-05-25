import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'social_oauth_models.dart';

/// Hosts the provider's authorisation page. When the WebView navigates to a
/// URL whose scheme matches [SocialOAuthArgs.redirectUri], we intercept it,
/// pull `code` + `state` from the query string, and pop back to the caller
/// with a [SocialOAuthResult].
///
/// Cancel paths:
/// - User taps the back arrow → pops with `null` (cubit interprets as cancel).
/// - WebView navigates to an `error=…` URL → pops with `null` and surfaces
///   the error via SnackBar in the parent.
class OwnerSocialOAuthWebViewScreen extends StatefulWidget {
  final SocialOAuthArgs args;
  const OwnerSocialOAuthWebViewScreen({super.key, required this.args});

  @override
  State<OwnerSocialOAuthWebViewScreen> createState() =>
      _OwnerSocialOAuthWebViewScreenState();
}

class _OwnerSocialOAuthWebViewScreenState
    extends State<OwnerSocialOAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigation,
        onWebResourceError: (err) {
          if (_completed) return;
          _popWithError('WebView error: ${err.description}');
        },
      ))
      ..loadRequest(Uri.parse(widget.args.authorizationUrl));
  }

  NavigationDecision _onNavigation(NavigationRequest req) {
    final url = req.url;
    if (_completed) return NavigationDecision.navigate;

    final redirectPrefix = widget.args.redirectUri;
    // Match the configured custom-scheme redirect (build4all://oauth/...).
    if (url.startsWith(redirectPrefix)) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _popWithError('Malformed callback URL');
        return NavigationDecision.prevent;
      }
      final err = uri.queryParameters['error']
            ?? uri.queryParameters['error_message'];
      if (err != null) {
        _popWithError('OAuth error: $err');
        return NavigationDecision.prevent;
      }
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      if (code == null || state == null) {
        _popWithError('Callback missing code or state');
        return NavigationDecision.prevent;
      }
      if (state != widget.args.stateToken) {
        // Defence-in-depth — backend also enforces this. Refuse to forward.
        _popWithError('OAuth state mismatch — refusing to continue');
        return NavigationDecision.prevent;
      }
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(SocialOAuthResult(code, state));
        }
      });
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _popWithError(String msg) {
    if (_completed || !mounted) return;
    _completed = true;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Allow normal back to close the WebView (interpreted as cancel).
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Connect ${widget.args.provider.displayName}'),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
