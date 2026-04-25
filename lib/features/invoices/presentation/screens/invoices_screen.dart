import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Invoices/api/invoice_service.dart';
import 'package:retilda/Views/Invoices/views/invoice_pdf_screen.dart';
import 'package:retilda/Views/Invoices/widgets/invoice_card.dart';
import 'package:retilda/Views/Widgets/webview.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
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

  String _money(num? value) => 'N${NumberFormat('#,##0').format(value ?? 0)}';

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
    final pendingInvoices = _invoices
        .where((invoice) => (invoice.status ?? '').toLowerCase() != 'paid')
        .toList();
    final paidInvoices = _invoices
        .where((invoice) => (invoice.status ?? '').toLowerCase() == 'paid')
        .toList();
    final pendingAmount = pendingInvoices.fold<num>(
      0,
      (sum, invoice) => sum + (invoice.amount ?? 0),
    );
    final totalAmount = _invoices.fold<num>(
      0,
      (sum, invoice) => sum + (invoice.amount ?? 0),
    );

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
                      horizontal: 14,
                      vertical: 12,
                    ),
                    children: [
                      _InvoiceHero(
                        invoiceCount: _invoices.length,
                        pendingCount: pendingInvoices.length,
                        paidCount: paidInvoices.length,
                        pendingAmount: _money(pendingAmount),
                        totalAmount: _money(totalAmount),
                      ),
                      const SizedBox(height: 18),
                      if (_invoices.isEmpty)
                        _EmptyInvoicesState(onRefresh: _loadInvoices)
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                'Recent invoices',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: CustomText(
                                '${_invoices.length} total',
                                fontSize: 11.8,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._invoices.map(
                          (invoice) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: InvoiceCard(
                              invoice: invoice,
                              onOpen: () => _openInvoice(invoice),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _InvoiceHero extends StatelessWidget {
  const _InvoiceHero({
    required this.invoiceCount,
    required this.pendingCount,
    required this.paidCount,
    required this.pendingAmount,
    required this.totalAmount,
  });

  final int invoiceCount;
  final int pendingCount;
  final int paidCount;
  final String pendingAmount;
  final String totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Billing and receipts',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          CustomText(
            'Track what is outstanding, open payment links, and keep every invoice and receipt in one clean place.',
            fontSize: 13.2,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStatTile(
                  label: 'Pending now',
                  value: pendingAmount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatTile(
                  label: 'Total billed',
                  value: totalAmount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(label: '$invoiceCount invoices'),
              _HeroChip(label: '$pendingCount pending'),
              _HeroChip(label: '$paidCount paid'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.72),
          ),
          const SizedBox(height: 7),
          CustomText(
            value,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: CustomText(
        label,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _EmptyInvoicesState extends StatelessWidget {
  const _EmptyInvoicesState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.05),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            CustomText(
              'No invoices yet',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
            const SizedBox(height: 8),
            CustomText(
              'Invoices created for your purchases will appear here together with invoice and receipt PDFs.',
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh invoices'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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

class _InvoiceActionsSheet extends StatelessWidget {
  const _InvoiceActionsSheet({
    required this.invoice,
    required this.onPay,
    required this.onCopyPayLink,
    required this.onViewInvoice,
    required this.onViewReceipt,
  });

  final Invoice invoice;
  final VoidCallback onPay;
  final VoidCallback onCopyPayLink;
  final VoidCallback onViewInvoice;
  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final isPaid = (invoice.status ?? '').toLowerCase() == 'paid';
    final amountText = invoice.amount != null
        ? 'N${NumberFormat('#,##0').format(invoice.amount)}'
        : 'N0';

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
              isPaid
                  ? 'This invoice has been paid. You can open the invoice or receipt PDF below.'
                  : 'Choose how you want to handle this invoice.',
              fontSize: 12.2.sp,
              color: Colors.black.withValues(alpha: 0.58),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _InvoiceSheetStat(
                      label: 'Amount',
                      value: amountText,
                      valueColor: AppTheme.ink,
                    ),
                  ),
                  Expanded(
                    child: _InvoiceSheetStat(
                      label: 'Status',
                      value: isPaid ? 'Paid' : 'Pending',
                      valueColor:
                          isPaid ? const Color(0xFF0E7C66) : AppTheme.accent,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!isPaid) ...[
              _InvoiceSheetAction(
                icon: Icons.payment_rounded,
                color: AppTheme.accent,
                title: 'Pay invoice',
                subtitle: 'Open the hosted payment screen now',
                onTap: onPay,
              ),
              _InvoiceSheetAction(
                icon: Icons.link_rounded,
                color: AppTheme.accent,
                title: 'Copy pay link',
                subtitle: 'Share or keep the payment URL',
                onTap: onCopyPayLink,
              ),
            ],
            _InvoiceSheetAction(
              icon: Icons.picture_as_pdf_rounded,
              color: AppTheme.ocean,
              title: 'View invoice PDF',
              subtitle: 'Open the printable invoice document',
              onTap: onViewInvoice,
            ),
            _InvoiceSheetAction(
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF0E7C66),
              title: 'View receipt PDF',
              subtitle: 'Open the final payment receipt',
              onTap: onViewReceipt,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSheetStat extends StatelessWidget {
  const _InvoiceSheetStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.48),
        ),
        const SizedBox(height: 5),
        CustomText(
          value,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: valueColor,
        ),
      ],
    );
  }
}

class _InvoiceSheetAction extends StatelessWidget {
  const _InvoiceSheetAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: 13.8,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      subtitle,
                      fontSize: 11.8,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
