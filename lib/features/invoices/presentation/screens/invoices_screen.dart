import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:retilda/Views/Invoices/api/invoice_service.dart';
import 'package:retilda/Views/Invoices/views/invoice_pdf_screen.dart';
import 'package:retilda/Views/Invoices/widgets/invoice_card.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/Views/Widgets/webview.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/invoice.dart';
import 'package:sizer/sizer.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final InvoiceService _service = InvoiceService();

  bool _loading = true;
  List<Invoice> _invoices = [];

  Future<void> _loadInvoices() async {
    setState(() => _loading = true);
    final response = await _service.listUserInvoices();
    setState(() {
      _invoices = response.data ?? [];
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _openInvoice(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceActionsSheet(
        invoice: invoice,
        onPay: () async {
          final result = await _service.payInvoice(invoice.id ?? '');
          if (!mounted) return;
          Navigator.pop(context);
          if (result.payLink != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewScreen(url: result.payLink!),
              ),
            );
          } else {
            showAppAlert(
              context: context,
              title: 'Payment unavailable',
              message: result.message ?? 'Unable to initiate payment',
              tone: AppFeedbackTone.error,
              buttonText: 'Okay',
            );
          }
        },
        onCopyPayLink: () async {
          Navigator.pop(context);
          final link = invoice.payLink;
          if (link != null && link.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: link));
            if (!mounted) return;
            showAppSnackBar(
              context,
              message: 'Pay link copied',
              tone: AppFeedbackTone.success,
            );
            return;
          }
          final result = await _service.payInvoice(invoice.id ?? '');
          if (!mounted) return;
          if (result.payLink != null) {
            await Clipboard.setData(ClipboardData(text: result.payLink!));
            if (!mounted) return;
            showAppSnackBar(
              context,
              message: 'Pay link copied',
              tone: AppFeedbackTone.success,
            );
          } else {
            showAppAlert(
              context: context,
              title: 'Link unavailable',
              message: result.message ?? 'Unable to get pay link',
              tone: AppFeedbackTone.error,
              buttonText: 'Okay',
            );
          }
        },
        onViewInvoice: () {
          Navigator.pop(context);
          final url = _service.invoicePdfUrl(
            invoice.id ?? '',
            type: 'invoice',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoicePdfScreen(
                url: url,
                title: 'Invoice PDF',
              ),
            ),
          );
        },
        onViewReceipt: () {
          Navigator.pop(context);
          final url = _service.invoicePdfUrl(
            invoice.id ?? '',
            type: 'receipt',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoicePdfScreen(
                url: url,
                title: 'Receipt PDF',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              'Invoices',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: accent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInvoices,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'Billing and receipts',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            CustomText(
                              'Open invoices, copy pay links, and view invoice or receipt PDFs from one place.',
                              fontSize: 12.5.sp,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                      if (_invoices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 140),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              CustomText(
                                'No invoices yet',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                              const SizedBox(height: 6),
                              CustomText(
                                'Your invoices will appear here once created.',
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 180,
                                child: ElevatedButton.icon(
                                  onPressed: _loadInvoices,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._invoices.map(
                          (invoice) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InvoiceCard(
                              invoice: invoice,
                              onOpen: () => _openInvoice(invoice),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _InvoiceActionsSheet extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPay;
  final VoidCallback onCopyPayLink;
  final VoidCallback onViewInvoice;
  final VoidCallback onViewReceipt;

  const _InvoiceActionsSheet({
    required this.invoice,
    required this.onPay,
    required this.onCopyPayLink,
    required this.onViewInvoice,
    required this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 14),
            CustomText(
              invoice.reference ?? 'Invoice',
              fontWeight: FontWeight.w800,
              fontSize: 15.sp,
              color: AppTheme.ink,
            ),
            const SizedBox(height: 4),
            CustomText(
              'Choose what you want to do with this invoice.',
              fontSize: 12.2.sp,
              color: Colors.black.withValues(alpha: 0.58),
            ),
            const SizedBox(height: 14),
            _InvoiceSheetAction(
              icon: Icons.payment_rounded,
              color: AppTheme.accent,
              title: 'Pay invoice',
              onTap: onPay,
            ),
            _InvoiceSheetAction(
              icon: Icons.link_rounded,
              color: AppTheme.accent,
              title: 'Copy pay link',
              onTap: onCopyPayLink,
            ),
            _InvoiceSheetAction(
              icon: Icons.picture_as_pdf_rounded,
              color: AppTheme.ocean,
              title: 'View invoice PDF',
              onTap: onViewInvoice,
            ),
            _InvoiceSheetAction(
              icon: Icons.receipt_long_rounded,
              color: AppTheme.ocean,
              title: 'View receipt PDF',
              onTap: onViewReceipt,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSheetAction extends StatelessWidget {
  const _InvoiceSheetAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      onTap: onTap,
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: CustomText(
        title,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.ink,
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black54),
    );
  }
}
