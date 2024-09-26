import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
    } else {
      setState(() {
        //_isLoading = false;
      });
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

   setState(() {
      isLoading = true;  // Start loading
    });

    var url = Uri.parse('https://retilda.onrender.com/Api/uploadproduct');
    var request = http.MultipartRequest('POST', url);

    // Add Bearer token to the request headers
    String token = 'your_bearer_token_here'; // Replace with your actual token
    request.headers['Authorization'] = 'Bearer $_token';

    // Adding text fields
    request.fields['name'] = nameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['specification'] = specificationController.text;
    request.fields['brand'] = brandController.text;
    request.fields['price'] = priceController.text;
    request.fields['availableStock'] = stockController.text;
    request.fields['categories'] = categoriesController.text;

    // Adding images if they are not null
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

    // Sending the request
    var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Response Body: $responseBody');

    if (response.statusCode == 201) {
      print(response);
      print('Product uploaded successfully');
    } else {
      print('Failed to upload product. Status code: ${response.statusCode}');
      print(response);

    setState(() {
      isLoading = false;  // Stop loading
    });

    }
  }

  @override
  void initState() {
    _loadUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, deviceType, orientation) {
      return Scaffold(
        appBar: AppBar(title: Text('Upload Product')),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Text Form Fields
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: specificationController,
                  decoration: InputDecoration(labelText: 'Specification'),
                ),
                TextFormField(
                  controller: brandController,
                  decoration: InputDecoration(labelText: 'Brand'),
                ),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: stockController,
                  decoration: InputDecoration(labelText: 'Available Stock'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: categoriesController,
                  decoration: InputDecoration(labelText: 'Categories'),
                ),
                SizedBox(height: 20),

                // Image Pickers with background images
                Row(
                  children: [
                    Text("Attach Product Images",style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp
                    ),),
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
                    padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
                  ),
                ),
              ],
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
                SizedBox(height: 2.h,),
                Text(label, style: GoogleFonts.poppins()),
              ],
            ))
            : null,
      ),
    );
  }

