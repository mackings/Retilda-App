import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Auth/kyc.dart';
import 'package:retilda/Views/Products/Connect/views/connect.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Products/terms.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/paymentoption.dart';
import 'package:retilda/Views/Widgets/webview.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
//DeliveryModal
  late final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  Timer? _kycGuardTimer;
  DateTime? _selectedDate;
  String? _selectedCategory;

  bool _isLoading = false;

  // API Call Function
  Future<void> _calculateDeliveryFee(BuildContext context) async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a delivery address first.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.post(
        'geo/delivery-quote',
        body: {
          "address": address,
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final deliveryFee = responseData['data']?['quote']?['deliveryFee'];
          final formattedAddress =
              responseData['data']?['formattedAddress'] ?? address;
          if (deliveryFee == null) {
            throw Exception('Courier delivery fee not available');
          }
          final formattedFee = deliveryFee.toString().replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (match) => ',',
              );

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Courier fee for $formattedAddress: ₦$formattedFee"),
            ),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception("Delivery fee request failed");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to calculate delivery fee.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Modal to collect delivery details
  void _showDeliveryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        "Courier Delivery Quote",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: "Delivery Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time
                      TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(
                          labelText: "Delivery Time",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.access_time_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      GestureDetector(
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate == null
                                    ? "Select Delivery Date"
                                    : "${_selectedDate!.toLocal()}"
                                        .split(' ')[0],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items:
                            ["local", "regional", "interstate"].map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category[0].toUpperCase() +
                                category.substring(1)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setModalState(() => _isLoading = true);
                                  await _calculateDeliveryFee(context);
                                  setModalState(() => _isLoading = false);
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.orangeAccent,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Calculate Courier Fee",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? selectedPurchaseType;
  String? selectedRepaymentFrequency;
  int? selectedDurationMonths;
  String? _lastPreviewSignature;

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
    _addressController.dispose();
    _phoneController.dispose();
    _timeController.dispose();
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
      'walletAccountNumber': wallet,
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

      if (!mounted) return;
      setState(() {
        token = loadedToken;
        userId = loadedUserId;
        productId = widget.product.id;
        wallet = loadedWallet;
        Activated = userDirectdebit;
        _isKycVerified = isKycUploaded;
      });
    }
  }

  String? productId;
  String? userId;
  String? token;
  String? userOptions;
  dynamic wallet;
  String? balance;

  bool get _isOutrightSelection => selectedPurchaseType == 'outright';

  bool get _isInstallmentSelection =>
      selectedPurchaseType != null && !_isOutrightSelection;

  bool get _isPlanFullySelected {
    if (_isOutrightSelection) {
      return true;
    }
    return selectedPurchaseType != null &&
        selectedDurationMonths != null &&
        selectedRepaymentFrequency != null;
  }

  String get _selectionSummary {
    if (selectedPurchaseType == null) {
      return 'Start by choosing outright or an installment plan. The matching payment options will become easier to follow.';
    }

    if (_isOutrightSelection) {
      return 'Outright plan selected. Next, use one-time card payment to complete checkout without direct debit.';
    }

    if (selectedDurationMonths == null || selectedRepaymentFrequency == null) {
      return 'Installment plan selected. Finish choosing duration and repayment frequency to unlock installment payment options.';
    }

    final duration = selectedDurationMonths != null
        ? '$selectedDurationMonths months'
        : 'pick a duration';
    final frequency =
        selectedRepaymentFrequency ?? 'pick a repayment frequency';
    if (!_isKycVerified) {
      return 'Installment plan selected for $duration with $frequency repayments. Verify BVN before you can continue with installment checkout.';
    }
    return 'Installment plan selected for $duration with $frequency repayments. Next, choose wallet checkout or installment card. Card checkout does not require direct debit for down_40/down_50 plans.';
  }

  void _handleWalletCheckout() {
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

    if (Activated == false) {
      _showConnectDialog(context);
      return;
    }

    purchaseProduct();
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

  String _formatMoney(num amount) {
    return '₦${NumberFormat('#,##0.00').format(amount)}';
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
        (purchaseType != null &&
            selectedDurationMonths != null &&
            selectedRepaymentFrequency != null);

    if (!readyForPreview) return;

    final signature =
        '${selectedPurchaseType ?? ''}|${selectedDurationMonths ?? ''}|${selectedRepaymentFrequency ?? ''}';
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
    final downPercent = _downPaymentPercent(purchaseType);
    final downPayment = totalPrice * downPercent;
    final remainingBalance = (totalPrice - downPayment).clamp(0, totalPrice);

    final isOutright = purchaseType == 'outright';
    final frequency = selectedRepaymentFrequency;
    final months = selectedDurationMonths;
    final count = isOutright ? 0 : _installmentCount(months!, frequency!);
    final repaymentFeePercent =
        isOutright ? 0.0 : _repaymentFeePercent(purchaseType, months!);
    final repaymentFee = remainingBalance * repaymentFeePercent;
    final totalRepaymentAmount = remainingBalance + repaymentFee;
    final totalAmountToPay =
        isOutright ? totalPrice : downPayment + totalRepaymentAmount;
    final eachInstallment = count > 0 ? (totalRepaymentAmount / count) : 0.0;
    final purchaseTypeLabel = switch (purchaseType) {
      'outright' => 'Outright payment',
      'down_50' => 'Pay 50% now',
      'down_40' => 'Pay 40% now',
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
        : 'You will pay ${_formatMoney(downPayment)} today, then complete ${_formatMoney(totalRepaymentAmount)} with $count $frequencyLabel payments of ${_formatMoney(eachInstallment)}.';
    final nextStepText = isOutright
        ? 'After this, you can continue to payment and complete checkout immediately.'
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
                                    isOutright ? 'Pay now' : 'Down payment now',
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
                                      'Next payments',
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
                                          : 'Down payment now',
                                      _formatMoney(isOutright
                                          ? totalPrice
                                          : downPayment),
                                    ),
                                    if (!isOutright) ...[
                                      _planRow('Remaining before fee',
                                          _formatMoney(remainingBalance)),
                                      _planRow(
                                        'Installment fee',
                                        '${(repaymentFeePercent * 100).round()}% (${_formatMoney(repaymentFee)})',
                                      ),
                                      _planRow('Repayment total',
                                          _formatMoney(totalRepaymentAmount)),
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
    String token,
    String productId,
    String purchaseType,
    int durationMonths,
    String repaymentFrequency,
  ) async {
    try {
      Map<String, dynamic> requestBody = {
        "productId": productId,
        "purchaseType": purchaseType,
        "durationMonths": durationMonths,
        "repaymentFrequency": repaymentFrequency,
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

    if (token != null &&
        productId != null &&
        selectedPurchaseType != null &&
        selectedDurationMonths != null &&
        selectedRepaymentFrequency != null) {
      await makeBuyProductRequest(
        token!,
        productId!,
        selectedPurchaseType!,
        selectedDurationMonths!,
        selectedRepaymentFrequency!,
      );
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

    if (token == null ||
        productId == null ||
        selectedPurchaseType == null ||
        selectedDurationMonths == null ||
        selectedRepaymentFrequency == null) {
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
          "purchaseType": selectedPurchaseType,
          "durationMonths": selectedDurationMonths,
          "repaymentFrequency": selectedRepaymentFrequency,
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
                        "Step 1: Choose how you want to buy",
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        "Pick a plan first. Retilda will then show the payment routes that match it.",
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedPurchaseType,
                        decoration: InputDecoration(
                          labelText: "Purchase type",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
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
                            }
                          });
                          _onPlanSelectionUpdated();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedDurationMonths,
                        decoration: InputDecoration(
                          labelText: "Duration (months)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text("2 months")),
                          DropdownMenuItem(value: 4, child: Text("4 months")),
                          DropdownMenuItem(value: 6, child: Text("6 months")),
                        ],
                        onChanged: selectedPurchaseType == "outright"
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
                        decoration: InputDecoration(
                          labelText: "Repayment frequency",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        onChanged: selectedPurchaseType == "outright"
                            ? null
                            : (value) {
                                setState(() {
                                  selectedRepaymentFrequency = value;
                                });
                                _onPlanSelectionUpdated();
                              },
                      ),
                    ],
                  ),
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
                        "Step 2: Select a payment method",
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
                                : 'Choose installment plan',
                        onPressed: _isInstallmentSelection &&
                                _isPlanFullySelected
                            ? () {
                                _showPaymentActionSheet(
                                  title: 'Installment card payment',
                                  summary: _isKycVerified
                                      ? 'This starts installment checkout with your card. Down_40 and down_50 card checkout does not require direct debit.'
                                      : 'BVN verification must be completed before installment card checkout can start.',
                                  detail: _isKycVerified
                                      ? 'Choose this if you want to pay the required down payment by card and continue without connecting a bank account for direct debit.'
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
                        subtitle: "For installment purchases.",
                        badge: !_isKycVerified
                            ? 'KYC required'
                            : Activated == true
                                ? 'Connected'
                                : 'Needs setup',
                        badgeColor: !_isKycVerified
                            ? const Color(0xFFB26A00)
                            : Activated == true
                                ? const Color(0xFF0E7C66)
                                : accent,
                        backgroundColor: const Color(0xFFF7F9FC),
                        actionLabel:
                            _isInstallmentSelection && _isPlanFullySelected
                                ? (_isKycVerified ? 'Select' : 'Verify BVN')
                                : 'Choose installment plan',
                        onPressed: _isInstallmentSelection &&
                                _isPlanFullySelected
                            ? () {
                                _showPaymentActionSheet(
                                  title: 'Wallet installment checkout',
                                  summary: !_isKycVerified
                                      ? 'BVN verification must be completed before wallet installment checkout can start.'
                                      : Activated == true
                                          ? 'This continues your wallet installment flow.'
                                          : 'This option needs bank connection before checkout can continue.',
                                  detail: !_isKycVerified
                                      ? 'The backend blocks installment checkout until KYC is complete. Verify BVN first, then return here to continue.'
                                      : Activated == true
                                          ? 'Your account is already connected. Continue to proceed with wallet installment checkout for this product.'
                                          : 'Wallet installment checkout may use direct debit for scheduled repayments. You will connect your account before continuing.',
                                  continueLabel: !_isKycVerified
                                      ? 'Verify BVN'
                                      : Activated == true
                                          ? 'Continue'
                                          : 'Connect account',
                                  onContinue: !_isKycVerified
                                      ? _showKycRequiredDialog
                                      : _handleWalletCheckout,
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
                        widget.product.description?.toString() ?? "",
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
                        widget.product.specification ??
                            "No Product Specifications",
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
