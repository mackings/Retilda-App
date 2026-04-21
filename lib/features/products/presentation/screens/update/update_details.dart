import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Products/Update/alldetailsupdate.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:retilda/model/products.dart';
import 'package:sizer/sizer.dart';

class UpdateDetails extends StatefulWidget {
  final Product product;

  const UpdateDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<UpdateDetails> createState() => _UpdateDetailsState();
}

class _UpdateDetailsState extends State<UpdateDetails> {
  late final ApiClient _apiClient = ApiClient(session: AppSession());
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  List<CartItem> cartItems = [];

  String? productId;
  String? userId;
  int? instCount;
  String? token;
  String? userOptions;
  dynamic wallet;
  String? balance;
  String? plan;

  @override
  void initState() {
    _loadUserData();
    Timer(const Duration(seconds: 20), () {
      if (wallet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText('Complete KYC to Continue.'),
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  Future<void> _loadUserData() async {
    final session = AppSession();
    final userData = await session.userData();
    final tokenValue = await session.userToken();
    if (userData != null && tokenValue != null) {
      String userIdValue = userData['data']['user']['_id'];
      String walletValue = userData['data']['user']['wallet']['accountNumber'];

      setState(() {
        token = tokenValue;
        userId = userIdValue;
        productId = widget.product.id;
        wallet = walletValue;
      });
    }
  }

  Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    String rawPrice = _priceController.text.replaceAll(",", "");
    Map<String, dynamic> body = {
      "price": rawPrice,
      "description": widget.product.description.toString(),
    };

    try {
      final response = await _apiClient.put(
        'updateProductByPrice/${widget.product.id}',
        auth: AuthScope.privileged,
        body: body,
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Product updated successfully!"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to update product"),
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Unable to update product. Please try again."),
      ));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await _apiClient.delete(
        'products/delete/${widget.product.id}',
        auth: AuthScope.privileged,
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Product deleted successfully!"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to delete product"),
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Unable to delete product. Please try again."),
      ));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.red.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    CustomText(
                      "Confirm Deletion",
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      "This action cannot be undone. Delete this product?",
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  void _showUpdatePriceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, -6),
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  CustomText(
                    "Update price",
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    "Set a new selling price for this product.",
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 14),
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
                      filled: true,
                      fillColor: const Color(0xFFF6F7FB),
                      prefixIcon: const Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a valid price";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RButtoncolor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: loading ? null : _updatePrice,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save price"),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    final String formattedPrice =
        "N${NumberFormat('#,##0').format(widget.product.price)}";
    final String? primaryCategory = widget.product.categories.isNotEmpty
        ? widget.product.categories.first
        : null;

    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          elevation: 0,
          title: CustomText(
            "Update Overview",
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: RButtoncolor,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: CustomText(
                  formattedPrice,
                  fontWeight: FontWeight.w700,
                  color: RButtoncolor,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 30.h,
                          child: PageView(
                            children: widget.product.images.map((image) {
                              return Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(image),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  widget.product.name,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _InfoChip(
                                      icon: Icons.sell_outlined,
                                      label: formattedPrice,
                                      color: ROrange,
                                    ),
                                    if (primaryCategory != null) ...[
                                      const SizedBox(width: 8),
                                      _InfoChip(
                                        icon: Icons.category_rounded,
                                        label: primaryCategory,
                                        color: Colors.white,
                                        dark: true,
                                      ),
                                    ],
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RButtoncolor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: loading
                            ? null
                            : () {
                                _showUpdatePriceModal(context);
                              },
                        icon: loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.price_change_rounded),
                        label: CustomText(
                          loading ? "Updating..." : "Update price",
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                bool confirm =
                                    await _showConfirmationDialog(context);
                                if (confirm) {
                                  _deleteProduct();
                                }
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: CustomText(
                          "Delete",
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UpdateAllDetails(product: widget.product),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit_note, color: RButtoncolor),
                  label: CustomText(
                    "Edit all details",
                    fontWeight: FontWeight.w700,
                    color: RButtoncolor,
                  ),
                ),
                const SizedBox(height: 6),
                _InfoCard(
                  title: "Product Description",
                  body: widget.product.description?.isNotEmpty == true
                      ? widget.product.description!
                      : "No description provided.",
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: "Specifications",
                  body: widget.product.specification?.isNotEmpty == true
                      ? widget.product.specification!
                      : "No specifications provided.",
                ),
              ],
            ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.white24 : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: dark ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : color,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          const SizedBox(height: 8),
          CustomText(
            body,
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
