import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;

  Future<Map<String, String>> _loadHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return {};
    final userData = jsonDecode(userDataString) as Map<String, dynamic>;
    final token = userData['data']?['token'];
    if (token == null) return {};
    return {
      'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    _loadHeaders().then((headers) {
      _controller.loadRequest(Uri.parse(widget.url), headers: headers);
    });
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
      body: WebViewWidget(controller: _controller),
    );
  }
}
