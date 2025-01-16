import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Products/Update/searchupdate.dart';
import 'package:retilda/Views/Products/Update/updatedetails.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Products/searchresults.dart';
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
  
  late List<Product> _products = [];
  late List<String> _categories = [];
  late String _token;
  bool _isLoading = true;

  String _selectedSortOption = 'lower_to_highest';
  String _selectedFilterOption = 'category';
  String? _selectedCategory;
  bool _isCategorySelected = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<ApiCategoryResponse<List<String>>> fetchCategories(
      String token) async {
    final String url = 'https://retilda-fintech.onrender.com/Api/products/allcategory';

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
        'https://retilda-fintech.onrender.com/Api/products/category/$category';
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
          _isCategorySelected = true;
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
                          _isCategorySelected = false;
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
                                  _isCategorySelected = selected;
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
      final response = await http.get(
        Uri.parse(
          'https://retilda-fintech.onrender.com/api/products/search?q=$query',
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
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: CustomText(
              "Product Update",
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                //  _showSearchDialog(context);
                                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SearchUpdate()));
                },
              ),

              IconButton(
                icon: Icon(Icons.sort),
                onPressed: () {
                  _showCategoriesDrawer(context);
                },
              ),

            ],
          ),
          body: _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    child: LinearProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            List<Product> displayedProducts =
                                List.from(_products);
                            if (_selectedSortOption == 'lower_to_highest') {
                              displayedProducts
                                  .sort((a, b) => a.price.compareTo(b.price));
                            } else if (_selectedSortOption ==
                                'highest_to_lower') {
                              displayedProducts
                                  .sort((a, b) => b.price.compareTo(a.price));
                            }

                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: GestureDetector(
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
                                child: ProductCard(
                                  product: displayedProducts[index],
                                  onTap: () {},
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
