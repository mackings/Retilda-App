import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Staff/api/staff_service.dart';
import 'package:retilda/Views/Staff/views/staff_chat_screen.dart';
import 'package:retilda/Views/Staff/views/staff_active_screen.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/chat.dart';
import 'package:sizer/sizer.dart';

class StaffThreadsScreen extends ConsumerStatefulWidget {
  const StaffThreadsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StaffThreadsScreenState();
}

class _StaffThreadsScreenState extends ConsumerState<StaffThreadsScreen> {
  final StaffService _service = StaffService();

  bool _loading = true;
  List<ChatThread> _threads = [];

  Future<void> _loadThreads() async {
    setState(() => _loading = true);
    final response = await _service.listStaffThreads();
    setState(() {
      _threads = response.data ?? [];
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadThreads();
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
              'Staff chats',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StaffActiveScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.toggle_on_outlined),
              )
            ],
          ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: accent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadThreads,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    children: [
                      if (_threads.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 140),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              CustomText(
                                'No chats yet',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: deepBlue,
                              ),
                            ],
                          ),
                        )
                      else
                        ..._threads.map(
                          (thread) => _ThreadTile(
                            thread: thread,
                            onOpen: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StaffChatScreen(
                                  threadId: thread.id ?? '',
                                ),
                              ),
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

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onOpen;

  const _ThreadTile({required this.thread, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
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
              child: const Icon(Icons.person, color: deepBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Customer',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: deepBlue,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    thread.status ?? 'open',
                    fontSize: 10.5.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
