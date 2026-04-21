import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/products.dart';
import 'package:sizer/sizer.dart';

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
  late final ApiClient _apiClient = ApiClient(session: AppSession());

  final Map<String, TextEditingController> _controllers = {};
  final List<File?> _selectedImages = [null, null, null];

  final List<Map<String, dynamic>> _fields = [
    {'label': 'Name', 'key': 'name', 'type': TextInputType.text},
    {'label': 'Price', 'key': 'price', 'type': TextInputType.number},
    {'label': 'Description', 'key': 'description', 'type': TextInputType.text},
    {
      'label': 'Specification',
      'key': 'specification',
      'type': TextInputType.text
    },
    {'label': 'Brand', 'key': 'brand', 'type': TextInputType.text},
    {'label': 'Categories', 'key': 'categories', 'type': TextInputType.text},
    {
      'label': 'Available Stock',
      'key': 'availableStock',
      'type': TextInputType.number
    },
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
        return widget.product.categories.isNotEmpty
            ? widget.product.categories[0]
            : '';
      default:
        return '';
    }
  }

  Future<void> _loadUserData() async {
    final loadedToken = await AppSession().userToken();
    if (loadedToken != null) {
      setState(() {
        token = loadedToken;
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

    try {
      final fields = <String, String>{};
      for (var field in _fields) {
        fields[field['key']] = field['type'] == TextInputType.number
            ? int.tryParse(_controllers[field['key']]!.text)?.toString() ?? '0'
            : _controllers[field['key']]!.text;
      }

      final filePaths = <String, String>{};
      for (int i = 0; i < _selectedImages.length; i++) {
        if (_selectedImages[i] != null) {
          filePaths['image${i + 1}'] = _selectedImages[i]!.path;
        }
      }

      final response = await _apiClient.multipart(
        'PUT',
        'products/update/${widget.product.id}',
        auth: AuthScope.privileged,
        fields: fields,
        filePaths: filePaths,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update product'),
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
    const Color pageBg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: CustomText(
          'Update product details',
          fontWeight: FontWeight.w800,
          color: RButtoncolor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [RButtoncolor, const Color(0xFF145E8D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          widget.product.name,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          'N${NumberFormat('#,##0').format(widget.product.price)}',
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.tune_rounded,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            CustomText(
                              'Update listing details & images',
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _fields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: _controllers[field['key']],
                            keyboardType: field['type'],
                            decoration: InputDecoration(
                              labelText: field['label'],
                              filled: true,
                              fillColor: const Color(0xFFF6F7FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter ${field['label'].toLowerCase()}'
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomText(
                    'New images',
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(3, (index) {
                      return GestureDetector(
                        onTap: () => _pickImage(index),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3.7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _selectedImages[index] != null
                                    ? Image.file(
                                        _selectedImages[index]!,
                                        width: double.infinity,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: double.infinity,
                                        height: 90,
                                        color: const Color(0xFFF6F7FB),
                                        child: const Icon(
                                            Icons.add_a_photo_outlined),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                _selectedImages[index] != null
                                    ? 'Change'
                                    : 'Add photo',
                                color: RButtoncolor,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RButtoncolor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: CustomText(
                        loading ? 'Updating...' : 'Update product',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      onPressed: loading ? null : _updateProduct,
                    ),
                  ),
                ],
              ),
            ),
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
