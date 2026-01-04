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

class _DashboardState extends ConsumerState<Dashboard>
    with SingleTickerProviderStateMixin {
  // Dybamics
  Map<String, dynamic>? _userData;
  List<Product> _products = [];
  Future<ApiResponse>? _futureProducts;
  String? Token;
  late final AnimationController _shimmerController;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      setState(() {
        Token = token;
        _futureProducts = fetchData(token);
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
    final String url = 'https://retilda-fintech-3jy7.onrender.com/Api/products';

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
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadUserData();
    //_futureProducts = _loadProducts();
    super.initState();
  }

  @override
  void dispose() {
    searchcontroller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  TextEditingController searchcontroller = TextEditingController();
  void _retryFetch() {
    if (Token != null) {
      setState(() {
        _futureProducts = fetchData(Token!);
      });
    }
  }

  Widget _shimmerBox(
      {double height = 16,
      double width = double.infinity,
      BorderRadius? radius}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: radius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
                Colors.grey.shade300,
              ],
              begin: Alignment(-1 - (_shimmerController.value * 2), -0.3),
              end: Alignment(1 + (_shimmerController.value * 2), 0.3),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF5F7FB);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          body: RefreshIndicator(
            onRefresh: () async {
              if (Token != null) {
                setState(() {
                  _futureProducts = fetchData(Token!);
                });
              }
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: pageBg,
                  elevation: 0,
                  floating: true,
                  pinned: true,
                  snap: false,
                  toolbarHeight: 40,
                  titleSpacing: 16,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CustomText(
                      //   "Retilda Market",
                      //   fontSize: 14.sp,
                      //   fontWeight: FontWeight.w700,
                      //   color: RButtoncolor,
                      // ),
                      const SizedBox(height: 8),
                      // GestureDetector(
                      //   onTap: () {
                      //     Navigator.push(context,
                      //         MaterialPageRoute(builder: (_) => Allproducts()));
                      //   },
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(14),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.black12.withOpacity(0.05),
                      //           blurRadius: 12,
                      //           offset: const Offset(0, 6),
                      //         ),
                      //       ],
                      //     ),
                      //     padding: const EdgeInsets.symmetric(horizontal: 10),
                      //     child: SearchContainer(controller: searchcontroller),
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // Carousel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 28.h,
                        child: CarouselPageView(),
                      ),
                    ),
                  ),
                ),

                // Top Categories Heading
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          "Curated categories",
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: RButtoncolor,
                        ),
                        Icon(Icons.auto_awesome_rounded,
                            color: ROrange, size: 20.sp),
                      ],
                    ),
                  ),
                ),

                // Category List
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 20.h,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _futureProducts == null
                          ? const Center(child: CircularProgressIndicator())
                          : FutureBuilder<ApiResponse>(
                              future: _futureProducts,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (_, __) => Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: _shimmerBox(
                                              height: 90, width: 100),
                                        ),
                                        const SizedBox(height: 10),
                                        _shimmerBox(
                                            height: 20,
                                            width: 80,
                                            radius:
                                                BorderRadius.circular(10)),
                                      ],
                                    ),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
                                    itemCount: 6,
                                  );
                                } else if (snapshot.hasError) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.redAccent),
                                      const SizedBox(height: 8),
                                      const Text("Error loading categories"),
                                      TextButton.icon(
                                        onPressed: _retryFetch,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text("Retry"),
                                      )
                                    ],
                                  );
                                } else if (snapshot.hasData) {
                                  final List<Product> products =
                                      snapshot.data!.data;
                                  Map<String, Product> categoryProductMap = {};

                                  for (var product in products) {
                                    for (var category in product.categories) {
                                      if (!categoryProductMap
                                          .containsKey(category)) {
                                        categoryProductMap[category] = product;
                                      }
                                    }
                                  }

                                  final categories =
                                      categoryProductMap.entries.toList();

                                  return AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 350),
                                    child: ListView.separated(
                                      key: ValueKey(categories.length),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.length,
                                      itemBuilder: (context, index) {
                                        var entry = categories[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CategoryProductsPage(
                                                        category: entry.key),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              TweenAnimationBuilder<double>(
                                                tween: Tween(begin: 0.9, end: 1),
                                                duration: Duration(
                                                    milliseconds:
                                                        400 + (index * 40)),
                                                curve: Curves.easeOutBack,
                                                builder:
                                                    (context, value, child) {
                                                  return Transform.scale(
                                                    scale: value,
                                                    child: child,
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        entry.value.images
                                                                .isNotEmpty
                                                            ? entry.value
                                                                .images[0]
                                                            : 'https://images.unsplash.com/photo-1542293787938-4d273c38f5bb?auto=format&fit=crop&w=400&q=60',
                                                    height: 90,
                                                    width: 100,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        Container(
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2)),
                                                    ),
                                                    errorWidget: (_, __, ___) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            size: 50,
                                                            color:
                                                                Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black12
                                                          .withOpacity(0.05),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 6),
                                                    )
                                                  ],
                                                ),
                                                child: CustomText(
                                                  '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 14),
                                    ),
                                  );
                                } else {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.inbox_outlined,
                                          color: Colors.grey),
                                      const SizedBox(height: 6),
                                      const Text("No categories available"),
                                    ],
                                  );
                                }
                              },
                            ),
                    ),
                  ),
                ),

                // Product Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flash_on_rounded,
                                color: ROrange, size: 18.sp),
                            const SizedBox(width: 6),
                            CustomText(
                              "Hot picks for you",
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: RButtoncolor,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => Allproducts()));
                          },
                          child: Row(
                            children: [
                              CustomText(
                                "View all",
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: RButtoncolor,
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  color: RButtoncolor, size: 16.sp),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Products Grid
                SliverToBoxAdapter(
                  child: _futureProducts != null
                      ? FutureBuilder<ApiResponse>(
                          future: _futureProducts,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: GridView.builder(
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: 6,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.9,
                                  ),
                                  itemBuilder: (_, __) => Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _shimmerBox(
                                            height: 110,
                                            width: double.infinity,
                                            radius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(14))),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _shimmerBox(
                                                  height: 16,
                                                  width: 120,
                                                  radius:
                                                      BorderRadius.circular(
                                                          10)),
                                              const SizedBox(height: 8),
                                              _shimmerBox(
                                                  height: 14,
                                                  width: 80,
                                                  radius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else if (snapshot.hasError || !snapshot.hasData) {
                              return Column(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.redAccent, size: 32),
                                  const SizedBox(height: 8),
                                  const Text("Error loading products"),
                                  TextButton.icon(
                                    onPressed: _retryFetch,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Retry"),
                                  )
                                ],
                              );
                            }

                            final products =
                                snapshot.data!.data.take(10).toList();
                            if (products.isEmpty) {
                              return Column(
                                children: const [
                                  Icon(Icons.inventory_2_outlined,
                                      color: Colors.grey, size: 32),
                                  SizedBox(height: 6),
                                  Text("No products found"),
                                ],
                              );
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: GridView.builder(
                                  key: ValueKey(products.length),
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: products.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.9,
                                  ),
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.92, end: 1),
                                      duration: Duration(
                                          milliseconds: 400 + (index * 50)),
                                      curve: Curves.easeOutBack,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                            scale: value, child: child);
                                      },
                                      child: ProductCard2(
                                        product: product,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProductDetails(
                                                      product: product),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        );
      },
    );
  }
}
