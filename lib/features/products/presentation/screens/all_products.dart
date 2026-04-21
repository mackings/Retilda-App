import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Products/searchresults.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/categorymodel.dart';
import 'package:retilda/model/products.dart';
import 'package:sizer/sizer.dart';

class Allproducts extends ConsumerStatefulWidget {
  const Allproducts({Key? key}) : super(key: key);

  @override
  _AllproductsState createState() => _AllproductsState();
}

class _AllproductsState extends ConsumerState<Allproducts> {
  late List<Product> _products = [];
  late List<String> _categories = [];
  late final ApiClient _apiClient;
  bool _isLoading = true;

  String _selectedSortOption = 'lower_to_highest';
  String _selectedFilterOption = 'category';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _apiClient = ref.read(apiClientProvider);
    _loadUserData();
  }

  Future<ApiCategoryResponse<List<String>>> fetchCategories(
      String token) async {
    try {
      final response = await _apiClient.get('products/allcategory');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final ApiCategoryResponse<List<String>> apiResponse =
            ApiCategoryResponse.fromJson(responseData, (data) {
          return List<String>.from(data);
        });

        return apiResponse;
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      throw error;
    }
  }

  Future<ApiResponse> fetchData(String token) async {
    try {
      final response = await _apiClient.get('products');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final ApiResponse apiResponse = ApiResponse.fromJson(responseData);
        return apiResponse;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      throw error;
    }
  }

  Future<void> _loadUserData() async {
    final token = await AppSession().userToken();
    if (token != null) {
      fetchData(token).then((apiResponse) {
        setState(() {
          _products = apiResponse.data;
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
      });

      fetchCategories(token).then((apiResponse) {
        setState(() {
          _categories = apiResponse.data;
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  Future<void> fetchProductsByCategory(String category) async {
    try {
      final response = await _apiClient.get(
        'products/category/${Uri.encodeComponent(category)}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final ApiResponse apiResponse = ApiResponse.fromJson(responseData);

        setState(() {
          _products = apiResponse.data;
          _selectedCategory = category;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {}
  }

  void _showCategoriesDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool _sortEnabled = _selectedFilterOption != null;

            return Scaffold(
              appBar: AppBar(
                title: CustomText(
                  'Filter',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const CustomText('Category'),
                      value: 'category',
                      groupValue: _selectedFilterOption,
                      onChanged: (value) {
                        setModalState(() {
                          _selectedFilterOption = value!;
                          _sortEnabled = true;
                        });
                        setState(() {
                          _selectedFilterOption = value!;
                          _selectedCategory = null;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    CustomText(
                      'Sort by',
                    ),
                    RadioListTile<String>(
                      title: const CustomText('Lower to Highest Price'),
                      value: 'lower_to_highest',
                      groupValue: _selectedSortOption,
                      onChanged: _sortEnabled
                          ? (value) {
                              setModalState(() {
                                _selectedSortOption = value!;
                              });
                              setState(() {
                                _selectedSortOption = value!;
                              });
                            }
                          : null,
                    ),
                    RadioListTile<String>(
                      title: const Text('Highest to Lower Price'),
                      value: 'highest_to_lower',
                      groupValue: _selectedSortOption,
                      onChanged: _sortEnabled
                          ? (value) {
                              setModalState(() {
                                _selectedSortOption = value!;
                              });
                              setState(() {
                                _selectedSortOption = value!;
                              });
                            }
                          : null,
                    ),
                    SizedBox(height: 10),
                    CustomText(
                      'Categories',
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _categories.map((category) {
                            return ChoiceChip(
                              label: CustomText(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedCategory =
                                      selected ? category : null;
                                });
                                setState(() {
                                  _selectedCategory =
                                      selected ? category : null;
                                  if (_selectedCategory != null) {
                                    fetchProductsByCategory(category);
                                    Timer(Duration(seconds: 2), () {
                                      Navigator.pop(context);
                                    });
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    TextEditingController _searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Search Products'),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'Enter search term'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Search'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SearchPage()));
                // Navigator.pop(context);
                // _searchProducts(context, _searchController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _searchProducts(BuildContext context, String query) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      final response = await _apiClient.get(
        'products/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonResponse);
        final List<Product> searchResults = apiResponse.data;

        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchResultsScreen(searchResults: searchResults),
          ),
        );
      } else {
        Navigator.pop(context);
        _showErrorDialog(context, 'Failed to load products');
      }
    } catch (error) {
      Navigator.pop(context);
      _showErrorDialog(context, 'An error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color pageBg = const Color(0xFFF6F7FB);
    final Color accent = const Color(0xFFFB9324);

    List<Product> displayedProducts = List.from(_products);
    if (_selectedSortOption == 'lower_to_highest') {
      displayedProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSortOption == 'highest_to_lower') {
      displayedProducts.sort((a, b) => b.price.compareTo(a.price));
    }

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          body: _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    child: LinearProgressIndicator(),
                  ),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      snap: false,
                      backgroundColor: pageBg,
                      elevation: 0,
                      title: CustomText(
                        "Marketplace",
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchPage()));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_alt_outlined),
                          onPressed: () {
                            _showCategoriesDrawer(context);
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF103C57),
                                const Color(0xFF145E8D),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      "Curated picks",
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(height: 6),
                                    CustomText(
                                      "Find your next purchase with secure checkout and rewards.",
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _pillStat(
                                            "${_products.length}", "products"),
                                        const SizedBox(width: 8),
                                        _pillStat("${_categories.length}",
                                            "categories"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_vert_rounded,
                                        color: Color(0xFF103C57)),
                                    const SizedBox(width: 6),
                                    CustomText(
                                      _selectedSortOption == 'highest_to_lower'
                                          ? "High to Low"
                                          : "Low to High",
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF103C57),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final bool isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: accent,
                              backgroundColor: Colors.white,
                              onSelected: (selected) {
                                if (selected) {
                                  fetchProductsByCategory(cat);
                                } else {
                                  _loadUserData();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = displayedProducts[index];
                            return ProductCard2(
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
                            );
                          },
                          childCount: displayedProducts.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
        );
      },
    );
  }
}

Widget _pillStat(String value, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          value,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        const SizedBox(width: 6),
        CustomText(
          label,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      ],
    ),
  );
}
