import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/togglebtn.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sizer/sizer.dart';

class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool isFirstButtonActive = true;
  int? selectedChipValue;
  String? Insurance;
  bool loading = false;

  List<CartItem> cartItems = [];

  @override
  void initState() {
    _loadUserData();
    super.initState();
    _loadCartItems();
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
    final Uri url = Uri.parse('https://retilda.onrender.com/Api/balance');

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

      setState(() {
        token = Token;
        userId = UserId;
        productId = widget.product.id;
        wallet = Wallet;
      });

      // getWalletBalance(wallet);

      print("User ID>> $userId");
      print("Product ID >> $productId");
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
    if (isFirstButtonActive) {
      setState(() {
        plan = 'weekly';
        instCount = chipValue;
        print(chipValue.toString());
        print(plan);
      });
    } else if (isFirstButtonActive == false) {
      setState(() {
        plan = 'monthly';
        instCount = chipValue;
        print(chipValue.toString());
        print(plan);
      });
    } else {
      setState(() {
        plan = 'once';
        instCount = chipValue;
        print(chipValue.toString());
        print(plan);
      });
    }
    print(
        'Action: $action, Chip: $chipValue, Plan: ${isFirstButtonActive ? "Weekly" : "Monthly"}');

    print('Data Tapped >>> $action, Installments: $chipValue, Plan: $plan');
  }

  void handleToggle(bool isFirstButtonActive) {
    setState(() {
      plan = isFirstButtonActive ? 'monthly' : 'weekly';
      selectedChipValue = null;
    });
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
        Uri.parse('https://retilda.onrender.com/Api/buyproduct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBodyJson,
      );
      setState(() {
        loading = true;
      });

      if (response.statusCode == 200) {
        
        print('Buy product request successful');
        print('Response: ${response.body}');
       setState(() {
        loading = false;
      });

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
          },
          child: Text('OK'),
        ),
      ],
    );
  },
);

    setState(() {
        loading = false;
      });
        print(response.body);
        print(
            'Buy product request failed with status code: ${response.statusCode}');
      }
    } catch (error) {

      setState(() {
        loading = false;
      });

      print('Error making buy product request: $error');
    }
  }

  Future<void> purchaseProduct() async {
    await _loadUserData();
    if (token != null &&
        userId != null &&
        productId != null &&
        plan != null &&
        instCount != null) {
      await makeBuyProductRequest(
          token!, userId!, productId!, plan!, instCount!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: CustomText('You need to Select Insurance or No Insurance'),
      ));
      print('Missing required data to purchase the product.');
    }
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
            "Product details",
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
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
                      fontWeight: FontWeight.w400,
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
                padding: const EdgeInsets.only(left: 25, right: 25, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      "N${NumberFormat('#,##0').format(widget.product.price)}",
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                    loading? CustomText('Making payments...'):GestureDetector(
                      onTap: () {
                        purchaseProduct();
                      },
                      child:Container(
                        height: 6.h,
                        width: 50.w,
                        decoration: BoxDecoration(
                          color: ROrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomText(
                            "Buy Now",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        color: ROrange,
                      ),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: CustomText(
                          'You Selected: The ${isFirstButtonActive ? "Weekly" : "Monthly"} Plan and ${selectedChipValue != null ? selectedChipValue.toString() : "No days selected"} ${isFirstButtonActive ? "Weeks" : "Months"} installments with ${Insurance == null ? "No Insurance" : Insurance}.',
                        ),
                      ),
                    ],
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
                      color: ROrange,
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
                      color: ROrange,
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
