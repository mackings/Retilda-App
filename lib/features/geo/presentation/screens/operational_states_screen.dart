import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Geo/api/geo_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/geo.dart';
import 'package:sizer/sizer.dart';

class OperationalStatesScreen extends ConsumerStatefulWidget {
  const OperationalStatesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OperationalStatesScreenState();
}

class _OperationalStatesScreenState
    extends ConsumerState<OperationalStatesScreen> {
  final GeoService _service = GeoService();

  bool _loading = true;
  List<OperationalState> _states = [];

  Future<void> _loadStates() async {
    setState(() => _loading = true);
    final response = await _service.listStates();
    setState(() {
      _states = response.data ?? [];
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStates();
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
              'Operational states',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: accent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStates,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    children: [
                      if (_states.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 140),
                          child: Column(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              CustomText(
                                'No operational states',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: deepBlue,
                              ),
                              const SizedBox(height: 6),
                              CustomText(
                                'States will appear once added by admin.',
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        )
                      else
                        ..._states.map(
                          (state) => Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_city,
                                    color: deepBlue, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomText(
                                    state.name ?? 'State',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                    color: deepBlue,
                                  ),
                                ),
                                if (state.active == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: CustomText(
                                      'Active',
                                      fontSize: 9.5.sp,
                                      color: accent,
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: CustomText(
                                      'Inactive',
                                      fontSize: 9.5.sp,
                                      color: Colors.grey[600],
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
