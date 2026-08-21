import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Products/Update/updatedetails.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/admin/data/models/missing_weight_summary.dart';
import 'package:retilda/features/admin/presentation/providers/admin_providers.dart';
import 'package:retilda/model/products.dart' as product_model;
import 'package:sizer/sizer.dart';

class MissingWeightScreen extends ConsumerStatefulWidget {
  const MissingWeightScreen({super.key});

  @override
  ConsumerState<MissingWeightScreen> createState() =>
      _MissingWeightScreenState();
}

class _MissingWeightScreenState extends ConsumerState<MissingWeightScreen> {
  late Future<MissingWeightSummary> _future;
  bool _isResolvingProduct = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MissingWeightSummary> _load() {
    return ref.read(missingWeightServiceProvider).getMissingWeightProducts();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openProduct(MissingWeightItem item) async {
    if (_isResolvingProduct) return;
    setState(() => _isResolvingProduct = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        'products/search',
        queryParameters: {'q': item.name},
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        _showLookupError();
        return;
      }

      final decoded = jsonDecode(response.body);
      final apiResponse = product_model.ApiResponse.fromJson(decoded);
      final results = apiResponse.data;

      product_model.Product? match;
      for (final product in results) {
        if (product.id == item.productId) {
          match = product;
          break;
        }
      }
      match ??= results.isNotEmpty ? results.first : null;

      if (match == null) {
        _showLookupError();
        return;
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateDetails(
            product: match!,
            openWeightModalOnLoad: true,
          ),
        ),
      );
      if (!mounted) return;
      _refresh();
    } catch (_) {
      if (mounted) _showLookupError();
    } finally {
      if (mounted) setState(() => _isResolvingProduct = false);
    }
  }

  void _showLookupError() {
    showAppAlert(
      context: context,
      title: 'Product not found',
      message:
          'Could not look up this product to edit it. Try finding it from Update Product instead.',
      tone: AppFeedbackTone.error,
      buttonText: 'Okay',
      icon: Icons.error_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            title: CustomText(
              'Missing weight',
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refresh,
              ),
            ],
          ),
          body: FutureBuilder<MissingWeightSummary>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                      color: AppTheme.accent,
                      minHeight: 4,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 12),
                        CustomText(
                          'Unable to load products',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final summary = snapshot.data ?? MissingWeightSummary.empty;

              if (summary.totalCount == 0 || summary.categories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 56,
                          color: Color(0xFF0E7C66),
                        ),
                        const SizedBox(height: 14),
                        CustomText(
                          'Every product has a delivery weight',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  CustomText(
                    '${summary.totalCount} product${summary.totalCount == 1 ? '' : 's'} missing a delivery weight',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 12),
                  ...summary.categories.map(
                    (category) => _MissingWeightCategorySection(
                      category: category,
                      isBusy: _isResolvingProduct,
                      onTapItem: _openProduct,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MissingWeightCategorySection extends StatelessWidget {
  const _MissingWeightCategorySection({
    required this.category,
    required this.isBusy,
    required this.onTapItem,
  });

  final MissingWeightCategory category;
  final bool isBusy;
  final ValueChanged<MissingWeightItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            '${category.category} (${category.count})',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          children: category.items
              .map(
                (item) => ListTile(
                  enabled: !isBusy,
                  onTap: () => onTapItem(item),
                  title: Text(
                    item.name,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.brand.isNotEmpty ? '${item.brand} · ' : ''}'
                    'Stock ${item.availableStock}'
                    '${item.activePurchaseCount > 0 ? ' · ${item.activePurchaseCount} active purchase${item.activePurchaseCount == 1 ? '' : 's'}' : ''}',
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  trailing: item.activePurchaseCount > 0
                      ? const Icon(Icons.priority_high_rounded,
                          color: Color(0xFFB54708))
                      : const Icon(Icons.chevron_right_rounded),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
