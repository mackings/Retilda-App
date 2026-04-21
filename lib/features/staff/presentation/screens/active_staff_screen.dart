import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Chat/api/chat_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/chat.dart';
import 'package:sizer/sizer.dart';

class ActiveStaffScreen extends ConsumerStatefulWidget {
  const ActiveStaffScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ActiveStaffScreenState();
}

class _ActiveStaffScreenState extends ConsumerState<ActiveStaffScreen> {
  final ChatService _service = ChatService();
  bool _loading = true;
  List<Staff> _staff = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    final response = await _service.listActiveStaff();
    setState(() {
      _staff = response.data ?? [];
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
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
              'Active staff',
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
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    children: [
                      if (_staff.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 140),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              CustomText(
                                'No active staff',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: deepBlue,
                              ),
                            ],
                          ),
                        )
                      else
                        ..._staff.map(
                          (staff) => Container(
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
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: deepBlue.withOpacity(0.1),
                                  child: const Icon(Icons.person,
                                      color: deepBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        staff.fullName ?? 'Staff',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                        color: deepBlue,
                                      ),
                                      const SizedBox(height: 4),
                                      CustomText(
                                        staff.email ?? '',
                                        fontSize: 10.5.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: CustomText(
                                    'Active',
                                    fontSize: 9.5.sp,
                                    color: accent,
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
