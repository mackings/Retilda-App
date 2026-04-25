import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/views/admin_create_invoice_screen.dart';
import 'package:retilda/Views/Invoices/api/invoice_service.dart';
import 'package:retilda/Views/Invoices/views/invoice_pdf_screen.dart';
import 'package:retilda/Views/Widgets/webview.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/invoice.dart';

class AdminInvoicesScreen extends ConsumerStatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends ConsumerState<AdminInvoicesScreen> {
  final InvoiceService _service = InvoiceService();
  final NumberFormat _money = NumberFormat('#,##0', 'en_NG');

  bool _loading = true;
  List<Invoice> _invoices = [];

  Future<void> _loadInvoices() async {
    setState(() => _loading = true);
    final response = await _service.listAdminInvoices();
    if (!mounted) return;
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

  Future<void> _openCreateInvoice() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminCreateInvoiceScreen(),
      ),
    );
    if (created == true) {
      _loadInvoices();
    }
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
      ),
    );
  }

  String _formatMoney(num amount) => 'N${_money.format(amount)}';

  int get _paidCount =>
      _invoices.where((invoice) => invoice.status == 'paid').length;

  int get _pendingCount =>
      _invoices.where((invoice) => invoice.status != 'paid').length;

  num get _invoiceTotal => _invoices.fold<num>(
        0,
        (sum, invoice) => sum + (invoice.amount ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: AppTheme.surface,
        titleSpacing: 16,
        title: Text(
          'Admin invoices',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _openCreateInvoice,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.ocean.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(color: AppTheme.accent),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _loadInvoices,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _InvoicesHero(
                    totalInvoices: _invoices.length,
                    paidCount: _paidCount,
                    pendingCount: _pendingCount,
                    invoiceTotal: _formatMoney(_invoiceTotal),
                    onCreate: _openCreateInvoice,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InvoiceMetricCard(
                          title: 'Pending',
                          value: '$_pendingCount',
                          subtitle: 'Needs payment',
                          icon: Icons.schedule_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InvoiceMetricCard(
                          title: 'Paid',
                          value: '$_paidCount',
                          subtitle: 'Completed',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF1E8E5A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_invoices.isEmpty)
                    const _EmptyInvoicesState()
                  else
                    ..._invoices.map(
                      (invoice) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AdminInvoiceCard(
                          invoice: invoice,
                          formatMoney: _formatMoney,
                          onOpen: () => _openInvoice(invoice),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InvoicesHero extends StatelessWidget {
  final int totalInvoices;
  final int paidCount;
  final int pendingCount;
  final String invoiceTotal;
  final VoidCallback onCreate;

  const _InvoicesHero({
    required this.totalInvoices,
    required this.paidCount,
    required this.pendingCount,
    required this.invoiceTotal,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3452), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    const Icon(Icons.receipt_long_rounded, color: Colors.white),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            invoiceTotal,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total invoice amount across current admin invoice records.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroInvoiceStat(
                  label: 'Invoices',
                  value: '$totalInvoices',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroInvoiceStat(
                  label: 'Paid',
                  value: '$paidCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroInvoiceStat(
                  label: 'Pending',
                  value: '$pendingCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInvoiceStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroInvoiceStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _InvoiceMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminInvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String Function(num amount) formatMoney;
  final VoidCallback onOpen;

  const _AdminInvoiceCard({
    required this.invoice,
    required this.formatMoney,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = invoice.createdAt == null
        ? 'No date'
        : DateFormat('d MMM yyyy').format(DateTime.parse(invoice.createdAt!));
    final isPaid = invoice.status == 'paid';
    final accent = isPaid ? const Color(0xFF1E8E5A) : AppTheme.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.reference ?? 'Invoice',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created $createdAt',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InvoiceBadge(
                    label: (invoice.status ?? 'pending').toUpperCase(),
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InvoiceInfoChip(
                      icon: Icons.account_balance_wallet_rounded,
                      label: formatMoney(invoice.amount ?? 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InvoiceInfoChip(
                      icon: Icons.link_rounded,
                      label: (invoice.payLink ?? '').isEmpty
                          ? 'Generate pay link'
                          : 'Pay link available',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _InvoiceBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _InvoiceInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InvoiceInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.ocean),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceActionsSheet extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPay;
  final VoidCallback onViewInvoice;
  final VoidCallback onViewReceipt;
  final VoidCallback onCopyPayLink;

  const _InvoiceActionsSheet({
    required this.invoice,
    required this.onPay,
    required this.onViewInvoice,
    required this.onViewReceipt,
    required this.onCopyPayLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              invoice.reference ?? 'Invoice',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.payment_rounded,
              label: 'Pay invoice',
              subtitle: 'Generate or open the payment flow',
              color: AppTheme.accent,
              onTap: onPay,
            ),
            _ActionTile(
              icon: Icons.link_rounded,
              label: 'Copy pay link',
              subtitle: 'Copy the invoice link for sharing',
              color: AppTheme.accent,
              onTap: onCopyPayLink,
            ),
            _ActionTile(
              icon: Icons.picture_as_pdf_rounded,
              label: 'View invoice PDF',
              subtitle: 'Open the invoice document',
              color: AppTheme.ocean,
              onTap: onViewInvoice,
            ),
            _ActionTile(
              icon: Icons.receipt_long_rounded,
              label: 'View receipt PDF',
              subtitle: 'Open the payment receipt document',
              color: AppTheme.ocean,
              onTap: onViewReceipt,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInvoicesState extends StatelessWidget {
  const _EmptyInvoicesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded,
              size: 42, color: AppTheme.ocean),
          const SizedBox(height: 12),
          Text(
            'No invoices yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create and send invoices to customers from the admin dashboard.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}
