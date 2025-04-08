import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Home/homecategory.dart';
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
import 'package:cached_network_image/cached_network_image.dart';





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
    'assets/dr1.png',
    'assets/dr2.png',
    'assets/dr3.png',
    'assets/dr4.png'
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
    final String url = 'https://retilda-fintech.onrender.com/Api/products';

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
  backgroundColor: Colors.white,
  body: RefreshIndicator(
    onRefresh: () async {
      setState(() {}); // Rebuild to refetch data
    },
    child: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          floating: true,
          pinned: false,
          snap: true,
          centerTitle: false,
          title: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Allproducts()));
            },
            child: SearchContainer(controller: searchcontroller),
          ),
        ),

        // Carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: 30.h,
            child: CarouselPageView(),
          ),
        ),

        // Top Categories Heading
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: CustomText(
              "Top Categories",
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: ROrange,
            ),
          ),
        ),

        // Category List
        SliverToBoxAdapter(
          child: SizedBox(
            height: 20.h,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder<ApiResponse>(
                future: Token != null ? fetchData(Token!) : Future.error("Token not available"),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Error loading categories"));
                  } else if (snapshot.hasData) {
                    final List<Product> products = snapshot.data!.data;
                    Map<String, Product> categoryProductMap = {};

                    for (var product in products) {
                      for (var category in product.categories) {
                        if (!categoryProductMap.containsKey(category)) {
                          categoryProductMap[category] = product;
                        }
                      }
                    }

                    final categories = categoryProductMap.entries.toList();

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        var entry = categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryProductsPage(category: entry.key),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: entry.value.images.isNotEmpty
                                      ? entry.value.images[0]
                                      : 'default_image_url',
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                              SizedBox(height: 8),
   CustomText(
  '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
  fontSize: 10.sp,
  fontWeight: FontWeight.w600,
  color: Colors.black,
),

                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(width: 16),
                    );
                  } else {
                    return const Center(child: Text("No categories available"));
                  }
                },
              ),
            ),
          ),
        ),

        // Product Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "Products",
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: ROrange,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => Allproducts()));
                  },
                  child: CustomText(
                    "View all",
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: RButtoncolor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Products Grid
        SliverToBoxAdapter(
          child: Token != null
              ? FutureBuilder<ApiResponse>(
                  future: fetchData(Token!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20),
                        child: LinearProgressIndicator(),
                      ));
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("No Products Found"));
                    }

                    final products = snapshot.data!.data.take(10).toList();

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetails(product: product),
                                ),
                              );
                            },
                            child: ProductCard2(
                              product: product,
                              onTap: () {},
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              : const Center(child: CircularProgressIndicator()),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    ),
  ),
);

      },
    );
  }
}
