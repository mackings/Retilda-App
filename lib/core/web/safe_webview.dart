import 'package:flutter/material.dart';
import 'package:retilda/core/config/app_config.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafeWebViewScreen extends StatefulWidget {
  const SafeWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.headers = const {},
    this.allowJavaScript = false,
    this.allowedHosts,
  });

  final String url;
  final String title;
  final Map<String, String> headers;
  final bool allowJavaScript;
  final Set<String>? allowedHosts;

  @override
  State<SafeWebViewScreen> createState() => _SafeWebViewScreenState();
}

class _SafeWebViewScreenState extends State<SafeWebViewScreen> {
  WebViewController? _controller;
  String? _error;

  Set<String> get _allowedHosts =>
      widget.allowedHosts ?? AppConfig.allowedWebHosts;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (!_isAllowed(uri)) {
      _error = 'This link cannot be opened securely.';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.allowJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final nextUri = Uri.tryParse(request.url);
            if (_isAllowed(nextUri)) return NavigationDecision.navigate;
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri!, headers: _headersFor(uri));
  }

  bool _isAllowed(Uri? uri) {
    if (uri == null || uri.scheme != 'https') return false;
    return _allowedHosts.contains(uri.host.toLowerCase());
  }

  Map<String, String> _headersFor(Uri uri) {
    final apiHost = Uri.parse(AppConfig.baseUrl).host.toLowerCase();
    if (uri.host.toLowerCase() == apiHost) return widget.headers;
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : WebViewWidget(controller: _controller!),
    );
  }
}
