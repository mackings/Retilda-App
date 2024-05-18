import 'package:flutter/material.dart';
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

  List<CartItem> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void handleToggle(bool isFirstButtonActive) {
    setState(() {
      this.isFirstButtonActive = isFirstButtonActive;
      selectedChipValue = null;
    });
  }

  void handleChipSelected(int chipValue, bool isFirstButtonActive) {
    setState(() {
      selectedChipValue = chipValue;
    });
    print('Selected Chip: $chipValue, Is First Button Active: $isFirstButtonActive');
  }

  void handleActionSelected(String action, int chipValue, bool isFirstButtonActive) {
    setState(() {
      Insurance = action;
    });
    print('Action: $action, Chip: $chipValue, Plan: ${isFirstButtonActive ? "Weekly" : "Monthly"}');
  }

  void addToCart() async {
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
      content: Text('Added to cart!'),
    ));
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = cartItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('cartItems', cartItemsJson);
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('cartItems');
    if (cartItemsJson != null) {
      setState(() {
        cartItems = cartItemsJson.map((item) => CartItem.fromJson(jsonDecode(item))).toList();
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

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CartPage(cartItems: cartItems),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.white,
          title: Text("Product Details"),

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
                      margin: EdgeInsets.symmetric(horizontal: 35.0, vertical: 2),
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
                      "N${widget.product.price}",
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                    Container(
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
