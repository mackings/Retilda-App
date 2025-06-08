import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/model/products.dart';
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

  Future<void> _removeCartItem(int index) async {
    setState(() {
      cartItems.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson =
        cartItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('cartItems', cartItemsJson);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: CustomText('Product Removed!'),
    ));
  }

  void _navigateToProductDetails(CartItem cartItem) {
    final product = Product(
      id: cartItem.id,
      name: cartItem.name,
      price: cartItem.price,
      description: cartItem.description,
      images: cartItem.images,
      categories: cartItem.categories,
      specification: cartItem.specification.toString(),
      brand: cartItem.brand.toString(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetails(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: CustomText(
        'Cart',
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
      ),
    ),
    body: cartItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket,size: 15.h,),
                CustomText(
                  'Your cart is empty.',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: GestureDetector(
                  onTap: () {
                    _navigateToProductDetails(cartItem);
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
                        SizedBox(width: 3.w),
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
                            //  CustomText(cartItem.description),
                              SizedBox(height: 8.0),
                              CustomText(
                                'N${NumberFormat('#,##0').format(cartItem.price)}',
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
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
                                  _removeCartItem(index);
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
