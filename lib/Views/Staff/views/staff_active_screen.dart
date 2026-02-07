import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Staff/api/staff_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class StaffActiveScreen extends ConsumerStatefulWidget {
  const StaffActiveScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StaffActiveScreenState();
}

class _StaffActiveScreenState extends ConsumerState<StaffActiveScreen> {
  final StaffService _service = StaffService();
  bool _isActive = true;
  bool _saving = false;

  Future<void> _save(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await _service.setActive(value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _isActive = value;
    });
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
              'Staff status',
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
                child: SwitchListTile(
                  value: _isActive,
                  title: const Text('Active for chat'),
                  subtitle: const Text('Users can start chats when active'),
                  activeColor: accent,
                  onChanged: (value) => _save(value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
