import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Notifications/api/notification_settings_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:sizer/sizer.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final NotificationSettingsService _service = NotificationSettingsService();

  bool _loading = true;
  bool _orderUpdates = true;
  bool _promos = false;
  bool _email = true;

  Future<void> _load() async {
    final settings = await _service.loadSettings();
    setState(() {
      _orderUpdates = settings['orderUpdates'] ?? true;
      _promos = settings['promos'] ?? false;
      _email = settings['email'] ?? true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.saveSettings(
      orderUpdates: _orderUpdates,
      promos: _promos,
      email: _email,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              'Notifications',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
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
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Stay in control',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          CustomText(
                            'Choose which updates you want Retilda to send for orders, promotions, and email activity.',
                            fontSize: 12.5.sp,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SettingTile(
                            value: _orderUpdates,
                            title: 'Order updates',
                            subtitle: 'Processing, ready, and delivered',
                            icon: Icons.local_shipping_outlined,
                            onChanged: (value) {
                              setState(() => _orderUpdates = value);
                              _save();
                            },
                          ),
                          _SettingTile(
                            value: _email,
                            title: 'Email notifications',
                            subtitle: 'Receive updates via email',
                            icon: Icons.mail_outline_rounded,
                            onChanged: (value) {
                              setState(() => _email = value);
                              _save();
                            },
                          ),
                          _SettingTile(
                            value: _promos,
                            title: 'Promotions',
                            subtitle: 'Special offers and discounts',
                            icon: Icons.local_offer_outlined,
                            onChanged: (value) {
                              setState(() => _promos = value);
                              _save();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomText(
                      'Push notifications are delivered via email in this release.',
                      fontSize: 11.5.sp,
                      color: Colors.black.withValues(alpha: 0.56),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      secondary: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.accent),
      ),
      value: value,
      title: CustomText(
        title,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.ink,
      ),
      subtitle: CustomText(
        subtitle,
        fontSize: 12.3,
        color: Colors.black.withValues(alpha: 0.58),
      ),
      activeColor: AppTheme.accent,
      onChanged: onChanged,
    );
  }
}
