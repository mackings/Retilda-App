import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retilda/model/categorymodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class UploadProducts extends ConsumerStatefulWidget {
  const UploadProducts({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UploadProductsState();
}

class _UploadProductsState extends ConsumerState<UploadProducts> {
  String? _token;
  String? _userId;
  bool isLoading = false;
  bool isLoadingCategories = false;

  List<String> categories = [];
  String? selectedCategory;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      String userId = userData['data']['user']['_id'];
      setState(() {
        _token = token;
        _userId = userId;
        print(" Token >>>> $_token");
      });
      await fetchAndSetCategories();
    } else {
      setState(() {});
    }
  }

  File? image1, image2, image3;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controllers for form inputs
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController specificationController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  TextEditingController categoriesController = TextEditingController();

  Future<ApiCategoryResponse<List<String>>> fetchCategories(
      String token) async {
    final String url = 'https://retilda.onrender.com/Api/products/allcategory';

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

  Future<void> fetchAndSetCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      final response = await fetchCategories(_token ?? '');
      setState(() {
        categories = response.data ?? [];
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $error')),
      );
    } finally {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> addNewCategory() async {
    final TextEditingController newCategoryController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextFormField(
            controller: newCategoryController,
            decoration: InputDecoration(labelText: 'New Category'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newCategory = newCategoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  setState(() {
                    categories.add(newCategory);
                    selectedCategory = newCategory;
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future pickImage(int imageNumber) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        if (imageNumber == 1) {
          image1 = File(pickedFile.path);
        } else if (imageNumber == 2) {
          image2 = File(pickedFile.path);
        } else if (imageNumber == 3) {
          image3 = File(pickedFile.path);
        }
      }
    });
  }

  Future<void> uploadProduct() async {
    String unformattedPrice =
        priceController.text.replaceAll(RegExp(r'[^\d]'), '');

    setState(() {
      isLoading = true;
    });

    var url = Uri.parse('https://retilda.onrender.com/Api/uploadproduct');
    var request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $_token';

    request.fields['name'] = nameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['specification'] = specificationController.text;
    request.fields['brand'] = brandController.text;
    request.fields['price'] = unformattedPrice;
    request.fields['availableStock'] = "1000";
    request.fields['categories'] = selectedCategory ?? '';

    if (image1 != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image1', image1!.path));
    }
    if (image2 != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image2', image2!.path));
    }
    if (image3 != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image3', image3!.path));
    }

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product Uploaded Successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload product: $responseBody')),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    _loadUserData();
    // fetchAndSetCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, deviceType, orientation) {
      return Scaffold(
        appBar: AppBar(
            title: Text(
          'Upload Product',
          style:
              GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w500),
        )),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Text Form Fields
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: specificationController,
                      decoration: InputDecoration(labelText: 'Specification'),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: brandController,
                      decoration: InputDecoration(labelText: 'Brand'),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        PriceInputFormatter()
                      ], // Add the formatter here
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isLoadingCategories
                        ? CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: selectedCategory,
                            items: [
                              ...categories.map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  )),
                              DropdownMenuItem(
                                value: 'add_new',
                                child: Text('Add New Category'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == 'add_new') {
                                addNewCategory();
                              } else {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                            decoration:
                                InputDecoration(labelText: 'Categories'),
                          ),
                  ),

                  SizedBox(height: 20),

                  // Image Pickers with background images
                  Row(
                    children: [
                      Text(
                        "Attach Product Images",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, fontSize: 13.sp),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImagePicker(image1, () => pickImage(1), 'Image 1'),
                      _buildImagePicker(image2, () => pickImage(2), 'Image 2'),
                      _buildImagePicker(image3, () => pickImage(3), 'Image 3'),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Upload Button with loading state
                  ElevatedButton(
                    onPressed: isLoading ? null : uploadProduct,
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Upload Product'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

Widget _buildImagePicker(File? image, VoidCallback onTap, String label) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 25.w,
      height: 12.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 0.5),
        image: image != null
            ? DecorationImage(
                image: FileImage(image),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: image == null
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_file),
                SizedBox(
                  height: 2.h,
                ),
                Text(label, style: GoogleFonts.poppins()),
              ],
            ))
          : null,
    ),
  );
}

class PriceInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters from the input
    final intSelection =
        int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intSelection == null) return oldValue;

    // Format the input value
    final formattedString = _formatter.format(intSelection);

    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}
