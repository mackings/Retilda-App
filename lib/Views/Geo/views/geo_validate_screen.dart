import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Geo/api/geo_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/geo.dart';
import 'package:sizer/sizer.dart';

class GeoValidateScreen extends ConsumerStatefulWidget {
  const GeoValidateScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GeoValidateScreenState();
}

class _GeoValidateScreenState extends ConsumerState<GeoValidateScreen> {
  final GeoService _service = GeoService();
  final TextEditingController _addressController = TextEditingController();

  bool _loading = false;
  GeoValidationData? _result;

  Future<void> _validate() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    setState(() => _loading = true);
    final response = await _service.validateLocation(address);
    setState(() {
      _result = response.data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              'Delivery coverage',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Validate delivery location',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                      color: deepBlue,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Enter delivery address',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _validate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Validate'),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        _result?.formattedAddress ?? '',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(title: 'State', value: _result?.state ?? 'N/A'),
                      _InfoRow(
                        title: 'Operational',
                        value: (_result?.isOperational ?? false)
                            ? 'Yes'
                            : 'No',
                      ),
                      if (_result?.coordinates != null)
                        _InfoRow(
                          title: 'Coordinates',
                          value:
                              '${_result!.coordinates!.lat}, ${_result!.coordinates!.lng}',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
          CustomText(
            value,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: deepBlue,
          ),
        ],
      ),
    );
  }
}
