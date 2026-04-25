import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Chat/api/chat_service.dart';
import 'package:retilda/Views/Chat/views/chat_screen.dart';
import 'package:retilda/Views/Staff/api/staff_service.dart';
import 'package:retilda/Views/Staff/views/staff_chat_screen.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/core/theme/app_theme.dart';
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
      isScrollControlled: true,
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
      if (!mounted) return;
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
    final openThreads = _threads
        .where((thread) => (thread.status ?? 'open').toLowerCase() != 'closed')
        .length;

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              _isPrivileged ? 'Support queue' : 'Chat',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
            actions: _isPrivileged
                ? null
                : [
                    IconButton(
                      onPressed: _startChat,
                      icon: const Icon(Icons.add_comment_outlined),
                    ),
                  ],
          ),
          floatingActionButton: _isPrivileged
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: AppTheme.accent,
                  onPressed: _startChat,
                  label: const Text('Start chat'),
                  icon: const Icon(Icons.chat_outlined),
                ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: AppTheme.accent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadThreads,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    children: [
                      _ChatHero(
                        isPrivileged: _isPrivileged,
                        threadCount: _threads.length,
                        openThreads: openThreads,
                        onStartChat: _isPrivileged ? null : _startChat,
                      ),
                      const SizedBox(height: 18),
                      if (_isPrivileged)
                        _AvailabilityCard(
                          active: _staffActive,
                          onChanged: _toggleActive,
                        ),
                      if (_isPrivileged) const SizedBox(height: 16),
                      if (_threads.isEmpty)
                        _EmptyChatState(
                          isPrivileged: _isPrivileged,
                          onStartChat: _isPrivileged ? null : _startChat,
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                _isPrivileged
                                    ? 'Active conversations'
                                    : 'Your conversations',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: CustomText(
                                '${_threads.length} threads',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._threads.map(
                          (thread) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ThreadTile(
                              thread: thread,
                              isPrivileged: _isPrivileged,
                              onOpen: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _isPrivileged
                                      ? StaffChatScreen(
                                          threadId: thread.id ?? '',
                                        )
                                      : ChatScreen(
                                          threadId: thread.id ?? '',
                                          staffName: 'Sales support',
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ChatHero extends StatelessWidget {
  const _ChatHero({
    required this.isPrivileged,
    required this.threadCount,
    required this.openThreads,
    this.onStartChat,
  });

  final bool isPrivileged;
  final int threadCount;
  final int openThreads;
  final VoidCallback? onStartChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            isPrivileged ? 'Support inbox' : 'Talk to Retilda',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          CustomText(
            isPrivileged
                ? 'Stay active, pick up conversations quickly, and keep delivery or payment questions moving.'
                : 'Reach a sales rep for payment, delivery, invoice, or order support from one thread.',
            fontSize: 13.2,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Open threads',
                  value: '$openThreads',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Total threads',
                  value: '$threadCount',
                ),
              ),
            ],
          ),
          if (onStartChat != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStartChat,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Start a new chat'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.72),
          ),
          const SizedBox(height: 7),
          CustomText(
            value,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.active,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color:
                  (active ? const Color(0xFFE9F8F1) : const Color(0xFFF2F5F8)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              active ? Icons.flash_on_rounded : Icons.pause_circle_outline,
              color: active ? const Color(0xFF0E7C66) : AppTheme.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  active ? 'You are active' : 'You are inactive',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
                const SizedBox(height: 4),
                CustomText(
                  active
                      ? 'New chats can be routed to you now.'
                      : 'Switch on availability to receive new chats.',
                  fontSize: 12.4,
                  color: Colors.black.withValues(alpha: 0.56),
                ),
              ],
            ),
          ),
          Switch(
            value: active,
            activeThumbColor: AppTheme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.isPrivileged,
    this.onStartChat,
  });

  final bool isPrivileged;
  final VoidCallback? onStartChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            CustomText(
              isPrivileged ? 'No active chats yet' : 'No chats yet',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
            const SizedBox(height: 8),
            CustomText(
              isPrivileged
                  ? 'New customer conversations will show up here as soon as they are created.'
                  : 'Start a chat when you need help with a payment, product, invoice, or delivery question.',
              fontSize: 12.9,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            if (onStartChat != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStartChat,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Start a chat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.isPrivileged,
    required this.onOpen,
  });

  final ChatThread thread;
  final bool isPrivileged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = (thread.status ?? 'open').toLowerCase();
    final isClosed = status == 'closed';

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onOpen,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.04),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isClosed
                      ? const [Color(0xFFB7C1CA), Color(0xFFD0D8DE)]
                      : const [Color(0xFF103C57), Color(0xFF145E8D)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isPrivileged ? Icons.support_agent_rounded : Icons.headset_mic,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          isPrivileged ? 'Customer thread' : 'Sales support',
                          fontSize: 14.8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? const Color(0xFFF1F4F7)
                              : const Color(0xFFE9F8F1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: CustomText(
                          isClosed ? 'Closed' : 'Open',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isClosed
                              ? Colors.black.withValues(alpha: 0.55)
                              : const Color(0xFF0E7C66),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    isPrivileged
                        ? 'Open the conversation to respond or update the customer.'
                        : 'Open your conversation and continue the discussion.',
                    fontSize: 12.4,
                    color: Colors.black.withValues(alpha: 0.56),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffPickerSheet extends StatelessWidget {
  const _StaffPickerSheet({
    required this.staffList,
    required this.onSelect,
  });

  final List<Staff> staffList;
  final void Function(Staff staff) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Choose a sales rep',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        'Pick an active support rep to start the conversation.',
                        fontSize: 12.4,
                        color: Colors.black.withValues(alpha: 0.56),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F7FB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...staffList.map(
              (staff) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelect(staff),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF103C57), Color(0xFF145E8D)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                staff.fullName ?? 'Sales rep',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                              if ((staff.email ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                CustomText(
                                  staff.email!,
                                  fontSize: 12.2,
                                  color: Colors.black.withValues(alpha: 0.56),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
