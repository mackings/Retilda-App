import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Products/Update/alldetailsupdate.dart';
import 'package:retilda/Views/Products/Update/searchupdate.dart';
import 'package:retilda/Views/Products/Update/updatedetails.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Products/searchresults.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/categorymodel.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class Producupdate extends ConsumerStatefulWidget {
  const Producupdate({Key? key}) : super(key: key);

  @override
  _ProducupdateState createState() => _ProducupdateState();
}

class _ProducupdateState extends ConsumerState<Producupdate> {
  static const Color _pageBg = Color(0xFFF6F7FB);
  static const Color _deepBlue = Color(0xFF103C57);
  static const Color _cardBlue = Color(0xFF145E8D);

  late List<Product> _products = [];
  late List<String> _categories = [];
  late String _token;
  bool _isLoading = true;

  String _selectedSortOption = 'lower_to_highest';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<ApiCategoryResponse<List<String>>> fetchCategories(
      String token) async {
    final String url =
        'https://retildaserver.vercel.app/Api/products/allcategory';

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
        final ApiCategoryResponse<List<String>> apiResponse =
            ApiCategoryResponse.fromJson(responseData, (data) {
          return List<String>.from(data);
        });

        print(apiResponse.data);
        return apiResponse;
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }

  Future<ApiResponse> fetchData(String token) async {
    final String url = 'https://retildaserver.vercel.app/Api/products';

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
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
        print('Error fetching products: $error');
      });

      fetchCategories(token).then((apiResponse) {
        setState(() {
          _categories = apiResponse.data;
          _isLoading = false;
        });
      }).catchError((error) {
        print('Error fetching categories: $error');
        setState(() {
          _isLoading = false;
        });
      });

      print("categories >>> $_categories");
    }
  }

  Future<void> fetchProductsByCategory(String category) async {
    final String url =
        'https://retildaserver.vercel.app/Api/products/category/$category';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
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
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showCategoriesDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            'Sort & Filter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _deepBlue,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                _selectedSortOption = 'lower_to_highest';
                                _selectedCategory = null;
                              });
                              setState(() {
                                _selectedSortOption = 'lower_to_highest';
                                _selectedCategory = null;
                        });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomText(
                        'Price',
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FilterPill(
                            label: 'Low → High',
                            selected: _selectedSortOption == 'lower_to_highest',
                            onTap: () {
                              setModalState(() {
                                _selectedSortOption = 'lower_to_highest';
                              });
                              setState(() {
                                _selectedSortOption = 'lower_to_highest';
                              });
                            },
                          ),
                          _FilterPill(
                            label: 'High → Low',
                            selected: _selectedSortOption == 'highest_to_lower',
                            onTap: () {
                              setModalState(() {
                                _selectedSortOption = 'highest_to_lower';
                              });
                              setState(() {
                                _selectedSortOption = 'highest_to_lower';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          CustomText(
                            'Categories',
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ROrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomText(
                              '${_categories.length}',
                              fontWeight: FontWeight.w700,
                              color: ROrange,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _categories.map((category) {
                              return FilterChip(
                                selectedColor: ROrange.withOpacity(0.12),
                                checkmarkColor: ROrange,
                                label: CustomText(
                                  category,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedCategory == category
                                      ? ROrange
                                      : Colors.grey[800],
                                ),
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
                                      Timer(const Duration(seconds: 1), () {
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
                      const SizedBox(height: 6),
                    ],
                  ),
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
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  ROrange.withOpacity(0.04),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ROrange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.red),
                ),
                const SizedBox(height: 12),
                CustomText(
                  'Something went wrong',
                  fontWeight: FontWeight.w700,
                  color: _deepBlue,
                ),
                const SizedBox(height: 8),
                CustomText(
                  message,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: _deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    TextEditingController _searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  _pageBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ROrange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.search, color: ROrange),
                    ),
                    const SizedBox(width: 12),
                    CustomText(
                      'Search inventory',
                      fontWeight: FontWeight.w800,
                      color: _deepBlue,
                      fontSize: 12.sp,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Try “Wireless earbuds”',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RButtoncolor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchPage(),
                        ),
                      );
                    },
                    child: const Text('Search'),
                  ),
                )
              ],
            ),
          ),
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
      final response = await http.get(
        Uri.parse(
          'https://retildaserver.vercel.app/api/products/search?q=$query',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonResponse);
        final List<Product> searchResults = apiResponse.data;

        Navigator.pop(context);

        print("Search results >>> $searchResults");

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
    final List<Product> displayedProducts = List<Product>.from(_products);
    if (_selectedSortOption == 'lower_to_highest') {
      displayedProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSortOption == 'highest_to_lower') {
      displayedProducts.sort((a, b) => b.price.compareTo(a.price));
    }

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          extendBodyBehindAppBar: false,
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: _pageBg,
            elevation: 0,
            titleSpacing: 0,
            title: CustomText(
              "Manage Inventory",
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: _deepBlue,
            ),
            actions: [
              _AppBarAction(
                icon: Icons.search,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SearchUpdate()));
                },
              ),
              _AppBarAction(
                icon: Icons.tune_rounded,
                onTap: () {
                  _showCategoriesDrawer(context);
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _deepBlue.withOpacity(0.9),
                            _cardBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const LinearProgressIndicator(
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_deepBlue, _cardBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              "Inventory hub",
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            CustomText(
                              "Quickly tweak pricing, categories and details.",
                              color: Colors.white70,
                              fontSize: 10.5.sp,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _StatPill(
                                  label: "Products",
                                  value: _products.length.toString(),
                                ),
                                const SizedBox(width: 10),
                                _StatPill(
                                  label: "Categories",
                                  value: _categories.length.toString(),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Low → High'),
                                  selected:
                                      _selectedSortOption == 'lower_to_highest',
                                  selectedColor: ROrange.withOpacity(0.16),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedSortOption = 'lower_to_highest';
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('High → Low'),
                                  selected:
                                      _selectedSortOption == 'highest_to_lower',
                                  selectedColor: ROrange.withOpacity(0.16),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedSortOption = 'highest_to_lower';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _deepBlue,
                              elevation: 0,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Filters'),
                            onPressed: () => _showCategoriesDrawer(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: displayedProducts.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: GestureDetector(
                                onLongPress: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UpdateAllDetails(
                                        product: displayedProducts[index],
                                      ),
                                    ),
                                  );
                                },
                
                                child: ProductCard2(
                                  product: displayedProducts[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UpdateDetails(
                                          product: displayedProducts[index],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

        );
      },
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, color: _ProducupdateState._deepBlue),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            value,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          CustomText(
            label,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ROrange.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ROrange : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.price_change_rounded,
              size: 18,
              color: selected ? ROrange : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            CustomText(
              label,
              fontWeight: FontWeight.w700,
              color: selected ? ROrange : Colors.grey[800],
            ),
          ],
        ),
      ),
    );
  }
}
