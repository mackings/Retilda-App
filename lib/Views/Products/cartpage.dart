import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:sizer/sizer.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
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

  // Future<void> _loadCartItems() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final cartItemsJson = prefs.getStringList('cartItems');
  //   if (cartItemsJson != null) {
  //     setState(() {
  //       cartItems = cartItemsJson.map((item) => CartItem.fromJson(item)).toList();
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: CustomText('Cart'),
      ),
      body: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final cartItem = cartItems[index];
          return Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: GestureDetector(
              onTap: () {
                print(cartItem.name);
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 0.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [

CircleAvatar(
  radius: 30,
  child: ClipOval(
    child: Image.network(
      cartItem.images.isNotEmpty ? cartItem.images[0] : '',
      width: 80, 
      height: 80,
      fit: BoxFit.cover, 
    ),
  ),
),
SizedBox(width: 3.w,),


                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            cartItem.name,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: 8.0),
                          CustomText(cartItem.description),
                          SizedBox(height: 8.0),
                          CustomText('N${cartItem.price}',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              // Add item functionality
                            },
                            icon: Icon(Icons.add),
                          ),
                          IconButton(
                            onPressed: () {
                              // Remove item functionality
                            },
                            icon: Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
