import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Invoices/api/invoice_service.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/invoice.dart';

class AdminCreateInvoiceScreen extends ConsumerStatefulWidget {
  const AdminCreateInvoiceScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminCreateInvoiceScreenState();
}

class _AdminCreateInvoiceScreenState
    extends ConsumerState<AdminCreateInvoiceScreen> {
  static final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'en_NG');

  final InvoiceService _service = InvoiceService();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _customerSearch = TextEditingController();

  bool _saving = false;
  bool _loadingOutstanding = false;
  List<OutstandingUser> _outstandingUsers = [];
  OutstandingUser? _selectedOutstandingUser;
  List<OutstandingPurchase> _outstandingPurchases = [];
  final Set<String> _selectedPurchaseIds = {};
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _loadOutstandingUsers();
  }

  @override
  void dispose() {
    _notes.dispose();
    _customerSearch.dispose();
    super.dispose();
  }

  Future<void> _loadOutstandingUsers() async {
    setState(() => _loadingOutstanding = true);
    final response = await _service.listOutstandingUsers();
    if (!mounted) {
      return;
    }
    setState(() {
      _outstandingUsers = response.data ?? [];
      _loadingOutstanding = false;
    });
  }

  Future<void> _loadOutstandingPurchases(String userId) async {
    setState(() => _loadingOutstanding = true);
    final response = await _service.listOutstandingPurchasesForUser(userId);
    if (!mounted) {
      return;
    }
    setState(() {
      _outstandingPurchases = response.data ?? [];
      _selectedPurchaseIds.clear();
      _loadingOutstanding = false;
    });
  }

  Future<void> _createFromPurchases() async {
    if (_selectedOutstandingUser?.user?.id == null ||
        _selectedPurchaseIds.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    final response = await _service.createInvoiceFromPurchases(
      userId: _selectedOutstandingUser!.user!.id!,
      purchaseIds: _selectedPurchaseIds.toList(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      dueDateIso: _dueDate?.toUtc().toIso8601String(),
    );
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    if (response.success == true) {
      await _showCreatedSheet(response.data?.payLink);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Failed to create invoice')),
    );
  }

  Future<void> _createFromUserOutstanding() async {
    if (_selectedOutstandingUser?.user?.id == null) {
      return;
    }

    setState(() => _saving = true);
    final response = await _service.createInvoiceForUserOutstanding(
      userId: _selectedOutstandingUser!.user!.id!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      dueDateIso: _dueDate?.toUtc().toIso8601String(),
    );
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    if (response.success == true) {
      await _showCreatedSheet(response.data?.payLink);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Failed to create invoice')),
    );
  }

  Future<void> _showCreatedSheet(String? payLink) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InvoiceCreatedSheet(
        payLink: payLink,
        onCopy: payLink == null
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: payLink));
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pay link copied')),
                );
              },
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  double get _selectedOutstandingTotal {
    return _outstandingPurchases
        .where((purchase) => _selectedPurchaseIds.contains(purchase.id ?? ''))
        .fold<double>(
          0,
          (sum, purchase) => sum + (purchase.remainingAmount?.toDouble() ?? 0),
        );
  }

  double get _userOutstandingTotal =>
      _selectedOutstandingUser?.totalOutstanding?.toDouble() ?? 0;

  String _formatMoney(num value) {
    return 'N${_currencyFormatter.format(value)}';
  }

  List<OutstandingUser> get _visibleOutstandingUsers {
    final query = _customerSearch.text.trim().toLowerCase();
    final users = [..._outstandingUsers];
    users.sort(
      (a, b) => (b.totalOutstanding?.toDouble() ?? 0)
          .compareTo(a.totalOutstanding?.toDouble() ?? 0),
    );
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      final name = (user.user?.fullName ?? '').toLowerCase();
      final email = (user.user?.email ?? '').toLowerCase();
      final phone = (user.user?.phone ?? '').toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = _selectedOutstandingUser;
    final canInvoiceSelected = !_saving &&
        selectedUser?.user?.id != null &&
        _selectedPurchaseIds.isNotEmpty;
    final canInvoiceOutstanding = !_saving && selectedUser?.user?.id != null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: AppTheme.surface,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create invoice',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            // Text(
            //   'Build a payment link from outstanding balances',
            //   style: GoogleFonts.manrope(
            //     fontWeight: FontWeight.w600,
            //     color: Colors.black.withValues(alpha: 0.5),
            //   ),
            // ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOutstandingUsers,
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
            top: 50,
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
          RefreshIndicator(
            onRefresh: _loadOutstandingUsers,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _buildHeroCard(selectedUser),
                const SizedBox(height: 16),
                _buildSummaryStrip(),
                const SizedBox(height: 18),
                _buildSectionTitle(
                  'Select customer',
                  selectedUser == null
                      ? 'Choose who this invoice should be billed to.'
                      : 'Customer selected. You can swap to another user if needed.',
                ),
                const SizedBox(height: 12),
                if (selectedUser == null) ...[
                  _buildCustomerSearchField(),
                  const SizedBox(height: 12),
                ],
                if (_loadingOutstanding)
                  ...List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _SelectionSkeleton(),
                    ),
                  )
                else if (_outstandingUsers.isEmpty)
                  _buildEmptyState()
                else if (selectedUser == null)
                  ...(_visibleOutstandingUsers.isEmpty
                      ? [
                          _buildNoCustomerMatchState(),
                        ]
                      : _visibleOutstandingUsers.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OutstandingUserCard(
                              user: user,
                              selected: false,
                              dueDate: null,
                              formatMoney: _formatMoney,
                              onTap: () {
                                setState(() {
                                  _selectedOutstandingUser = user;
                                });
                                final userId = user.user?.id;
                                if (userId != null) {
                                  _loadOutstandingPurchases(userId);
                                }
                              },
                            ),
                          ),
                        ))
                else ...[
                  _OutstandingUserCard(
                    user: selectedUser,
                    selected: true,
                    dueDate: _dueDate,
                    formatMoney: _formatMoney,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedOutstandingUser = null;
                          _outstandingPurchases = [];
                          _selectedPurchaseIds.clear();
                          _dueDate = null;
                        });
                      },
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Change customer'),
                    ),
                  ),
                ],
                if (selectedUser != null) ...[
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    'Choose balances',
                    'Pick specific purchases or invoice the customer’s full outstanding balance.',
                  ),
                  const SizedBox(height: 12),
                  if (_loadingOutstanding)
                    ...List.generate(
                      2,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _SelectionSkeleton(),
                      ),
                    )
                  else if (_outstandingPurchases.isEmpty)
                    _buildPurchaseEmptyState()
                  else
                    ..._outstandingPurchases.map(
                      (purchase) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OutstandingPurchaseTile(
                          purchase: purchase,
                          selected:
                              _selectedPurchaseIds.contains(purchase.id ?? ''),
                          formatMoney: _formatMoney,
                          onChanged: (value) {
                            final id = purchase.id ?? '';
                            if (id.isEmpty) {
                              return;
                            }
                            setState(() {
                              if (value == true) {
                                _selectedPurchaseIds.add(id);
                              } else {
                                _selectedPurchaseIds.remove(id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    'Invoice details',
                    'Add internal notes and optionally set a due date before creating the pay link.',
                  ),
                  const SizedBox(height: 12),
                  _buildNotesCard(),
                  const SizedBox(height: 12),
                  _DueDatePicker(
                    dueDate: _dueDate,
                    onTap: _pickDueDate,
                    onClear: () => setState(() => _dueDate = null),
                  ),
                  const SizedBox(height: 18),
                  _buildActionCard(
                    canInvoiceSelected: canInvoiceSelected,
                    canInvoiceOutstanding: canInvoiceOutstanding,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(OutstandingUser? selectedUser) {
    final selectedName = selectedUser?.user?.fullName ??
        selectedUser?.user?.email ??
        'No customer selected';

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
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -14,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -12,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  selectedUser == null
                      ? 'Create a payable invoice'
                      : 'Invoice for $selectedName',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedUser == null
                      ? 'Start by selecting a customer with outstanding balances.'
                      : 'Issue a focused invoice for selected purchases or bill the user’s full outstanding amount.',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Customers owing',
            value: '${_outstandingUsers.length}',
            subtitle: 'Ready to invoice',
            icon: Icons.people_alt_rounded,
            color: AppTheme.ocean,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Selected purchases',
            value: '${_selectedPurchaseIds.length}',
            subtitle: _formatMoney(_selectedOutstandingTotal),
            icon: Icons.shopping_bag_rounded,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Full outstanding',
            value: _formatMoney(_userOutstandingTotal),
            subtitle: 'Current customer',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF1E8E5A),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _customerSearch,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search customer by name, email, or phone',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ocean),
          suffixIcon: _customerSearch.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _customerSearch.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sentiment_satisfied_alt_rounded,
            color: AppTheme.ocean,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'No outstanding users yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When customers still owe money, they will appear here for fast invoice creation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'No outstanding purchases were returned for this user.',
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.56),
        ),
      ),
    );
  }

  Widget _buildNoCustomerMatchState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'No customers matched your search. Try another name, email, or phone number.',
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.56),
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _notes,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Invoice notes',
          hintText: 'Add optional context for the customer or internal team.',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 56),
            child: Icon(Icons.sticky_note_2_outlined),
          ),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required bool canInvoiceSelected,
    required bool canInvoiceOutstanding,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create invoice',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose whether to invoice only the selected purchases or the customer’s full outstanding amount.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canInvoiceSelected ? _createFromPurchases : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.receipt_rounded),
              label: Text(
                _saving ? 'Creating invoice...' : 'Invoice selected purchases',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canInvoiceOutstanding && !_saving
                  ? _createFromUserOutstanding
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Invoice full outstanding'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutstandingPurchaseTile extends StatelessWidget {
  final OutstandingPurchase purchase;
  final bool selected;
  final String Function(num value) formatMoney;
  final ValueChanged<bool?> onChanged;

  const _OutstandingPurchaseTile({
    required this.purchase,
    required this.selected,
    required this.formatMoney,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = purchase.remainingAmount ?? 0;
    final accent = selected ? AppTheme.accent : AppTheme.ocean;
    final deliveryLabel = (purchase.deliveryStatus ?? '').isEmpty
        ? 'Delivery status unavailable'
        : purchase.deliveryStatus!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            activeColor: AppTheme.accent,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.product?.name ?? 'Purchase',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Remaining ${formatMoney(remaining)}',
                      color: AppTheme.accent,
                    ),
                    if ((purchase.purchaseType ?? '').isNotEmpty)
                      _MetaPill(
                        icon: Icons.style_outlined,
                        label: purchase.purchaseType!.replaceAll('_', ' '),
                        color: AppTheme.ocean,
                      ),
                    _MetaPill(
                      icon: Icons.local_shipping_outlined,
                      label: deliveryLabel,
                      color: AppTheme.ink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutstandingUserCard extends StatelessWidget {
  final OutstandingUser user;
  final bool selected;
  final DateTime? dueDate;
  final String Function(num value) formatMoney;
  final VoidCallback onTap;

  const _OutstandingUserCard({
    required this.user,
    required this.selected,
    required this.dueDate,
    required this.formatMoney,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = user.totalOutstanding ?? 0;
    final displayName =
        user.user?.fullName ?? user.user?.email ?? user.user?.phone ?? 'User';
    final dueLabel = dueDate == null
        ? 'No due date yet'
        : 'Due ${DateFormat('d MMM yyyy').format(dueDate!)}';
    final accent = selected ? AppTheme.accent : AppTheme.ocean;
    final subtitle = user.user?.email ?? user.user?.phone ?? 'No contact';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withValues(alpha: 0.14)),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      accent.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayName.trim().isEmpty
                      ? '?'
                      : displayName
                          .trim()
                          .split(RegExp(r'\s+'))
                          .take(2)
                          .map((part) => part[0].toUpperCase())
                          .join(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 21,
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: Icons.schedule_rounded,
                          label: dueLabel,
                          color: accent,
                        ),
                        _MetaPill(
                          icon: Icons.shopping_bag_outlined,
                          label:
                              '${user.purchases?.length ?? 0} purchase${(user.purchases?.length ?? 0) == 1 ? '' : 's'}',
                          color: AppTheme.ocean,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Outstanding',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.46),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(total),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
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

class _DueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DueDatePicker({
    required this.dueDate,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final label = dueDate == null
        ? 'Set due date'
        : 'Due ${DateFormat('d MMM yyyy').format(dueDate!)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          if (dueDate != null) ...[
            const SizedBox(width: 10),
            IconButton(
              onPressed: onClear,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.04),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSkeleton extends StatelessWidget {
  const _SelectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _InvoiceCreatedSheet extends StatelessWidget {
  final String? payLink;
  final VoidCallback? onCopy;
  final VoidCallback onDone;

  const _InvoiceCreatedSheet({
    required this.payLink,
    required this.onCopy,
    required this.onDone,
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
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF1E8E5A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF1E8E5A),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Invoice created',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              payLink == null
                  ? 'The invoice is ready. You can share the pay link once it is available.'
                  : 'The pay link is ready to send to the customer.',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.56),
              ),
            ),
            const SizedBox(height: 16),
            if (payLink != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
                ),
                child: Text(
                  payLink!,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (payLink != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy link'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                if (payLink != null) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Back to invoices'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
