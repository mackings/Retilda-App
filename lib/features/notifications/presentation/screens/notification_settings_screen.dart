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

  int get _enabledCount =>
      [_orderUpdates, _promos, _email].where((value) => value).length;

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

  Future<void> _updateSetting({
    required ValueSetter<bool> setValue,
    required bool value,
  }) async {
    setState(() => setValue(value));
    await _save();
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
                    _NotificationHero(enabledCount: _enabledCount),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniInsightCard(
                            label: 'Order alerts',
                            value: _orderUpdates ? 'On' : 'Off',
                            icon: Icons.local_shipping_outlined,
                            tint: const Color(0xFFEAF4FB),
                            iconColor: AppTheme.ocean,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniInsightCard(
                            label: 'Email updates',
                            value: _email ? 'On' : 'Off',
                            icon: Icons.mail_outline_rounded,
                            tint: const Color(0xFFFFF2E5),
                            iconColor: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SettingsGroup(
                      title: 'Primary alerts',
                      subtitle:
                          'Keep the important purchase and account updates flowing.',
                      children: [
                        _SettingCard(
                          value: _orderUpdates,
                          title: 'Order updates',
                          subtitle:
                              'Processing, ready, delivery, and completion updates.',
                          icon: Icons.inventory_2_outlined,
                          accentColor: AppTheme.ocean,
                          onChanged: (value) => _updateSetting(
                            value: value,
                            setValue: (next) => _orderUpdates = next,
                          ),
                        ),
                        _SettingCard(
                          value: _email,
                          title: 'Email notifications',
                          subtitle:
                              'Receive billing and support updates through email.',
                          icon: Icons.alternate_email_rounded,
                          accentColor: const Color(0xFF0E7C66),
                          onChanged: (value) => _updateSetting(
                            value: value,
                            setValue: (next) => _email = next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsGroup(
                      title: 'Optional updates',
                      subtitle:
                          'Only enable this if you want promotional messages.',
                      children: [
                        _SettingCard(
                          value: _promos,
                          title: 'Promotions',
                          subtitle:
                              'Special offers, discounts, launches, and campaigns.',
                          icon: Icons.local_offer_outlined,
                          accentColor: AppTheme.accent,
                          onChanged: (value) => _updateSetting(
                            value: value,
                            setValue: (next) => _promos = next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.ink.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              'Push notifications are currently delivered through your saved email and in-app updates in this release.',
                              fontSize: 12.7,
                              color: Colors.black.withValues(alpha: 0.62),
                            ),
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

class _NotificationHero extends StatelessWidget {
  const _NotificationHero({required this.enabledCount});

  final int enabledCount;

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
            'Stay in control',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          CustomText(
            'Choose which updates reach you for orders, billing, support, and promos without clutter.',
            fontSize: 13.2,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Channels active',
                  value: '$enabledCount of 3',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Delivery mode',
                  value: 'Email + app',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
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
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.72),
          ),
          const SizedBox(height: 7),
          CustomText(
            value,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          CustomText(
            label,
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.54),
          ),
          const SizedBox(height: 6),
          CustomText(
            value,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.ink,
        ),
        const SizedBox(height: 4),
        CustomText(
          subtitle,
          fontSize: 12.5,
          color: Colors.black.withValues(alpha: 0.56),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor),
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
                        title,
                        fontSize: 14.5,
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
                        color: value
                            ? const Color(0xFFE9F8F1)
                            : const Color(0xFFF2F5F8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: CustomText(
                        value ? 'On' : 'Off',
                        fontSize: 11.2,
                        fontWeight: FontWeight.w800,
                        color: value
                            ? const Color(0xFF0E7C66)
                            : Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CustomText(
                  subtitle,
                  fontSize: 12.4,
                  color: Colors.black.withValues(alpha: 0.58),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: value,
                    activeThumbColor: AppTheme.accent,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
