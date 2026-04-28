import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Auth/kyc.dart';
import 'package:retilda/Views/Products/Connect/views/connect.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Widgets/webview.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/core/utils/delivery_coverage.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);

  final TextEditingController _deliveryQuoteAddressController =
      TextEditingController();
  Timer? _kycGuardTimer;
  bool _deliveryQuoteLoading = false;
  String? _deliveryQuoteError;
  num? _quotedDeliveryFee;
  num? _estimatedDeliveredTotal;
  String? _quotedDeliveryAddress;
  String? _quotedDeliveryState;
  bool? _deliveryAreaOperational;
  Map<String, dynamic>? _deliveryQuoteDetails;
  Map<String, num>? _quotedDeliveryCoordinates;

  void _clearDeliveryQuote() {
    if (_quotedDeliveryFee == null &&
        _estimatedDeliveredTotal == null &&
        _quotedDeliveryAddress == null &&
        _deliveryQuoteError == null &&
        _deliveryAreaOperational == null &&
        _quotedDeliveryState == null) {
      return;
    }

    setState(() {
      _deliveryQuoteError = null;
      _quotedDeliveryFee = null;
      _estimatedDeliveredTotal = null;
      _quotedDeliveryAddress = null;
      _quotedDeliveryState = null;
      _deliveryAreaOperational = null;
      _deliveryQuoteDetails = null;
      _quotedDeliveryCoordinates = null;
    });
  }

  Map<String, num>? _coordinatesFromDestination(Map<String, dynamic> data) {
    if (data['coordinateSource']?.toString() != 'request') return null;
    final coordinates = data['coordinates'];
    if (coordinates is! Map) return null;
    final lat = _readNum(coordinates['lat']);
    final lng = _readNum(coordinates['lng']);
    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  Map<String, dynamic> _deliveryQuotePayload(String address) {
    return {
      'address': address,
      if (_quotedDeliveryCoordinates != null)
        'coordinates': _quotedDeliveryCoordinates,
    };
  }

  Future<void> _quoteProductDeliveryBeforePurchase() async {
    final address = _deliveryQuoteAddressController.text.trim();
    if (address.isEmpty) {
      showAppAlert(
        context: context,
        title: 'Address required',
        message:
            'Enter a delivery address to estimate this product delivery fee.',
        tone: AppFeedbackTone.info,
        buttonText: 'Okay',
        icon: Icons.location_on_outlined,
      );
      return;
    }

    await _loadUserData();
    if (token == null) {
      showAppAlert(
        context: context,
        title: 'Sign in required',
        message:
            'Sign in before checking a delivery estimate for this product.',
        tone: AppFeedbackTone.warning,
        buttonText: 'Okay',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    setState(() {
      _deliveryQuoteLoading = true;
      _deliveryQuoteError = null;
    });

    try {
      final response = await _apiClient.post(
        'products/${widget.product.id}/delivery-quote',
        body: _deliveryQuotePayload(address),
      );

      final decoded = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded['data'])
            : const <String, dynamic>{};
        final destination = data['deliveryDestination'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['deliveryDestination'])
            : const <String, dynamic>{};
        final quote = data['deliveryQuote'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['deliveryQuote'])
            : const <String, dynamic>{};
        final checkoutEstimate =
            data['checkoutEstimate'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(data['checkoutEstimate'])
                : const <String, dynamic>{};

        setState(() {
          _quotedDeliveryFee = _readNum(
            quote['deliveryFee'] ?? checkoutEstimate['deliveryFee'],
          );
          _estimatedDeliveredTotal = _readNum(
            checkoutEstimate['totalPayableNow'],
          );
          _quotedDeliveryAddress =
              destination['formattedAddress']?.toString() ??
                  destination['address']?.toString() ??
                  address;
          _quotedDeliveryState = destination['state']?.toString();
          _deliveryAreaOperational = destination['isOperational'] == true;
          _deliveryQuoteDetails = quote;
          _quotedDeliveryCoordinates = _coordinatesFromDestination(destination);
        });
      } else {
        setState(() {
          _deliveryQuoteError = DeliveryCoverage.userMessage(
            decoded['message']?.toString() ??
                'Unable to calculate delivery fee.',
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryQuoteError =
            'We could not calculate the delivery fee for this product right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _deliveryQuoteLoading = false);
      }
    }
  }

  String? selectedPurchaseType;
  String? selectedRepaymentFrequency;
  int? selectedDurationMonths;
  String? selectedLegacyPaymentPlan;
  int? selectedLegacyInstallments;
  String? _lastPreviewSignature;
  String? _userPurchaseRule;
  static final DateTime _purchaseRuleCutoffUtc =
      DateTime.parse('2026-04-24T23:00:00.000Z');

  String? Insurance;
  bool loading = false;
  bool? Activated;
  bool _isKycVerified = false;
  bool termsAccepted = false;

  List<CartItem> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _kycGuardTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      if (wallet == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: CustomText('Please complete KYC on profile page'),
        ));
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
        if (navigator.canPop()) navigator.pop();
      } else {}
    });
    _loadCartItems();
  }

  @override
  void dispose() {
    _kycGuardTimer?.cancel();
    _deliveryQuoteAddressController.dispose();
    super.dispose();
  }

  Future<void> initializePayment(BuildContext context) async {
    await _loadUserData();
    if (token == null || productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                CustomText('Unable to start payment. Please sign in again.')),
      );
      return;
    }

    try {
      final response = await _apiClient.post(
        'buyproductonsales/onetimepaymentusingcard',
        body: {"productId": productId},
      );

      if (response.statusCode == 200) {
        // Parse the response
        final responseData = json.decode(response.body);

        if (responseData['success'] == true &&
            responseData['data'] != null &&
            responseData['data']['authorizationUrl'] != null) {
          final String paymentUrl = responseData['data']['authorizationUrl'];

          // Navigate to the WebViewScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(url: paymentUrl),
            ),
          );
        } else {
          // Handle API error response
          _showErrorDialog(context, responseData['message']);
        }
      } else {
        // Handle HTTP error
        _showErrorDialog(
            context, "Failed to initialize payment. Please try again.");
      }
    } catch (e) {
      // Handle exceptions
      _showErrorDialog(context, "An error occurred: $e");
    }
  }

  void addToCart() async {
    bool productExistsInCart =
        cartItems.any((item) => item.id == widget.product.id);

    if (productExistsInCart) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Product already exists in cart!'),
      ));
    } else {
      setState(() {
        cartItems.add(CartItem(
          id: widget.product.id,
          name: widget.product.name,
          price: widget.product.price,
          description: widget.product.description,
          images: widget.product.images,
          categories: widget.product.categories,
          specification: widget.product.specification,
          brand: widget.product.brand,
        ));
      });

      await _saveCartItems();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Added to cart!'),
      ));
    }
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson =
        cartItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('cartItems', cartItemsJson);
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('cartItems');
    if (!mounted) return;
    if (cartItemsJson != null) {
      setState(() {
        cartItems = cartItemsJson
            .map((item) => CartItem.fromJson(jsonDecode(item)))
            .toList();
      });
    }
  }

  void goToCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(),
      ),
    );
  }

  Future<void> getWalletBalance(String walletAccountNumber) async {
    Map<String, String> requestBody = {
      'walletAccountNumber': walletAccountNumber,
    };

    try {
      final response = await _apiClient.post(
        'balance',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = jsonDecode(response.body);

        setState(() {
          balance = responseBody['data']['responseBody']['availableBalance']
              .toString();
        });
      } else {}
    } catch (_) {}
  }

  String _resolveUserPurchaseRule(Map<String, dynamic>? user) {
    final explicitRule = user?['userPurchaseRule']?.toString();
    if (explicitRule == 'legacy' || explicitRule == 'new_update') {
      return explicitRule!;
    }

    final createdAtRaw = user?['createdAt']?.toString();
    final createdAt =
        createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
    if (createdAt != null) {
      return createdAt.toUtc().isBefore(_purchaseRuleCutoffUtc)
          ? 'legacy'
          : 'new_update';
    }

    return 'new_update';
  }

  int _legacyInstallmentCountFromDuration(int months, String paymentPlan) {
    switch (paymentPlan) {
      case 'weekly':
        return months * 4;
      case 'biweekly':
        return months * 2;
      case 'monthly':
      default:
        return months;
    }
  }

  int _legacyDurationMonthsFromInstallments(
    int installmentCount,
    String paymentPlan,
  ) {
    switch (paymentPlan) {
      case 'weekly':
        return (installmentCount / 4).round();
      case 'biweekly':
        return (installmentCount / 2).round();
      case 'monthly':
      default:
        return installmentCount;
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _session.userData();
    if (userData != null) {
      final data = userData['data'] as Map<String, dynamic>?;
      final user = data?['user'] as Map<String, dynamic>?;
      final userWallet = user?['wallet'] as Map<String, dynamic>?;

      final String? loadedToken = await _session.userToken();
      final String? loadedUserId = user?['_id'] as String?;
      final String? loadedWallet = userWallet?['accountNumber'] as String?;
      final bool? userDirectdebit = user?['isDirectDebit'] as bool?;
      final bool isKycUploaded = user?['isKycUploaded'] == true;
      final num? sessionBalance =
          _readNum(user?['balance'] ?? userWallet?['balance']);
      final resolvedRule = _resolveUserPurchaseRule(user);

      if (!mounted) return;
      setState(() {
        token = loadedToken;
        userId = loadedUserId;
        productId = widget.product.id;
        wallet = loadedWallet;
        Activated = userDirectdebit;
        _isKycVerified = isKycUploaded;
        balance = sessionBalance?.toString() ?? balance;
        _userPurchaseRule = resolvedRule;
      });

      if (loadedWallet != null && loadedWallet.isNotEmpty) {
        await getWalletBalance(loadedWallet);
      }
    }
  }

  String? productId;
  String? userId;
  String? token;
  String? userOptions;
  dynamic wallet;
  String? balance;

  bool get _isOutrightSelection => selectedPurchaseType == 'outright';

  bool get _isLegacyUser => _userPurchaseRule == 'legacy';

  bool get _canCreateLegacyInstallment => _isLegacyUser;

  bool get _isLegacyInstallmentSelection =>
      _canCreateLegacyInstallment &&
      selectedPurchaseType == 'legacy_installment';

  bool get _isInstallmentSelection =>
      selectedPurchaseType != null && !_isOutrightSelection;

  double? get _walletBalanceAmount => _readNum(balance)?.toDouble();

  num? get _requiredWalletCheckoutAmount =>
      _isInstallmentSelection ? _currentProductChargeEstimate() : null;

  bool get _walletCanCoverCurrentPurchase {
    final available = _walletBalanceAmount;
    final required = _requiredWalletCheckoutAmount;
    if (available == null || required == null) return false;
    return available >= required;
  }

  bool get _isPlanFullySelected {
    if (_isOutrightSelection) {
      return true;
    }
    if (_isLegacyInstallmentSelection) {
      return selectedLegacyPaymentPlan != null &&
          selectedLegacyInstallments != null;
    }
    return selectedPurchaseType != null &&
        selectedDurationMonths != null &&
        selectedRepaymentFrequency != null;
  }

  Future<void> _handleWalletCheckout() async {
    if (_isOutrightSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText('Use One Time Pay for outright purchases'),
        ),
      );
      return;
    }

    if (!_isKycVerified) {
      _showKycRequiredDialog();
      return;
    }

    await _loadUserData();
    if (!mounted) return;

    if (Activated != true && !_walletCanCoverCurrentPurchase) {
      _showConnectDialog(context);
      return;
    }

    await purchaseProduct();
  }

  Future<void> _showPaymentActionSheet({
    required String title,
    required String summary,
    required String detail,
    required String continueLabel,
    required VoidCallback onContinue,
    required IconData icon,
    Color accentColor = const Color(0xFF103C57),
  }) async {
    await showAppNoticeSheet<void>(
      context: context,
      title: title,
      message: '$summary\n\n$detail',
      tone: accentColor == const Color(0xFFFB9324)
          ? AppFeedbackTone.warning
          : AppFeedbackTone.info,
      primaryLabel: continueLabel,
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        onContinue();
      },
      icon: icon,
      isDismissible: true,
    );
  }

  bool _isKycRequiredResponse(int statusCode, String? message) {
    if (statusCode != 400 || message == null) {
      return false;
    }
    final normalized = message.toLowerCase();
    return normalized.contains('bvn') ||
        normalized.contains('kyc') ||
        normalized.contains('verification');
  }

  void _showKycRequiredDialog([String? message]) {
    showAppAlert(
      context: context,
      title: 'BVN verification required',
      message:
          message ?? 'Complete BVN verification before you buy on installment.',
      tone: AppFeedbackTone.warning,
      buttonText: 'Verify BVN',
      icon: Icons.verified_user_outlined,
      onButtonPressed: () {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KYC(),
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showAppAlert(
      context: context,
      title: 'Error',
      message: message,
      tone: AppFeedbackTone.error,
      buttonText: 'Okay',
      icon: Icons.error_outline_rounded,
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    VoidCallback? onContinue,
  }) {
    showAppAlert(
      context: context,
      title: title,
      message: message,
      tone: AppFeedbackTone.success,
      buttonText: 'Continue',
      icon: Icons.check_circle_outline_rounded,
      onButtonPressed: () {
        Navigator.of(context).pop();
        onContinue?.call();
      },
    );
  }

  num? _readNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.replaceAll(',', '').trim());
    return null;
  }

  String _formatMoney(num amount) {
    return '₦${NumberFormat('#,##0.00').format(amount)}';
  }

  num? _currentProductChargeEstimate() {
    final price = widget.product.price.toDouble();
    if (_isLegacyInstallmentSelection) {
      final installments = selectedLegacyInstallments;
      if (installments == null || installments <= 0) return null;
      return price / installments;
    }
    switch (selectedPurchaseType) {
      case 'outright':
        return price;
      case 'down_50':
        return price * 0.5;
      case 'down_40':
        return price * 0.4;
      default:
        return null;
    }
  }

  String _currentProductChargeLabel() {
    if (_isLegacyInstallmentSelection) {
      return 'First installment now';
    }
    switch (selectedPurchaseType) {
      case 'outright':
        return 'Product payment now';
      case 'down_50':
        return 'Down payment now';
      case 'down_40':
        return 'Down payment now';
      default:
        return 'Choose a plan first';
    }
  }

  Widget _buildDeliveryEstimateSection({
    required Color deepBlue,
    required Color accent,
  }) {
    final currentProductCharge = _currentProductChargeEstimate();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: deepBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step 2",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Estimate delivery before purchase",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        color: deepBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Check the delivery fee for this exact product and address before you pay for it.",
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Delivery address",
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: deepBlue,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _deliveryQuoteAddressController,
            minLines: 2,
            maxLines: 3,
            onChanged: (_) => _clearDeliveryQuote(),
            style: GoogleFonts.manrope(
              fontSize: 15.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF263238),
            ),
            decoration: InputDecoration(
              hintText: "e.g. Ikeja, Lagos, Nigeria",
              hintStyle: GoogleFonts.manrope(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: deepBlue,
                size: 24,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 52,
                minHeight: 64,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.fromLTRB(4, 18, 16, 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE5EAF0),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: deepBlue, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deliveryQuoteLoading
                  ? null
                  : _quoteProductDeliveryBeforePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: _deliveryQuoteLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(
                _deliveryQuoteLoading
                    ? 'Checking delivery estimate...'
                    : 'Estimate delivery',
                style: GoogleFonts.manrope(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF6D2B0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFFB26A00),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Delivery is paid later after purchase. This estimate shows the expected courier fee for the address you enter.\n\n${DeliveryCoverage.supportedStatesMessage}",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A4A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_deliveryQuoteError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD1D1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _deliveryQuoteError!,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7A1F1F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_quotedDeliveryFee != null &&
              _estimatedDeliveredTotal != null) ...[
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
                  _planRow('Product price', _formatMoney(widget.product.price)),
                  if (currentProductCharge != null)
                    _planRow(
                      _currentProductChargeLabel(),
                      _formatMoney(currentProductCharge),
                    ),
                  _planRow('Estimated delivery fee',
                      _formatMoney(_quotedDeliveryFee!)),
                  _planRow(
                    'Estimated product + delivery total',
                    _formatMoney(_estimatedDeliveredTotal!),
                  ),
                  if (_quotedDeliveryAddress != null)
                    _planRow('Destination', _quotedDeliveryAddress!),
                  if (_quotedDeliveryState != null)
                    _planRow('Operational state', _quotedDeliveryState!),
                  ..._deliveryQuoteBreakdownRows(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _deliveryAreaOperational == true
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: _deliveryAreaOperational == true
                      ? const Color(0xFF0E7C66)
                      : const Color(0xFFB54708),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    _deliveryAreaOperational == true
                        ? "This location is currently operational for delivery."
                        : "This location may not be operational for delivery yet.",
                    fontSize: 10.8.sp,
                    color: _deliveryAreaOperational == true
                        ? const Color(0xFF0E7C66)
                        : const Color(0xFFB54708),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _deliveryQuoteBreakdownRows() {
    final quote = _deliveryQuoteDetails;
    if (quote == null || quote.isEmpty) return const <Widget>[];

    final zoneLabel = quote['deliveryZoneLabel']?.toString() ??
        quote['deliveryZone']?.toString();
    final roadDistance = _readNum(quote['estimatedRoadDistanceKm']);
    final weightKg = _readNum(quote['weightKg']);
    final baseFee = _readNum(quote['baseFee']);
    final costPerKm = _readNum(quote['costPerKm']);
    final distanceFee = _readNum(quote['distanceFee']);
    final weightSurcharge = _readNum(quote['weightSurcharge']);

    return [
      if (zoneLabel != null) _planRow('Delivery zone', zoneLabel),
      if (roadDistance != null)
        _planRow('Road distance', '${roadDistance.toStringAsFixed(1)} km'),
      if (weightKg != null)
        _planRow(
          'Product weight',
          '${weightKg.toStringAsFixed(weightKg % 1 == 0 ? 0 : 1)} kg',
        ),
      if (baseFee != null) _planRow('Base fee', _formatMoney(baseFee)),
      if (costPerKm != null) _planRow('Cost per km', _formatMoney(costPerKm)),
      if (distanceFee != null)
        _planRow('Distance fee', _formatMoney(distanceFee)),
      if (weightSurcharge != null)
        _planRow('Weight surcharge', _formatMoney(weightSurcharge)),
    ];
  }

  double _downPaymentPercent(String purchaseType) {
    switch (purchaseType) {
      case 'down_50':
        return 0.50;
      case 'down_40':
        return 0.40;
      case 'outright':
      default:
        return 1.0;
    }
  }

  TextStyle _purchaseDropdownTextStyle(Color deepBlue) {
    return GoogleFonts.manrope(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: deepBlue,
    );
  }

  InputDecoration _purchaseDropdownDecoration({
    required String hint,
    required IconData icon,
    required Color deepBlue,
    bool enabled = true,
  }) {
    final borderRadius = BorderRadius.circular(18);
    final inactiveBorder = BorderSide(
      color: enabled ? const Color(0xFFE5EAF0) : const Color(0xFFE8EAEE),
      width: 1.2,
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: enabled ? deepBlue : const Color(0xFF9CA3AF),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 54,
      ),
      filled: true,
      fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.fromLTRB(4, 18, 14, 18),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: inactiveBorder,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: inactiveBorder,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: deepBlue, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: inactiveBorder,
      ),
    );
  }

  double _repaymentFeePercent(String purchaseType, int months) {
    if (purchaseType == 'down_50') {
      return switch (months) {
        2 => 0.05,
        4 => 0.10,
        6 => 0.20,
        _ => 0,
      };
    }

    if (purchaseType == 'down_40') {
      return switch (months) {
        2 => 0.10,
        4 => 0.20,
        6 => 0.30,
        _ => 0,
      };
    }

    return 0;
  }

  int _installmentCount(int months, String frequency) {
    switch (frequency) {
      case 'weekly':
        return months * 4;
      case 'biweekly':
        return months * 2;
      case 'monthly':
      default:
        return months;
    }
  }

  void _onPlanSelectionUpdated() {
    final purchaseType = selectedPurchaseType;
    final readyForPreview = purchaseType == 'outright' ||
        (_isLegacyInstallmentSelection &&
            selectedLegacyPaymentPlan != null &&
            selectedLegacyInstallments != null) ||
        (purchaseType != null &&
            !_isLegacyInstallmentSelection &&
            selectedDurationMonths != null &&
            selectedRepaymentFrequency != null);

    if (!readyForPreview) return;

    final signature =
        '${selectedPurchaseType ?? ''}|${selectedDurationMonths ?? ''}|${selectedRepaymentFrequency ?? ''}|${selectedLegacyPaymentPlan ?? ''}|${selectedLegacyInstallments ?? ''}';
    if (signature == _lastPreviewSignature) return;
    _lastPreviewSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPaymentPlanBreakdownSheet();
    });
  }

  void _showPaymentPlanBreakdownSheet() {
    final purchaseType = selectedPurchaseType;
    if (purchaseType == null) return;

    final totalPrice = widget.product.price.toDouble();
    final isOutright = purchaseType == 'outright';
    final isLegacyInstallment = _isLegacyInstallmentSelection;
    final frequency = isLegacyInstallment
        ? selectedLegacyPaymentPlan
        : selectedRepaymentFrequency;
    final months = isLegacyInstallment
        ? (selectedLegacyInstallments != null &&
                selectedLegacyPaymentPlan != null
            ? _legacyDurationMonthsFromInstallments(
                selectedLegacyInstallments!,
                selectedLegacyPaymentPlan!,
              )
            : null)
        : selectedDurationMonths;
    final count = isOutright
        ? 0
        : isLegacyInstallment
            ? (selectedLegacyInstallments ?? 0)
            : _installmentCount(months!, frequency!);
    final eachInstallment = count > 0 ? (totalPrice / count) : 0.0;
    final downPercent =
        isLegacyInstallment ? 0.0 : _downPaymentPercent(purchaseType);
    final downPayment =
        isLegacyInstallment ? eachInstallment : totalPrice * downPercent;
    final remainingBalance = (totalPrice - downPayment).clamp(0, totalPrice);
    final repaymentFeePercent = isOutright || isLegacyInstallment
        ? 0.0
        : _repaymentFeePercent(purchaseType, months!);
    final repaymentFee = remainingBalance * repaymentFeePercent;
    final totalRepaymentAmount = isLegacyInstallment
        ? totalPrice - downPayment
        : remainingBalance + repaymentFee;
    final totalAmountToPay =
        isOutright ? totalPrice : downPayment + totalRepaymentAmount;
    final purchaseTypeLabel = switch (purchaseType) {
      'outright' => 'Outright payment',
      'legacy_installment' => 'LGC installment',
      'down_50' || 'down_40' => '${_formatMoney(downPayment)} now',
      _ => purchaseType.replaceAll('_', ' '),
    };
    final frequencyLabel = switch (frequency) {
      'weekly' => 'Weekly',
      'biweekly' => 'Every 2 weeks',
      'monthly' => 'Monthly',
      _ => frequency ?? 'Not selected',
    };
    final planExplanation = isOutright
        ? 'You are paying the full product price once. There will be no follow-up installment payments for this order.'
        : isLegacyInstallment
            ? 'You are on the LGC installment flow. You will pay ${_formatMoney(downPayment)} now, then complete the remaining ${_formatMoney(totalPrice - downPayment)} across $count $frequencyLabel payments.'
            : 'You will pay ${_formatMoney(downPayment)} today, then complete ${_formatMoney(totalRepaymentAmount)} with $count $frequencyLabel payments of ${_formatMoney(eachInstallment)}.';
    final nextStepText = isOutright
        ? 'After this, you can continue to payment and complete checkout immediately.'
        : isLegacyInstallment
            ? 'This uses the LGC purchase flow, so the app will send paymentPlan and numberOfInstallments instead of the new purchaseType fields.'
            : 'After this, choose your preferred payment method to continue with this installment plan.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 58,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF103C57),
                              Color(0xFF1C6A98),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Payment plan summary',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: Colors.white,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.name,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              planExplanation,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F8FA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOutright
                                        ? 'Pay now'
                                        : isLegacyInstallment
                                            ? 'First installment now'
                                            : 'Down payment now',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatMoney(
                                        isOutright ? totalPrice : downPayment),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF103C57),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isOutright) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isLegacyInstallment
                                          ? 'Remaining installments'
                                          : 'Next payments',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatMoney(eachInstallment),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF103C57),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      frequencyLabel,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFB9324),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  children: [
                                    _planRow('Product price',
                                        _formatMoney(totalPrice)),
                                    _planRow(
                                        'Plan selected', purchaseTypeLabel),
                                    _planRow(
                                      isOutright
                                          ? 'Amount to pay'
                                          : isLegacyInstallment
                                              ? 'First installment now'
                                              : 'Down payment now',
                                      _formatMoney(isOutright
                                          ? totalPrice
                                          : downPayment),
                                    ),
                                    if (!isOutright) ...[
                                      _planRow(
                                        isLegacyInstallment
                                            ? 'Remaining installments'
                                            : 'Remaining before fee',
                                        _formatMoney(remainingBalance),
                                      ),
                                      if (!isLegacyInstallment)
                                        _planRow(
                                          'Installment fee',
                                          _formatMoney(repaymentFee),
                                        ),
                                      _planRow(
                                        isLegacyInstallment
                                            ? 'Remaining total'
                                            : 'Repayment total',
                                        _formatMoney(totalRepaymentAmount),
                                      ),
                                      _planRow('Repayment frequency',
                                          frequencyLabel),
                                      _planRow('Repayment duration',
                                          '$months months'),
                                      _planRow('Number of payments', '$count'),
                                      _planRow('Amount per payment',
                                          _formatMoney(eachInstallment)),
                                    ],
                                    _planRow('Total to pay',
                                        _formatMoney(totalAmountToPay)),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'What this means',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF103C57),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      nextStepText,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        height: 1.55,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black
                                            .withValues(alpha: 0.74),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF103C57),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
        );
      },
    );
  }

  Widget _planRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF103C57),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> makeBuyProductRequest(
    String productId,
  ) async {
    try {
      final Map<String, dynamic> requestBody = {
        "productId": productId,
        if (_isLegacyInstallmentSelection) ...{
          "paymentPlan": selectedLegacyPaymentPlan,
          "numberOfInstallments": selectedLegacyInstallments,
        } else ...{
          "purchaseType": selectedPurchaseType,
          "durationMonths": selectedDurationMonths,
          "repaymentFrequency": selectedRepaymentFrequency,
        },
      };

      final response = await _apiClient.post(
        'buyProductOnInstallment',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        _showSuccessDialog(
          title: 'Success',
          message: 'Purchase successful!',
          onContinue: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String errorMessage =
            responseData['message'] ?? 'Purchase could not be completed.';
        if (_isKycRequiredResponse(response.statusCode, errorMessage)) {
          _showKycRequiredDialog(errorMessage);
          return;
        }
        showAppAlert(
          context: context,
          title: 'Unable to continue',
          message: errorMessage,
          tone: AppFeedbackTone.error,
          buttonText: 'Okay',
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (_) {}
  }

  Future<void> purchaseProduct() async {
    if (!mounted) return;
    setState(() {
      loading = true;
    });

    await _loadUserData();
    if (selectedPurchaseType == "outright") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Use One Time Pay for outright purchases'),
      ));
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }

    if (token != null && productId != null && _isPlanFullySelected) {
      await makeBuyProductRequest(productId!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Please complete purchase requirements'),
      ));
    }

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  Future<void> initializeInstallmentCardPayment(BuildContext context) async {
    await _loadUserData();
    if (selectedPurchaseType == "outright") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Use One Time Pay for outright purchases'),
      ));
      return;
    }

    if (!_isKycVerified) {
      _showKycRequiredDialog();
      return;
    }

    if (token == null || productId == null || !_isPlanFullySelected) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Please complete purchase requirements'),
      ));
      return;
    }

    try {
      final response = await _apiClient.post(
        'buyProductOnInstallmentUsingCard',
        body: {
          "productId": productId,
          if (_isLegacyInstallmentSelection) ...{
            "paymentPlan": selectedLegacyPaymentPlan,
            "numberOfInstallments": selectedLegacyInstallments,
          } else ...{
            "purchaseType": selectedPurchaseType,
            "durationMonths": selectedDurationMonths,
            "repaymentFrequency": selectedRepaymentFrequency,
          },
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true &&
            responseData['data'] != null &&
            responseData['data']['paymentUrl'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WebViewScreen(url: responseData['data']['paymentUrl']),
            ),
          );
        } else {
          _showErrorDialog(
              context, responseData['message'] ?? 'Payment link not available');
        }
      } else {
        Map<String, dynamic>? responseData;
        String errorMessage = "Failed to initialize payment. Please try again.";
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = responseData['message']?.toString() ?? errorMessage;
        } catch (_) {}
        if (_isKycRequiredResponse(response.statusCode, errorMessage)) {
          _showKycRequiredDialog(errorMessage);
          return;
        }
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      _showErrorDialog(context, "An error occurred: $e");
    }
  }

  Widget _buildActionIcon(
      {required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF103C57)),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color backgroundColor,
    required String actionLabel,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required IconData icon,
  }) {
    final Color textColor = isPrimary ? Colors.white : const Color(0xFF103C57);
    final Color secondaryColor =
        isPrimary ? Colors.white.withValues(alpha: 0.84) : Colors.grey.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary
            ? null
            : Border.all(
                color: Colors.black.withValues(alpha: 0.05),
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
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
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFF103C57).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFF103C57),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPrimary ? Colors.white : badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                backgroundColor:
                    isPrimary ? Colors.white : const Color(0xFF103C57),
                disabledBackgroundColor: isPrimary
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade300,
                foregroundColor:
                    isPrimary ? const Color(0xFF103C57) : Colors.white,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);
    final String categoryLabel = widget.product.categories.isNotEmpty
        ? widget.product.categories.first
        : 'Marketplace';

    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          elevation: 0,
          title: CustomText(
            "Details",
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: deepBlue,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 28.h,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: PageView(
                            children: widget.product.images.map((image) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(image, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.35),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.storefront_outlined,
                                              size: 16, color: Colors.black87),
                                          const SizedBox(width: 6),
                                          Text(
                                            categoryLabel,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    widget.product.name,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.sp,
                                    color: deepBlue,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.verified,
                                          size: 16, color: accent),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        "Buyer protection active",
                                        fontSize: 11.sp,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildActionIcon(
                                  icon: Icons.add_shopping_cart_outlined,
                                  onTap: addToCart,
                                ),
                                _buildActionIcon(
                                  icon: Icons.favorite_border,
                                  onTap: () {},
                                ),
                                _buildActionIcon(
                                  icon: Icons.share_outlined,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  "₦${NumberFormat('#,##0').format(widget.product.price)}",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17.sp,
                                  color: deepBlue,
                                ),
                                const SizedBox(height: 4),
                                CustomText(
                                  "Fast delivery & wallet checkout",
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.flash_on_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    "Limited stock",
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4FB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.payments_rounded,
                              color: deepBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Step 1",
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Choose how you want to buy",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    height: 1.05,
                                    fontWeight: FontWeight.w700,
                                    color: deepBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isLegacyUser
                            ? "Pick a plan first. Older accounts can use down-payment plans, and may still use the LGC installment option."
                            : "Pick a plan first. Retilda will then show the payment routes that match it.",
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      if ((_userPurchaseRule ?? '').isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _isLegacyUser
                                ? const Color(0xFFFFF4E8)
                                : const Color(0xFFEAF4FB),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _isLegacyUser
                                    ? Icons.history_rounded
                                    : Icons.verified_rounded,
                                size: 18,
                                color: _isLegacyUser
                                    ? const Color(0xFFB26A00)
                                    : deepBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isLegacyUser
                                      ? 'Older account: you can use down-payment plans or LGC installment.'
                                      : 'Installment checkout uses the Down 40% or Down 50% plans.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w800,
                                    color: _isLegacyUser
                                        ? const Color(0xFFB26A00)
                                        : deepBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: selectedPurchaseType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Colors.white,
                        style: _purchaseDropdownTextStyle(deepBlue),
                        decoration: _purchaseDropdownDecoration(
                          hint: "Purchase type",
                          icon: Icons.shopping_bag_outlined,
                          deepBlue: deepBlue,
                        ),
                        items: _canCreateLegacyInstallment
                            ? const [
                                DropdownMenuItem(
                                  value: "outright",
                                  child: Text("Outright (100% upfront)"),
                                ),
                                DropdownMenuItem(
                                  value: "down_50",
                                  child: Text("Down 50% upfront"),
                                ),
                                DropdownMenuItem(
                                  value: "down_40",
                                  child: Text("Down 40% upfront"),
                                ),
                                DropdownMenuItem(
                                  value: "legacy_installment",
                                  child: Text("LGC installment plan"),
                                ),
                              ]
                            : const [
                                DropdownMenuItem(
                                  value: "outright",
                                  child: Text("Outright (100% upfront)"),
                                ),
                                DropdownMenuItem(
                                  value: "down_50",
                                  child: Text("Down 50% upfront"),
                                ),
                                DropdownMenuItem(
                                  value: "down_40",
                                  child: Text("Down 40% upfront"),
                                ),
                              ],
                        onChanged: (value) {
                          setState(() {
                            selectedPurchaseType = value;
                            if (value == "outright") {
                              selectedDurationMonths = null;
                              selectedRepaymentFrequency = null;
                              selectedLegacyPaymentPlan = null;
                              selectedLegacyInstallments = null;
                            } else if (value == "legacy_installment") {
                              selectedDurationMonths = null;
                              selectedRepaymentFrequency = null;
                            } else {
                              selectedLegacyPaymentPlan = null;
                              selectedLegacyInstallments = null;
                            }
                          });
                          _onPlanSelectionUpdated();
                        },
                      ),
                      if (_isLegacyInstallmentSelection) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedLegacyPaymentPlan,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          dropdownColor: Colors.white,
                          style: _purchaseDropdownTextStyle(deepBlue),
                          decoration: _purchaseDropdownDecoration(
                            hint: "LGC payment plan",
                            icon: Icons.calendar_month_outlined,
                            deepBlue: deepBlue,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "weekly",
                              child: Text("Weekly"),
                            ),
                            DropdownMenuItem(
                              value: "biweekly",
                              child: Text("Biweekly"),
                            ),
                            DropdownMenuItem(
                              value: "monthly",
                              child: Text("Monthly"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedLegacyPaymentPlan = value;
                              selectedLegacyInstallments = null;
                            });
                            _onPlanSelectionUpdated();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedLegacyInstallments,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          dropdownColor: Colors.white,
                          style: _purchaseDropdownTextStyle(deepBlue),
                          decoration: _purchaseDropdownDecoration(
                            hint: "Number of installments",
                            icon: Icons.format_list_numbered_rounded,
                            deepBlue: deepBlue,
                            enabled: selectedLegacyPaymentPlan != null,
                          ),
                          items: (selectedLegacyPaymentPlan == null
                                  ? const <int>[]
                                  : <int>[
                                      _legacyInstallmentCountFromDuration(
                                        2,
                                        selectedLegacyPaymentPlan!,
                                      ),
                                      _legacyInstallmentCountFromDuration(
                                        4,
                                        selectedLegacyPaymentPlan!,
                                      ),
                                      _legacyInstallmentCountFromDuration(
                                        6,
                                        selectedLegacyPaymentPlan!,
                                      ),
                                    ])
                              .toSet()
                              .map(
                                (count) => DropdownMenuItem(
                                  value: count,
                                  child: Text(
                                    '$count installments (${_legacyDurationMonthsFromInstallments(count, selectedLegacyPaymentPlan!)} months)',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: selectedLegacyPaymentPlan == null
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedLegacyInstallments = value;
                                  });
                                  _onPlanSelectionUpdated();
                                },
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedDurationMonths,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          dropdownColor: Colors.white,
                          style: _purchaseDropdownTextStyle(deepBlue),
                          decoration: _purchaseDropdownDecoration(
                            hint: "Duration (months)",
                            icon: Icons.schedule_rounded,
                            deepBlue: deepBlue,
                            enabled: selectedPurchaseType != null &&
                                selectedPurchaseType != "outright",
                          ),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text("2 months")),
                            DropdownMenuItem(value: 4, child: Text("4 months")),
                            DropdownMenuItem(value: 6, child: Text("6 months")),
                          ],
                          onChanged: selectedPurchaseType == null ||
                                  selectedPurchaseType == "outright"
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedDurationMonths = value;
                                  });
                                  _onPlanSelectionUpdated();
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedRepaymentFrequency,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          dropdownColor: Colors.white,
                          style: _purchaseDropdownTextStyle(deepBlue),
                          decoration: _purchaseDropdownDecoration(
                            hint: "Repayment frequency",
                            icon: Icons.repeat_rounded,
                            deepBlue: deepBlue,
                            enabled: selectedPurchaseType != null &&
                                selectedPurchaseType != "outright",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "weekly",
                              child: Text("Weekly"),
                            ),
                            DropdownMenuItem(
                              value: "biweekly",
                              child: Text("Biweekly"),
                            ),
                            DropdownMenuItem(
                              value: "monthly",
                              child: Text("Monthly"),
                            ),
                          ],
                          onChanged: selectedPurchaseType == null ||
                                  selectedPurchaseType == "outright"
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedRepaymentFrequency = value;
                                  });
                                  _onPlanSelectionUpdated();
                                },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildDeliveryEstimateSection(
                  deepBlue: deepBlue,
                  accent: accent,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Step 3: Select a payment method",
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        "Choose one option. A short explanation will appear before you continue.",
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                      ),
                      if (_isInstallmentSelection && !_isKycVerified) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF6C26B),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFFB26A00),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomText(
                                  "Installment checkout is locked until BVN verification is complete.",
                                  fontSize: 10.5.sp,
                                  color: const Color(0xFF7A4A00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _buildPaymentMethodCard(
                        title: "Installment card payment",
                        subtitle: "Use card for installment checkout.",
                        badge: _isKycVerified
                            ? 'Card alternative'
                            : 'KYC required',
                        badgeColor:
                            _isKycVerified ? accent : const Color(0xFFB26A00),
                        backgroundColor: const Color(0xFFFFFAF4),
                        actionLabel:
                            _isInstallmentSelection && _isPlanFullySelected
                                ? (_isKycVerified ? 'Select' : 'Verify BVN')
                                : 'Choose purchase plan',
                        onPressed: _isInstallmentSelection &&
                                _isPlanFullySelected
                            ? () {
                                _showPaymentActionSheet(
                                  title: 'Installment card payment',
                                  summary: _isKycVerified
                                      ? _isLegacyInstallmentSelection
                                          ? 'This starts LGC installment checkout with your card using your selected payment plan and installment count.'
                                          : 'This starts installment checkout with your card. Down_40 and down_50 card checkout does not require direct debit.'
                                      : 'BVN verification must be completed before installment card checkout can start.',
                                  detail: _isKycVerified
                                      ? _isLegacyInstallmentSelection
                                          ? 'Choose this if you want to pay the first LGC installment by card. The app will send paymentPlan and numberOfInstallments for this checkout.'
                                          : 'Choose this if you want to pay the required down payment by card and continue without connecting a bank account for direct debit.'
                                      : 'The backend blocks installment checkout until KYC is complete. Verify BVN first, then return here to continue.',
                                  continueLabel: _isKycVerified
                                      ? 'Continue to card payment'
                                      : 'Verify BVN',
                                  onContinue: _isKycVerified
                                      ? () => initializeInstallmentCardPayment(
                                            context,
                                          )
                                      : _showKycRequiredDialog,
                                  icon: Icons.payments_outlined,
                                  accentColor: accent,
                                );
                              }
                            : null,
                        isPrimary: false,
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodCard(
                        title: "One-time card payment",
                        subtitle: "Pay once with your card.",
                        badge: 'No direct debit',
                        badgeColor: const Color(0xFF0E7C66),
                        backgroundColor: deepBlue,
                        actionLabel: 'Select',
                        onPressed: () {
                          _showPaymentActionSheet(
                            title: 'One-time card payment',
                            summary:
                                'This pays the full amount now with your card and does not use direct debit.',
                            detail:
                                'Choose this if you want the fastest single-payment checkout. Retilda will open the secure card payment page next.',
                            continueLabel: 'Continue to card payment',
                            onContinue: () => initializePayment(context),
                            icon: Icons.credit_card_rounded,
                          );
                        },
                        isPrimary: true,
                        icon: Icons.credit_card_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodCard(
                        title: "Wallet installment checkout",
                        subtitle:
                            "Use wallet balance first. Direct debit is only needed when wallet funds cannot cover the required upfront amount.",
                        badge: !_isKycVerified
                            ? 'KYC required'
                            : _walletCanCoverCurrentPurchase
                                ? 'Wallet funded'
                                : Activated == true
                                    ? 'Connected'
                                    : 'Needs setup',
                        badgeColor: !_isKycVerified
                            ? const Color(0xFFB26A00)
                            : _walletCanCoverCurrentPurchase
                                ? const Color(0xFF0E7C66)
                                : Activated == true
                                    ? const Color(0xFF0E7C66)
                                    : accent,
                        backgroundColor: const Color(0xFFF7F9FC),
                        actionLabel:
                            _isInstallmentSelection && _isPlanFullySelected
                                ? (_isKycVerified ? 'Select' : 'Verify BVN')
                                : 'Choose purchase plan',
                        onPressed: _isInstallmentSelection &&
                                _isPlanFullySelected
                            ? () {
                                _showPaymentActionSheet(
                                  title: 'Wallet installment checkout',
                                  summary: !_isKycVerified
                                      ? 'BVN verification must be completed before wallet installment checkout can start.'
                                      : _walletCanCoverCurrentPurchase
                                          ? _isLegacyInstallmentSelection
                                              ? 'Your wallet balance can cover the first installment required for this LGC plan.'
                                              : 'Your wallet balance can cover the required upfront payment for this plan.'
                                          : Activated == true
                                              ? 'This continues your wallet installment flow.'
                                              : 'This option needs bank connection before checkout can continue.',
                                  detail: !_isKycVerified
                                      ? 'The backend blocks installment checkout until KYC is complete. Verify BVN first, then return here to continue.'
                                      : _walletCanCoverCurrentPurchase
                                          ? 'Available wallet balance: ${_formatMoney(_walletBalanceAmount ?? 0)}. Required now: ${_formatMoney(_requiredWalletCheckoutAmount ?? 0)}. You can continue without setting up direct debit.'
                                          : Activated == true
                                              ? _isLegacyInstallmentSelection
                                                  ? 'Your account is already connected. Continue to proceed with the LGC installment checkout for this product.'
                                                  : 'Your account is already connected. Continue to proceed with wallet installment checkout for this product.'
                                              : 'Available wallet balance: ${_formatMoney(_walletBalanceAmount ?? 0)}. Required now: ${_formatMoney(_requiredWalletCheckoutAmount ?? 0)}. Wallet installment checkout may use direct debit for scheduled repayments when wallet funds are not enough, so you will connect your account before continuing.',
                                  continueLabel: !_isKycVerified
                                      ? 'Verify BVN'
                                      : _walletCanCoverCurrentPurchase
                                          ? 'Pay with wallet'
                                          : Activated == true
                                              ? 'Continue'
                                              : 'Connect account',
                                  onContinue: !_isKycVerified
                                      ? _showKycRequiredDialog
                                      : () {
                                          _handleWalletCheckout();
                                        },
                                  icon: Icons.account_balance_wallet_outlined,
                                );
                              }
                            : null,
                        isPrimary: false,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Product Description",
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 8),
                      _buildExpandableText(
                        widget.product.description.toString(),
                        expanded: _showFullDescription,
                        onToggle: () => setState(
                            () => _showFullDescription = !_showFullDescription),
                      ),
                      const SizedBox(height: 14),
                      CustomText(
                        "Product Specifications",
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 8),
                      _buildExpandableText(
                        widget.product.specification,
                        expanded: _showFullSpecs,
                        onToggle: () =>
                            setState(() => _showFullSpecs = !_showFullSpecs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showConnectDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool termsAccepted = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: 5,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF103C57).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Color(0xFF103C57),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Connect account',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'To continue with wallet installment checkout, connect your bank account and approve the terms below.',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: CheckboxListTile(
                            value: termsAccepted,
                            onChanged: (value) {
                              setState(() {
                                termsAccepted = value ?? false;
                              });
                            },
                            title: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'I agree to the ',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Terms and Policy',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF103C57),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: termsAccepted
                                    ? () {
                                        Navigator.pop(sheetContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ConnectAccount(),
                                          ),
                                        );
                                      }
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF103C57),
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  'Connect',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
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
          },
        );
      },
    );
  }

  bool _showFullDescription = false;
  bool _showFullSpecs = false;

  Widget _buildExpandableText(String text,
      {required bool expanded, required VoidCallback onToggle}) {
    final bool shouldTrim = text.length > 160;
    final String displayText =
        expanded || !shouldTrim ? text : text.substring(0, 160) + '...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          displayText,
          fontSize: 14.sp,
          color: Colors.grey[800],
        ),
        if (shouldTrim)
          TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: CustomText(
              expanded ? "Show less" : "Read more",
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF103C57),
            ),
          ),
      ],
    );
  }
}
