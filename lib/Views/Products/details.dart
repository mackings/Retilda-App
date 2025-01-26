import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:retilda/Views/Products/Connect/views/connect.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Products/terms.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/togglebtn.dart';
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
  DateTime? _selectedDate;
  String? _selectedCategory;

  bool _isLoading = false;

  // API Call Function
  Future<void> _calculateDeliveryFee(BuildContext context) async {
    final url =
        "https://retilda-fintech.onrender.com/Api/deliveryFeeCalculation/$productId";
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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final deliveryFee = responseData['data']['deliveryFee'];
          final formattedFee = deliveryFee.toString().replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (match) => ',',
              );

          Navigator.of(context).pop(); // Close the modal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delivery Fee: ₦$formattedFee")),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter Delivery Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: "Delivery Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: "Delivery Time",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
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
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? "Select Delivery Date"
                            : "${_selectedDate!.toLocal()}".split(' ')[0],
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    items: ["local", "regional", "interstate"]
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _calculateDeliveryFee(context);
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Calculate Delivery Fee"),
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






  bool isFirstButtonActive = true;
  int? selectedChipValue;

  String? Insurance;
  bool loading = false;
  bool? Activated;
  bool termsAccepted = false;

  List<CartItem> cartItems = [];

  @override
  void initState() {
    _loadUserData();
    Timer(Duration(seconds: 20), () {
      if (wallet == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: CustomText('Please complete KYC on profile page'),
        ));
        Navigator.pop(context);
        Navigator.pop(context);
      } else {}
    });
    super.initState();
    _loadCartItems();
  }

Future<void> initializePayment(BuildContext context) async {
  const String apiUrl =
      "https://retilda-fintech.onrender.com/Api/buyproductonsales/onetimepaymentusingcard";

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

      if (responseData['success'] == true) {
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
    final Uri url = Uri.parse('https://retilda-fintech.onrender.com/Api/balance');

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
      String Token = userData['data']['token'];
      String UserId = userData['data']['user']['_id'];
      String Wallet = userData['data']['user']['wallet']['accountNumber'];
      bool userDirectdebit = userData['data']['user']['isDirectDebit'];

      setState(() {
        token = Token;
        userId = UserId;
        productId = widget.product.id;
        wallet = Wallet;
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
  int? instCount;
  String? token;
  String? userOptions;
  dynamic wallet;
  String? balance;
  String? plan;

  void handleActionSelected(
      String action, int chipValue, bool isFirstButtonActive) {
    setState(() {
      if (isFirstButtonActive == true) {
        plan = 'weekly';
      } else if (isFirstButtonActive == false) {
        plan = 'monthly';
      }
      instCount = chipValue;
    });

    print('Action: $action, Chip: $chipValue, Plan: $plan');
    print('Data Tapped >>> $action, Installments: $chipValue, Plan: $plan');
  }

  void handleToggle(bool isFirstButtonActive) {
    setState(() {
      this.isFirstButtonActive =
          isFirstButtonActive; // Make sure this updates correctly
      plan = isFirstButtonActive ? 'weekly' : 'monthly';
      selectedChipValue = null; // Reset selected chip value on toggle
    });
    print('Toggle Updated: ${isFirstButtonActive ? "Weekly" : "Monthly"}');
  }

  void handleChipSelected(int chipValue, bool isFirstButtonActive) {
    setState(() {
      selectedChipValue = chipValue;
    });
    print(
        'Selected Chip: $chipValue, Is First Button Active: $isFirstButtonActive');
  }

  Future<void> makeBuyProductRequest(String token, String userId,
      String productId, String plan, int numberOfInstallments) async {
    try {
      Map<String, dynamic> requestBody = {
        "userid": userId,
        "productId": productId,
        "paymentPlan": plan,
        "numberOfInstallments": numberOfInstallments,
      };

      String requestBodyJson = jsonEncode(requestBody);
      print("Payload >> $requestBodyJson");
      final response = await http.post(
        Uri.parse(
            'https://retilda-fintech.onrender.com/Api/buyProductOnInstallment'),
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
        content: CustomText('Please complete  your KYC on your profile page'),
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
    setState(() {
      loading = true;
    });

    await _loadUserData();
    if (token != null &&
        userId != null &&
        productId != null &&
        plan != null &&
        selectedChipValue != null) {
      await makeBuyProductRequest(
          token!, userId!, productId!, plan!, selectedChipValue!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('Please complete purchase requirements'),
      ));

      print(token);
      print(userId);
      print(productId);
      print(plan);
      print(instCount);
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.white,
          title: CustomText(
            "Details",
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
          actions: [
 GestureDetector(
            onTap: () => _showDeliveryModal(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  "Delivery",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(children: [
              SizedBox(
                height: 2.h,
              ),
              SizedBox(
                height: 30.h,
                child: PageView(
                  children: widget.product.images.map((image) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 35.0, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.transparent,
                        image: DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      widget.product.name,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_shopping_cart),
                          onPressed: addToCart,
                        ),
                        IconButton(
                          icon: Icon(Icons.favorite_border),
                          onPressed: () {
                            // Favorite action
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            // Share action
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 5),
                child: Divider(
                  color: Colors.grey,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20),
                child: Row(
                  children: [
                    CustomText(
                      "Select desired Payment frequency",
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
              ToggleButtonsWidget(
                firstButtonText: 'Weekly',
                secondButtonText: 'Monthly',
                onToggle: handleToggle,
                onChipSelected: handleChipSelected,
                onActionSelected: handleActionSelected,
              ),
              if (selectedChipValue != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: CustomText(
                          'You Selected: The ${isFirstButtonActive ? "Weekly" : "Monthly"} Plan and ${selectedChipValue != null ? selectedChipValue.toString() : "No days selected"} ${isFirstButtonActive ? "Weeks" : "Months"} installments.',
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      "N${NumberFormat('#,##0').format(widget.product.price)}",
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                    loading
                        ? CustomText('Making payments...')
                        : GestureDetector(
                            onTap: () {
                              if (Activated == false) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    bool termsAccepted =
                                        false; // Local state for dialog

                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          title: Text(
                                            'Connect',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'To proceed, please consent to connect your bank account to the platform and read our privacy policy for more details.',
                                              ),
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: termsAccepted,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        termsAccepted = value!;
                                                      });
                                                    },
                                                  ),

Flexible(
  child: Row(
    children: [
      Text('I accept the'),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InAppWebViewPage(
                url: 'https://docs.google.com/document/d/1zWEYmMZ_tRhC198qMsN5rP55YmeQ8rtiuTbaPEC_Fw0/edit?usp=sharing',
                title: 'Terms and Policy',
              ),
            ),
          );
        },
        child: Text(
          'Terms',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    ],
  ),
),


                                                ],
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: termsAccepted
                                                  ? () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ConnectAccount()),
                                                      );
                                                      print(
                                                          "Bank account connected");
                                                    }
                                                  : null, // Disable button if terms are not accepted
                                              child: Text('Connect'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              } else {
                                purchaseProduct();
                              }
                            },
                            child: Container(
                              height: 6.h,
                              width: 50.w,
                              decoration: BoxDecoration(
                                color: RButtoncolor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: CustomText(
                                  "Pay Installments",
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                  ],
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
              Text("OR "),
              SizedBox(
                height: 2.h,
              ),
              GestureDetector(
                onTap: () => initializePayment(context),
                child: Container(
                  height: 6.h,
                  width: MediaQuery.of(context).size.width - 10.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "One Time Payment",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20),
                child: Row(
                  children: [
                    CustomText(
                      "Product Description :",
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 1),
                child: ListTile(
                  title: CustomText(
                    widget.product.description.toString(),
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20),
                child: Row(
                  children: [
                    CustomText(
                      "Product Specifications :",
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 1),
                child: ListTile(
                  title: CustomText(
                    widget.product.specification ?? "No Product Specifications",
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}





class InAppWebViewPage extends StatelessWidget {
  final String url;
  final String title;

  const InAppWebViewPage({required this.url, required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
