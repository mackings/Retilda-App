import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/admin/data/data_sources/admin_user_service.dart';
import 'package:retilda/features/admin/data/models/admin_model.dart';
import 'package:retilda/features/admin/presentation/screens/pending.dart';
import 'package:retilda/features/admin/presentation/widgets/purchase_modal.dart';

class Glace extends StatefulWidget {
  const Glace({super.key});

  @override
  State<Glace> createState() => _GlaceState();
}

class _GlaceState extends State<Glace> {
  static const int _pageSize = 20;
  static const int _aggregatePageSize = 100;
  static final NumberFormat _currencyFormatter =
      NumberFormat('#,##0.00', 'en_NG');
  static final NumberFormat _compactCurrencyFormatter =
      NumberFormat('#,##0', 'en_NG');

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
  bool _overviewLoading = true;
  String? _error;
  String _filterMode = 'all';

  double _overallPaid = 0;
  double _overallPending = 0;
  int _overallRealUsers = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _refreshDashboard();
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

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _fetchUsers(page: 1, showLoader: true),
      _loadOverallTotals(),
    ]);
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

  Future<void> _loadOverallTotals() async {
    if (mounted) {
      setState(() {
        _overviewLoading = true;
      });
    }

    try {
      final firstPage = await ApiService.fetchUsers(
        page: 1,
        limit: _aggregatePageSize,
      );

      final pages = <GlanceUsersPage>[firstPage];
      if (firstPage.pagination.totalPages > 1) {
        final remainingPages = await Future.wait(
          List.generate(
            firstPage.pagination.totalPages - 1,
            (index) => ApiService.fetchUsers(
              page: index + 2,
              limit: _aggregatePageSize,
            ),
          ),
        );
        pages.addAll(remainingPages);
      }

      final allUsers = pages
          .expand((page) => page.users)
          .where((user) => !user.isExcludedSalesTestAccount)
          .toList();

      final totalPaid = allUsers.fold<double>(
        0,
        (sum, user) => sum + user.purchaseSummary.totalAmountPaid,
      );
      final totalPending = allUsers.fold<double>(
        0,
        (sum, user) => sum + _userOutstanding(user),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _overallPaid = totalPaid;
        _overallPending = totalPending;
        _overallRealUsers = allUsers.length;
        _overviewLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _overviewLoading = false;
      });
    }
  }

  Future<void> _openPurchaseModal(GlanceUser user) async {
    if (user.purchaseSummary.purchaseCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.fullName} has no purchases')),
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

  double _userOutstanding(GlanceUser user) {
    final summary = user.purchaseSummary;
    return summary.totalAmountToPay > summary.totalAmountPaid
        ? summary.totalAmountToPay - summary.totalAmountPaid
        : 0;
  }

  List<GlanceUser> get _displayedUsers {
    final filtered = _users.where((user) {
      final summary = user.purchaseSummary;
      if (_filterMode == 'high') {
        return summary.totalAmountPaid >= 100000;
      }
      if (_filterMode == 'zero') {
        return summary.totalAmountPaid == 0;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final amountCompare = b.purchaseSummary.totalAmountPaid
          .compareTo(a.purchaseSummary.totalAmountPaid);
      if (amountCompare != 0) {
        return amountCompare;
      }
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return filtered;
  }

  int get _highSpenderCount => _users
      .where((user) => user.purchaseSummary.totalAmountPaid >= 100000)
      .length;

  int get _zeroSpendCount =>
      _users.where((user) => user.purchaseSummary.purchaseCount == 0).length;

  String _formatCurrency(double amount) {
    return 'N${_currencyFormatter.format(amount)}';
  }

  String _formatCompactCurrency(double amount) {
    return 'N${_compactCurrencyFormatter.format(amount)}';
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'NA';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = AppTheme.surface;
    final displayedUsers = _displayedUsers;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: pageBg,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'At a glance',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            Text(
              'Real customer sales performance only',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.52),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
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
            top: 30,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.ocean.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildMetricsGrid(),
                const SizedBox(height: 16),
                _buildSearchField(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterPill(
                      icon: Icons.grid_view_rounded,
                      label: 'All customers',
                      selected: _filterMode == 'all',
                      onTap: () => setState(() => _filterMode = 'all'),
                    ),
                    _FilterPill(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Top spenders',
                      selected: _filterMode == 'high',
                      onTap: () => setState(() => _filterMode = 'high'),
                    ),
                    _FilterPill(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'No purchases',
                      selected: _filterMode == 'zero',
                      onTap: () => setState(() => _filterMode = 'zero'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader(displayedUsers.length),
                const SizedBox(height: 12),
                if (_loading)
                  ...List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _UserCardSkeleton(),
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else if (displayedUsers.isEmpty)
                  _buildEmptyState()
                else
                  ...displayedUsers.map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UserSummaryCard(
                        user: user,
                        totalPaid: user.purchaseSummary.totalAmountPaid,
                        pendingAmount: _userOutstanding(user),
                        purchaseCount: user.purchaseSummary.purchaseCount,
                        deliveryCount:
                            user.purchaseSummary.completedDeliveryCount,
                        initials: _initials(user.fullName),
                        onTap: () => _openPurchaseModal(user),
                        formatCurrency: _formatCompactCurrency,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _PaginationCard(
                  page: _pagination.page,
                  totalPages: _pagination.totalPages,
                  totalItems: _overallRealUsers,
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
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
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
            top: -30,
            right: -15,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -45,
            left: -10,
            child: Container(
              width: 130,
              height: 130,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PendingPaymentsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.pending_actions_rounded, size: 18),
                      label: const Text('Pending'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  _overviewLoading
                      ? 'Updating totals...'
                      : _formatCurrency(_overallPaid),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total money spent by real users across the entire sales dashboard.',
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Pending money',
                        value: _overviewLoading
                            ? '...'
                            : _formatCompactCurrency(_overallPending),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        label: 'Real users',
                        value: _overviewLoading ? '...' : '$_overallRealUsers',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        label: 'Page',
                        value: '${_pagination.page}/${_pagination.totalPages}',
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
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Top spenders',
            value: '$_highSpenderCount',
            subtitle: 'Highest paid users',
            icon: Icons.trending_up_rounded,
            color: AppTheme.ocean,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'No purchases',
            value: '$_zeroSpendCount',
            subtitle: 'Still inactive',
            icon: Icons.pause_circle_outline_rounded,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Loaded users',
            value: '${_users.length}',
            subtitle: 'Excluding test accounts',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF1E8E5A),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search by name, email, or phone',
          hintStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ocean),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _fetchUsers(page: 1);
                  },
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          'Customer list',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count visible',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppTheme.accent),
          const SizedBox(height: 12),
          Text(
            'Unable to load users',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
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
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _refreshDashboard,
            child: const Text('Retry'),
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 34,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching customers',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or switch the current filter to see more results.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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

class _UserSummaryCard extends StatelessWidget {
  final GlanceUser user;
  final double totalPaid;
  final double pendingAmount;
  final int purchaseCount;
  final int deliveryCount;
  final String initials;
  final VoidCallback onTap;
  final String Function(double amount) formatCurrency;

  const _UserSummaryCard({
    required this.user,
    required this.totalPaid,
    required this.pendingAmount,
    required this.purchaseCount,
    required this.deliveryCount,
    required this.initials,
    required this.onTap,
    required this.formatCurrency,
  });

  bool get _hasNoPurchases => purchaseCount == 0;
  bool get _isTopSpender => totalPaid >= 100000;

  Color get _accentColor {
    if (_hasNoPurchases) {
      return AppTheme.accent;
    }
    if (_isTopSpender) {
      return const Color(0xFF1E8E5A);
    }
    return AppTheme.ocean;
  }

  String get _statusLabel {
    if (_hasNoPurchases) {
      return 'No purchases yet';
    }
    if (_isTopSpender) {
      return 'Top spender';
    }
    return pendingAmount > 0 ? 'Outstanding balance' : 'Cleared';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _accentColor.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentColor,
                            _accentColor.withValues(alpha: 0.72),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
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
                            user.fullName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel,
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(totalPaid),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View purchases',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withValues(alpha: 0.42),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.black.withValues(alpha: 0.42),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.shopping_bag_outlined,
                        label:
                            '$purchaseCount purchase${purchaseCount == 1 ? '' : 's'}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: 'Pending ${formatCurrency(pendingAmount)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.local_shipping_outlined,
                        label: '$deliveryCount deliveries completed',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.mail_outline_rounded,
                        label: user.email,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
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
                fontSize: 12.5,
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

class _PaginationCard extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const _PaginationCard({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page $page of $totalPages',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalItems total users from server',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: hasPreviousPage ? onPrevious : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: hasNextPage ? onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _UserCardSkeleton extends StatelessWidget {
  const _UserCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 160,
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

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppTheme.accent : AppTheme.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.14)
                : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.accent.withValues(alpha: 0.3)
                  : AppTheme.ink.withValues(alpha: 0.08),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
