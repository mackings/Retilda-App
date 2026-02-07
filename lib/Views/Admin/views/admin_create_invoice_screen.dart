import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Invoices/api/invoice_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/invoice.dart';
import 'package:sizer/sizer.dart';

class AdminCreateInvoiceScreen extends ConsumerStatefulWidget {
  const AdminCreateInvoiceScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminCreateInvoiceScreenState();
}

class _AdminCreateInvoiceScreenState
    extends ConsumerState<AdminCreateInvoiceScreen> {
  final InvoiceService _service = InvoiceService();
  final TextEditingController _notes = TextEditingController();
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

  Future<void> _loadOutstandingUsers() async {
    setState(() => _loadingOutstanding = true);
    final response = await _service.listOutstandingUsers();
    if (!mounted) return;
    setState(() {
      _outstandingUsers = response.data ?? [];
      _loadingOutstanding = false;
    });
  }

  Future<void> _loadOutstandingPurchases(String userId) async {
    setState(() => _loadingOutstanding = true);
    final response = await _service.listOutstandingPurchasesForUser(userId);
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() => _saving = false);
    if (response.success == true) {
      await _showCreatedSheet(response.data?.payLink);
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Failed to create invoice')),
      );
    }
  }

  Future<void> _createFromUserOutstanding() async {
    if (_selectedOutstandingUser?.user?.id == null) return;
    setState(() => _saving = true);
    final response = await _service.createInvoiceForUserOutstanding(
      userId: _selectedOutstandingUser!.user!.id!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      dueDateIso: _dueDate?.toUtc().toIso8601String(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (response.success == true) {
      await _showCreatedSheet(response.data?.payLink);
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Failed to create invoice')),
      );
    }
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pay link copied')),
                );
              },
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
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
              'Create invoice',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadOutstandingUsers,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_loadingOutstanding)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      )
                    else ...[
                      if (_outstandingUsers.isEmpty)
                        Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            CustomText(
                              'No outstanding users yet',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: deepBlue,
                            ),
                          ],
                        )
                      else if (_selectedOutstandingUser == null)
                        ..._outstandingUsers.map(
                          (user) => _OutstandingUserCard(
                            user: user,
                            selected: false,
                            dueDate: null,
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
                        )
                      else ...[
                        _OutstandingUserCard(
                          user: _selectedOutstandingUser!,
                          selected: true,
                          dueDate: _dueDate,
                          onTap: () {},
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedOutstandingUser = null;
                                _outstandingPurchases = [];
                                _selectedPurchaseIds.clear();
                              });
                            },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Change user'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._outstandingPurchases.map(
                          (purchase) => _OutstandingPurchaseTile(
                            purchase: purchase,
                            selected: _selectedPurchaseIds
                                .contains(purchase.id ?? ''),
                            onChanged: (value) {
                              final id = purchase.id ?? '';
                              if (id.isEmpty) return;
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
                      ],
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Notes (optional)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DueDatePicker(
                      dueDate: _dueDate,
                      onTap: () async {
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
                      },
                      onClear: () => setState(() => _dueDate = null),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_saving ||
                                    _selectedOutstandingUser?.user?.id == null ||
                                    _selectedPurchaseIds.isEmpty)
                                ? null
                                : _createFromPurchases,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Invoice selected purchases'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_saving ||
                                    _selectedOutstandingUser?.user?.id == null)
                                ? null
                                : _createFromUserOutstanding,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Invoice full outstanding'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutstandingPurchaseTile extends StatelessWidget {
  final OutstandingPurchase purchase;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _OutstandingPurchaseTile({
    required this.purchase,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = purchase.remainingAmount ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(value: selected, onChanged: onChanged),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.product?.name ?? 'Purchase',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: N${remaining.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[600]),
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
  final VoidCallback onTap;

  const _OutstandingUserCard({
    required this.user,
    required this.selected,
    required this.dueDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);
    final total = user.totalOutstanding ?? 0;
    final displayName =
        user.user?.fullName ?? user.user?.email ?? user.user?.phone ?? 'User';
    final dueLabel = dueDate == null
        ? 'Due date: Not set'
        : 'Due date: ${dueDate!.toLocal().toString().split(' ').first}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade200,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent.withOpacity(0.15),
              child: const Icon(Icons.person, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueLabel,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Owed',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'N${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: deepBlue,
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
        ? 'Set due date (optional)'
        : 'Due: ${dueDate!.toLocal().toString().split(' ').first}';
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onTap,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 10),
        if (dueDate != null)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
      ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            CustomText(
              'Invoice created',
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: deepBlue,
            ),
            const SizedBox(height: 8),
            CustomText(
              payLink == null
                  ? 'You can share the pay link once it is generated.'
                  : 'Share this pay link with the customer.',
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            if (payLink != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payLink!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (payLink != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy link'),
                    ),
                  ),
                if (payLink != null) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
