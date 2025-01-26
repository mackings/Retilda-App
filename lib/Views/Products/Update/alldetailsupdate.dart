import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retilda/model/products.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';





class UpdateAllDetails extends StatefulWidget {
  final Product product;

  const UpdateAllDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<UpdateAllDetails> createState() => _UpdateAllDetailsState();
}

class _UpdateAllDetailsState extends State<UpdateAllDetails> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  String? token;

  final Map<String, TextEditingController> _controllers = {};
  final List<File?> _selectedImages = [null, null, null];

  final List<Map<String, dynamic>> _fields = [
    {'label': 'Name', 'key': 'name', 'type': TextInputType.text},
    {'label': 'Price', 'key': 'price', 'type': TextInputType.number},
    {'label': 'Description', 'key': 'description', 'type': TextInputType.text},
    {'label': 'Specification', 'key': 'specification', 'type': TextInputType.text},
    {'label': 'Brand', 'key': 'brand', 'type': TextInputType.text},
    {'label': 'Categories', 'key': 'categories', 'type': TextInputType.text},
    {'label': 'Available Stock', 'key': 'availableStock', 'type': TextInputType.number},
    {'label': 'Weight', 'key': 'weight', 'type': TextInputType.number},
    {'label': 'Width', 'key': 'width', 'type': TextInputType.number},
    {'label': 'Height', 'key': 'height', 'type': TextInputType.number},
    {'label': 'Length', 'key': 'length', 'type': TextInputType.number},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    for (var field in _fields) {
      final key = field['key'];
      _controllers[key] = TextEditingController(
        text: _getInitialValue(key),
      );
    }
  }

  String _getInitialValue(String key) {
    switch (key) {
      case 'name':
        return widget.product.name;
      case 'price':
        return widget.product.price.toString();
      case 'description':
        return widget.product.description ?? '';
      case 'specification':
        return widget.product.specification ?? '';

      case 'categories':
        return widget.product.categories[0] ?? '';
      default:
        return '';
    }

  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        token = userData['data']['token'];
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages[index] = File(image.path);
      });
    }
  }



Future<void> _updateProduct() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    loading = true;
  });

  final url = Uri.parse(
      'https://retilda-fintech.onrender.com/Api/products/update/${widget.product.id}');
  final headers = {
    'Authorization': 'Bearer $token',
  };

  try {
    final request = http.MultipartRequest('PUT', url);
    request.headers.addAll(headers);

    // Add form fields
    for (var field in _fields) {
      request.fields[field['key']] = field['type'] == TextInputType.number
          ? int.tryParse(_controllers[field['key']]!.text)?.toString() ?? '0'
          : _controllers[field['key']]!.text;
    }

    // Add images to the request
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image${i + 1}', // Image field names must match the API requirement
          _selectedImages[i]!.path,
        ));
      }
    }

    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Product updated successfully!'),
        backgroundColor: Colors.green,
      ));
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update product: ${error['message']}'),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
    ));
  } finally {
    setState(() {
      loading = false;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Update Product Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._fields.map((field) {
                return TextFormField(
                  controller: _controllers[field['key']],
                  keyboardType: field['type'],
                  decoration: InputDecoration(labelText: field['label']),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter ${field['label'].toLowerCase()}'
                      : null,
                );
              }).toList(),

              Padding(
                padding: const EdgeInsets.only(top: 20,bottom: 20),
                child: Text('Select New Images:'),
              ),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Adjusts spacing between items
  children: List.generate(3, (index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Column(
        children: [
          _selectedImages[index] != null
              ? Image.file(
                  _selectedImages[index]!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[300],
                  child: Icon(Icons.add_a_photo),
                ),
          SizedBox(height: 10), // Space below each image
        ],
      ),
    );
  }),
),


              SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : _updateProduct,
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Update Product'),
              ),


            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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