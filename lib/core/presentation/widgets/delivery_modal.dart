import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/presentation/widgets/webview.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/core/theme/app_theme.dart';

class DeliveryModal extends StatefulWidget {
  final String purchaseId;
  final Map<String, dynamic>? initialCalculation;
  final String? initialMessage;
  final bool autoFetch;

  const DeliveryModal({
    super.key,
    required this.purchaseId,
    this.initialCalculation,
    this.initialMessage,
    this.autoFetch = true,
  });

  @override
  State<DeliveryModal> createState() => _DeliveryModalState();
}

class _DeliveryModalState extends State<DeliveryModal> {
  late final ApiClient _apiClient = ApiClient(session: AppSession());

  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM'
  ];
  final List<String> _categories = ['local', 'regional', 'interstate'];
  String? _selectedTimeSlot;
  String? _selectedCategory;
  bool isLoading = false;
  String? token;
  num? deliveryThresholdAmount;
  num? currentAmountPaid;
  num? targetAmountPaid;
  num? targetPercent;
  String? quotedProductName;
  String? quoteMessage;
  String? deliveryRequirement;
  num? courierDeliveryFee;
  String? quotedAddress;
  bool? deliveryAreaOperational;
  String? calculationError;
  bool? deliveryEligible;
  bool? deliveryRequested;
  String? deliveryPaymentStatus;
  String? deliveryPaymentReference;
  String? deliveryPaymentRequestedAt;
  String? deliveryPaymentPaidAt;
  bool isQuotationFetched = false;

  bool get _hasCourierQuote =>
      courierDeliveryFee != null && quotedAddress != null;

  bool get _deliveryPaymentPending =>
      deliveryPaymentStatus == 'pending' && deliveryRequested != true;

  bool get _deliveryCompleted =>
      deliveryRequested == true && deliveryPaymentStatus == 'paid';

  bool get _deliveryPaymentCanStart =>
      deliveryEligible == true || _deliveryPaymentPending || _deliveryCompleted;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final loadedToken = await AppSession().userToken();
    if (!mounted) return;
    setState(() {
      token = loadedToken;
    });

    if (widget.initialCalculation != null) {
      _applyCalculationData(
        widget.initialCalculation!,
        message: widget.initialMessage,
      );
      return;
    }

    if (widget.autoFetch) {
      await _fetchQuotation(showError: false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _clearCourierQuote() {
    if (_deliveryPaymentPending || _deliveryCompleted) {
      return;
    }
    if (!_hasCourierQuote &&
        quotedAddress == null &&
        deliveryAreaOperational == null) {
      return;
    }
    setState(() {
      courierDeliveryFee = null;
      quotedAddress = null;
      deliveryAreaOperational = null;
    });
  }

  void _revealCourierQuote() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _fetchQuotation({bool showError = true}) async {
    if (token == null) {
      final error = 'Unable to fetch your session details right now.';
      setState(() => calculationError = error);
      if (showError) {
        showAppAlert(
          context: context,
          title: 'Session unavailable',
          message: error,
          tone: AppFeedbackTone.error,
          buttonText: 'Okay',
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
      calculationError = null;
    });

    try {
      final response = await _apiClient.post(
        'requestForGoodsDeliveryCalculation/${widget.purchaseId}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final quoteData =
            data is Map<String, dynamic> ? data : const <String, dynamic>{};
        if (!mounted) return;
        _applyCalculationData(
          quoteData,
          message: decoded['message']?.toString(),
        );
      } else {
        if (!mounted) return;
        const error = 'Unable to calculate the delivery threshold right now.';
        setState(() => calculationError = error);
        if (showError) {
          showAppAlert(
            context: context,
            title: 'Calculation failed',
            message: error,
            tone: AppFeedbackTone.error,
            buttonText: 'Okay',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      const error = 'Unable to calculate the delivery threshold right now.';
      setState(() => calculationError = error);
      if (showError) {
        showAppAlert(
          context: context,
          title: 'Calculation failed',
          message: error,
          tone: AppFeedbackTone.error,
          buttonText: 'Okay',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyCalculationData(
    Map<String, dynamic> quoteData, {
    String? message,
  }) {
    final amountNeeded =
        _readNum(quoteData['amountNeeded'] ?? quoteData['deliveryFee']) ?? 0;
    final destination = quoteData['deliveryDestination'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(quoteData['deliveryDestination'])
        : const <String, dynamic>{};
    final quote = quoteData['deliveryQuote'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(quoteData['deliveryQuote'])
        : const <String, dynamic>{};
    final resolvedAddress = destination['formattedAddress']?.toString() ??
        destination['address']?.toString();
    final resolvedDeliveryFee = _readNum(
      quoteData['deliveryFeeAmount'] ??
          quote['deliveryFee'] ??
          quoteData['deliveryFee'],
    );

    setState(() {
      deliveryThresholdAmount = amountNeeded;
      currentAmountPaid =
          _readNum(quoteData['currentAmountPaid']) ?? currentAmountPaid;
      targetAmountPaid =
          _readNum(quoteData['targetAmountPaid']) ?? targetAmountPaid;
      targetPercent = _readNum(quoteData['targetPercent']) ?? targetPercent;
      quotedProductName =
          quoteData['productName']?.toString() ?? quotedProductName;
      quoteMessage = message ?? quoteMessage;
      deliveryRequirement =
          quoteData['deliveryRequirement']?.toString() ?? deliveryRequirement;
      deliveryEligible = quoteData.containsKey('deliveryEligible')
          ? quoteData['deliveryEligible'] == true
          : deliveryEligible;
      deliveryRequested = quoteData.containsKey('deliveryRequested')
          ? quoteData['deliveryRequested'] == true
          : deliveryRequested;
      deliveryPaymentStatus = quoteData['deliveryPaymentStatus']?.toString() ??
          deliveryPaymentStatus;
      deliveryPaymentReference =
          quoteData['deliveryPaymentReference']?.toString() ??
              deliveryPaymentReference;
      deliveryPaymentRequestedAt =
          quoteData['deliveryPaymentRequestedAt']?.toString() ??
              deliveryPaymentRequestedAt;
      deliveryPaymentPaidAt = quoteData['deliveryPaymentPaidAt']?.toString() ??
          deliveryPaymentPaidAt;
      quotedAddress = resolvedAddress ?? quotedAddress;
      deliveryAreaOperational = destination.containsKey('isOperational')
          ? destination['isOperational'] == true
          : deliveryAreaOperational;
      courierDeliveryFee = resolvedDeliveryFee ?? courierDeliveryFee;
      calculationError = null;
      isQuotationFetched = true;
    });

    if (resolvedAddress != null && _addressController.text.trim().isEmpty) {
      _addressController.text = resolvedAddress;
    }
    if (resolvedDeliveryFee != null || resolvedAddress != null) {
      _revealCourierQuote();
    }
  }

  Future<void> _payDeliveryThreshold() async {
    if (token == null) {
      showAppAlert(
        context: context,
        title: 'Session unavailable',
        message: 'Unable to fetch your session details right now.',
        tone: AppFeedbackTone.error,
        buttonText: 'Okay',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _apiClient.post(
        'installmentRepaymentUsingWalletByPercentage',
        body: {
          'purchaseId': widget.purchaseId,
        },
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        final responseData = decoded['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded['data'])
            : Map<String, dynamic>.from(decoded);
        final amountDeducted = _readNum(responseData['amountDeducted']) ?? 0;
        final requirement = responseData['deliveryRequirement']?.toString() ??
            deliveryRequirement;
        final eligible = responseData['deliveryEligible'] == true;

        if (!mounted) return;
        _applyCalculationData(
          {
            'amountNeeded': responseData['amountNeeded'] ?? 0,
            'currentAmountPaid':
                responseData['currentAmountPaid'] ?? responseData['amountPaid'],
            'targetAmountPaid': responseData['targetAmountPaid'],
            'targetPercent': responseData['targetPercent'],
            'productName': responseData['productName'],
            'deliveryRequirement': requirement,
            'deliveryEligible': responseData['deliveryEligible'],
          },
          message: decoded['message']?.toString(),
        );
        await showAppNoticeSheet(
          context: context,
          title: amountDeducted > 0 ? 'Top-up paid' : 'Delivery updated',
          message: eligible && requirement == 'down_payment'
              ? 'No extra delivery top-up was charged. This purchase is now using the completed down-payment rule for delivery.'
              : 'Your wallet payment was successful. You can now submit your delivery details.',
          tone: eligible ? AppFeedbackTone.success : AppFeedbackTone.info,
          primaryLabel: 'Continue',
          icon: Icons.local_shipping_outlined,
        );
      } else {
        if (!mounted) return;
        showAppAlert(
          context: context,
          title: 'Payment failed',
          message:
              decoded['message']?.toString() ?? 'Unable to complete payment.',
          tone: AppFeedbackTone.error,
          buttonText: 'Okay',
        );
      }
    } catch (_) {
      if (!mounted) return;
      showAppAlert(
        context: context,
        title: 'Payment failed',
        message: 'Unable to complete payment right now.',
        tone: AppFeedbackTone.error,
        buttonText: 'Okay',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pollDeliveryStatus({
    int attempts = 6,
    bool showPendingNotice = true,
  }) async {
    for (var index = 0; index < attempts; index++) {
      try {
        final response =
            await _apiClient.get('order/status/${widget.purchaseId}');
        final decoded = _tryDecodeJson(response.body);
        final data = decoded?['data'];
        if (response.statusCode == 200 && data is Map<String, dynamic>) {
          _applyCalculationData(
            data,
            message: decoded?['message']?.toString(),
          );

          if (data['deliveryPaymentStatus'] == 'paid' &&
              data['deliveryRequested'] == true) {
            if (!mounted) return;
            await showAppNoticeSheet(
              context: context,
              title: 'Delivery request confirmed',
              message:
                  'Your delivery fee payment was confirmed and the delivery request has now been recorded successfully.',
              tone: AppFeedbackTone.success,
              primaryLabel: 'Done',
              icon: Icons.local_shipping_outlined,
            );
            if (!mounted) return;
            Navigator.of(context).pop(true);
            return;
          }

          if (data['deliveryPaymentStatus'] == 'failed') {
            if (!mounted) return;
            showAppAlert(
              context: context,
              title: 'Delivery payment failed',
              message:
                  'The delivery payment did not complete. You can try again from this screen.',
              tone: AppFeedbackTone.error,
              buttonText: 'Okay',
            );
            return;
          }
        }
      } catch (_) {}

      if (index < attempts - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!mounted || !showPendingNotice) return;
    await showAppNoticeSheet(
      context: context,
      title: 'Payment still pending',
      message:
          'Your delivery payment link has been created, but we have not received confirmation yet. If you already paid, please wait a moment and check again. You can also reopen the same payment link from this screen.',
      tone: AppFeedbackTone.info,
      primaryLabel: 'Okay',
      icon: Icons.hourglass_top_rounded,
    );
  }

  Future<void> _initializeDeliveryPayment() async {
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      showAppAlert(
        context: context,
        title: 'Address required',
        message: 'Enter a delivery address before starting delivery payment.',
        tone: AppFeedbackTone.info,
        buttonText: 'Okay',
      );
      return;
    }

    if (!_deliveryPaymentCanStart) {
      showAppAlert(
        context: context,
        title: 'Delivery not ready',
        message:
            'This purchase is not yet eligible for delivery. Complete the required payment condition first.',
        tone: AppFeedbackTone.warning,
        buttonText: 'Okay',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _apiClient.post(
        'requestForGoodsDelivery/${widget.purchaseId}',
        body: {
          'address': address,
        },
      );

      final decoded = _tryDecodeJson(response.body);
      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] == true) {
        final data = decoded['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded['data'])
            : const <String, dynamic>{};
        _applyCalculationData(
          data,
          message: decoded['message']?.toString(),
        );
        final paymentUrl = data['paymentUrl']?.toString();
        if (paymentUrl == null || paymentUrl.isEmpty) {
          showAppAlert(
            context: context,
            title: 'Payment link unavailable',
            message:
                'The delivery payment was initialized but no payment link was returned.',
            tone: AppFeedbackTone.error,
            buttonText: 'Okay',
          );
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewScreen(
              url: paymentUrl,
              title: 'Pay delivery fee',
            ),
          ),
        );
        if (!mounted) return;
        await _pollDeliveryStatus();
        return;
      }

      if (decoded is Map<String, dynamic>) {
        if (response.statusCode == 400) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            _applyCalculationData(
              data,
              message: decoded['message']?.toString(),
            );
          }
        }

        if (response.statusCode == 409) {
          await _pollDeliveryStatus(attempts: 1, showPendingNotice: false);
          if (!mounted) return;
          await showAppNoticeSheet(
            context: context,
            title: 'Delivery already completed',
            message: decoded['message']?.toString() ??
                'Delivery has already been requested for this purchase.',
            tone: AppFeedbackTone.info,
            primaryLabel: 'Done',
            icon: Icons.local_shipping_outlined,
          );
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }

        showAppAlert(
          context: context,
          title: response.statusCode == 404
              ? 'Purchase not found'
              : 'Unable to start delivery payment',
          message: decoded['message']?.toString() ??
              'Delivery payment could not be initialized right now.',
          tone: AppFeedbackTone.error,
          buttonText: 'Okay',
        );
        return;
      }

      showAppAlert(
        context: context,
        title: 'Unable to start delivery payment',
        message: response.statusCode == 404
            ? 'The delivery endpoint is not available on the current server deployment yet.'
            : 'Delivery payment could not be initialized right now.',
        tone: AppFeedbackTone.error,
        buttonText: 'Okay',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showAppAlert(
        context: context,
        title: 'Unable to start delivery payment',
        message: 'Delivery payment could not be initialized right now.',
        tone: AppFeedbackTone.error,
        buttonText: 'Okay',
      );
    }
  }

  num? _readNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String _formatMoney(num amount) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: 'N',
      decimalDigits: 0,
    ).format(amount);
  }

  String _primaryButtonLabel() {
    final amount = deliveryThresholdAmount ?? 0;
    if (isLoading && !isQuotationFetched) return 'Checking delivery...';
    if (isLoading) return 'Starting delivery payment...';
    if (!isQuotationFetched) return 'Retry delivery check';
    if (_deliveryCompleted) return 'Delivery already paid';
    if (_deliveryPaymentPending) return 'Continue delivery payment';
    if (amount > 0 && _canPayDeliveryThreshold) {
      return 'Pay ${_formatMoney(amount)} from wallet';
    }
    if (amount > 0) return 'Complete down payment first';
    if (deliveryEligible != true) return 'Meet delivery conditions first';
    return 'Pay delivery fee';
  }

  IconData _primaryButtonIcon() {
    final amount = deliveryThresholdAmount ?? 0;
    if (!isQuotationFetched) return Icons.refresh_rounded;
    if (_deliveryCompleted) return Icons.check_circle_outline_rounded;
    if (_deliveryPaymentPending) return Icons.open_in_new_rounded;
    if (amount > 0 && _canPayDeliveryThreshold) {
      return Icons.account_balance_wallet_outlined;
    }
    if (amount > 0) return Icons.info_outline_rounded;
    if (deliveryEligible != true) return Icons.lock_outline_rounded;
    return Icons.payments_outlined;
  }

  bool get _canPayDeliveryThreshold =>
      deliveryRequirement != 'down_payment' &&
      (deliveryThresholdAmount ?? 0) > 0;

  Future<void> _handlePrimaryAction() async {
    if (_deliveryCompleted) {
      await showAppNoticeSheet(
        context: context,
        title: 'Delivery already completed',
        message:
            'This purchase already has a paid delivery request. There is nothing else to do here.',
        tone: AppFeedbackTone.success,
        primaryLabel: 'Done',
        icon: Icons.check_circle_outline_rounded,
      );
      return;
    }
    if (isQuotationFetched && _canPayDeliveryThreshold) {
      await _payDeliveryThreshold();
      return;
    }
    if (isQuotationFetched && (deliveryThresholdAmount ?? 0) > 0) {
      await showAppNoticeSheet(
        context: context,
        title: 'Down payment required',
        message:
            'This purchase is eligible for delivery only after the selected down payment has been completed. Use the payment actions on the purchase summary to continue.',
        tone: AppFeedbackTone.info,
        primaryLabel: 'Okay',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (isQuotationFetched &&
        deliveryEligible != true &&
        !_deliveryPaymentPending) {
      await showAppNoticeSheet(
        context: context,
        title: 'Delivery not ready',
        message:
            'This purchase must first meet the delivery eligibility condition before delivery payment can be started.',
        tone: AppFeedbackTone.info,
        primaryLabel: 'Okay',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }
    if (isQuotationFetched) {
      await _initializeDeliveryPayment();
      return;
    }
    await _fetchQuotation();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Complete delivery payment for the selected address after purchase eligibility is confirmed.',
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: 0.64),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF4F7FB),
                            foregroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Delivery address'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              onChanged: (_) => _clearCourierQuote(),
                              style: GoogleFonts.manrope(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter address',
                                prefixIcon: const Icon(Icons.home_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  14,
                                ),
                                collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                title: Text(
                                  'Optional delivery preferences',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                subtitle: Text(
                                  'Phone, date, time, and category',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withValues(alpha: 0.56),
                                  ),
                                ),
                                children: [
                                  TextFormField(
                                    controller: _phoneNumberController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Phone number',
                                      prefixIcon:
                                          const Icon(Icons.phone_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => _selectDate(context),
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: _dateController,
                                        style: GoogleFonts.manrope(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Preferred date',
                                          prefixIcon: const Icon(
                                            Icons.calendar_today_outlined,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      hintText: 'Time slot',
                                    ),
                                    initialValue: _selectedTimeSlot,
                                    items: _timeSlots
                                        .map(
                                          (slot) => DropdownMenuItem(
                                            value: slot,
                                            child: Text(slot),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedTimeSlot = value),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      hintText: 'Category',
                                    ),
                                    initialValue: _selectedCategory,
                                    items: _categories
                                        .map(
                                          (category) => DropdownMenuItem(
                                            value: category,
                                            child:
                                                Text(_categoryLabel(category)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedCategory = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isLoading && !isQuotationFetched)
                              _buildInfoBanner(
                                icon: Icons.sync_rounded,
                                title: 'Checking delivery status',
                                message:
                                    'Please wait while we confirm eligibility.',
                                backgroundColor: const Color(0xFFF4F8FC),
                                borderColor: const Color(0xFFD8E7F3),
                              ),
                            if (calculationError != null && !isQuotationFetched)
                              _buildInfoBanner(
                                icon: Icons.error_outline_rounded,
                                title: 'Unable to check delivery',
                                message: calculationError!,
                                backgroundColor: const Color(0xFFFFF5F5),
                                borderColor: const Color(0xFFFFD1D1),
                              ),
                            if (deliveryPaymentStatus != null ||
                                deliveryRequested != null)
                              _buildDeliveryPaymentStatusCard(),
                            if (deliveryThresholdAmount != null)
                              _buildEligibilityCard(),
                            if (_hasCourierQuote) ...[
                              const SizedBox(height: 14),
                              _buildCourierQuoteCard(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : _handlePrimaryAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_primaryButtonIcon()),
                        label: Text(
                          _primaryButtonLabel(),
                          style: GoogleFonts.manrope(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.64),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPaymentStatusCard() {
    final status = deliveryPaymentStatus ?? 'not_started';
    final isPaid = status == 'paid' && deliveryRequested == true;
    final isPending = status == 'pending' && deliveryRequested != true;
    final isFailed = status == 'failed';

    final backgroundColor = isPaid
        ? const Color(0xFFF3FAF7)
        : isPending
            ? const Color(0xFFFFF7ED)
            : isFailed
                ? const Color(0xFFFFF5F5)
                : const Color(0xFFF7F9FC);
    final borderColor = isPaid
        ? const Color(0xFFB7E8DA)
        : isPending
            ? const Color(0xFFF6D2B0)
            : isFailed
                ? const Color(0xFFFFD1D1)
                : const Color(0xFFD8E7F3);
    final title = isPaid
        ? 'Delivery request paid'
        : isPending
            ? 'Delivery payment pending'
            : isFailed
                ? 'Delivery payment failed'
                : 'Delivery payment not started';
    final message = isPaid
        ? 'Your payment has been confirmed and the delivery request has been recorded.'
        : isPending
            ? 'A payment link has already been created for this purchase. Reopen it to continue paying for delivery.'
            : isFailed
                ? 'The last delivery payment attempt failed. You can start a new one from this screen.'
                : 'Enter the address and continue to generate the delivery payment link.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.68),
            ),
          ),
          if (deliveryPaymentReference != null &&
              deliveryPaymentReference!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Reference: $deliveryPaymentReference',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibilityCard() {
    final amount = deliveryThresholdAmount ?? 0;
    final isReady = amount <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFF3FAF7) : const Color(0xFFFFFAF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady ? const Color(0xFFB7E8DA) : const Color(0xFFF8D8B8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReady ? 'Ready for delivery' : 'More payment needed',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isReady
                ? 'This purchase can proceed to delivery payment for the chosen address.'
                : 'You need ${_formatMoney(amount)} before delivery can continue.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.66),
            ),
          ),
          if (currentAmountPaid != null || targetPercent != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (currentAmountPaid != null && targetAmountPaid != null)
                  'Paid ${_formatMoney(currentAmountPaid!)} of ${_formatMoney(targetAmountPaid!)}',
                if (targetPercent != null)
                  'Target ${((targetPercent ?? 0) * 100).round()}%',
                if (deliveryRequirement != null &&
                    deliveryRequirement == 'legacy_60_percent')
                  'Legacy delivery rule',
              ].join('  •  '),
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourierQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery fee',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMoney(courierDeliveryFee ?? 0),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (quotedAddress != null)
            Text(
              quotedAddress!,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.66),
              ),
            ),
          if (deliveryAreaOperational != null) ...[
            const SizedBox(height: 4),
            Text(
              deliveryAreaOperational == true
                  ? 'Coverage available for this address'
                  : 'Area currently not operational',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: deliveryAreaOperational == true
                    ? const Color(0xFF0E7C66)
                    : const Color(0xFFB54708),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.ink,
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'local':
        return 'Local';
      case 'regional':
        return 'Regional';
      case 'interstate':
        return 'Interstate';
      default:
        return category;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _dateController.dispose();
    _phoneNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
