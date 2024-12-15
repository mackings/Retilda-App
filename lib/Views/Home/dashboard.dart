import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Products/Allproducts.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Widgets/carousel.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/indicators.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/searchwidget.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;





class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  //Dybamics
  Map<String, dynamic>? _userData;
  List<Product> _products = [];
  late Future<ApiResponse> _futureProducts;
  String? Token;

  final List<String> _assetPaths = [
    'assets/c1.jpg',
    'assets/k1.jpg',
    'assets/m1.jpg',
    'assets/t1.jpg'
  ];

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      setState(() {
        Token = token;
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
  void initState() {
    _loadUserData();
    //_futureProducts = _loadProducts();
    super.initState();
  }

  @override
  void dispose() {
    searchcontroller;
    super.dispose();
  }

  TextEditingController searchcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Allproducts()));
                  },
                  child: SearchContainer(
                    controller: searchcontroller,
                  ),
                ),
                SizedBox(
                  height: 32.h,
                  child: PageView(
                    children: [
                      CarouselPageView(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Row(
                    children: [
                      CustomText(
                        "Top Categories",
                        fontSize: 12.sp,
                        color: ROrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),


GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Allproducts()),
    );
  },
  child: SizedBox(
    height: 25.h,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<ApiResponse>(
        future: fetchData(Token!), // Fetch data using the Token
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading products"));
          } else if (snapshot.hasData) {
            final List<Product> products = snapshot.data!.data;

            // Create a map of categories and their associated products
            Map<String, Product> categoryProductMap = {};

            for (var product in products) {
              // For each category in the product, store the first product found
              for (var category in product.categories) {
                if (!categoryProductMap.containsKey(category)) {
                  categoryProductMap[category] = product;
                }
              }
            }

            // Convert map to list for displaying
            final categoriesWithProduct = categoryProductMap.entries.toList();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categoriesWithProduct.length,
              itemBuilder: (context, index) {
                var categoryEntry = categoriesWithProduct[index];
                var category = categoryEntry.key;
                var product = categoryEntry.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.images.isNotEmpty ? product.images[0] : 'default_image_url',
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Category Name
                      CustomText(
                        category,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: ROrange,
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("No products found"));
          }
        },
      ),
    ),
  ),
),



                SizedBox(
                  height: 3.h,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        "Products",
                        fontSize: 12.sp,
                        color: ROrange,
                        fontWeight: FontWeight.w600,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Allproducts()));
                        },
                        child: CustomText(
                          "View all",
                          fontSize: 12.sp,
                          color: RButtoncolor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Token != null
                    ? FutureBuilder<ApiResponse>(
                        future: fetchData(Token!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 10.h,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 40, right: 40),
                                    child: LinearProgressIndicator(),
                                  ),
                                ],
                              ),
                            ));
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('No Products Found'),
                            );
                          } else if (snapshot.hasData) {
                            print(snapshot.data);

                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: SizedBox(
                                height: 60
                                    .h, // Set an appropriate height for the grid
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap:
                                      true, // Ensure the grid does not take infinite height
                                  physics:
                                      NeverScrollableScrollPhysics(), // Disable scrolling inside the GridView
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  children: snapshot.data!.data
                                      .take(4)
                                      .map(
                                        (product) => GestureDetector(
                                          onTap: () {
                                            print("heyy");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProductDetails(
                                                        product: product),
                                              ),
                                            );
                                          },
                                          child: ProductCard2(
                                            product: product,
                                            onTap: () {},
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            );
                          } else {
                            return Center(
                              child: Text('No products available'),
                            );
                          }
                        },
                      )
                    : CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}
