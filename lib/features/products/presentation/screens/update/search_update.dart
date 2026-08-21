import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Products/Update/alldetailsupdate.dart';
import 'package:retilda/Views/Products/Update/updatedetails.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/products.dart';
import 'package:sizer/sizer.dart';

class SearchUpdate extends StatefulWidget {
  const SearchUpdate({super.key});

  @override
  State<SearchUpdate> createState() => _SearchUpdateState();
}

class _SearchUpdateState extends State<SearchUpdate> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? token;
  late final ApiClient _apiClient = ApiClient(session: AppSession());

  Future<void> _loadUserData() async {
    final loadedToken = await AppSession().userToken();
    if (loadedToken != null) {
      setState(() {
        token = loadedToken;
      });
    }
  }

  void _searchProducts(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.get(
        'products/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonResponse);
        final List<Product> searchResults = apiResponse.data;

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchUpdateResultsScreen(searchResults: searchResults),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(context, 'Product Not Found');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(context, 'An error occurred');
    }
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

  @override
  void initState() {
    _loadUserData();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: CustomText(
          'Search',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for Products',
                    hintStyle: GoogleFonts.poppins(),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.search,
                        color: ROrange,
                      ),
                      onPressed: () {
                        _searchProducts(_searchController.text);
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            _isLoading
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: LinearProgressIndicator(),
                  ))
                : Container(),
          ],
        ),
      ),
    );
  }
}

class SearchUpdateResultsScreen extends StatelessWidget {
  final List<Product> searchResults;

  const SearchUpdateResultsScreen({super.key, required this.searchResults});

  void _openPriceUpdate(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateDetails(product: product),
      ),
    );
  }

  void _openFullUpdate(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateAllDetails(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: searchResults.isEmpty
          ? Center(child: Text('No products found'))
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final product = searchResults[index];
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () {
                      _openPriceUpdate(context, product);
                    },
                    onLongPress: () {
                      _openFullUpdate(context, product);
                    },
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        _openPriceUpdate(context, product);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
