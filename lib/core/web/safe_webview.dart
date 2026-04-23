import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    this.onAllowedNavigation,
  });

  final String url;
  final String title;
  final Map<String, String> headers;
  final bool allowJavaScript;
  final Set<String>? allowedHosts;
  final ValueChanged<Uri>? onAllowedNavigation;

  @override
  State<SafeWebViewScreen> createState() => _SafeWebViewScreenState();
}

class _SafeWebViewScreenState extends State<SafeWebViewScreen> {
  WebViewController? _controller;
  String? _error;
  int _progress = 0;
  bool _isLoading = true;

  Set<String> get _allowedHosts =>
      widget.allowedHosts ?? AppConfig.allowedWebHosts;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (!_isAllowed(uri)) {
      debugPrint('[SafeWebView] Blocked initial URL: ${widget.url}');
      debugPrint('[SafeWebView] Allowed hosts: ${_allowedHosts.join(', ')}');
      _error = 'This link cannot be opened securely.';
      return;
    }
    final initialUri = uri!;
    widget.onAllowedNavigation?.call(initialUri);

    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.allowJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
            });
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _progress = 100;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _error = 'We could not load this payment page. Please try again.';
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final nextUri = Uri.tryParse(request.url);
            if (_isAllowed(nextUri)) {
              widget.onAllowedNavigation?.call(nextUri!);
              return NavigationDecision.navigate;
            }
            debugPrint('[SafeWebView] Blocked navigation URL: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(initialUri, headers: _headersFor(initialUri));
  }

  bool _isAllowed(Uri? uri) {
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return _allowedHosts.any((allowedHost) {
      final normalized = allowedHost.toLowerCase();
      return host == normalized || host.endsWith('.$normalized');
    });
  }

  Map<String, String> _headersFor(Uri uri) {
    final apiHost = Uri.parse(AppConfig.baseUrl).host.toLowerCase();
    if (uri.host.toLowerCase() == apiHost) return widget.headers;
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        title: Text(
          widget.title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF103C57),
            letterSpacing: -0.6,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF103C57),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF103C57).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF103C57),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure checkout',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF103C57),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your payment page is opened in a protected in-app browser.',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      if (_isLoading)
                        LinearProgressIndicator(
                          value: _progress == 0 ? null : _progress / 100,
                          minHeight: 3,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF103C57),
                          ),
                        ),
                      Expanded(
                        child: _error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 56,
                                        width: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF4F4),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Unable to load checkout',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF103C57),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          height: 1.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black.withValues(
                                            alpha: 0.68,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : WebViewWidget(controller: _controller!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
