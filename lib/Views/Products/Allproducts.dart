import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class Allproducts extends ConsumerStatefulWidget {
  const Allproducts({Key? key}) : super(key: key);

  @override
  _AllproductsState createState() => _AllproductsState();
}

class _AllproductsState extends ConsumerState<Allproducts> {
  late List<Product> _products = [];
  late String _token;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      setState(() {
        _token = token;
      });

      fetchData(token).then((apiResponse) {
        setState(() {
          _products = apiResponse.data;
        });
      }).catchError((error) {
        print('Error fetching products: $error');
      });
      print("User >>> $userData");
    }
  }

  Future<ApiResponse> fetchData(String token) async {
    final String url = 'https://retilda.onrender.com/Api/products';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final ApiResponse apiResponse = ApiResponse.fromJson(responseData);
        return apiResponse;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
  extendBodyBehindAppBar: true,
  backgroundColor: Colors.white,
  appBar: AppBar(
    backgroundColor: Colors.white,
    title: CustomText(
            "Products",
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
  ),
  body: _products.isEmpty 
      ? Center(
          child: CircularProgressIndicator(), 
        )
      : Padding(
          padding: const EdgeInsets.all(5.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetails(product: _products[index]),
                        ),
                      );       
                  },
                  child: ProductCard(
                    product: _products[index],
                    onTap: () {},
                  ),
                ),
              );
            },
          ),
        ),
);
      },
    );
  }
}
