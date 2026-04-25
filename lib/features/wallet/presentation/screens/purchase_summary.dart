import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Wallet/Api/ApiService.dart';
import 'package:retilda/Views/Widgets/deliverymodal.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/presentation/widgets/webview.dart';
import 'package:retilda/model/purchases.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Purchasesummary extends ConsumerStatefulWidget {
  final Purchase purchase;
  const Purchasesummary({super.key, required this.purchase});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PurchasesummaryState();
}

class _PurchasesummaryState extends ConsumerState<Purchasesummary> {
  final WalletApiService _walletService = WalletApiService();

  String? productId;
  bool _isLoading = false;
  String? _activeAction;
  bool _deliveryCheckLoading = false;
  bool _deliveryAutoModalShown = false;
  Map<String, dynamic>? _deliveryCalculation;
  String? _deliveryCalculationMessage;

  Future<void> _loadUserData() async {
    final userData = await _walletService.getUserData();
    if (userData != null) {
      setState(() {
        productId = widget.purchase.product!.id;
      });
    }
  }

  String getNextPaymentDate(List<Payment> payments) {
    for (int i = 0; i < payments.length; i++) {
      if (payments[i].status != 'completed') {
        final String? dateValue =
            payments[i].nextPaymentDate ?? payments[i].paymentDate;
        if (dateValue == null) return "Pending";
        try {
          final DateTime nextPaymentDateTime = DateTime.parse(dateValue);
          final DateFormat formatter = DateFormat('dd MMM yy');
          return formatter.format(nextPaymentDateTime);
        } catch (_) {
          return "Pending";
        }
      }
    }
    return "Cleared";
  }

  String getNextPaymentAmount(
    Payment? nextPendingPayment,
    num remainingBalance,
  ) {
    return _formatMoney(
      _displayOutstandingAmount(
        payment: nextPendingPayment,
        remainingBalance: remainingBalance,
      ),
    );
  }

  String getNextPaymentStatus(
    Payment? nextPendingPayment,
    num remainingBalance,
  ) {
    if (nextPendingPayment == null) return "Fully Paid";
    final amountPaid = nextPendingPayment.amountPaid ?? 0;
    final outstanding = _displayOutstandingAmount(
      payment: nextPendingPayment,
      remainingBalance: remainingBalance,
    );

    if (outstanding <= 0) return 'Fully Paid';
    if (amountPaid > 0) {
      return 'Partially Paid (${_formatMoney(amountPaid)} paid, ${_formatMoney(outstanding)} left)';
    }
    return 'Not Paid (${_formatMoney(outstanding)} due)';
  }

  Payment? _nextPendingPayment(List<Payment> payments) {
    for (final payment in payments) {
      if (payment.status != 'completed') return payment;
    }
    return null;
  }

  num _displayOutstandingAmount({
    required Payment? payment,
    required num remainingBalance,
  }) {
    if (payment == null) return 0;
    final rawOutstanding = payment.outstandingAmount;
    final cappedOutstanding =
        remainingBalance > 0 ? remainingBalance : rawOutstanding;
    return rawOutstanding.clamp(0, cappedOutstanding);
  }

  num _displayInstallmentTarget({
    required Payment? payment,
    required num remainingBalance,
  }) {
    if (payment == null) return 0;
    final amountPaid = payment.amountPaid ?? 0;
    final outstanding = _displayOutstandingAmount(
      payment: payment,
      remainingBalance: remainingBalance,
    );
    return amountPaid + outstanding;
  }

  num? _readNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  num _deliveryAmountNeeded(Map<String, dynamic>? data) {
    if (data == null) return 0;
    return _readNum(data['amountNeeded'] ?? data['deliveryFee']) ?? 0;
  }

  bool _canPayLegacyDeliveryTopUp(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['deliveryRequirement']?.toString() != 'down_payment' &&
        _deliveryAmountNeeded(data) > 0;
  }

  bool _deliveryPaymentAvailable(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['deliveryRequested'] == true &&
        data['deliveryPaymentStatus'] == 'paid') {
      return true;
    }
    if (data['deliveryPaymentStatus'] == 'pending') {
      return true;
    }
    return data['deliveryEligible'] == true;
  }

  Map<String, dynamic> get _purchaseDeliveryCalculation =>
      widget.purchase.deliveryStateSnapshot;

  bool get _purchaseHasResolvedDeliveryState =>
      widget.purchase.isDeliveryCompleted ||
      widget.purchase.hasPendingDeliveryPayment;

  Map<String, dynamic>? get _effectiveDeliveryCalculation =>
      _purchaseHasResolvedDeliveryState
          ? _purchaseDeliveryCalculation
          : (_deliveryCalculation == null
              ? _purchaseDeliveryCalculation
              : {
                  ..._purchaseDeliveryCalculation,
                  ..._deliveryCalculation!,
                });

  bool _shouldShowDeliveryModal(Map<String, dynamic> data) {
    return _deliveryPaymentAvailable(data) || _deliveryAmountNeeded(data) > 0;
  }

  String _deliveryButtonLabel() {
    final data = _effectiveDeliveryCalculation;
    if (_deliveryCheckLoading) return 'Checking delivery...';
    if (data == null) return 'Delivery options';
    if (data['deliveryRequested'] == true &&
        data['deliveryPaymentStatus'] == 'paid') {
      return 'Delivery confirmed';
    }
    if (data['deliveryPaymentStatus'] == 'pending') {
      return 'Continue delivery payment';
    }
    if (_canPayLegacyDeliveryTopUp(data)) return 'Top up for delivery';
    if (data['deliveryEligible'] == true) {
      return 'Pay delivery fee';
    }
    if (_deliveryAmountNeeded(data) > 0) return 'Complete down payment';
    return 'Meet delivery conditions first';
  }

  IconData _deliveryButtonIcon() {
    final data = _effectiveDeliveryCalculation;
    if (_deliveryCheckLoading) return Icons.sync_rounded;
    if (data == null) return Icons.local_shipping_outlined;
    if (data['deliveryRequested'] == true &&
        data['deliveryPaymentStatus'] == 'paid') {
      return Icons.check_circle_outline_rounded;
    }
    if (data['deliveryPaymentStatus'] == 'pending') {
      return Icons.open_in_new_rounded;
    }
    if (_canPayLegacyDeliveryTopUp(data)) {
      return Icons.account_balance_wallet_outlined;
    }
    if (data['deliveryEligible'] == true) {
      return Icons.local_shipping_outlined;
    }
    if (_deliveryAmountNeeded(data) > 0) return Icons.info_outline_rounded;
    return Icons.lock_outline_rounded;
  }

  Future<void> _checkDeliveryEligibilityInBackground({
    bool showModalIfActionable = false,
  }) async {
    if (_purchaseHasResolvedDeliveryState) {
      if (_deliveryCalculation == null && mounted) {
        setState(() {
          _deliveryCalculation = _purchaseDeliveryCalculation;
        });
      }
      return;
    }

    final purchaseId = widget.purchase.id;
    if (_deliveryCheckLoading || purchaseId == null || purchaseId.isEmpty) {
      return;
    }

    setState(() => _deliveryCheckLoading = true);

    final result =
        await _walletService.calculateDeliveryEligibility(purchaseId);

    if (!mounted) return;

    final data = result['data'];
    final calculation = data is Map ? Map<String, dynamic>.from(data) : null;
    final message = result['message']?.toString();

    setState(() {
      _deliveryCheckLoading = false;
      if (result['success'] == true && calculation != null) {
        _deliveryCalculation = calculation;
        _deliveryCalculationMessage = message;
      }
    });

    if (result['success'] == true &&
        calculation != null &&
        showModalIfActionable &&
        !_deliveryAutoModalShown &&
        _shouldShowDeliveryModal(calculation)) {
      _deliveryAutoModalShown = true;
      await _openDeliveryModal(
        purchaseId: purchaseId,
        initialCalculation: calculation,
        initialMessage: message,
      );
    }
  }

  Future<void> _runLoadingAction(
    String actionKey,
    Future<Map<String, dynamic>> Function() request,
    Future<void> Function(Map<String, dynamic> result) onSuccess,
    String fallbackError,
  ) async {
    if (_isLoading || productId == null) return;

    setState(() {
      _isLoading = true;
      _activeAction = actionKey;
    });

    final result = await request();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _activeAction = null;
    });

    if (result['success'] == true) {
      await onSuccess(result);
      return;
    }

    _showApiDialog(
      title: 'Error',
      message: result['message'] ?? fallbackError,
    );
  }

  Future<void> _handleWalletPayment() async {
    final purchaseId = widget.purchase.id;
    await _runLoadingAction(
      'wallet_payment',
      () => _walletService.makeInstallmentPaymentUsingWallet(
        productId!,
        purchaseId: purchaseId,
      ),
      (result) async {
        await showAppAlert(
          context: context,
          title: 'Success',
          message: result['message'] ?? 'Payment completed successfully.',
          tone: AppFeedbackTone.success,
          buttonText: 'Continue',
          icon: Icons.check_circle_outline_rounded,
          onButtonPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(true);
          },
        );
      },
      'Payment failed',
    );
  }

  Future<void> _handleCardPayment() async {
    final purchaseId = widget.purchase.id;
    await _runLoadingAction(
      'card_payment',
      () => _walletService.makeInstallmentPaymentUsingCard(
        productId!,
        purchaseId: purchaseId,
      ),
      (result) async {
        final String paymentUrl = result['paymentUrl'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewScreen(
              url: paymentUrl,
              title: 'Pay with card',
            ),
          ),
        );
      },
      'Card payment failed',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (_purchaseHasResolvedDeliveryState) {
      _deliveryCalculation = _purchaseDeliveryCalculation;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkDeliveryEligibilityInBackground(showModalIfActionable: true);
    });
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please sign in again.')),
    );
  }

  void _showApiDialog({
    required String title,
    required String message,
  }) {
    final lower = message.toLowerCase();
    final bool tokenExpired =
        lower.contains('token has expired') || lower.contains('401');
    showAppAlert(
      context: context,
      title: tokenExpired ? 'Session expired' : title,
      message: tokenExpired
          ? 'Your session has expired. Please log out and sign back in to continue.'
          : message,
      tone: tokenExpired ? AppFeedbackTone.warning : AppFeedbackTone.error,
      buttonText: tokenExpired ? 'Stay here' : 'Okay',
      secondaryButtonText: tokenExpired ? 'Log out' : null,
      onSecondaryButtonPressed: tokenExpired ? _forceLogout : null,
      icon: tokenExpired
          ? Icons.lock_clock_outlined
          : Icons.error_outline_rounded,
    );
    if (tokenExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please sign in again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showPaymentConfirmationSheet({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
    AppFeedbackTone tone = AppFeedbackTone.info,
  }) async {
    await showAppNoticeSheet<void>(
      context: context,
      title: title,
      message: message,
      tone: tone,
      primaryLabel: confirmLabel,
      secondaryLabel: 'Cancel',
      icon: icon,
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        onConfirm();
      },
      onSecondaryPressed: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _openDeliveryModal({
    required String purchaseId,
    Map<String, dynamic>? initialCalculation,
    String? initialMessage,
  }) async {
    final refreshed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryModal(
        purchaseId: purchaseId,
        initialCalculation: initialCalculation,
        initialMessage: initialMessage,
      ),
    );
    if (refreshed == true) {
      await _checkDeliveryEligibilityInBackground();
    }
  }

  Future<void> _showTopUpConfirmationSheet() async {
    final purchaseId = widget.purchase.id;
    if (purchaseId == null || purchaseId.isEmpty) {
      _showApiDialog(
        title: 'Delivery unavailable',
        message: 'Unable to check delivery eligibility for this purchase.',
      );
      return;
    }

    if (_deliveryCheckLoading) return;

    final data = _effectiveDeliveryCalculation;
    if (data?['deliveryRequested'] == true ||
        data?['deliveryPaymentStatus'] == 'paid') {
      await showAppNoticeSheet(
        context: context,
        title: 'Delivery already completed',
        message:
            'This purchase already has a completed delivery payment and recorded delivery request.',
        tone: AppFeedbackTone.success,
        primaryLabel: 'Done',
        icon: Icons.check_circle_outline_rounded,
      );
      return;
    }

    await _openDeliveryModal(
      purchaseId: purchaseId,
      initialCalculation: data,
      initialMessage: _deliveryCalculationMessage,
    );
  }

  String _formatMoney(num amount) {
    return 'N${NumberFormat('#,##0').format(amount)}';
  }

  double _completionRatio(num totalPaid, num totalToPay) {
    if (totalToPay <= 0) {
      return 0;
    }
    return (totalPaid / totalToPay).clamp(0, 1).toDouble();
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color valueColor,
    IconData? icon,
    String? caption,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: valueColor),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
              letterSpacing: -0.4,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.54),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF103C57),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payments = widget.purchase.payments ?? const <Payment>[];
    final imageUrl = (widget.purchase.product?.images?.isNotEmpty ?? false)
        ? widget.purchase.product!.images!.first
        : '';
    final productTitle = widget.purchase.product?.name?.trim();
    final displayTitle = (productTitle != null && productTitle.isNotEmpty)
        ? productTitle
        : 'Purchased item';
    final totalToPay = widget.purchase.totalToPayComputed;
    final totalPaid = widget.purchase.totalPaidComputed;
    final remainingBalance = widget.purchase.totalOutstandingComputed;
    final progress = _completionRatio(totalPaid, totalToPay);
    final nextPaymentDate = getNextPaymentDate(payments);
    final nextPendingPayment = _nextPendingPayment(payments);
    final nextPaymentAmount =
        getNextPaymentAmount(nextPendingPayment, remainingBalance);
    final nextPaymentStatus =
        getNextPaymentStatus(nextPendingPayment, remainingBalance);
    final nextLateFee = nextPendingPayment?.lateFeeTotal ?? 0;
    final nextLateFeeWeeks = nextPendingPayment?.lateFeeAppliedWeeks ?? 0;
    final nextAmountPaid = nextPendingPayment?.amountPaid ?? 0;
    final nextOutstanding = _displayOutstandingAmount(
      payment: nextPendingPayment,
      remainingBalance: remainingBalance,
    );
    final nextInstallmentTarget = _displayInstallmentTarget(
      payment: nextPendingPayment,
      remainingBalance: remainingBalance,
    );
    final deliveryStatus =
        widget.purchase.deliveryStatus?.toString() ?? 'Pending';
    final durationLabel = widget.purchase.durationMonths != null
        ? '${widget.purchase.durationMonths} ${widget.purchase.repaymentFrequency ?? 'months'}'
        : '${payments.length} ${widget.purchase.paymentPlan == "monthly" ? 'Months' : "weeks"}';
    final planLabel =
        (widget.purchase.purchaseType ?? widget.purchase.paymentPlan ?? 'Plan')
            .replaceAll('_', ' ');

    return Sizer(
      builder: (context, orientation, deviceType) {
        const Color pageBg = Color(0xFFF6F7FB);
        const Color deepBlue = Color(0xFF103C57);
        const Color accent = Color(0xFFFB9324);

        return Scaffold(
          backgroundColor: pageBg,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _deliveryCheckLoading
                      ? null
                      : _showTopUpConfirmationSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shadowColor: Colors.orange.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_deliveryCheckLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(_deliveryButtonIcon(), size: 19),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _deliveryButtonLabel(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              "Payment summary",
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    height: 24.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              color: const Color(0xFFEAF1F6),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: Color(0xFF103C57),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.62),
                                  Colors.transparent
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      size: 16, color: Colors.black87),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    planLabel,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.16),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Next: $nextPaymentDate',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.22),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        deliveryStatus,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment progress',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: deepBlue,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.purchase.paymentPlan == "once"
                              ? 'This order was created as a one-time payment.'
                              : 'You have paid ${_formatMoney(totalPaid)} out of ${_formatMoney(totalToPay)} so far.',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.68),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: 'Paid',
                                value: _formatMoney(totalPaid),
                                backgroundColor: const Color(0xFFF7F9FC),
                                valueColor: deepBlue,
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                label: 'Remaining',
                                value: _formatMoney(remainingBalance),
                                backgroundColor: const Color(0xFFFFF7ED),
                                valueColor: accent,
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Payment completion',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: deepBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    deepBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'Next payment',
                                      value: nextPaymentAmount,
                                      caption: nextPaymentDate,
                                      backgroundColor: Colors.white,
                                      valueColor: deepBlue,
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'Status',
                                      value: nextPaymentStatus,
                                      backgroundColor: Colors.white,
                                      valueColor: accent,
                                      icon: Icons.info_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment actions',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: deepBlue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Choose how you want to continue with this purchase.',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: 0.64),
                                ),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final verticalLayout =
                                      constraints.maxWidth < 430;
                                  final walletButton = OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            _showPaymentConfirmationSheet(
                                              title: 'Confirm wallet payment',
                                              message:
                                                  'You are about to pay $nextPaymentAmount from your Retilda wallet for this installment. Continue?',
                                              confirmLabel: 'Confirm and pay',
                                              icon: Icons
                                                  .account_balance_wallet_outlined,
                                              onConfirm: _handleWalletPayment,
                                            );
                                          },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _activeAction == 'wallet_payment'
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Wallet payment",
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w800,
                                              color: deepBlue,
                                            ),
                                          ),
                                  );

                                  final cardButton = FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            _showPaymentConfirmationSheet(
                                              title: 'Confirm card payment',
                                              message:
                                                  'You are about to continue this installment payment with your card for $nextPaymentAmount. Continue?',
                                              confirmLabel: 'Confirm and pay',
                                              icon: Icons.credit_card_rounded,
                                              onConfirm: _handleCardPayment,
                                            );
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: deepBlue,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _activeAction == 'card_payment'
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Card payment",
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  );

                                  if (verticalLayout) {
                                    return Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: walletButton,
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: cardButton,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: walletButton),
                                      const SizedBox(width: 10),
                                      Expanded(child: cardButton),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment breakdown",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: deepBlue,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A simple summary of this plan and what is left to pay.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.64),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                label: 'Total amount',
                                value: _formatMoney(totalToPay),
                              ),
                              _buildDetailRow(
                                label: 'Total paid',
                                value: _formatMoney(totalPaid),
                              ),
                              _buildDetailRow(
                                label: 'Payment plan',
                                value:
                                    widget.purchase.paymentPlan?.toString() ??
                                        'N/A',
                              ),
                              _buildDetailRow(
                                label: 'Purchase type',
                                value: widget.purchase.purchaseType ?? 'N/A',
                              ),
                              _buildDetailRow(
                                label: 'Down payment',
                                value: _formatMoney(
                                  widget.purchase.downPaymentAmount ?? 0,
                                ),
                              ),
                              _buildDetailRow(
                                label: 'Payment duration',
                                value: durationLabel,
                              ),
                              _buildDetailRow(
                                label: 'Next payment date',
                                value: nextPaymentDate,
                              ),
                              _buildDetailRow(
                                label: 'Next payment amount',
                                value: nextPaymentAmount,
                              ),
                              if (nextPendingPayment != null) ...[
                                _buildDetailRow(
                                  label: 'Next payment target',
                                  value: _formatMoney(nextInstallmentTarget),
                                ),
                                _buildDetailRow(
                                  label: 'Paid toward next payment',
                                  value: _formatMoney(nextAmountPaid),
                                ),
                                _buildDetailRow(
                                  label: 'Left on next payment',
                                  value: _formatMoney(nextOutstanding),
                                ),
                                _buildDetailRow(
                                  label: 'Late fees',
                                  value:
                                      '${_formatMoney(nextLateFee)} over $nextLateFeeWeeks week${nextLateFeeWeeks == 1 ? '' : 's'}',
                                ),
                              ],
                              _buildDetailRow(
                                label: 'Shipping status',
                                value: deliveryStatus,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF6D2B0),
                            ),
                          ),
                          child: Text(
                            widget.purchase.paymentPlan == 'once'
                                ? 'This purchase is expected to be cleared in one payment.'
                                : 'You still have ${_formatMoney(remainingBalance)} left on this plan. Pending installment amounts may include backend-applied late fees when payments are overdue.',
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 100), // ensure bottom CTA visible
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
