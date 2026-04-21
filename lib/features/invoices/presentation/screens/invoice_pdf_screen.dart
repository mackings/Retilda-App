import 'package:flutter/material.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/core/web/safe_webview.dart';

class InvoicePdfScreen extends StatefulWidget {
  final String url;
  final String title;

  const InvoicePdfScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<InvoicePdfScreen> createState() => _InvoicePdfScreenState();
}

class _InvoicePdfScreenState extends State<InvoicePdfScreen> {
  late final ApiClient _apiClient = ApiClient(session: AppSession());
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    final headers = await _apiClient.authHeaders(
      auth: AuthScope.user,
      jsonContent: false,
    );
    if (!mounted) return;
    setState(() => _headers = headers);
  }

  @override
  Widget build(BuildContext context) {
    if (_headers == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeWebViewScreen(
      url: widget.url,
      title: widget.title,
      headers: _headers!,
    );
  }
}
