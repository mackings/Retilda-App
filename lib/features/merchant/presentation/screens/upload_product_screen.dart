import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/categorymodel.dart';
import 'package:sizer/sizer.dart';

class UploadProducts extends ConsumerStatefulWidget {
  const UploadProducts({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UploadProductsState();
}

class _UploadProductsState extends ConsumerState<UploadProducts> {
  bool isLoading = false;
  bool isLoadingCategories = false;
  late final ApiClient _apiClient;

  List<String> categories = [];
  String? selectedCategory;

  Future<void> _loadUserData() async {
    final session = AppSession();
    final userData = await session.userData();
    final token = await session.userToken();
    if (userData != null && token != null) {
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
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController lengthController = TextEditingController();

  Future<ApiCategoryResponse<List<String>>> fetchCategories() async {
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

  Future<void> fetchAndSetCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      final response = await fetchCategories();
      setState(() {
        categories = response.data;
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Category'),
              content: TextFormField(
                controller: newCategoryController,
                decoration: InputDecoration(labelText: 'New Category'),
                onChanged: (value) => setState(() {}), // Update UI on change
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: newCategoryController.text.trim().isEmpty
                      ? null // Disable if empty
                      : () {
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
    // Trim and extract price
    String unformattedPrice =
        priceController.text.replaceAll(RegExp(r'[^\d]'), '');

    // Check for empty fields
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        specificationController.text.trim().isEmpty ||
        brandController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        selectedCategory == null ||
        heightController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty ||
        widthController.text.trim().isEmpty ||
        lengthController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields before uploading')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final filePaths = <String, String>{};
    if (image1 != null) {
      filePaths['image1'] = image1!.path;
    }
    if (image2 != null) {
      filePaths['image2'] = image2!.path;
    }
    if (image3 != null) {
      filePaths['image3'] = image3!.path;
    }

    final response = await _apiClient.multipart(
      'POST',
      'uploadproduct',
      fields: {
        'name': nameController.text,
        'description': descriptionController.text,
        'specification': specificationController.text,
        'brand': brandController.text,
        'price': unformattedPrice,
        'availableStock': '1000',
        'categories': selectedCategory ?? '',
        'height': heightController.text,
        'weight': weightController.text,
        'width': widthController.text,
        'length': lengthController.text,
      },
      filePaths: filePaths,
    );

    if (!mounted) return;
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product Uploaded Successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload product')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    _apiClient = ref.read(apiClientProvider);
    _loadUserData();
    // fetchAndSetCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, deviceType, orientation) {
      return Scaffold(
        backgroundColor: Colors.white,
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
                    child: TextFormField(
                      controller: heightController,
                      decoration: InputDecoration(labelText: 'Height'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: weightController,
                      decoration: InputDecoration(labelText: 'Weight'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: widthController,
                      decoration: InputDecoration(labelText: 'Width'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: lengthController,
                      decoration: InputDecoration(labelText: 'Length'),
                      keyboardType: TextInputType.number,
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
