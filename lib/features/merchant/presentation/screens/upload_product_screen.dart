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
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/categorymodel.dart';

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

  File? image1, image2, image3;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController specificationController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController categoriesController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();

  Future<void> _loadUserData() async {
    final session = AppSession();
    final userData = await session.userData();
    final token = await session.userToken();
    if (userData != null && token != null) {
      await fetchAndSetCategories();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<ApiCategoryResponse<List<String>>> fetchCategories() async {
    final response = await _apiClient.get('products/allcategory');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return ApiCategoryResponse.fromJson(responseData, (data) {
        return List<String>.from(data);
      });
    }
    throw Exception('Failed to load categories');
  }

  Future<void> fetchAndSetCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      final response = await fetchCategories();
      if (!mounted) return;
      setState(() {
        categories = response.data;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> addNewCategory() async {
    final TextEditingController newCategoryController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: TextFormField(
                controller: newCategoryController,
                decoration: const InputDecoration(labelText: 'New Category'),
                onChanged: (_) => setModalState(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: newCategoryController.text.trim().isEmpty
                      ? null
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
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> pickImage(int imageNumber) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
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
    final unformattedPrice =
        priceController.text.replaceAll(RegExp(r'[^\d]'), '');

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
        const SnackBar(
          content: Text('Please fill in all fields before uploading'),
        ),
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
        const SnackBar(content: Text('Product Uploaded Successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload product')),
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
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    specificationController.dispose();
    brandController.dispose();
    priceController.dispose();
    stockController.dispose();
    categoriesController.dispose();
    heightController.dispose();
    weightController.dispose();
    widthController.dispose();
    lengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: AppTheme.surface,
        titleSpacing: 16,
        title: Text(
          'Upload product',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.ocean.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _MerchantHero(),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Product details',
                  subtitle:
                      'Add the core catalogue fields for the new merchant listing.',
                ),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    _LabeledField(
                      label: 'Name',
                      controller: nameController,
                      hintText: 'Product name',
                    ),
                    _gap,
                    _LabeledField(
                      label: 'Description',
                      controller: descriptionController,
                      hintText: 'Describe the product',
                      maxLines: 3,
                    ),
                    _gap,
                    _LabeledField(
                      label: 'Specification',
                      controller: specificationController,
                      hintText: 'Enter product specification',
                      maxLines: 3,
                    ),
                    _gap,
                    _LabeledField(
                      label: 'Brand',
                      controller: brandController,
                      hintText: 'Brand name',
                    ),
                    _gap,
                    _LabeledField(
                      label: 'Price',
                      controller: priceController,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [PriceInputFormatter()],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Dimensions',
                  subtitle:
                      'Capture the physical measurements used for fulfillment.',
                ),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Height',
                            controller: heightController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Weight',
                            controller: weightController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _gap,
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Width',
                            controller: widthController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Length',
                            controller: lengthController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Category and media',
                  subtitle:
                      'Choose a category and attach up to three product images.',
                ),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        isLoadingCategories
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<String>(
                                initialValue: selectedCategory,
                                items: [
                                  ...categories.map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  ),
                                  const DropdownMenuItem(
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
                                decoration: const InputDecoration(
                                  hintText: 'Select a category',
                                ),
                              ),
                      ],
                    ),
                    _gap,
                    Row(
                      children: [
                        Expanded(
                          child: _ImagePickerCard(
                            image: image1,
                            onTap: () => pickImage(1),
                            label: 'Image 1',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ImagePickerCard(
                            image: image2,
                            onTap: () => pickImage(2),
                            label: 'Image 2',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ImagePickerCard(
                            image: image3,
                            onTap: () => pickImage(3),
                            label: 'Image 3',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : uploadProduct,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      isLoading ? 'Uploading product...' : 'Upload product',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _gap = SizedBox(height: 12);

class _MerchantHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3452), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'Create a merchant listing',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add catalogue details, dimensions, category, and media for a new product.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.52),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final String label;

  const _ImagePickerCard({
    required this.image,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
          image: image != null
              ? DecorationImage(
                  image: FileImage(image!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: AppTheme.ocean),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
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

    final intSelection =
        int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intSelection == null) return oldValue;

    final formattedString = _formatter.format(intSelection);

    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}
