import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:retilda/Views/Invoices/api/invoice_service.dart';
import 'package:retilda/Views/Invoices/views/invoice_pdf_screen.dart';
import 'package:retilda/Views/Invoices/widgets/invoice_card.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/Views/Widgets/webview.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message ?? 'Unable to initiate payment'),
              ),
            );
          }
        },
        onCopyPayLink: () async {
          Navigator.pop(context);
          final link = invoice.payLink;
          if (link != null && link.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: link));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pay link copied')),
            );
            return;
          }
          final result = await _service.payInvoice(invoice.id ?? '');
          if (!mounted) return;
          if (result.payLink != null) {
            await Clipboard.setData(ClipboardData(text: result.payLink!));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pay link copied')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message ?? 'Unable to get pay link'),
              ),
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
    const Color deepBlue = Color(0xFF103C57);
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
              color: deepBlue,
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
                                color: deepBlue,
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
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
              color: deepBlue,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.payment, color: accent),
              title: const Text('Pay invoice'),
              onTap: onPay,
            ),
            ListTile(
              leading: const Icon(Icons.link, color: accent),
              title: const Text('Copy pay link'),
              onTap: onCopyPayLink,
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: deepBlue),
              title: const Text('View invoice PDF'),
              onTap: onViewInvoice,
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: deepBlue),
              title: const Text('View receipt PDF'),
              onTap: onViewReceipt,
            ),
          ],
        ),
      ),
    );
  }
}
