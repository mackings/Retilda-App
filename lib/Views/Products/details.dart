import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:retilda/Views/Products/Connect/views/connect.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Products/terms.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/paymentoption.dart';
import 'package:retilda/Views/Widgets/webview.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
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

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  Timer? _kycGuardTimer;
  DateTime? _selectedDate;
  String? _selectedCategory;

  bool _isLoading = false;

  // API Call Function
  Future<void> _calculateDeliveryFee(BuildContext context) async {
    final url =
        "https://retildaserver.vercel.app/Api/deliveryFeeCalculation/$productId";
    final data = {
      "deliveryAddress": _addressController.text,
      "phoneNumber": _phoneController.text,
      "deliveryTime": _timeController.text,
      "deliveryDate": _selectedDate?.toIso8601String(),
      "category": _selectedCategory,
      "distance": _selectedCategory, // Assuming distance = category
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );
      print(data);

      if (response.statusCode == 200) {
        print(response.body);
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final deliveryFee = responseData['data']['deliveryFee'];
          final formattedFee = deliveryFee.toString().replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (match) => ',',
              );

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delivery Fee: ₦$formattedFee")),
          );
        } else {
          print(response.body);
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
      Navigator.of(context).pop();
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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
                        "Delivery Details",
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
                                  "Calculate Delivery Fee",
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
    const String apiUrl =
        "https://retildaserver.vercel.app/Api/buyproductonsales/onetimepaymentusingcard";
    await _loadUserData();
    if (token == null || productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: CustomText('Unable to start payment. Please sign in again.')),
      );
      return;
    }

    try {
      // Make the API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"productId": productId}),
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
        print(response.body);
      }
    } catch (e) {
      print(e);
      // Handle exceptions
      _showErrorDialog(context, "An error occurred: $e");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Okay"),
          ),
        ],
      ),
    );
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
    final Uri url =
        Uri.parse('https://retildaserver.vercel.app/Api/balance');

    Map<String, String> requestBody = {
      'walletAccountNumber': wallet,
    };

    String requestBodyJson = jsonEncode(requestBody);

    try {
      http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        print(response.body);
        Map<String, dynamic> responseBody = jsonDecode(response.body);

        print(
            'Wallet balance: ${responseBody['data']['responseBody']['availableBalance']}');

        setState(() {
          balance = responseBody['data']['responseBody']['availableBalance']
              .toString();
        });
      } else {
        print(response.body);
        print('Failed to fetch wallet balance: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching wallet balance: $error');
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      final data = userData['data'] as Map<String, dynamic>?;
      final user = data?['user'] as Map<String, dynamic>?;
      final userWallet = user?['wallet'] as Map<String, dynamic>?;

      final String? loadedToken = data?['token'] as String?;
      final String? loadedUserId = user?['_id'] as String?;
      final String? loadedWallet = userWallet?['accountNumber'] as String?;
      final bool? userDirectdebit = user?['isDirectDebit'] as bool?;

      if (!mounted) return;
      setState(() {
        token = loadedToken;
        userId = loadedUserId;
        productId = widget.product.id;
        wallet = loadedWallet;
        Activated = userDirectdebit;
      });

      print("User ID>> $userId");
      print("Product ID >> $productId");
      print("All User>> $userData");
      print("User Activation $Activated");
    }
  }

  String? productId;
  String? userId;
  String? token;
  String? userOptions;
  dynamic wallet;
  String? balance;

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
    final count = isOutright
        ? 0
        : _installmentCount(months!, frequency!);
    final eachInstallment = count > 0 ? (remainingBalance / count) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.8,
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
                  Text(
                    'Payment Plan Breakdown',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF103C57),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _planRow('Product price', _formatMoney(totalPrice)),
                          _planRow('Purchase type', purchaseType.replaceAll('_', ' ')),
                          _planRow('Down payment now', _formatMoney(downPayment)),
                          if (!isOutright) ...[
                            _planRow('Remaining balance', _formatMoney(remainingBalance)),
                            _planRow('Repayment frequency', frequency!),
                            _planRow('Duration', '$months months'),
                            _planRow('No. of installments', '$count'),
                            _planRow(
                              'Each ${frequency == 'biweekly' ? '2 weeks' : frequency}',
                              _formatMoney(eachInstallment),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8FA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              isOutright
                                  ? 'You will pay ${_formatMoney(totalPrice)} once.'
                                  : 'You will pay ${_formatMoney(downPayment)} now, then $count payments of ${_formatMoney(eachInstallment)}.',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF103C57),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF103C57),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
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
  }

  Widget _planRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
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

      String requestBodyJson = jsonEncode(requestBody);
      print("Payload >> $requestBodyJson");
      final response = await http.post(
        Uri.parse(
            'https://retildaserver.vercel.app/Api/buyProductOnInstallment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        print('Buy product request successful');

        print('Response: ${response.body}');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Purchase successful!'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            Map<String, dynamic> responseData = jsonDecode(response.body);
            String errorMessage = responseData['message'];

            return AlertDialog(
              title: Text('Failed'),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: CustomText(
                          'Please complete  your KYC on your profile page'),
                    ));
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );

        print(response.body);
        print(
            'Buy product request failed with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error making buy product request: $error');
    }
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

      print(token);
      print(productId);
      print(selectedPurchaseType);
      print(selectedDurationMonths);
      print(selectedRepaymentFrequency);
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
      final response = await http.post(
        Uri.parse(
            'https://retildaserver.vercel.app/Api/buyProductOnInstallmentUsingCard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "productId": productId,
          "purchaseType": selectedPurchaseType,
          "durationMonths": selectedDurationMonths,
          "repaymentFrequency": selectedRepaymentFrequency,
        }),
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
        _showErrorDialog(
            context, "Failed to initialize payment. Please try again.");
        print(response.body);
      }
    } catch (e) {
      print(e);
      _showErrorDialog(context, "An error occurred: $e");
    }
  }

  Widget _buildActionIcon({required IconData icon, required VoidCallback onTap}) {
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

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);
    final String categoryLabel =
        widget.product.categories.isNotEmpty ? widget.product.categories.first : 'Marketplace';

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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                      Icon(Icons.verified, size: 16, color: accent),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                        "Select your payment plan",
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 10),
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
                      if (selectedPurchaseType != null ||
                          selectedDurationMonths != null ||
                          selectedRepaymentFrequency != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 4, right: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: CustomText(
                                  'Selection: ${selectedPurchaseType ?? "Select purchase type"}, '
                                  '${selectedDurationMonths != null ? "${selectedDurationMonths} months" : "Select duration"}, '
                                  '${selectedRepaymentFrequency ?? "Select frequency"}.',
                                  fontSize: 11.sp,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                              "Wallet checkout",
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: deepBlue,
                            ),
                            const SizedBox(height: 6),
                            CustomText(
                              "Secure, instant payment from your Retilda wallet.",
                              fontSize: 11.sp,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 10),
                            loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      if (Activated == false) {
                                        _showConnectDialog(context);
                                      } else {
                                        purchaseProduct();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: accent,
                                      elevation: 0,
                                      side: const BorderSide(color: accent, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: CustomText(
                                      "Pay Now",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                      color: accent,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: deepBlue,
                          borderRadius: BorderRadius.circular(16),
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
                              "One-time card",
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            CustomText(
                              "Quick card payment with instant confirmation.",
                              fontSize: 11.sp,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => initializePayment(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: deepBlue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: CustomText(
                                  "One Time Pay",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                  color: deepBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    initializeInstallmentCardPayment(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  side: const BorderSide(
                                      color: Colors.white, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: CustomText(
                                  "Installment Card",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                        onToggle: () => setState(() => _showFullDescription = !_showFullDescription),
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
                        widget.product.specification ?? "No Product Specifications",
                        expanded: _showFullSpecs,
                        onToggle: () => setState(() => _showFullSpecs = !_showFullSpecs),
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
    showDialog(
      context: context,
      builder: (context) {
        bool termsAccepted = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: Text(
                'Connect',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To proceed, please consent to connect your bank account and read our privacy policy for more details.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            termsAccepted = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'I agree to the ',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (_) => InAppWebViewPage(
                                //       url:
                                //           'https://docs.google.com/document/d/17afb6dSPPh2RVRodtq-r7v16eEAjZ6SVHOUb6h_edFs/edit?usp=sharing',
                                //       title: 'Terms and Policy',
                                //     ),
                                //   ),
                                // );
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                'Terms and Policy',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: termsAccepted
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConnectAccount(),
                            ),
                          );
                          debugPrint("Bank account connected");
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Connect',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
