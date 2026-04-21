import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/products.dart';

class CategoryProductsPage extends StatefulWidget {
  final String category;

  const CategoryProductsPage({Key? key, required this.category})
      : super(key: key);

  @override
  _CategoryProductsPageState createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  String? token;
  late Future<List<Product>> _futureProducts;
  late final ApiClient _apiClient = ApiClient(session: AppSession());

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final loadedToken = await AppSession().userToken();
    if (loadedToken != null) {
      setState(() {
        token = loadedToken;
        _futureProducts = fetchCategoryProducts(widget.category, token!);
      });
    }
  }

  Future<List<Product>> fetchCategoryProducts(
      String category, String token) async {
    try {
      final response = await _apiClient.get(
        'products/category/${Uri.encodeComponent(category)}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final ApiResponse apiResponse = ApiResponse.fromJson(responseData);
        return apiResponse.data;
      } else {
        throw Exception('Failed to load category products');
      }
    } catch (error) {
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: CustomText(
        widget.category,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      )),
      body: token == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child:
                        Text('Error fetching products for ${widget.category}'),
                  );
                } else if (snapshot.hasData) {
                  final List<Product> products = snapshot.data!;

                  if (products.isEmpty) {
                    return Center(
                      child: Text('No products found for ${widget.category}'),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      return Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ProductCard2(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetails(product: product),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text('No data available'),
                  );
                }
              },
            ),
    );
  }
}
