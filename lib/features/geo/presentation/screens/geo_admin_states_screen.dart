import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Geo/api/geo_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/geo.dart';
import 'package:sizer/sizer.dart';

class GeoAdminStatesScreen extends ConsumerStatefulWidget {
  const GeoAdminStatesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GeoAdminStatesScreenState();
}

class _GeoAdminStatesScreenState extends ConsumerState<GeoAdminStatesScreen> {
  final GeoService _service = GeoService();
  final TextEditingController _stateController = TextEditingController();

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

  Future<void> _addState() async {
    final name = _stateController.text.trim();
    if (name.isEmpty) return;
    final result = await _service.addState(name);
    if (result.success == true) {
      _stateController.clear();
      await _loadStates();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to add state')),
      );
    }
  }

  Future<void> _deactivateState(String id) async {
    final result = await _service.deactivateState(id);
    if (result.success == true) {
      await _loadStates();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to deactivate state')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _stateController.dispose();
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
              'Manage states',
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
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        children: [
                          TextField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              hintText: 'Add state e.g. Lagos',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addState,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Add state'),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
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
                              TextButton(
                                onPressed: () =>
                                    _deactivateState(state.id ?? ''),
                                child: const Text('Deactivate'),
                              )
                            else
                              const Text('Inactive'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
