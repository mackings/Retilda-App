import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/productcard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/products.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';



class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? token;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String Token = userData['data']['token'];
      setState(() {
        token = Token;
      });

      print("All User>> $userData");
    }
  }

  void _searchProducts(BuildContext context, String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://retilda-fintech-3jy7.onrender.com/api/products/search?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonResponse);
        final List<Product> searchResults = apiResponse.data;

        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchResultsScreen(searchResults: searchResults),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(context, 'Product Not Found');
      }
    } catch (error) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText('Search',
                      fontSize: 15.sp,
              fontWeight: FontWeight.w500,),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [


            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8)
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for Products',
                    hintStyle: GoogleFonts.poppins(),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search,color: ROrange,),
                      onPressed: () {
                        _searchProducts(context, _searchController.text);
                      },
                    ),
                  ),
                ),
              ),
            ),


            SizedBox(height: 20.h),
            
            _isLoading
                ? Center(child: Padding(
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

class SearchResultsScreen extends StatelessWidget {
  final List<Product> searchResults;

  SearchResultsScreen({required this.searchResults});

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
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetails(product: searchResults[index]),
                        ),
                      );
                    },
                    child: ProductCard(
                      product: searchResults[index],
                      onTap: () {},
                    ),
                  ),
                );
              },
            ),
    );
  }
}
