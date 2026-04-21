import 'package:flutter/material.dart';
import 'package:retilda/core/web/safe_webview.dart';

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeWebViewScreen(
      url: url,
      title: 'Payment',
      allowJavaScript: true,
    );
  }
}

class InAppWebViewPage extends StatelessWidget {
  final String url;
  final String title;

  const InAppWebViewPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeWebViewScreen(
      url: url,
      title: title,
      allowJavaScript: true,
    );
  }
}
