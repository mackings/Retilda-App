import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:retilda/model/products.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sizer/sizer.dart';




class UpdateDetails extends StatefulWidget {
  final Product product;

  const UpdateDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<UpdateDetails> createState() => _UpdateDetailsState();
}

class _UpdateDetailsState extends State<UpdateDetails> {

  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();


  List<CartItem> cartItems = [];

  @override
  void initState() {

    _loadUserData();
    Timer(Duration(seconds: 20), () {
      if (wallet == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: CustomText('Complete KYC to Continue.'),
        ));
        Navigator.pop(context);
        Navigator.pop(context);
      } else {}
    });
    super.initState();

  }



  Future<void> _loadUserData() async {

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String Token = userData['data']['token'];
      String UserId = userData['data']['user']['_id'];
      String Wallet = userData['data']['user']['wallet']['accountNumber'];


      setState(() {
        token = Token;
        userId = UserId;
        productId = widget.product.id;
        wallet = Wallet;
      });

      print("User ID>> $userId");
      print("Product ID >> $productId");
      print("All User>> $userData");

    }
  }

    Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    String rawPrice = _priceController.text.replaceAll(",", "");
    String url =
        "https://retilda.onrender.com/Api/updateProductByPrice/${widget.product.id}";

    Map<String, dynamic> body = {
      "price": rawPrice,
      "description": widget.product.description.toString(),
    };

    try {
      var response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Product updated successfully!"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to update product: ${response.body}"),
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $error"),
      ));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }


    void _showUpdatePriceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter New Price",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: "Price",
                  hintText: "Enter amount (e.g., 10,000)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a valid price";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : _updatePrice,
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Update Price"),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }



  String? productId;
  String? userId;
  int? instCount;
  String? token;
  String? userOptions;
  dynamic wallet;
  String? balance;
  String? plan;



  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: CustomText(
          "Update Overview",
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(children: [
            SizedBox(
              height: 2.h,
            ),
            SizedBox(
              height: 30.h,
              child: PageView(
                children: widget.product.images.map((image) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 35.0, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.transparent,
                      image: DecorationImage(
                        image: NetworkImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    widget.product.name,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 5),
              child: Divider(
                color: Colors.grey,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "N${NumberFormat('#,##0').format(widget.product.price)}",
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                  loading
                      ? CircularProgressIndicator()
                      : GestureDetector(
                          onTap: () {
                            _showUpdatePriceModal(context);
                          },
                          child: Container(
                            height: 6.h,
                            width: 50.w,
                            decoration: BoxDecoration(
                              color: RButtoncolor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: CustomText(
                                "Update Product",
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            SizedBox(
              height: 2.h,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 20),
              child: Row(
                children: [
                  CustomText(
                    "Product Description :",
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 2.h,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 1),
              child: ListTile(
                title: CustomText(
                  widget.product.description.toString(),
                  fontSize: 12.sp,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 20),
              child: Row(
                children: [
                  CustomText(
                    "Product Specifications :",
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 1),
              child: ListTile(
                title: CustomText(
                  widget.product.specification ?? "No Product Specifications",
                  fontSize: 12.sp,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    });
  }
}





class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,##0");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    String newText = newValue.text.replaceAll(",", "");
    String formatted = _formatter.format(int.parse(newText));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}