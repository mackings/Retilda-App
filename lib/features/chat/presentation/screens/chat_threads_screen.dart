import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Chat/api/chat_service.dart';
import 'package:retilda/Views/Chat/views/chat_screen.dart';
import 'package:retilda/Views/Staff/api/staff_service.dart';
import 'package:retilda/Views/Staff/views/staff_chat_screen.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class ChatThreadsScreen extends ConsumerStatefulWidget {
  const ChatThreadsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChatThreadsScreenState();
}

class _ChatThreadsScreenState extends ConsumerState<ChatThreadsScreen> {
  final ChatService _service = ChatService();
  final StaffService _staffService = StaffService();

  bool _loading = true;
  List<ChatThread> _threads = [];
  bool _isPrivileged = false;
  bool _staffActive = false;

  String? _extractRole(dynamic rawRoles) {
    if (rawRoles == null) return null;
    if (rawRoles is String) {
      final value = rawRoles.trim().toLowerCase();
      return value.isEmpty ? null : value;
    }
    if (rawRoles is List) {
      final roles = rawRoles
          .whereType<String>()
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toList();
      if (roles.contains('admin')) return 'admin';
      if (roles.contains('staff')) return 'staff';
      if (roles.contains('user')) return 'user';
      return roles.isNotEmpty ? roles.first : null;
    }
    return null;
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final storedStaffRole = prefs.getString('staffRole');
    final storedActive = prefs.getBool('staffActive') ?? false;
    final session = AppSession();
    final userData = await session.userData();
    final storedUserRole = await session.userRole();
    final staffToken = await session.staffToken();

    String? role;
    if (userData != null) {
      final rawRole = userData['data']?['user']?['roles'];
      role = _extractRole(rawRole) ?? storedUserRole;
    } else {
      role = storedStaffRole ?? (staffToken != null ? 'staff' : 'user');
    }

    setState(() {
      _isPrivileged = role == 'admin' || role == 'staff';
      _staffActive = storedActive;
    });
  }

  Future<void> _loadThreads() async {
    setState(() => _loading = true);
    final response = _isPrivileged
        ? await _staffService.listStaffThreads()
        : await _service.listUserThreads();
    setState(() {
      _threads = response.data ?? [];
      _loading = false;
    });
  }

  Future<void> _startChat() async {
    if (_isPrivileged) return;
    final staffResponse = await _service.listActiveStaff();
    if (!mounted) return;
    final staffList = staffResponse.data ?? [];

    if (staffList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff available right now.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffPickerSheet(
        staffList: staffList,
        onSelect: (staff) async {
          Navigator.pop(context);
          final result = await _service.startChat(staff.id ?? '');
          if (!mounted) return;
          if (result.success == true && result.data?.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  threadId: result.data!.id!,
                  staffName: staff.fullName,
                ),
              ),
            );
            await _loadThreads();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? 'Failed to start chat')),
            );
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRole().then((_) => _loadThreads());
  }

  Future<void> _toggleActive(bool value) async {
    final ok = await _staffService.setActive(value);
    if (!mounted) return;
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('staffActive', value);
      setState(() => _staffActive = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'You are active' : 'You are inactive')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
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
              'Chat',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
            actions: _isPrivileged
                ? null
                : [
                    IconButton(
                      onPressed: _startChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                    )
                  ],
          ),
          floatingActionButton: _isPrivileged
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: accent,
                  onPressed: _startChat,
                  label: const Text('New chat'),
                  icon: const Icon(Icons.add_comment_outlined),
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
                      if (_isPrivileged)
                        Container(
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
                          child: SwitchListTile(
                            value: _staffActive,
                            onChanged: _toggleActive,
                            title: const Text('Set yourself active'),
                            subtitle: Text(
                              _staffActive
                                  ? 'You can receive new chats'
                                  : 'You will not receive new chats',
                            ),
                          ),
                        ),
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
                              const SizedBox(height: 6),
                              if (!_isPrivileged)
                                CustomText(
                                  'Start a chat with a sales rep.',
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
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
                                builder: (_) => _isPrivileged
                                    ? StaffChatScreen(
                                        threadId: thread.id ?? '',
                                      )
                                    : ChatScreen(
                                        threadId: thread.id ?? '',
                                        staffName: 'Sales Rep',
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
                    'Sales Rep',
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

class _StaffPickerSheet extends StatelessWidget {
  final List<Staff> staffList;
  final void Function(Staff staff) onSelect;

  const _StaffPickerSheet({
    required this.staffList,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 14),
            CustomText(
              'Start chat with',
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
              color: deepBlue,
            ),
            const SizedBox(height: 12),
            ...staffList.map(
              (staff) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: deepBlue.withOpacity(0.1),
                  child: const Icon(Icons.person, color: deepBlue, size: 18),
                ),
                title: Text(staff.fullName ?? 'Sales Rep'),
                subtitle: Text(staff.email ?? ''),
                onTap: () => onSelect(staff),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
