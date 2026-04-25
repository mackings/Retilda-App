import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/admin/data/data_sources/admin_user_service.dart';
import 'package:retilda/features/admin/data/models/admin_model.dart';
import 'package:retilda/features/admin/presentation/widgets/purchase_modal.dart';

class PendingPaymentsPage extends StatefulWidget {
  const PendingPaymentsPage({super.key});

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<GlanceUser> _users = [];
  AdminPagination _pagination = const AdminPagination(
    page: 1,
    limit: _pageSize,
    totalItems: 0,
    totalPages: 1,
    hasNextPage: false,
    hasPreviousPage: false,
  );
  bool _loading = true;
  String? _error;
  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchUsers(page: 1);
    });
  }

  Future<void> _fetchUsers({int? page, bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.fetchUsers(
        page: page ?? _pagination.page,
        limit: _pageSize,
        search: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _users = response.users
            .where((user) => !user.isExcludedSalesTestAccount)
            .toList();
        _pagination = response.pagination;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  bool _isCompleted(GlanceUser user) {
    final summary = user.purchaseSummary;
    if (summary.purchaseCount == 0) {
      return false;
    }
    return summary.totalAmountPaid >= summary.totalAmountToPay &&
        summary.totalAmountToPay > 0;
  }

  List<GlanceUser> get _filteredUsers {
    return _users.where((user) {
      if (user.purchaseSummary.purchaseCount == 0) {
        return false;
      }
      final completed = _isCompleted(user);
      return _statusFilter == 'completed' ? completed : !completed;
    }).toList();
  }

  Future<void> _openPurchaseModal(GlanceUser user) async {
    if (user.purchaseSummary.purchaseCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No purchases found.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PurchaseDetailsModal(
        user: user,
        pageSize: _pageSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = AppTheme.surface;
    final filteredUsers = _filteredUsers;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: Text(
          'Payments',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(
                  _statusFilter == 'completed' ? 'Completed' : 'Pending',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Switch(
                  value: _statusFilter == 'completed',
                  activeThumbColor: AppTheme.accent,
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value ? 'completed' : 'pending';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchUsers(showLoader: false),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _buildSearchField(),
            const SizedBox(height: 14),
            _buildStatusSummary(filteredUsers.length),
            const SizedBox(height: 14),
            if (_loading)
              ...List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: _PendingUserSkeleton(),
                ),
              )
            else if (_error != null)
              _buildErrorState()
            else if (filteredUsers.isEmpty)
              _buildEmptyState()
            else
              ...filteredUsers.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PendingUserCard(
                    user: user,
                    completed: _isCompleted(user),
                    onTap: () => _openPurchaseModal(user),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _PendingPagination(
              page: _pagination.page,
              totalPages: _pagination.totalPages,
              hasNextPage: _pagination.hasNextPage,
              hasPreviousPage: _pagination.hasPreviousPage,
              onNext: _pagination.hasNextPage
                  ? () => _fetchUsers(page: _pagination.page + 1)
                  : null,
              onPrevious: _pagination.hasPreviousPage
                  ? () => _fetchUsers(page: _pagination.page - 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
        decoration: InputDecoration(
          hintText: 'Search name or email',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ocean),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _fetchUsers(page: 1);
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusSummary(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (_statusFilter == 'completed'
                      ? const Color(0xFF1E8E5A)
                      : AppTheme.accent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _statusFilter == 'completed'
                  ? Icons.check_circle_outline_rounded
                  : Icons.pending_actions_rounded,
              color: _statusFilter == 'completed'
                  ? const Color(0xFF1E8E5A)
                  : AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusFilter == 'completed'
                      ? 'Cleared customers'
                      : 'Customers with balances',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count result${count == 1 ? '' : 's'} on this page',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.accent, size: 40),
          const SizedBox(height: 12),
          Text(
            'Unable to load payments',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AppTheme.ocean,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching payment records',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try another search or switch the payment status filter.',
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
}

class _PendingUserCard extends StatelessWidget {
  final GlanceUser user;
  final bool completed;
  final VoidCallback onTap;

  const _PendingUserCard({
    required this.user,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = user.purchaseSummary;
    final accent = completed ? const Color(0xFF1E8E5A) : AppTheme.accent;
    final label = completed ? 'CLEARED' : 'PENDING';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.ink.withValues(alpha: 0.08),
                child: Text(
                  user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${summary.purchaseCount} purchases • Paid N${summary.totalAmountPaid.toStringAsFixed(0)} of N${summary.totalAmountToPay.toStringAsFixed(0)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const _PendingPagination({
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: hasPreviousPage ? onPrevious : null,
            child: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: hasNextPage ? onNext : null,
            child: Text('Page $page / $totalPages'),
          ),
        ),
      ],
    );
  }
}

class _PendingUserSkeleton extends StatelessWidget {
  const _PendingUserSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
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
